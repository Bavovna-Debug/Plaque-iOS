//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@protocol PaquetSenderDelegate;

@interface Paquet : NSObject

@property (strong, nonatomic, readwrite) id<PaquetSenderDelegate> senderDelegate;

@property (assign, nonatomic) UInt32            paquetId;
@property (assign, nonatomic) UInt32            commandCode;
@property (assign, nonatomic) UInt32            commandSubcode;
@property (strong, nonatomic) NSMutableData     *payload;
@property (assign, nonatomic) Boolean           inTheAir;
@property (assign, nonatomic) Boolean           cancelWhenPossible;
@property (assign, nonatomic) Boolean           rejectedByCloud;
@property (strong, nonatomic) NSData            *userInfo;

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
