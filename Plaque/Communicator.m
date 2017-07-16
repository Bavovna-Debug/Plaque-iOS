//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "GCDAsyncSocket.h"

#import "Authentificator.h"
#import "Communicator.h"
#import "Plaques.h"
#import "Servers.h"
#import "StatusBar.h"

#include "API.h"
#include "Definitions.h"

@interface Communicator () <GCDAsyncSocketDelegate>

@property (strong, nonatomic) NSLock            *connectionLock;
@property (strong, nonatomic) NSTimer           *reconnectTimer;
@property (strong, nonatomic) NSTimer           *flushQueueTimer;
@property (strong, nonatomic) NSMutableArray    *inputPieces;
@property (strong, nonatomic) NSLock            *inputPiecesLock;
@property (strong, nonatomic) NSLock            *inputPiecesReaderLock;
@property (strong, nonatomic) NSTimer           *inputPiecesReaderTimer;
@property (strong, nonatomic) NSMutableArray    *outputPieces;
@property (strong, nonatomic) NSLock            *outputPiecesLock;
@property (strong, nonatomic) GCDAsyncSocket    *socket;
@property (strong, nonatomic) NSMutableArray    *paquets;
@property (strong, nonatomic) NSLock            *paquetsLock;

@end

@implementation Communicator
{
    Boolean         connected;
    Boolean         disconnectWhenPossible;
    Boolean         anticipantConnection;
    Boolean         dialogueEstablished;
    Boolean         background;
    UInt32          lastPaquetId;
    NSMutableData   *pieceOnReceive;
    StatusBar       *statusBar;
}

+ (Communicator *)sharedCommunicator
{
    static dispatch_once_t onceToken;
    static Communicator *communicator;

    dispatch_once(&onceToken, ^
    {
        communicator = [[Communicator alloc] init];
    });

    return communicator;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.connectionLock = [[NSLock alloc] init];
    self.inputPieces = [NSMutableArray array];
    self.inputPiecesLock = [[NSLock alloc] init];
    self.inputPiecesReaderLock = [[NSLock alloc] init];
    self.outputPieces = [NSMutableArray array];
    self.outputPiecesLock = [[NSLock alloc] init];
    self.paquets = [NSMutableArray array];
    self.paquetsLock = [[NSLock alloc] init];

    connected = NO;
    lastPaquetId = 0;

    statusBar = [StatusBar sharedStatusBar];

    [self connect];

    return self;
}

