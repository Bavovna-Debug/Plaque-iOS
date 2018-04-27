//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Definitions.h"
#import "EditModeAltitudeSubview.h"
#import "Plaques.h"

@interface EditModeAltitudeSubview () <CLLocationManagerDelegate>

@property (weak,   nonatomic) CLLocationManager *locationManager;
@property (weak,   nonatomic) Plaque            *plaque;
@property (strong, nonatomic) UIView            *backgroundView;
@property (strong, nonatomic) UIView            *controlsView;
@property (strong, nonatomic) UILabel           *altitudeLabel1;
@property (strong, nonatomic) UILabel           *altitudeLabel2;
@property (strong, nonatomic) UILabel           *altitudeLabel3;
@property (strong, nonatomic) UIImageView       *deviceLogo;
@property (strong, nonatomic) UIImageView       *plaqueLogo;
@property (strong, nonatomic) UIView            *touchPad;
@property (assign, nonatomic) Boolean           moving;
@property (strong, nonatomic) NSTimer           *touchPadTimer;
@property (strong, nonatomic) NSTimer           *controlsTimer;

@end

@implementation EditModeAltitudeSubview
{
    Boolean             controlsAnimationDirection;
    CLLocationDistance  shiftAltitudePerTimerTick;
}

- (id)initWithLocationManager:(CLLocationManager *)locationManager
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.locationManager = locationManager;

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    self.moving = NO;

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil)
    {
        [self preparePanel];

        [self.locationManager setDelegate:self];
    }
    else
    {
        [self.locationManager setDelegate:nil];

        [self destroyPanel];
    }
}

- (void)preparePanel
{
    [self setBackgroundColor:[UIColor clearColor]];

    // Setup backround.
    //
    {
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeAltitudeBackground"]];
        [self addSubview:self.backgroundView];

        self.controlsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeAltitudeControls"]];
        [self addSubview:self.controlsView];

        controlsAnimationDirection = FALSE;

        [self.controlsView setAlpha:EditModeControlsAnimationAlphaLow];

        [self.controlsView.layer setShadowColor:[[UIColor blueColor] CGColor]];
        [self.controlsView.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
        [self.controlsView.layer setShadowOpacity:EditModeControlsShadowOpacity];

        self.controlsTimer =
        [NSTimer scheduledTimerWithTimeInterval:EditModeControlsAnimationDuration
                                         target:self
                                       selector:@selector(fireControlsTimer:)
                                       userInfo:nil
                                        repeats:YES];
        [self.controlsTimer fire];
    }

    CGRect bounds = self.bounds;
    CGRect valueFrame = CGRectMake(0.0f, 0.0f, 96.0f, 20.0f);

    CGPoint altitudeLabel1Point = CGPointMake(40.0f, 140.0f);
    CGPoint altitudeLabel2Point = CGPointMake(115.0f, 65.0f);
    CGPoint altitudeLabel3Point = CGPointMake(190.0f, 105.0f);

    CGRect touchPadFrame = CGRectMake(CGRectGetMaxX(bounds) - 80.0f,
                                      CGRectGetMinY(bounds),
                                      80.0f,
                                      CGRectGetHeight(bounds));

    UILabel *altitudeLabel1 = [[UILabel alloc] init];
    [altitudeLabel1 setFrame:valueFrame];
    [altitudeLabel1 setCenter:altitudeLabel1Point];
    [altitudeLabel1 setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [altitudeLabel1 setTextAlignment:NSTextAlignmentCenter];
    [altitudeLabel1 setBackgroundColor:[UIColor clearColor]];
    [altitudeLabel1 setTextColor:[UIColor darkTextColor]];
    [self addSubview:altitudeLabel1];

    UILabel *altitudeLabel2 = [[UILabel alloc] init];
    [altitudeLabel2 setFrame:valueFrame];
    [altitudeLabel2 setCenter:altitudeLabel2Point];
    [altitudeLabel2 setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [altitudeLabel2 setTextAlignment:NSTextAlignmentCenter];
    [altitudeLabel2 setBackgroundColor:[UIColor clearColor]];
    [altitudeLabel2 setTextColor:[UIColor darkTextColor]];
    [self addSubview:altitudeLabel2];

    UILabel *altitudeLabel3 = [[UILabel alloc] init];
    [altitudeLabel3 setFrame:valueFrame];
    [altitudeLabel3 setCenter:altitudeLabel3Point];
    [altitudeLabel3 setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [altitudeLabel3 setTextAlignment:NSTextAlignmentCenter];
    [altitudeLabel3 setBackgroundColor:[UIColor clearColor]];
    [altitudeLabel3 setTextColor:[UIColor darkTextColor]];
    [self addSubview:altitudeLabel3];

    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    self.altitudeLabel1 = altitudeLabel1;
    self.altitudeLabel2 = altitudeLabel2;
    self.altitudeLabel3 = altitudeLabel3;
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
    {
        [touchPadTimer invalidate];
    }
}

- (void)fireControlsTimer:(NSTimer *)timer
{
    if (self.moving == NO)
    {
        [UIView beginAnimations:nil
                        context:nil];
        [UIView setAnimationDuration:EditModeControlsAnimationDuration];

        if (controlsAnimationDirection == FALSE)
        {
            [self.controlsView setAlpha:EditModeControlsAnimationAlphaHigh];

            controlsAnimationDirection = TRUE;
        }
        else
        {
            [self.controlsView setAlpha:EditModeControlsAnimationAlphaLow];

            controlsAnimationDirection = FALSE;
        }

        [UIView commitAnimations];
    }
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

    if (CGRectContainsPoint(self.touchPad.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPad];

        [self recalculateMoveParameters:point];

        self.moving = YES;

        [self.touchPadTimer fire];
    }

    [self.controlsView setAlpha:EditModeControlsAnimationAlphaAction];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    /*
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];
    */

    self.moving = NO;
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:[touch view]];

    point = [[touch view] convertPoint:point toView:self];

    if (CGRectContainsPoint(self.touchPad.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPad];

        [self recalculateMoveParameters:point];
    }
    else
    {
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

    NSString *deviceOverSeaZeroText = [NSString stringWithFormat:@"%0.02f m", deviceOverSeaZero];
    NSString *plaqueOverSeaZeroText = [NSString stringWithFormat:@"%0.02f m", plaqueOverSeaZero];
    NSString *plaqueOverDeviceText = [NSString stringWithFormat:@"%0.02f m", plaqueOverDevice];

    if (plaqueOverDevice > 0.0f)
    {
        [self.deviceLogo setCenter:lowerPoint];
        [self.plaqueLogo setCenter:higherPoint];

        [self.altitudeLabel1 setText:deviceOverSeaZeroText];
        [self.altitudeLabel2 setText:plaqueOverDeviceText];
        [self.altitudeLabel3 setText:plaqueOverSeaZeroText];
    }
    else
    {
        [self.deviceLogo setCenter:higherPoint];
        [self.plaqueLogo setCenter:lowerPoint];

        [self.altitudeLabel1 setText:plaqueOverSeaZeroText];
        [self.altitudeLabel2 setText:plaqueOverDeviceText];
        [self.altitudeLabel3 setText:deviceOverSeaZeroText];
    }
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [self refreshValues];
}

@end
