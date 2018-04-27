//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "Gyro.h"
#import "Navigator.h"

#include "Definitions.h"

@interface Gyro ()

@property (assign, atomic, readwrite) double tilt;
@property (assign, atomic, readwrite) double turn;

@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation Gyro

+ (Gyro *)sharedGyro
{
    static dispatch_once_t onceToken;
    static Gyro *gyro;

    dispatch_once(&onceToken, ^
    {
        gyro = [[Gyro alloc] init];
    });

    return gyro;
}

#pragma mark - Object cunstructors/destructors

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.2f;
    self.motionManager.gyroUpdateInterval = 0.5f;

    [self.motionManager
     startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
     withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        double tilt =
        CorrectDegrees(RadiandsToDegrees(-atan2(accelerometerData.acceleration.y,
                                                accelerometerData.acceleration.z)) - 90.0f);

        double turn =
        CorrectDegrees(RadiandsToDegrees(-atan2(accelerometerData.acceleration.x,
                                                accelerometerData.acceleration.y)) - 180.0f);

        if (round(tilt / TiltAccuracy) != round(self.tilt / TiltAccuracy))
        {
            double previousTilt = self.tilt;

            self.tilt = tilt;

            if ((self.delegate != nil) &&
                [self.delegate respondsToSelector:@selector(gyro:tiltDidChangeFrom:to:)])
            {
                [self.delegate gyro:self
                  tiltDidChangeFrom:previousTilt
                                 to:tilt];
            }
        }

        if (round(turn / TurnAccuracy) != round(self.turn / TurnAccuracy))
        {
            double previousTurn = self.turn;

            self.turn = turn;

            if ((self.delegate != nil) &&
                [self.delegate respondsToSelector:@selector(gyro:turnDidChangeFrom:to:)])
            {
                [self.delegate gyro:self
                  turnDidChangeFrom:previousTurn
                                 to:turn];
            }
        }

        if (error)
        {
            NSLog(@"[Gyro] %@", error);
        }
    }];

    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error)
    {
        NSLog(@"[Gyro] %f %f %f",
              gyroData.rotationRate.x,
              gyroData.rotationRate.y,
              gyroData.rotationRate.z);

        if (error)
        {
            NSLog(@"[Gyro] %@", error);
        }
    }];

    return self;
}

@end
