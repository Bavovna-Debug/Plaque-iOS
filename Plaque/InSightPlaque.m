//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "InSightPlaque.h"
#import "InSightView.h"
#import "Navigator.h"

#ifdef DEBUG
#undef REDRAW
#endif

@interface InSightPlaque ()

@property (weak, nonatomic) InSightView *parentView;

@end

@implementation InSightPlaque
{
    CGFloat transX;
    CGFloat transY;
    CGFloat transZ;
    CGFloat scaleFactor;
}

@synthesize directionFromUser = _directionFromUser;
@synthesize distanceToUser = _distanceToUser;
@synthesize altitudeOverUser = _altitudeOverUser;
@synthesize inSight = _inSight;

- (id)initWithParentView:(UIView *)parentView
{
    self = [super init];
    if (self == nil)
        return nil;

    self.parentView = (InSightView *)parentView;
    self.needRedraw = YES;

    return self;
}

#pragma mark - Properties

- (void)setDirectionFromUser:(CLLocationDirection)directionFromUser
{
    if (directionFromUser != _directionFromUser) {
        _directionFromUser = directionFromUser;

        [self setInSight:(fabs(directionFromUser) < 45.0f)];

        [self setNeedRedraw:YES];
    }
}

- (void)setDistanceToUser:(CLLocationDistance)distanceToUser
{
    if (distanceToUser != _distanceToUser) {
        _distanceToUser = distanceToUser;
        [self setNeedRedraw:YES];
    }
}

- (void)setAltitudeOverUser:(CLLocationDistance)altitudeOverUser
{
    if (altitudeOverUser != _altitudeOverUser) {
        _altitudeOverUser = altitudeOverUser;
        [self setNeedRedraw:YES];
    }
}

- (void)setInSight:(Boolean)inSight
{
    if (inSight != _inSight) {
        _inSight = inSight;
        if (inSight == NO) {
            [self destroyLayer];
        } else {
            [self createLayer];
        }
    }
}

- (CGFloat)distanceToAimWithTiltOffset:(CGFloat)tiltOffset
{
    if ([self inSight] == NO) {
        return CGFLOAT_MAX;
    } else {
        return roundf(sqrtf(powf(transX, 2.0f) + powf(transY - tiltOffset, 2.0f)));
    }
}

#pragma mark - Visual layer

- (void)createLayer
{
    CALayer *plaqueLayer = [self.plaque layerWithFrameToFit:[self plaqueLayerFrame]];
    CALayer *inscriptionLayer = [self.plaque inscriptionLayerForLayer:plaqueLayer];

    // Set self as main layers delegate to allow the parent view to find a corresponfing InSightPlaque
    // when user touches it.
    //
    [plaqueLayer setDelegate:self];

    self.plaqueLayer = plaqueLayer;
    self.inscriptionLayer = inscriptionLayer;

    [self.parentView.container addSublayer:plaqueLayer];
}


- (void)destroyLayer
{
    CALayer *plaqueLayer = self.plaqueLayer;
    if (plaqueLayer != nil)
        [plaqueLayer removeFromSuperlayer];
}

- (CGRect)plaqueLayerFrame
{
    Plaque *plaque = self.plaque;
    CGSize plaqueViewSize = CGSizeMake(plaque.size.width * self.parentView.fullScreenWidth,
                                       plaque.size.height * self.parentView.fullScreenWidth);
    CGRect frame = CGRectMake(CGRectGetMidX(self.parentView.container.bounds) - plaqueViewSize.width / 2,
                              CGRectGetMidY(self.parentView.container.bounds) - plaqueViewSize.height / 2,
                              plaqueViewSize.width,
                              plaqueViewSize.height);
    return frame;
}

