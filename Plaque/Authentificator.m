//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Authentificator.h"
#import "Communicator.h"
#import "Paquet.h"

#include "API.h"

#ifdef DEBUG
#define VERBOSE
#endif

#define DeviceRegistrationTryInterval   5.0f

#ifdef DEBUG
#define DeviceTokenKey                  @"DeviceToken2"
#define SessionTokenKey                 @"SessionToken2"
#define ProfileTokenKey                 @"ProfileToken2"
#define NotificationsTokenKey           @"NotificationsToken2"
#else
#define DeviceTokenKey                  @"DeviceToken"
#define SessionTokenKey                 @"SessionToken"
#define ProfileTokenKey                 @"ProfileToken"
#define NotificationsTokenKey           @"NotificationsToken"
#endif

@interface Authentificator () <PaquetDelegate>

@end

@implementation Authentificator

+ (Authentificator *)sharedAuthentificator
{
    static dispatch_once_t onceToken;
    static Authentificator *authentificator;

    dispatch_once(&onceToken, ^{
        authentificator = [[Authentificator alloc] init];
    });

    return authentificator;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    //[self setDeviceToken:nil];
    //[self setNotificationsToken:nil];

    // Device token is important for all kinds of network communication.
    // If there is no device token associated to this device yet then
    // schedule the device registration action and try it once immediately right now.

    return self;
}

- (Boolean)deviceRegistered
{
    return [self deviceToken] != nil;
}

- (Boolean)profileRegistered
{
    return [self profileToken] != nil;
}

- (void)checkWhetherProfileNameIsFree:(NSString *)profileName
{
}

- (void)createProfileWithName:(NSString *)profileName
{
}

#pragma mark - Tokens

- (NSUUID *)deviceToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = [defaults stringForKey:DeviceTokenKey];
    if (tokenString == nil)
        return nil;

    NSUUID *token = [[NSUUID alloc] initWithUUIDString:tokenString];
    return token;
}

- (NSUUID *)sessionToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = [defaults stringForKey:SessionTokenKey];
    if (tokenString == nil)
        return nil;

    NSUUID *token = [[NSUUID alloc] initWithUUIDString:tokenString];
    return token;
}

- (NSUUID *)profileToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = [defaults stringForKey:ProfileTokenKey];
    if (tokenString == nil)
        return nil;

    NSUUID *token = [[NSUUID alloc] initWithUUIDString:tokenString];
    return token;
}

- (NSData *)notificationsToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults dataForKey:NotificationsTokenKey];
    return data;
}

- (void)setDeviceToken:(NSUUID *)deviceToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = (deviceToken == nil) ? nil : [deviceToken UUIDString];
    [defaults setValue:tokenString
                forKey:DeviceTokenKey];
    
#ifdef VERBOSE
    NSLog(@"Set device token: %@", [deviceToken UUIDString]);
#endif
}

- (void)setSessionToken:(NSUUID *)sessionToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = (sessionToken == nil) ? nil : [sessionToken UUIDString];
    [defaults setValue:tokenString
                forKey:SessionTokenKey];

#ifdef VERBOSE
    NSLog(@"Set session token: %@", [sessionToken UUIDString]);
#endif
}

- (void)setProfileToken:(NSUUID *)profileToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tokenString = (profileToken == nil) ? nil : [profileToken UUIDString];
    [defaults setValue:tokenString
                forKey:ProfileTokenKey];

#ifdef VERBOSE
    NSLog(@"Set profile token: %@", [profileToken UUIDString]);
#endif
}

- (void)setNotificationsToken:(NSData *)notificationsToken
{
    NSData *knownToken = [self notificationsToken];

    if ((knownToken == nil) || ([notificationsToken isEqualToData:knownToken] == NO))
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:notificationsToken
                    forKey:NotificationsTokenKey];

#ifdef VERBOSE
        NSLog(@"Set notifications token: %@", notificationsToken);
#endif
    }
}

- (void)validateNotificationsToken:(NSData *)notificationsToken
{
    NSData *knownToken = [self notificationsToken];

    if ((knownToken == nil) || ([notificationsToken isEqualToData:knownToken] == NO))
    {
        Paquet *paquet = [[Paquet alloc] initWithCommand:PaquetNotificationsToken];

        [paquet setDelegate:self];
        [paquet setUserInfo:notificationsToken];

        [paquet putData:notificationsToken];

        [paquet send];
    }
}

#pragma mark - Device registration

- (NSMutableData *)prepareAnticipant
{
    NSMutableData *anticipant = [NSMutableData data];

    NSUUID *deviceVendorId = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSString *deviceModel = [[UIDevice currentDevice] model];
    NSString *systemName = [[UIDevice currentDevice] systemName];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];

    uuid_t deviceVendorIdBytes;
    [deviceVendorId getUUIDBytes:deviceVendorIdBytes];
    NSData *deviceVendorIdData = [NSData dataWithBytes:deviceVendorIdBytes
                                                length:TokenBinarySize];
    [anticipant appendData:deviceVendorIdData];

    NSString *paddedString;
    NSData *paddedStringData;

    paddedString = [deviceName stringByPaddingToLength:AnticipantDeviceNameLength
                                        withString:@"\0"
                                   startingAtIndex:0];
    paddedStringData = [paddedString dataUsingEncoding:NSUTF8StringEncoding];
    [anticipant appendBytes:[paddedStringData bytes] length:AnticipantDeviceNameLength];

    paddedString = [deviceModel stringByPaddingToLength:AnticipantDeviceModelLength
                                        withString:@"\0"
                                   startingAtIndex:0];
    paddedStringData = [paddedString dataUsingEncoding:NSUTF8StringEncoding];
    [anticipant appendBytes:[paddedStringData bytes] length:AnticipantDeviceModelLength];

    paddedString = [systemName stringByPaddingToLength:AnticipantSystemNamelLength
                                        withString:@"\0"
                                   startingAtIndex:0];
    paddedStringData = [paddedString dataUsingEncoding:NSUTF8StringEncoding];
    [anticipant appendBytes:[paddedStringData bytes] length:AnticipantSystemNamelLength];

    paddedString = [systemVersion stringByPaddingToLength:AnticipantSystemVersionlLength
                                        withString:@"\0"
                                   startingAtIndex:0];
    paddedStringData = [paddedString dataUsingEncoding:NSUTF8StringEncoding];
    [anticipant appendBytes:[paddedStringData bytes] length:AnticipantSystemVersionlLength];

    return anticipant;
}

- (void)processAnticipant:(NSMutableData *)anticipant
{
    if ([anticipant length] == TokenBinarySize) {
        NSData* tokenData = [NSData dataWithBytesNoCopy:(char *)[anticipant bytes]
                                                 length:TokenBinarySize
                                           freeWhenDone:NO];
        NSUUID *deviceToken = [[NSUUID alloc] initWithUUIDBytes:[tokenData bytes]];
        if (deviceToken != nil)
            [self setDeviceToken:deviceToken];
    }
}

#pragma mark - Paquet delegate

- (void)paquetComplete:(Paquet *)paquet
{
    switch (paquet.commandCode)
    {
        case PaquetNotificationsToken:
        {
            UInt32 status = [paquet getUInt32];
            if (status == PaquetNotificationsTokenAccepted) {
#ifdef VERBOSE
                NSLog(@"Notifications token accepted");
#endif
                NSData *notificationsToken = [paquet userInfo];
                [self setNotificationsToken:notificationsToken];
            } else {
#ifdef VERBOSE
                NSLog(@"Notifications token declined: 0x%08X", status);
#endif
            }
            break;
        }

        default:
            break;
    }
}

@end
