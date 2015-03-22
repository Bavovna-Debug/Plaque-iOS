//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "EditModeAltitudeSubview.h"
#import "Plaques.h"

@interface EditModeAltitudeSubview () <CLLocationManagerDelegate>

@property (weak,   nonatomic) Plaque *plaque;
@property (strong, nonatomic) UILabel *deviceOverSeaZeroValue;
@property (strong, nonatomic) UILabel *plaqueOverSeaZeroValue;
@property (strong, nonatomic) UILabel *plaqueOverDeviceValue;
@property (strong, nonatomic) UIImageView *deviceLogo;
@property (strong, nonatomic) UIImageView *plaqueLogo;
@property (strong, nonatomic) UIView *touchPad;
@property (assign, nonatomic) Boolean moving;
@property (strong, nonatomic) NSTimer *touchPadTimer;

@end

@implementation EditModeAltitudeSubview
{
    CLLocationDistance shiftAltitudePerTimerTick;
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

    UIView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeAltitudeSubview"]];
    [self addSubview:backgroundView];

    CGRect bounds = self.bounds;
    CGRect valueFrame = CGRectMake(0.0f, 0.0f, 96.0f, 20.0f);
    CGPoint deviceOverSeaZeroValuePoint = CGPointMake(40.0f, 140.0f);
    CGPoint plaqueOverSeaZeroValuePoint = CGPointMake(190.0f, 105.0f);
    CGPoint plaqueOverDeviceValuePoint = CGPointMake(115.0f, 65.0f);
    CGRect touchPadFrame = CGRectMake(CGRectGetMaxX(bounds) - 80.0f,
                                      CGRectGetMinY(bounds),
                                      80.0f,
                                      CGRectGetHeight(bounds));

    UILabel *deviceOverSeaZeroValue = [[UILabel alloc] init];
    [deviceOverSeaZeroValue setFrame:valueFrame];
    [deviceOverSeaZeroValue setCenter:deviceOverSeaZeroValuePoint];
    [deviceOverSeaZeroValue setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [deviceOverSeaZeroValue setTextAlignment:NSTextAlignmentCenter];
    [deviceOverSeaZeroValue setBackgroundColor:[UIColor clearColor]];
    [deviceOverSeaZeroValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:deviceOverSeaZeroValue];

    UILabel *plaqueOverSeaZeroValue = [[UILabel alloc] init];
    [plaqueOverSeaZeroValue setFrame:valueFrame];
    [plaqueOverSeaZeroValue setCenter:plaqueOverSeaZeroValuePoint];
    [plaqueOverSeaZeroValue setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [plaqueOverSeaZeroValue setTextAlignment:NSTextAlignmentCenter];
    [plaqueOverSeaZeroValue setBackgroundColor:[UIColor clearColor]];
    [plaqueOverSeaZeroValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:plaqueOverSeaZeroValue];

    UILabel *plaqueOverDeviceValue = [[UILabel alloc] init];
    [plaqueOverDeviceValue setFrame:valueFrame];
    [plaqueOverDeviceValue setCenter:plaqueOverDeviceValuePoint];
    [plaqueOverDeviceValue setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [plaqueOverDeviceValue setTextAlignment:NSTextAlignmentCenter];
    [plaqueOverDeviceValue setBackgroundColor:[UIColor clearColor]];
    [plaqueOverDeviceValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:plaqueOverDeviceValue];

    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    self.deviceOverSeaZeroValue = deviceOverSeaZeroValue;
    self.plaqueOverSeaZeroValue = plaqueOverSeaZeroValue;
    self.plaqueOverDeviceValue = plaqueOverDeviceValue;
    self.touchPad = touchPad;

    self.deviceLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeAltitudeViewDevice"]];
    self.plaqueLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeAltitudeViewPlaque"]];

    [self addSubview:self.deviceLogo];
    [self addSubview:self.plaqueLogo];

    self.touchPadTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.1f
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

- (void)recalculateMoveParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPad.bounds;
    CGFloat padCenter = CGRectGetMidY(padBounds);
    CGFloat moveVector = fingerPoint.y - padCenter;

    shiftAltitudePerTimerTick = -(moveVector / padCenter);
    shiftAltitudePerTimerTick *= 0.4f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CLLocationDistance plaqueAltitude = [self.plaque altitude];

        plaqueAltitude += shiftAltitudePerTimerTick;

        plaqueAltitude = nearbyintf(plaqueAltitude * 100.0f);
        plaqueAltitude /= 100.0f;

        [self.plaque setAltitude:plaqueAltitude];

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
        [self recalculateMoveParameters:point];
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
        [self recalculateMoveParameters:point];
    } else {
        self.moving = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    self.moving = NO;
}

- (void)refreshValues
{
    CLLocation *deviceLocation = [self.locationManager location];
    CLLocation *plaqueLocation = [self.plaque location];
    CLLocationDistance deviceOverSeaZero = [deviceLocation altitude];
    CLLocationDistance plaqueOverSeaZero = [plaqueLocation altitude];
    CLLocationDistance plaqueOverDevice = plaqueOverSeaZero - deviceOverSeaZero;

    CGPoint lowerPoint = CGPointMake(78.0f, 100.0f);
    CGPoint higherPoint = CGPointMake(152.0f, 30.0f);
    if (plaqueOverDevice > 0.0f) {
        [self.deviceLogo setCenter:lowerPoint];
        [self.plaqueLogo setCenter:higherPoint];
    } else {
        [self.deviceLogo setCenter:higherPoint];
        [self.plaqueLogo setCenter:lowerPoint];
        plaqueOverDevice = -plaqueOverDevice;
    }

    NSString *deviceOverSeaZeroText = [NSString stringWithFormat:@"%0.02f m", deviceOverSeaZero];
    NSString *plaqueOverSeaZeroText = [NSString stringWithFormat:@"%0.02f m", plaqueOverSeaZero];
    NSString *plaqueOverDeviceText = [NSString stringWithFormat:@"%0.02f m", plaqueOverDevice];

    [self.deviceOverSeaZeroValue setText:deviceOverSeaZeroText];
    [self.plaqueOverSeaZeroValue setText:plaqueOverSeaZeroText];
    [self.plaqueOverDeviceValue setText:plaqueOverDeviceText];
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [self refreshValues];
}

@end
