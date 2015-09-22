//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Communicator.h"
#import "Paquet.h"

#include "API.h"

#ifdef DEBUG
#undef VERBOSE_TO_ARGB
#undef VERBOSE_FROM_ARGB
#undef VERBOSE_FROM_ARGB_FLOATS
#endif

@implementation Paquet
{
    NSUInteger payloadOffset;
}

- (id)initWithCommand:(UInt32)commandCode;
{
    self = [super init];
    if (self == nil)
        return nil;

    self.commandCode = commandCode;
    self.payload = [NSMutableData data];
    self.inTheAir = NO;

    payloadOffset = 0;

    return self;
}

- (void)send
{
    [[Communicator sharedCommunicator] send:self];
}

- (void)complete:(NSMutableData *)payload
{
    self.payload = payload;
    payloadOffset = 0;

    id<PaquetDelegate> delegate = self.delegate;
    if (delegate != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate paquetComplete:self];
        });
    }
}

- (BOOL)payloadEOF
{
    return (payloadOffset < [self.payload length]) ? NO : YES;
}

- (void)putBoolean:(Boolean)value
{
    [self.payload appendBytes:&value length:sizeof(value)];
}

- (Boolean)getBoolean
{
    UInt8 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return value;
}

- (void)putUInt16:(UInt16)value
{
    value = CFSwapInt16HostToBig(value);
    [self.payload appendBytes:&value length:sizeof(value)];
}

- (UInt16)getUInt16
{
    UInt16 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return CFSwapInt16BigToHost(value);
}

- (void)putUInt32:(UInt32)value
{
    value = CFSwapInt32HostToBig(value);
    [self.payload appendBytes:&value length:sizeof(value)];
}

- (UInt32)getUInt32
{
    UInt32 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return CFSwapInt32BigToHost(value);
}

- (void)putUInt64:(UInt64)value
{
    value = CFSwapInt64HostToBig(value);
    [self.payload appendBytes:&value length:sizeof(value)];
}

- (UInt64)getUInt64
{
    UInt64 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return CFSwapInt64BigToHost(value);
}

- (void)putDouble:(double)value
{
    CFSwappedFloat64 swapped = CFConvertDoubleHostToSwapped(value);
    [self.payload appendBytes:&swapped length:sizeof(swapped)];
}

- (double)getDouble
{
    CFSwappedFloat64 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return CFConvertDoubleSwappedToHost(value);
}

- (void)putFloat:(float)value
{
    CFSwappedFloat32 swapped = CFConvertFloatHostToSwapped(value);
    [self.payload appendBytes:&swapped length:sizeof(swapped)];
}

- (float)getFloat
{
    CFSwappedFloat32 value;
    NSData *valueData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:sizeof(value)
                                       freeWhenDone:NO];
    [valueData getBytes:&value length:sizeof(value)];

    payloadOffset += sizeof(value);

    return CFConvertFloatSwappedToHost(value);
}

- (void)putString:(NSString *)string
{
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    UInt32 stringLength = (UInt32)[stringData length];

    [self putUInt32:stringLength];

    [self.payload appendBytes:[stringData bytes] length:stringLength];
}

- (NSString *)getString
{
    UInt32 stringLength = [self getUInt32];
    if (stringLength == 0)
        return nil;

    NSData *stringData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                              length:stringLength
                                        freeWhenDone:NO];
    NSString *string = [[NSString alloc] initWithData:stringData
                                             encoding:NSUTF8StringEncoding];

    payloadOffset += [stringData length];

    return string;
}

- (void)putFixedString:(NSString *)string length:(NSUInteger)length
{
    if (string == nil)
        string = @"";

    NSString *paddedString = [string stringByPaddingToLength:length
                                                  withString:@"\0"
                                             startingAtIndex:0];
    NSData *paddedStringData = [paddedString dataUsingEncoding:NSUTF8StringEncoding];

    [self.payload appendBytes:[paddedStringData bytes] length:length];
}