- (void)redraw
{
    CALayer *plaqueLayer = self.plaqueLayer;

    [self setNeedRedraw:NO];

    scaleFactor = self.parentView.fullScreenMeterDistance / self.distanceToUser;

    CGFloat angleX = radiandsToDegrees(sinf(degreesToRadians(self.directionFromUser)));
    transX = angleX / (self.parentView.fullScreenAngle / 2) * (self.parentView.fullScreenWidth / 2);
    transY = self.altitudeOverUser * scaleFactor * self.parentView.fullScreenWidth;
    transZ = 0.0f;

    transX *= 10.0f;
    transY *= 10.0f;
    scaleFactor *= 10.0f;

    if ((self.plaque.cloneChain != nil) && (self.plaque.rowId != 0)) {
        [plaqueLayer setOpacity:0.2f];
    } else {
        [plaqueLayer setOpacity:0.8f];
    }

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 500.0f;
    transform = CATransform3DTranslate(transform, transX, -transY, -transZ);
    transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);

    if (self.rotationOnScreen != 0.0f)
        transform = CATransform3DRotate(transform, degreesToRadians(self.rotationOnScreen), 0, -1, 0);

    if (self.plaque.tilt != 0.0f)
        transform = CATransform3DRotate(transform, degreesToRadians(self.plaque.tilt), 1, 0, 0);

    [plaqueLayer setZPosition:roundf(self.parentView.rangeInSight - self.distanceToUser)];
    [plaqueLayer setTransform:transform];

#ifdef REDRAW
    NSLog(@"Redraw plaque in sight %@ (%@)",
          [self.plaque.plaqueToken UUIDString],
          self.plaque.inscription);
#endif
}

#pragma mark -

- (void)didDisappear
{
    [self destroyLayer];
}

- (void)didChangeLocation
{
    [self setNeedRedraw:YES];
}

- (void)didChangeOrientation
{
    [self setNeedRedraw:YES];
}

- (void)didResize
{
    CALayer *plaqueLayer = self.plaqueLayer;
    CALayer *inscriptionLayer = self.inscriptionLayer;

    if ((plaqueLayer != nil) && (inscriptionLayer != nil))
    {
        CGRect plaqueLayerFrame = [self plaqueLayerFrame];
        [self.plaqueLayer setFrame:plaqueLayerFrame];
        //[self.plaqueTextLayer setFrame:CGRectInset(self.plaqueLayer.bounds, 2.0f, 2.0f)];
        [self.plaque resizeInscriptionLayer:inscriptionLayer
                                   forLayer:plaqueLayer];
    }
}

- (void)didChangeColor
{
    [self.plaqueLayer setBackgroundColor:[self.plaque.backgroundColor CGColor]];
    if (self.plaque.image == nil) {
        CATextLayer *textLayer = (CATextLayer *)self.inscriptionLayer;
        [textLayer setForegroundColor:[self.plaque.foregroundColor CGColor]];
    }
}

- (void)didChangeFont
{
    if (self.plaque.image == nil) {
        CALayer *plaqueLayer = self.plaqueLayer;
        CATextLayer *textLayer = (CATextLayer *)self.inscriptionLayer;

        if ((plaqueLayer != nil) && (textLayer != nil))
            [self.plaque resizeInscriptionLayer:textLayer
                                       forLayer:plaqueLayer];

        [self setNeedRedraw:YES];
    }
}

- (void)didChangeInscription
{
    if (self.plaque.image == nil) {
        CATextLayer *textLayer = (CATextLayer *)self.inscriptionLayer;

        if (textLayer != nil)
            [textLayer setString:[self.plaque inscription]];
    }
}

- (void)didBecomeCaptured
{
    CALayer *plaqueLayer = self.plaqueLayer;

    CALayer *capturedLayer = [CALayer layer];

    [capturedLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
    [capturedLayer setBorderColor:[[UIColor greenColor] CGColor]];
    [capturedLayer setBorderWidth:self.parentView.fullScreenWidth * 0.6f];
    [capturedLayer setCornerRadius:self.parentView.fullScreenWidth * 0.6f];

    CGRect capturedLayerFrame = CGRectInset(plaqueLayer.bounds,
                                            -self.parentView.fullScreenWidth,
                                            -self.parentView.fullScreenWidth);

    [capturedLayer setFrame:capturedLayerFrame];

    [plaqueLayer addSublayer:capturedLayer];

    self.capturedLayer = capturedLayer;
}

- (void)didReleaseCaptured
{
    [self.capturedLayer removeFromSuperlayer];
}

@end
