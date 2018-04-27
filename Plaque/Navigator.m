//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Navigator.h"

#include "Definitions.h"

@interface Navigator () <CLLocationManagerDelegate>

@property (assign, atomic,    readwrite) Boolean                inBackground;

@property (assign, atomic,    readwrite) CLLocationCoordinate2D startPosition;
@property (assign, atomic,    readwrite) CLLocationCoordinate2D deviceCoordinate;
@property (assign, atomic,    readwrite) CLLocationDistance     deviceAltitude;
@property (assign, atomic,    readwrite) CLLocationDirection    deviceDirection;

@property (strong, nonatomic)            CLLocationManager      *locationManager;

@end

@implementation Navigator

@synthesize inBackground = _inBackground;

+ (Navigator *)sharedNavigator
{
    static dispatch_once_t onceToken;
    static Navigator *navigator;

    dispatch_once(&onceToken, ^
    {
        navigator = [[Navigator alloc] init];
    });

    return navigator;
}

#pragma mark - Object cunstructors/destructors

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDistanceFilter:ForegroundDistance];
    [self.locationManager setDesiredAccuracy:ForegroundAccuracy];
    [self.locationManager setHeadingFilter:1.0f];
    [self.locationManager setDelegate:self];

#if 0
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [self.locationManager requestAlwaysAuthorization];
    }
#endif
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [self.locationManager requestWhenInUseAuthorization];
    }

    self.startPosition = [[self.locationManager location] coordinate];

    self.deviceCoordinate = [[self.locationManager location] coordinate];
    self.deviceAltitude = [[self.locationManager location] altitude];
    self.deviceDirection = [[self.locationManager heading] trueHeading];

    return self;
}

- (Boolean)inBackground
{
    return _inBackground;
}

- (void)setInBackground:(Boolean)inBackground
{
    if (inBackground != _inBackground)
    {
        _inBackground = inBackground;

        if (inBackground == YES)
        {
            NSLog(@"[Navigator] Switch to background");

            [self.locationManager setDistanceFilter:BackgroundDistance];
            [self.locationManager setDesiredAccuracy:BackgroundAccuracy];
        }
        else
        {
            NSLog(@"[Navigator] Switch to foreground");

            [self.locationManager setDistanceFilter:ForegroundDistance];
            [self.locationManager setDesiredAccuracy:ForegroundAccuracy];
        }
    }
}

#pragma mark - Navigation activation/deactivation

- (void)startNavigation
{
    [self.locationManager startUpdatingHeading];
    [self.locationManager startUpdatingLocation];

    self.startPosition = [[self.locationManager location] coordinate];

    self.deviceCoordinate = [[self.locationManager location] coordinate];
    self.deviceAltitude = [[self.locationManager location] altitude];
    self.deviceDirection = [[self.locationManager heading] trueHeading];
}

- (void)stopNavigation
{
    [self.locationManager stopUpdatingHeading];
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = (CLLocation *)[locations lastObject];

    [self setDeviceAltitude:location.altitude];
    [self setDeviceCoordinate:location.coordinate];

    if ((self.delegate != nil) &&
        [self.delegate respondsToSelector:@selector(navigator:coordinateDidChange:)])
    {
        [self.delegate navigator:self
             coordinateDidChange:location.coordinate];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    CLLocationDirection oldDirection = self.deviceDirection;
    CLLocationDirection newDirection = newHeading.trueHeading;

    [self setDeviceDirection:newDirection];

    if ((self.delegate != nil) &&
        [self.delegate respondsToSelector:@selector(navigator:directionDidChangeFrom:to:)])
    {
        [self.delegate navigator:self
          directionDidChangeFrom:oldDirection
                              to:newDirection];
    }
}

#pragma mark - Navigator static API

+ (CLLocationCoordinate2D)coordinateFromLocation:(NSDictionary*)location
{
    double latitude = [[location objectForKey:@"lat"] doubleValue];
    double longitude = [[location objectForKey:@"lng"] doubleValue];

    return CLLocationCoordinate2DMake(latitude, longitude);
}

+ (CLLocationDirection)directionFrom:(CLLocationCoordinate2D)fromCoordinate
                                  to:(CLLocationCoordinate2D)toCoordinate
{
    CLLocationDegrees fromLatitude = DegreesToRadians(fromCoordinate.latitude);
    CLLocationDegrees fromLongitude = DegreesToRadians(fromCoordinate.longitude);
    CLLocationDegrees toLatitude = DegreesToRadians(toCoordinate.latitude);
    CLLocationDegrees toLongitude = DegreesToRadians(toCoordinate.longitude);

    CLLocationDirection degree;

    degree =
    atan2(sin(toLongitude - fromLongitude) * cos(toLatitude),
          cos(fromLatitude) * sin(toLatitude) -
          sin(fromLatitude) * cos(toLatitude) * cos(toLongitude - fromLongitude));

    degree = RadiandsToDegrees(degree);

    return (degree >= 0.0f) ? degree : 360.0f + degree;
}

+ (CLLocationDirection)directionFrom:(CLLocationCoordinate2D)fromCoordinate
                                  to:(CLLocationCoordinate2D)toCoordinate
                          forHeading:(CLLocationDirection)forHeading
{
    CLLocationDirection headingAbsolute = [self directionFrom:fromCoordinate
                                                           to:toCoordinate];

    CLLocationDirection headingRelative = headingAbsolute - forHeading;

    if (headingRelative < 180.0f)
    {
        headingRelative = 360.0f + headingRelative;
    }

    if (headingRelative > 180.0f)
    {
        headingRelative = headingRelative - 360.0f;
    }

    return headingRelative;
}

+ (CLLocationDistance)distanceFrom:(CLLocationCoordinate2D)fromCoordinate
                                to:(CLLocationCoordinate2D)toCoordinate
{
    CLLocation *fromLocation =
    [[CLLocation alloc] initWithLatitude:fromCoordinate.latitude
                               longitude:fromCoordinate.longitude];

    CLLocation *toLocation =
    [[CLLocation alloc] initWithLatitude:toCoordinate.latitude
                               longitude:toCoordinate.longitude];

    CLLocationDistance distance =
    [toLocation distanceFromLocation:fromLocation];

    return distance;
}

+ (CLLocationCoordinate2D)shift:(CLLocationCoordinate2D)fromCoordinate
                        heading:(CLLocationDegrees)heading
                       distance:(CLLocationDistance)distance
{
    double distanceRadians = distance / 6371000.0f;

    double bearingRadians = DegreesToRadians(heading);

    double fromLatitudeRadians = DegreesToRadians(fromCoordinate.latitude);

    double fromLongitudeRadians = DegreesToRadians(fromCoordinate.longitude);

    double toLatitudeRadians =
    asin(sin(fromLatitudeRadians) * cos(distanceRadians) +
         cos(fromLatitudeRadians) * sin(distanceRadians) * cos(bearingRadians));

    double toLongitudeRadians =
    fromLongitudeRadians +
    atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatitudeRadians),
          cos(distanceRadians) - sin(fromLatitudeRadians) * sin(toLatitudeRadians));

    toLongitudeRadians = fmod((toLongitudeRadians + 3 * M_PI), (2 * M_PI)) - M_PI;

    CLLocationCoordinate2D toCoordinate;
    toCoordinate.latitude = RadiandsToDegrees(toLatitudeRadians);
    toCoordinate.longitude = RadiandsToDegrees(toLongitudeRadians);

    return toCoordinate;
}

