//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "EditModeCoordinateSubview.h"
#import "Navigator.h"
#import "Plaques.h"
#import "SurroundingSelector.h"

@interface EditModeCoordinateSubview ()

@property (weak,   nonatomic) Plaque *plaque;
@property (strong, nonatomic) UILabel *latitudeValue;
@property (strong, nonatomic) UILabel *longitudeValue;
@property (strong, nonatomic) UILabel *distanceValue;
@property (strong, nonatomic) UIView *touchPad;
@property (assign, nonatomic) Boolean moving;
@property (strong, nonatomic) NSTimer *touchPadTimer;

@end

@implementation EditModeCoordinateSubview
{
    CLLocationDegrees shiftDirectionOnPad;
    CLLocationDistance shiftDistancePerTimerTick;
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

    UIView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeCoordinateSubview"]];
    [self addSubview:backgroundView];

    CGRect bounds = self.bounds;
    CGRect latitudeValueFrame = CGRectMake(22.0f, 21.0f, 94.0f, 20.0f);
    CGRect longitudeValueFrame = CGRectOffset(latitudeValueFrame, 0.0f, 20.0f);
    CGRect touchPadFrame = CGRectMake(CGRectGetMaxX(bounds) - CGRectGetHeight(bounds),
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

    CGFloat rotateX = degreesToRadians(50.0f);
    CGFloat rotateY = degreesToRadians(30.0f);
    CGFloat rotateZ = degreesToRadians(40.0f);
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
        [touchPadTimer invalidate];
}

- (void)recalculateMoveParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPad.bounds;
    CGPoint padCenter = CGPointMake(CGRectGetMidX(padBounds),
                                    CGRectGetMidY(padBounds));
    CGVector moveVector = CGVectorMake(fingerPoint.x - padCenter.x,
                                       fingerPoint.y - padCenter.y);

    shiftDirectionOnPad = correctDegrees(radiandsToDegrees(atan2f(moveVector.dy, moveVector.dx)) + 90.0f);
    shiftDistancePerTimerTick = sqrtf(powf(moveVector.dx, 2) + powf(moveVector.dy, 2)) / padCenter.x;
    shiftDistancePerTimerTick *=  2.0f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CLLocationCoordinate2D plaqueCoordinate = [self.plaque coordinate];

        CLLocationDegrees shiftDirectionInWorld = shiftDirectionOnPad;

        if ([[SurroundingSelector panel] surroundingViewMode] == SurroundingInSight) {
            CLLocationDirection userHeading = [[self.locationManager heading] trueHeading];
            shiftDirectionInWorld = correctDegrees(shiftDirectionInWorld + userHeading);
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
