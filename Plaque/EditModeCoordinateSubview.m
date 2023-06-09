//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Definitions.h"
#import "EditModeCoordinateSubview.h"
#import "Navigator.h"
#import "Plaques.h"
#import "SurroundingSelector.h"

@interface EditModeCoordinateSubview ()

@property (weak,   nonatomic) CLLocationManager *locationManager;
@property (weak,   nonatomic) Plaque            *plaque;
@property (strong, nonatomic) UIView            *backgroundView;
@property (strong, nonatomic) UIView            *controlsView;
@property (strong, nonatomic) UILabel           *latitudeValue;
@property (strong, nonatomic) UILabel           *longitudeValue;
@property (strong, nonatomic) UILabel           *distanceValue;
@property (strong, nonatomic) UIView            *touchPad;
@property (assign, nonatomic) Boolean           moving;
@property (strong, nonatomic) NSTimer           *touchPadTimer;
@property (strong, nonatomic) NSTimer           *controlsTimer;

@end

@implementation EditModeCoordinateSubview
{
    Boolean             controlsAnimationDirection;
    CLLocationDegrees   shiftDirectionOnPad;
    CLLocationDistance  shiftDistancePerTimerTick;
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
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeCoordinateBackground"]];
        [self addSubview:self.backgroundView];

        self.controlsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeCoordinateControls"]];
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

    CGRect latitudeValueFrame =
    CGRectMake(22.0f,
               21.0f,
               94.0f,
               20.0f);

    CGRect longitudeValueFrame =
    CGRectOffset(latitudeValueFrame,
                 0.0f,
                 20.0f);

    CGRect touchPadFrame =
    CGRectMake(CGRectGetMaxX(bounds) - CGRectGetHeight(bounds),
               CGRectGetMinY(bounds),
               CGRectGetHeight(bounds),
               CGRectGetHeight(bounds));

    UILabel *latitudeValue = [[UILabel alloc] init];
    [latitudeValue setFrame:latitudeValueFrame];
    [latitudeValue setFont:[UIFont systemFontOfSize:12.0f]];
    [latitudeValue setTextAlignment:NSTextAlignmentRight];
    [latitudeValue setBackgroundColor:[UIColor clearColor]];
    [latitudeValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:latitudeValue];

    UILabel *longitudeValue = [[UILabel alloc] init];
    [longitudeValue setFrame:longitudeValueFrame];
    [longitudeValue setFont:[UIFont systemFontOfSize:12.0f]];
    [longitudeValue setTextAlignment:NSTextAlignmentRight];
    [longitudeValue setBackgroundColor:[UIColor clearColor]];
    [longitudeValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:longitudeValue];

    UILabel *distanceValue = [[UILabel alloc] init];
    [distanceValue setBounds:CGRectMake(0.0f, 0.0f, 128.0f, 32.0f)];
    [distanceValue setCenter:CGPointMake(76.0f, 128.0f)];
    [distanceValue setFont:[UIFont boldSystemFontOfSize:24.0f]];
    [distanceValue setTextAlignment:NSTextAlignmentCenter];
    [distanceValue setBackgroundColor:[UIColor clearColor]];
    [distanceValue setTextColor:[UIColor darkTextColor]];

    CGFloat rotateX = DegreesToRadians(50.0f);
    CGFloat rotateY = DegreesToRadians(30.0f);
    CGFloat rotateZ = DegreesToRadians(40.0f);
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 250.0f;
    transform = CATransform3DRotate(transform, rotateX, 1, 0, 0);
    transform = CATransform3DRotate(transform, rotateY, 0, -1, 0);
    transform = CATransform3DRotate(transform, rotateZ, 0, 0, 1);
    [distanceValue.layer setTransform:transform];
    [self addSubview:distanceValue];

    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    self.latitudeValue = latitudeValue;
    self.longitudeValue = longitudeValue;
    self.distanceValue = distanceValue;
    self.touchPad = touchPad;

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

    CGPoint padCenter =
    CGPointMake(CGRectGetMidX(padBounds),
                CGRectGetMidY(padBounds));

    CGVector moveVector =
    CGVectorMake(fingerPoint.x - padCenter.x,
                 fingerPoint.y - padCenter.y);

    shiftDirectionOnPad = CorrectDegrees(RadiandsToDegrees(atan2f(moveVector.dy, moveVector.dx)) + 90.0f);
    shiftDistancePerTimerTick = sqrtf(powf(moveVector.dx, 2) + powf(moveVector.dy, 2)) / padCenter.x;
    shiftDistancePerTimerTick *=  2.0f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CLLocationCoordinate2D plaqueCoordinate = [self.plaque coordinate];

        CLLocationDegrees shiftDirectionInWorld = shiftDirectionOnPad;

        if ([[SurroundingSelector panel] surroundingViewMode] == SurroundingInSight)
        {
            CLLocationDirection userHeading = [[self.locationManager heading] trueHeading];
            shiftDirectionInWorld = CorrectDegrees(shiftDirectionInWorld + userHeading);
        }

        plaqueCoordinate = [Navigator shift:plaqueCoordinate
                                    heading:shiftDirectionInWorld
                                   distance:shiftDistancePerTimerTick];

        [self.plaque setCoordinate:plaqueCoordinate];

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
    CLLocationDistance distance = [plaqueLocation distanceFromLocation:deviceLocation];

    NSString *latitudeText = [Navigator degreesMinutesSecondsFor:plaqueLocation.coordinate.latitude];
    NSString *longitudeText = [Navigator degreesMinutesSecondsFor:plaqueLocation.coordinate.longitude];
    NSString *distanceText = [NSString stringWithFormat:@"%0.2f m", distance];

    [self.latitudeValue setText:latitudeText];
    [self.longitudeValue setText:longitudeText];
    [self.distanceValue setText:distanceText];
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [self refreshValues];
}

@end