+ (NSString *)degreesMinutesSecondsFor:(CLLocationDegrees)value
{
    CGFloat degrees = floorf(value);
    CGFloat minutes = floorf((value - degrees) * 60);
    CGFloat seconds = (value - degrees - minutes / 60) * 3600;

    NSString *string = [NSString stringWithFormat:@"%.0f° %02.0f′ %02.2f″",
                        degrees, minutes, seconds];
    return string;
}

@end

/******************************************************************************/
/*                                                                            */
/******************************************************************************/

@implementation CLLocation(Navigator)

- (NSInteger)floorlevel
{
    CLFloor *floor = self.floor;

    return (floor == nil) ? 0 : floor.level;
}

- (CLLocation *)locationWithShiftFor:(CLLocationDistance)distance
                           direction:(CLLocationDegrees)direction
{
    double distanceRadians = distance / 6371000.0f;

    double bearingRadians = DegreesToRadians(direction);

    double fromLatitudeRadians = DegreesToRadians(self.coordinate.latitude);

    double fromLongitudeRadians = DegreesToRadians(self.coordinate.longitude);

    double toLatitudeRadians =
    asin(sin(fromLatitudeRadians) * cos(distanceRadians) +
         cos(fromLatitudeRadians) * sin(distanceRadians) * cos(bearingRadians));

    double toLongitudeRadians =
    fromLongitudeRadians +
    atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatitudeRadians),
          cos(distanceRadians) - sin(fromLatitudeRadians) * sin(toLatitudeRadians));

    toLongitudeRadians = fmod((toLongitudeRadians + 3 * M_PI), (2 * M_PI)) - M_PI;

    CLLocationCoordinate2D newCoordinate =
    CLLocationCoordinate2DMake(RadiandsToDegrees(toLatitudeRadians),
                               RadiandsToDegrees(toLongitudeRadians));

    return [[CLLocation alloc] initWithCoordinate:newCoordinate
                                         altitude:self.altitude
                               horizontalAccuracy:self.horizontalAccuracy
                                 verticalAccuracy:self.verticalAccuracy
                                           course:self.course
                                            speed:self.speed
                                        timestamp:[NSDate date]];
}

- (CLLocationDirection)directionFrom:(CLLocation *)fromLocation
{
    CLLocationDegrees fromLatitude = DegreesToRadians(fromLocation.coordinate.latitude);
    CLLocationDegrees fromLongitude = DegreesToRadians(fromLocation.coordinate.longitude);
    CLLocationDegrees toLatitude = DegreesToRadians(self.coordinate.latitude);
    CLLocationDegrees toLongitude = DegreesToRadians(self.coordinate.longitude);

    CLLocationDirection degree;

    degree =
    atan2(sin(toLongitude - fromLongitude) * cos(toLatitude),
          cos(fromLatitude) * sin(toLatitude) -
          sin(fromLatitude) * cos(toLatitude) * cos(toLongitude - fromLongitude));

    degree = RadiandsToDegrees(degree);

    return (degree >= 0.0f) ? degree : 360.0f + degree;
}

- (CLLocationDirection)directionRelativeFrom:(CLLocation *)fromLocation
                                     heading:(CLLocationDirection)heading
{
    CLLocationDirection headingAbsolute = [self directionFrom:fromLocation];
    CLLocationDirection headingRelative = headingAbsolute - heading;

    if (headingRelative < 180.0f)
    {
        headingRelative = 360.0f + headingRelative;
    }

    if (headingRelative > 180.0f)
    {
        headingRelative = headingRelative - 360.0f;
    }

    return headingRelative;
}

@end
