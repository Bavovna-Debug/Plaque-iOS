//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "Plaques.h"

@interface InSightPlaque : NSObject <PlaquesDelegate>

@property (weak,   nonatomic) Plaque               *plaque;
@property (weak,   nonatomic) CALayer              *plaqueLayer;
@property (weak,   nonatomic) CALayer              *inscriptionLayer;
@property (weak,   nonatomic) CALayer              *capturedLayer;
@property (assign, nonatomic) Boolean              inSight;
@property (assign, nonatomic) Boolean              needRedraw;
@property (assign, nonatomic) CLLocationDirection  directionFromUser;
@property (assign, nonatomic) CLLocationDistance   distanceToUser;
@property (assign, nonatomic) CLLocationDistance   altitudeOverUser;
@property (assign, nonatomic) CLLocationDirection  rotationOnScreen;

- (id)initWithParentView:(UIView *)parentView;

- (CGFloat)distanceToAimWithTiltOffset:(CGFloat)tiltOffset;

- (void)redraw;

- (void)didDisappear;

- (void)didChangeLocation;

- (void)didChangeOrientation;

- (void)didResize;

- (void)didChangeColor;

- (void)didChangeFont;

- (void)didChangeInscription;

- (void)didBecomeCaptured;

- (void)didReleaseCaptured;

@end
