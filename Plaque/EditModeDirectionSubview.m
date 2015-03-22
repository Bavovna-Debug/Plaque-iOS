//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "EditModeDirectionSubview.h"
#import "Navigator.h"
#import "Plaques.h"

@interface EditModeDirectionSubview ()

@property (weak,   nonatomic) Plaque *plaque;
@property (strong, nonatomic) CALayer *plaqueLayer;
@property (strong, nonatomic) UIView *touchPad;
@property (assign, nonatomic) Boolean moving;
@property (strong, nonatomic) NSTimer *touchPadTimer;

@end

@implementation EditModeDirectionSubview
{
    CGFloat changeDirectionPerTimerTick;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil) {
        [self preparePanel];
    } else {
        [self destroyPanel];
    }
}

- (void)preparePanel
{
    [self setBackgroundColor:[UIColor clearColor]];

    UIView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeDirectionSubview"]];
    [self addSubview:backgroundView];

    CGRect bounds = self.bounds;
    CGRect touchPadFrame = CGRectMake(CGRectGetMinX(bounds) + 30.0f,
                                      CGRectGetMaxY(bounds) - 90.0f,
                                      310.0f,
                                      90.0f);


    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    CALayer *plaqueLayer = [self.plaque layerWithFrameToFit:CGRectMake(95.0f, 30.0f, 180.0f, 100.0f)];
    [self.plaque inscriptionLayerForLayer:plaqueLayer];
    [self.layer addSublayer:plaqueLayer];

    self.plaqueLayer = plaqueLayer;
    self.touchPad = touchPad;

    self.touchPadTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.2f
                                     target:self
                                   selector:@selector(fireTouchPadTimer:)
                                   userInfo:nil
                                    repeats:YES];
    [self.touchPadTimer fire];

    [self refreshValues];
}

- (void)destroyPanel
{
    NSTimer *touchPadTimer = self.touchPadTimer;
    if (touchPadTimer != nil)
        [touchPadTimer invalidate];
}

- (void)recalculateTiltParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPad.bounds;
    CGFloat padCenter = CGRectGetMidX(padBounds);
    CGFloat moveVector = fingerPoint.x - padCenter;

    changeDirectionPerTimerTick = -(moveVector / padCenter);
    changeDirectionPerTimerTick *= 8.0f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CGFloat plaqueDirection = [self.plaque direction];

        plaqueDirection += changeDirectionPerTimerTick;

        plaqueDirection = nearbyintf(plaqueDirection);

        plaqueDirection = correctDegrees(plaqueDirection);

        [self.plaque setDirection:plaqueDirection];

        [self refreshValues];
    }
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];
    if (CGRectContainsPoint(self.touchPad.frame, point) == YES) {
        point = [touch locationInView:self.touchPad];
        [self recalculateTiltParameters:point];
        self.moving = YES;
        [self.touchPadTimer fire];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];

    self.moving = NO;
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];
    if (CGRectContainsPoint(self.touchPad.frame, point) == YES) {
        point = [touch locationInView:self.touchPad];
        [self recalculateTiltParameters:point];
    } else {
        self.moving = NO;
    }
}

- (void)refreshValues
{
    CLHeading *heading = [self.locationManager heading];
    CGFloat direction = [self.plaque direction];
    CGFloat tilt = [self.plaque tilt];

    direction = correctDegrees(direction - oppositeDirection(heading.trueHeading));

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 500.0f;
    transform = CATransform3DRotate(transform, degreesToRadians(direction), 0, -1, 0);
    transform = CATransform3DRotate(transform, degreesToRadians(tilt), 1, 0, 0);

    [self.plaqueLayer setTransform:transform];
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    [self refreshValues];
}

@end