- (NSString *)getFixedString:(NSUInteger)length
{
    NSData *stringData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                              length:length
                                        freeWhenDone:NO];
    NSString *string = [[NSString alloc] initWithBytes:[stringData bytes]
                                                length:length
                                              encoding:NSUTF8StringEncoding];
    payloadOffset += length;

    return string;
}

- (void)putToken:(NSUUID *)token
{
    uuid_t tokenBytes;
    [token getUUIDBytes:tokenBytes];
    NSData *tokenData = [NSData dataWithBytes:tokenBytes
                                       length:TokenBinarySize];
    [self.payload appendData:tokenData];
}

- (NSUUID *)getToken
{
    NSData *tokenData = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                             length:TokenBinarySize
                                       freeWhenDone:NO];
    NSUUID *token = [[NSUUID alloc] initWithUUIDBytes:[tokenData bytes]];

    payloadOffset += TokenBinarySize;

    return token;
}

- (void)putData:(NSData *)data
{
    [self.payload appendData:data];
}

- (NSData *)getData:(NSUInteger)length
{
    NSData *data = [NSData dataWithBytesNoCopy:(char *)[self.payload bytes] + payloadOffset
                                        length:length
                                  freeWhenDone:NO];

    payloadOffset += length;

    return data;
}

- (void)putColor:(CGColorRef)color
{
    UInt32 argb = [[UIColor colorWithCGColor:color] argb];

    [self putUInt32:argb];
}

- (CGColorRef)getColor
{
    UInt32 argb = [self getUInt32];
    
    UIColor *color = [UIColor colorWithARGB:argb];
    
    return [color CGColor];
}

@end

/******************************************************************************/
/*                                                                            */
/*  Color convertion.                                                         */
/*                                                                            */
/******************************************************************************/

@implementation UIColor(Endian)

+ (UIColor *)colorWithARGB:(UInt32)argb
{
#if (defined(VERBOSE_FROM_ARGB) || defined(VERBOSE_FROM_ARGB_FLOATS))
    UInt32 originalARGB = argb;
#endif

    uint alpha, red, green, blue;

    blue = argb & 0xFF;
    argb >>= 8;
    green = argb & 0xFF;
    argb >>= 8;
    red = argb & 0xFF;
    argb >>= 8;
    alpha = argb & 0xFF;

    UIColor *color = [UIColor colorWithRed:(float)red   / 255.0f
                                     green:(float)green / 255.0f
                                      blue:(float)blue  / 255.0f
                                     alpha:(float)alpha / 255.0f];

#ifdef VERBOSE_FROM_ARGB
    NSLog(@"0x%08X -> A:%d R:%d G:%d B:%d", originalARGB, alpha, red, green, blue);
#endif

#ifdef VERBOSE_FROM_ARGB_FLOATS
    const CGFloat *components = CGColorGetComponents([color CGColor]);

    CGFloat red2    = components[0];
    CGFloat green2  = components[1];
    CGFloat blue2   = components[2];
    CGFloat alpha2  = components[3];

    NSLog(@"0x%08X -> A:%0.3f R:%0.3f G:%0.3f B:%0.3f", originalARGB, alpha2, red2, green2, blue2);
#endif

    return color;
}

- (UInt32)argb
{
    const CGFloat *components = CGColorGetComponents([self CGColor]);

    uint red    = ((uint)floorf(components[0] * 255.0f)) & 0xFF;
    uint green  = ((uint)floorf(components[1] * 255.0f)) & 0xFF;
    uint blue   = ((uint)floorf(components[2] * 255.0f)) & 0xFF;
    uint alpha  = ((uint)floorf(components[3] * 255.0f)) & 0xFF;

    UInt32 argb = 0;

    argb |= alpha;
    argb <<= 8;
    argb |= red;
    argb <<= 8;
    argb |= green;
    argb <<= 8;
    argb |= blue;

#ifdef VERBOSE_TO_ARGB
    NSLog(@"A:%d R:%d G:%d B:%d -> 0x%08X", alpha, red, green, blue, argb);
#endif

    return argb;
}

@end