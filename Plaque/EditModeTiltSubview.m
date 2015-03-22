//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "EditModeTiltSubview.h"
#import "Navigator.h"
#import "Plaques.h"

@interface EditModeTiltSubview ()

@property (weak,   nonatomic) Plaque *plaque;
@property (strong, nonatomic) CALayer *plaqueLayer;
@property (strong, nonatomic) UIView *touchPad;
@property (assign, nonatomic) Boolean moving;
@property (strong, nonatomic) NSTimer *touchPadTimer;

@end

@implementation EditModeTiltSubview
{
    CGFloat changeTiltPerTimerTick;
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

    UIView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeTiltSubview"]];
    [self addSubview:backgroundView];

    CGRect bounds = self.bounds;
    CGRect touchPadFrame = CGRectMake(CGRectGetMaxX(bounds) - 120.0f,
                                      CGRectGetMinY(bounds),
                                      120.0f,
                                      CGRectGetHeight(bounds));


    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    CALayer *plaqueLayer = [self.plaque layerWithFrameToFit:CGRectMake(80.0f, 20.0f, 160.0f, 160.0f)];
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
    CGFloat padCenter = CGRectGetMidY(padBounds);
    CGFloat moveVector = fingerPoint.y - padCenter;

    changeTiltPerTimerTick = -(moveVector / padCenter);
    changeTiltPerTimerTick *= 8.0f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CGFloat plaqueTilt = [self.plaque tilt];

        plaqueTilt += changeTiltPerTimerTick;

        plaqueTilt = nearbyintf(plaqueTilt);

        if (plaqueTilt < -90.0f)
            plaqueTilt = -90.0f;

        if (plaqueTilt > 90.0f)
            plaqueTilt = 90.0f;

        [self.plaque setTilt:plaqueTilt];

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
    CGFloat tilt = [self.plaque tilt];

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 500.0f;
    transform = CATransform3DRotate(transform, degreesToRadians(65.0f), 0, 1, 0);
    transform = CATransform3DRotate(transform, degreesToRadians(tilt), 1, 0, 0);

    [self.plaqueLayer setTransform:transform];
}

@end
