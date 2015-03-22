//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GyroDelegate;

@interface Gyro : NSObject

@property (weak,   nonatomic, readwrite) id<GyroDelegate> delegate;

@property (assign, nonatomic, readonly)  double tilt;
@property (assign, nonatomic, readonly)  double turn;

+ (Gyro *)sharedGyro;

@end

@protocol GyroDelegate <NSObject>

@optional

- (void)gyro:(Gyro *)gyro
tiltDidChangeFrom:(double)from
          to:(double)to;

- (void)gyro:(Gyro *)gyro
turnDidChangeFrom:(double)from
          to:(double)to;

@end