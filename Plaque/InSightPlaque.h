//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "Plaques.h"

@interface InSightPlaque : NSObject

@property (weak,   nonatomic, readwrite) Plaque                 *plaque;
@property (weak,   nonatomic, readwrite) CALayer                *plaqueLayer;
@property (weak,   nonatomic, readwrite) CALayer                *inscriptionLayer;
@property (weak,   nonatomic, readwrite) CALayer                *capturedLayer;
@property (assign, nonatomic, readwrite) Boolean                inSight;
@property (assign, nonatomic, readwrite) Boolean                needRedraw;
@property (assign, nonatomic, readwrite) CLLocationDirection    directionFromUser;
@property (assign, nonatomic, readwrite) CLLocationDistance     distanceToUser;
@property (assign, nonatomic, readwrite) CLLocationDistance     altitudeOverUser;
@property (assign, nonatomic, readwrite) CLLocationDirection    rotationOnScreen;

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
