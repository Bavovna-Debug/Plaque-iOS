//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@protocol PaquetSenderDelegate;

@interface Paquet : NSObject

@property (strong, nonatomic, readwrite) id<PaquetSenderDelegate> senderDelegate;

@property (assign, nonatomic, readwrite) UInt32         paquetId;
@property (assign, nonatomic, readwrite) UInt32         commandCode;
@property (assign, nonatomic, readwrite) UInt32         commandSubcode;
@property (strong, nonatomic, readonly)  NSMutableData  *payload;
@property (assign, atomic,    readwrite) Boolean        inTheAir;
@property (assign, atomic,    readwrite) Boolean        cancelWhenPossible;
@property (assign, atomic,    readonly)  Boolean        rejectedByCloud;
@property (strong, atomic,    readwrite) NSData         *userInfo;

+ (void)report:(NSString *)message;

- (id)initWithCommand:(UInt32)commandCode;

- (void)send;

- (void)complete:(NSMutableData *)payload;

- (BOOL)payloadEOF;

- (void)putBoolean:(Boolean)value;
- (Boolean)getBoolean;

- (void)putUInt16:(UInt16)value;
- (UInt16)getUInt16;

- (void)putUInt32:(UInt32)value;
- (UInt32)getUInt32;

- (void)putUInt64:(UInt64)value;
- (UInt64)getUInt64;

- (void)putDouble:(double)value;
- (double)getDouble;

- (void)putFloat:(float)value;
- (float)getFloat;

- (void)putString:(NSString *)string;
- (NSString *)getString;

- (void)putFixedString:(NSString *)string length:(NSUInteger)length;
- (NSString *)getFixedString:(NSUInteger)length;

- (void)putToken:(NSUUID *)token;
- (NSUUID *)getToken;

- (void)putData:(NSData *)data;
- (NSData *)getData:(NSUInteger)length;

- (void)putColor:(CGColorRef)color;
- (CGColorRef)getColor;

@end

@protocol PaquetSenderDelegate <NSObject>

@required

- (void)paquetComplete:(Paquet *)paquet;

@optional

- (void)paquetFailed:(Paquet *)paquet;

@end

/******************************************************************************/
/*                                                                            */
/*  Color convertion.                                                         */
/*                                                                            */
/******************************************************************************/

@interface UIColor(Endian)

+ (UIColor *)colorWithARGB:(UInt32)argb;

- (UInt32)argb;

@end