- (void)switchToBackground
{
    background = YES;

    if (self.flushQueueTimer != nil)
    {
        [self.flushQueueTimer invalidate];
    }

    self.flushQueueTimer =
    [NSTimer scheduledTimerWithTimeInterval:FlushQueueBackgroundInterval
                                     target:self
                                   selector:@selector(flushOutputQueue)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)switchToForeground
{
    background = NO;

    [self connect];

    if (self.flushQueueTimer != nil)
    {
        [self.flushQueueTimer invalidate];
    }

    self.flushQueueTimer =
    [NSTimer scheduledTimerWithTimeInterval:FlushQueueForegroundInterval
                                     target:self
                                   selector:@selector(flushOutputQueue)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)send:(Paquet *)paquet
{
    [self.paquetsLock lock];

    lastPaquetId++;

    [paquet setPaquetId:lastPaquetId];

    [self.paquets addObject:paquet];

    [self.paquetsLock unlock];

    [self enqueue:paquet];

    [self flushOutputQueue];
}

- (void)enqueue:(Paquet *)paquet
{
    NSMutableData *piece = [NSMutableData data];

    {
        // Paquet signature.
        //
        UInt64 signature = CFSwapInt64HostToBig(API_PaquetSignature);
        [piece appendBytes:&signature
                    length:sizeof(signature)];

        UInt32 paquetId = CFSwapInt32HostToBig([paquet paquetId]);
        [piece appendBytes:&paquetId
                    length:sizeof(paquetId)];

        UInt32 commandCode = CFSwapInt32HostToBig([paquet commandCode]);
        [piece appendBytes:&commandCode
                    length:sizeof(commandCode)];

        UInt32 commandSubcode = CFSwapInt32HostToBig([paquet commandSubcode]);
        [piece appendBytes:&commandSubcode
                    length:sizeof(commandSubcode)];

        UInt32 payloadSize = CFSwapInt32HostToBig((UInt32)[paquet.payload length]);
        [piece appendBytes:&payloadSize
                    length:sizeof(payloadSize)];
    }

    NSUInteger payloadSize = [paquet.payload length];

    if ([piece length] + payloadSize <= BytesPerSendFragment)
    {
        [piece appendData:paquet.payload];

        [self.outputPiecesLock lock];
        [self.outputPieces addObject:piece];
        [self.outputPiecesLock unlock];

#ifdef VerboseCommunicationEnqueue
        NSLog(@"[Communicator] Enqueue single piece of paquet %d with %lu bytes command=0x%08X",
              (unsigned int) paquet.paquetId,
              (unsigned long) [piece length],
              (unsigned int) [paquet commandCode]);
#endif
    }
    else
    {
        NSUInteger packedBytes = 0;
        NSUInteger bytesToPack = BytesPerSendFragment - [piece length];

        [self.outputPiecesLock lock];
        while (packedBytes < payloadSize)
        {
            [piece appendBytes:[paquet.payload bytes] + packedBytes
                        length:bytesToPack];
            [self.outputPieces addObject:piece];
#ifdef VerboseCommunicationEnqueue
            NSLog(@"[Communicator] Enqueue piece of paquet %d with %lu bytes",
                  (unsigned int) paquet.paquetId,
                  (unsigned long) [piece length]);
#endif

            // Reset piece for next loop.
            //
            piece = [NSMutableData data];

            packedBytes += bytesToPack;

            bytesToPack = MIN(BytesPerSendFragment, payloadSize - packedBytes);
        }
        [self.outputPiecesLock unlock];
    }

    [paquet setInTheAir:YES];
}

// Paquets lock must be held locked when dequeue() is called.
//
- (void)dequeue:(Paquet *)paquet
        payload:(NSMutableData *)payload
{
    [self.paquets removeObject:paquet];

    if (disconnectWhenPossible == TRUE)
    {
        // If a non-forced disconnect has being requested then do disconnect
        // if there are no outstanding paquets in a queue.
        //
        if ([self.paquets count] == 0)
        {
            [self disconnect:YES];
        }

        disconnectWhenPossible = FALSE;
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [paquet complete:payload];
    });
}

- (void)flushOutputQueue
{
    // If not connected then start connect.
    //
    if (connected == NO)
    {
#ifdef VerboseCommunicationSocketConnection
        NSLog(@"[Communicator] Not connected");
#endif
        [self connect];
        return;
    }

    if ([self.paquetsLock tryLock] == YES)
    {
        BOOL needToLoop;

        do
        {
            needToLoop = FALSE;
            for (Paquet *paquet in self.paquets)
            {
                if ([paquet cancelWhenPossible] == YES)
                {
                    [self.paquets removeObject:paquet];
                    needToLoop = TRUE;
                    break;
                }

                if ([paquet inTheAir] == NO)
                {
                    [self enqueue:paquet];
                }
            }
        }
        while (needToLoop == TRUE);

        [self.paquetsLock unlock];
    }

    if (dialogueEstablished == NO)
    {
#ifdef VerboseCommunicationSocketConnection
        NSLog(@"[Communicator] Dialogue not established yet");
#endif
    }
    else
    {
        [self.outputPiecesLock lock];

        while ([self.outputPieces count] > 0)
        {
            NSMutableData *piece = [self.outputPieces firstObject];

            [self.socket writeData:piece
                       withTimeout:TimeoutOnWaitingForPaquetTransmit
                               tag:2];

            [self.outputPieces removeObject:piece];
        }
        
        [self.outputPiecesLock unlock];
    }
}

#pragma mark - Connection

- (void)connect
{
    // Already connected or trying to establish connection right now?
    // If yes, then quit.
    //
    if ([self.connectionLock tryLock] == NO)
    {
#ifdef VerboseCommunicationSocketConnection
        NSLog(@"[Communicator] Already connected or establishing a connection");
#endif
        return;
    }

#ifdef VerboseCommunicationSocketConnection
    NSLog(@"[Communicator] Establish connection");
    [statusBar postMessage:NSLocalizedString(@"STATUS_BAR_VPCLOUD_ESTABLISH_CONNECTION", nil)];
#endif

    dialogueEstablished = NO;

    Authentificator *authentificator = [Authentificator sharedAuthentificator];
    if ([authentificator deviceRegistered] == NO)
    {
        anticipantConnection = YES;
    }
    else
    {
        anticipantConnection = NO;
    }

    Servers *servers = [Servers sharedServers];

    self.socket =
    [[GCDAsyncSocket alloc] initWithDelegate:self
                               delegateQueue:dispatch_get_main_queue()];

    [self.socket setIPv4Enabled:YES];
    [self.socket setIPv6Enabled:YES];
    [self.socket setIPv4PreferredOverIPv6:YES];

    if (background == YES)
    {
        [self.socket performBlock:^
        {
            [self.socket enableBackgroundingOnSocket];
        }];
    }

    NSError *error = nil;
    BOOL status = [self.socket connectToHost:[servers serverAddress]
                                      onPort:[servers serverPort]
                                       error:&error];
    NSLog(@"[Communicator] Connecting %@ %u",
          [servers serverAddress],
          (unsigned int) [servers serverPort]);

    [servers nextServer];

    if (status == NO)
    {
        [self.connectionLock unlock];

        [statusBar postMessage:NSLocalizedString(@"STATUS_BAR_VPCLOUD_CANNOT_CONNECT", nil)];

#ifdef VerboseCommunicationSocketConnection
        NSLog(@"[Communicator] Cannot connect: %@", error);
#endif
    }
}

- (void)disconnect:(Boolean)forced
{
    if (forced == YES)
    {
        [self.socket disconnect];
    }
    else
    {
        disconnectWhenPossible = TRUE;
    }
}

- (void)clearAllQueues
{
    [self.paquetsLock lock];
    [self.inputPiecesLock lock];
    [self.outputPiecesLock lock];

    for (Paquet *paquet in self.paquets)
    {
        [paquet setInTheAir:NO];
    }

    [self.inputPieces removeAllObjects];

    [self.outputPieces removeAllObjects];

    [self.outputPiecesLock unlock];
    [self.inputPiecesLock unlock];
    [self.paquetsLock unlock];
}

- (void)scheduleReconnectWithInterval:(NSTimeInterval)reconnectInterval
{
    // Don't reconnect if application is in background mode.
    //
    if (background == YES)
        return;

    // If reconnect is already scheduled then stop the timer.
    //
    NSTimer *reconnectTimer = self.reconnectTimer;
    if (reconnectTimer != nil)
    {
        [reconnectTimer invalidate];
    }

    self.reconnectTimer =
    [NSTimer scheduledTimerWithTimeInterval:reconnectInterval
                                     target:self
                                   selector:@selector(fireReconnect:)
                                   userInfo:nil
                                    repeats:NO];

    [statusBar postMessage:[NSString stringWithFormat:
                            NSLocalizedString(@"STATUS_BAR_VPCLOUD_SCHEDULE_RECONNECT", nil),
                            reconnectInterval]];
}

- (void)fireReconnect:(NSTimer *)timer
{
    [self connect];
}

#pragma mark - Socket delegate

- (void)socket:(GCDAsyncSocket *)sock
didConnectToHost:(NSString *)host
          port:(uint16_t)port
{
#ifdef VerboseCommunicationSocketConnection
    NSLog(@"[Communicator] Connected");
#endif

    connected = YES;

    [self.connectionLock unlock];

    [statusBar postMessage:NSLocalizedString(@"STATUS_BAR_VPCLOUD_CONNECTION_ESTABLISHED", nil)];

#ifdef VerboseCommunicationSocket
    NSLog(@"[Communicator] Send dialogue demande");
#endif
    NSMutableData *payload = [self prepareDialogueDemande];
    [self.socket writeData:payload
               withTimeout:TimeoutOnDialogueTransmit
                       tag:0];

    if (anticipantConnection == YES)
    {
        NSMutableData *anticipant = [[Authentificator sharedAuthentificator] prepareAnticipant];
        [self.socket writeData:anticipant
                   withTimeout:TimeoutOnAnticipantTransmit
                           tag:1];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
                  withError:(NSError *)error
{
#ifdef VerboseCommunicationSocketConnection
    NSLog(@"[Communicator] Disconnected");
#endif

    self.socket = nil;

    connected = NO;

    // If connection lock is occupied then disconnect happened right after connect request.
    //
    if ([self.connectionLock tryLock] == NO)
    {
#ifdef VerboseCommunicationSocketConnection
        NSLog(@"[Communicator] Disconnect without I/O");
#endif
    }
    else
    {
        [statusBar postMessage:NSLocalizedString(@"STATUS_BAR_VPCLOUD_LOST_CONNECTION", nil)];
    }

    [self processCards];

    [self clearAllQueues];

    [self.connectionLock unlock];

}

#ifdef VerboseCommunicationSocket
- (void)socket:(GCDAsyncSocket *)sock
didWritePartialDataOfLength:(NSUInteger)partialLength
           tag:(long)tag
{
    NSLog(@"[Communicator] Written %lu bytes of tag %ld",
          (unsigned long) partialLength, tag);
}
#endif

- (void)socket:(GCDAsyncSocket *)sock
didWriteDataWithTag:(long)tag
{
    [self flushOutputQueue];

    NSMutableData *nextPieceToReceive = [NSMutableData data];

    [self.socket readDataWithTimeout:TimeoutOnWaitingForPaquetReceive
                              buffer:nextPieceToReceive
                        bufferOffset:0
                                 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock
   didReadData:(NSData *)data
       withTag:(long)tag
{
#ifdef VerboseCommunicationReadData
    NSLog(@"[Communicator] Read %lu bytes from socket",
          (unsigned long) [data length]);
#endif
    if (anticipantConnection == YES)
    {
        NSMutableData *anticipant = [NSMutableData dataWithData:data];
        [[Authentificator sharedAuthentificator] processAnticipant:anticipant];
    }
    else
    {
        NSMutableData *recivedPiece = [NSMutableData dataWithData:data];

#ifdef VerboseCommunicationDumpReceivedPayload
        // TODO
#endif

        [self.inputPiecesLock lock];
        [self.inputPieces addObject:recivedPiece];
        [self.inputPiecesLock unlock];
        
        NSMutableData *nextPieceToReceive = [NSMutableData data];
        [self.socket readDataWithTimeout:TimeoutOnWaitingForPaquetReceive
                                  buffer:nextPieceToReceive
                            bufferOffset:0
                                     tag:0];

        [self processCards];
        
        [self flushOutputQueue];
    }
}

#pragma mark - Dialogue

- (NSMutableData *)prepareDialogueDemande
{
    NSMutableData *payload = [NSMutableData data];

    // Dialogue signature.
    //
    UInt64 dialogueSignature = CFSwapInt64HostToBig(API_DialogueSignature);
    [payload appendBytes:&dialogueSignature
                  length:sizeof(dialogueSignature)];

    // Device's timestamp.
    //
    NSTimeInterval deviceTimestamp = [[NSDate date] timeIntervalSince1970];
    [payload appendBytes:&deviceTimestamp
                  length:sizeof(deviceTimestamp)];

    // Dialogue type.
    //
    UInt32 dialogueType;
    if (anticipantConnection == YES)
    {
        dialogueType = CFSwapInt32HostToBig(API_DialogueTypeAnticipant);
    }
    else
    {
        dialogueType = CFSwapInt32HostToBig(API_DialogueTypeRegular);
    }
    [payload appendBytes:&dialogueType
                  length:sizeof(dialogueType)];

    // Application version.
    //
    UInt8 applicationVersion;
    UInt8 applicationSubersion;
    UInt16 applicationRelease;
    UInt16 deviceType;

    //NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        deviceType = API_DeviceTypeAppleiPad;
    }
    else
    {
        deviceType = API_DeviceTypeAppleiPhone;
    }

    NSData *buildData = [build dataUsingEncoding:NSUTF8StringEncoding];
    [payload appendBytes:[buildData bytes] length:[buildData length]];

    [payload appendBytes:&applicationVersion
                  length:sizeof(applicationVersion)];
    [payload appendBytes:&applicationSubersion
                  length:sizeof(applicationSubersion)];
    [payload appendBytes:&applicationRelease
                  length:sizeof(applicationRelease)];
    [payload appendBytes:&deviceType
                  length:sizeof(deviceType)];

    // Device token.
    //
    {
        NSUUID *deviceToken = [[Authentificator sharedAuthentificator] deviceToken];
        if (deviceToken == nil)
        {
            deviceToken = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        }

        uuid_t deviceTokenBytes;
        [deviceToken getUUIDBytes:deviceTokenBytes];
        NSData *deviceTokenData = [NSData dataWithBytes:deviceTokenBytes
                                                 length:API_TokenBinarySize];
        [payload appendData:deviceTokenData];
    }

    // Profile token.
    //
    {
        NSUUID *profileToken = [[Authentificator sharedAuthentificator] profileToken];
        if (profileToken == nil)
        {
            profileToken = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        }

        uuid_t profileTokenBytes;
        [profileToken getUUIDBytes:profileTokenBytes];
        NSData *profileTokenData = [NSData dataWithBytes:profileTokenBytes
                                                  length:API_TokenBinarySize];
        [payload appendData:profileTokenData];
    }

    // Session token.
    //
    {
        NSUUID *sessionToken = [[Authentificator sharedAuthentificator] sessionToken];
        if (sessionToken == nil)
        {
            sessionToken = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        }

        uuid_t sessionTokenBytes;
        [sessionToken getUUIDBytes:sessionTokenBytes];
        NSData *sessionTokenData = [NSData dataWithBytes:sessionTokenBytes
                                                  length:API_TokenBinarySize];
        [payload appendData:sessionTokenData];
    }

    return payload;
}

- (Boolean)parseDialogueVerdict:(NSMutableData *)data
{
#ifdef VerboseCommunicationDialogue
    NSLog(@"[Communicator] Parsing dialogue verdict");
#endif

    UInt64 dialogueSignature;
    UInt32 verdictCode;
    NSUUID *sessionToken;

    NSUInteger payloadOffset = 0;
    NSData* fetchData;
    
    // Dialogue signature.
    //
    {
        fetchData = [NSData dataWithBytesNoCopy:(char *) [data bytes] + payloadOffset
                                         length:sizeof(dialogueSignature)
                                   freeWhenDone:NO];

        [fetchData getBytes:&dialogueSignature length:sizeof(dialogueSignature)];

        payloadOffset += sizeof(dialogueSignature);

        dialogueSignature = CFSwapInt64BigToHost(dialogueSignature);
    }

    // Dialogue status.
    //
    {
        fetchData = [NSData dataWithBytesNoCopy:(char *) [data bytes] + payloadOffset
                                         length:sizeof(verdictCode)
                                   freeWhenDone:NO];

        [fetchData getBytes:&verdictCode length:sizeof(verdictCode)];

        payloadOffset += sizeof(verdictCode);

        verdictCode = CFSwapInt32BigToHost(verdictCode);
    }

    // Session token.
    //
    {
        fetchData = [NSData dataWithBytesNoCopy:(char *) [data bytes] + payloadOffset
                                         length:API_TokenBinarySize
                                   freeWhenDone:NO];

        sessionToken = [[NSUUID alloc] initWithUUIDBytes:[fetchData bytes]];
    }

    if (dialogueSignature != API_DialogueSignature)
    {
#ifdef VerboseCommunicationDialogue
        NSLog(@"[Communicator] Wrong dialogue signature 0x%016llX",
              dialogueSignature);
#endif
        return FALSE;
    }

    Authentificator *authentificator = [Authentificator sharedAuthentificator];

    switch (verdictCode)
    {
        case API_DialogueVerdictWelcome:
        {
#ifdef VerboseCommunicationDialogue
            NSLog(@"[Communicator] Dialogue established");
#endif

            id<ConnectionDelegate> delegate = self.connectionDelegate;
            if (delegate != nil)
            {
                [delegate communicatorDidEstablishDialogue];
            }

            break;
        }

        case API_DialogueVerdictInvalidDevice:
        {
#ifdef VerboseCommunicationDialogue
            NSLog(@"[Communicator] Dialogue verdict: invalid device");
#endif

            [authentificator setDeviceToken:nil];

            return FALSE;

            break;
        }

        case API_DialogueVerdictInvalidProfile:
        {
#ifdef VerboseCommunicationDialogue
            NSLog(@"[Communicator] Dialogue verdict: invalid profile");
#endif

            [authentificator setProfileToken:nil];

            break;
        }

        case API_DialogueVerdictNewSession:
        {
#ifdef VerboseCommunicationDialogue
            NSLog(@"[Communicator] Dialogue verdict: open new session %@",
                  [sessionToken UUIDString]);
#endif

            [authentificator setSessionToken:sessionToken];

            [[Plaques sharedPlaques] removeAllPlaques];

            break;
        }

        default:
        {
#ifdef VerboseCommunicationDialogue
            NSLog(@"[Communicator] Unknown dialogue status 0x%08X",
                  (unsigned int) verdictCode);
#endif

            break;
        }
    }

    return TRUE;
}

- (void)processCards
{
    if ([self.inputPiecesReaderLock tryLock] == NO)
    {
        NSTimer *inputPiecesReaderTimer = self.inputPiecesReaderTimer;
        if (inputPiecesReaderTimer != nil)
            [inputPiecesReaderTimer invalidate];

        self.inputPiecesReaderTimer =
        [NSTimer scheduledTimerWithTimeInterval:TimerIntervalProcessInputPieces
                                         target:self
                                       selector:@selector(processCards)
                                       userInfo:nil
                                        repeats:NO];
        return;
    }

    while (TRUE)
    {
        [self.inputPiecesLock lock];

        if ([self.inputPieces count] == 0)
        {
            [self.inputPiecesLock unlock];

            break;
        }

        NSMutableData *piece = [self.inputPieces firstObject];

        UInt64 cardSignature;
        UInt32 paquetId;
        UInt32 commandCode;
        UInt32 commandSubcode;
        UInt32 payloadSize;
        NSUInteger headerSize;

        if (dialogueEstablished == NO)
        {
            paquetId = 0;
            commandCode = 0;
            commandSubcode = 0;
            payloadSize = sizeof(UInt64) + sizeof(UInt32) + API_TokenBinarySize;
            headerSize = 0;

            if ([piece length] < payloadSize)
            {
                [self.inputPiecesLock unlock];

                break;
            }
        }
        else
        {
            headerSize =
            sizeof(cardSignature) +
            sizeof(paquetId) +
            sizeof(commandCode) +
            sizeof(commandSubcode) +
            sizeof(payloadSize);

            if ([piece length] < headerSize)
            {
                [self.inputPiecesLock unlock];

                break;
            }

            NSData *data;
            NSUInteger dataOffset = 0;

            {
                data =
                [NSData dataWithBytesNoCopy:(char *) [piece bytes] + dataOffset
                                     length:sizeof(cardSignature)
                               freeWhenDone:NO];

                [data getBytes:&cardSignature
                        length:sizeof(cardSignature)];
            }

            dataOffset += sizeof(cardSignature);

            {
                data =
                [NSData dataWithBytesNoCopy:(char *) [piece bytes] + dataOffset
                                     length:sizeof(paquetId)
                               freeWhenDone:NO];

                [data getBytes:&paquetId
                        length:sizeof(paquetId)];
            }

            dataOffset += sizeof(paquetId);

            {
                data =
                [NSData dataWithBytesNoCopy:(char *) [piece bytes] + dataOffset
                                     length:sizeof(commandCode)
                               freeWhenDone:NO];

                [data getBytes:&commandCode
                        length:sizeof(commandCode)];
            }

            dataOffset += sizeof(commandCode);

            {
                data =
                [NSData dataWithBytesNoCopy:(char *) [piece bytes] + dataOffset
                                     length:sizeof(commandSubcode)
                               freeWhenDone:NO];

                [data getBytes:&commandSubcode
                        length:sizeof(commandSubcode)];
            }

            dataOffset += sizeof(commandSubcode);

            {
                data =
                [NSData dataWithBytesNoCopy:(char *) [piece bytes] + dataOffset
                                     length:sizeof(payloadSize)
                               freeWhenDone:NO];

                [data getBytes:&payloadSize
                        length:sizeof(payloadSize)];
            }

            cardSignature = CFSwapInt64BigToHost(cardSignature);
            paquetId = CFSwapInt32BigToHost(paquetId);
            commandCode = CFSwapInt32BigToHost(commandCode);
            commandSubcode = CFSwapInt32BigToHost(commandSubcode);
            payloadSize = CFSwapInt32BigToHost(payloadSize);
            
#ifdef VerboseCommunicationProcessCards
            NSLog(@"[Communicator] Piece contains paquet %d for command 0x%08X with payload %d bytes",
                  (unsigned int) paquetId,
                  (unsigned int) commandCode,
                  (unsigned int) payloadSize);
#endif
        }

        // Calculate the amount of available data and amount of data needed to process one paquet.
        //
        NSUInteger sizeOfFirstPaquet = headerSize + payloadSize;
        NSUInteger sizeOfAllPieces = 0;

        for (NSMutableData *inputPiece in self.inputPieces)
        {
            sizeOfAllPieces += [inputPiece length];
        }

        // Quit if not enough data received yet.
        //
        if (sizeOfAllPieces < sizeOfFirstPaquet)
        {
#ifdef VerboseCommunicationProcessCards
            NSLog(@"[Communicator] Not enough data received yet: available %lu bytes in %lu pieces, expected %lu bytes",
                  (unsigned long) sizeOfAllPieces,
                  (unsigned long) [self.inputPieces count],
                  (unsigned long) sizeOfFirstPaquet);
#endif
            [self.inputPiecesLock unlock];

            break;
        }

        NSMutableData *payload;
        if ([piece length] == sizeOfFirstPaquet)
        {
            //
            // First piece is a complete paquet.
            //
            payload = [NSMutableData dataWithBytes:(char *) [piece bytes] + headerSize
                                            length:payloadSize];

            // Remove piece from the queue.
            //
            [self.inputPieces removeObject:piece];
        }
        else
        {
            //
            // First piece is either a part of a paquet or it contains also data of the next paquet as well.

            NSUInteger bytesOfRestOfPayload = payloadSize;
            NSInteger offsetInCurrentPiece = headerSize;

            // Allocate payload.
            //
            payload = [NSMutableData data];

            do
            {
                // Which amount of data can be taken out of the piece.
                //
                NSUInteger bytesToTakeFromPiece = [piece length] - offsetInCurrentPiece;

                // If it is less then needed for current paquet then take complete data and get to the next piece.
                // If it is exactly an amount of data needed for current paquet then just take the data.
                //
                if (bytesToTakeFromPiece <= bytesOfRestOfPayload)
                {
                    NSUInteger pieceSize = [piece length];

                    if (pieceSize <= offsetInCurrentPiece)
                    {
                        // If current piece contains only a paquet pilot or even just part of paquet pilot
                        // then mention how many bytes of paquet pilot are already skipped.
                        //
                        offsetInCurrentPiece -= pieceSize;
                    }
                    else
                    {
                        NSMutableData *payloadPart;

                        if (offsetInCurrentPiece == 0)
                        {
                            // This is a portion of data without paquet pilot.
                            //
                            payloadPart = piece;
                        }
                        else
                        {
                            // This is a portion of data with paquet pilot. Skip paquet pilot.
                            //
                            payloadPart = [NSMutableData dataWithBytes:(char *)[piece bytes] + offsetInCurrentPiece
                                                                length:bytesToTakeFromPiece];
                        }

                        // Append payload part.
                        //
                        [payload appendData:payloadPart];

                        // Paquet pilot or its part were skipped and there are no other parts of paquet pilot
                        // any more in further pieces.
                        //
                        offsetInCurrentPiece = 0;

                        bytesOfRestOfPayload -= [payloadPart length];
                    }

                    // Remove handled piece from the queue.
                    //
                    [self.inputPieces removeObject:piece];

                    // Switch to next piece.
                    //
                    piece = [self.inputPieces firstObject];
                }
                else
                {
                    // This piece contains data from the next paquet(s).
                    // Split piece in two parts.

                    NSUInteger numberOfBytesLeft = bytesOfRestOfPayload + offsetInCurrentPiece;
                    NSUInteger numberOfBytesRight = [piece length] - numberOfBytesLeft;

                    // Left part contains data for current paquet.
                    //
                    NSData *leftPart =
                    [NSData dataWithBytes:(char *)[piece bytes] + offsetInCurrentPiece
                                   length:numberOfBytesLeft - offsetInCurrentPiece];

                    // Right part contains data for the next paquet(s).
                    //
                    NSData *rightPart =
                    [NSData dataWithBytes:(char *)[piece bytes] + numberOfBytesLeft
                                   length:numberOfBytesRight];

                    // Append payload part.
                    //
                    [payload appendData:leftPart];

                    // Replace the first piece in a queue with the rest of data.
                    //
                    [self.inputPieces replaceObjectAtIndex:0 withObject:rightPart];

                    // This was anyway the last piece to process for current paquet.
                    // Therefore quit from the loop.
                    //
                    break;
                }
            }
            while (piece != nil);
        }

        [self.inputPiecesLock unlock];

#ifdef VerboseCommunicationProcessCards
        NSLog(@"[Communicator] Taken payload %lu bytes (%lu pieces left in a queue)",
              (unsigned long) [payload length],
              (unsigned long) [self.inputPieces count]);
#endif

        if (dialogueEstablished == NO)
        {
            if ([self parseDialogueVerdict:payload] == FALSE)
            {
                [self disconnect:YES];
                [self scheduleReconnectWithInterval:ReconnectIntervalIfHandshakeFailed];
            }
            else
            {
                dialogueEstablished = YES;
            }
        }
        else
        {
            if (paquetId == 0)
            {
                // This paquet was initiated by cloud. Look for a corresponding handler.
                //
                /*switch (commandCode)
                {
                    case XXX:
                        break;
                        
                    default:
                        break;
                }*/
            }
            else
            {
                // Search for paquet in paquet queue. If there is one then dequeue it - paquet owner is waiting
                // for paquet completion notification.
                //
                [self.paquetsLock lock];

                for (Paquet *paquet in self.paquets)
                {
                    if (paquet.paquetId == paquetId)
                    {
                        if (paquet.commandCode == commandCode)
                        {
                            paquet.commandSubcode = commandSubcode;
                            
                            [self dequeue:paquet payload:payload];

                            break;
                        }
                    }
                }

                [self.paquetsLock unlock];
            }
        }
    }

    [self.inputPiecesReaderLock unlock];
}

@end
