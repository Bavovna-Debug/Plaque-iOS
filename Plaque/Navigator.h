//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define DegreesToRadians(degrees) \
        (degrees * (M_PI / 180.0f))

#define RadiandsToDegrees(radiands) \
        (radiands * (180.0f / M_PI))

#define OppositeDirection(direction) \
        ((direction < 180.0f) ? (direction + 180.0f) : (direction - 180.0f))

#define CorrectDegrees(x) \
        ((x < 0.0f) ? (360.0f + x) : ((x >= 360.0f) ? (x - 360.0f) : x))

@protocol NavigatorDelegate;

@interface Navigator : NSObject

@property (weak,   nonatomic, readwrite) id<NavigatorDelegate> delegate;
@property (weak,   nonatomic, readwrite) id<NavigatorDelegate> backgroundDelegate;

@property (assign, atomic,    readonly)  Boolean                inBackground;

@property (assign, atomic,    readonly)  CLLocationCoordinate2D startPosition;
@property (assign, atomic,    readonly)  CLLocationCoordinate2D deviceCoordinate;
@property (assign, atomic,    readonly)  CLLocationDistance     deviceAltitude;
@property (assign, atomic,    readonly)  CLLocationDirection    deviceDirection;

+ (Navigator *)sharedNavigator;

- (void)startNavigation;

- (void)stopNavigation;

+ (CLLocationCoordinate2D)coordinateFromLocation:(NSDictionary*)location;

+ (CLLocationDirection)directionFrom:(CLLocationCoordinate2D)fromCoordinate
                                  to:(CLLocationCoordinate2D)toCoordinate;

+ (CLLocationDirection)directionFrom:(CLLocationCoordinate2D)fromCoordinate
                                  to:(CLLocationCoordinate2D)toCoordinate
                          forHeading:(CLLocationDirection)forHeading;

+ (CLLocationDistance)distanceFrom:(CLLocationCoordinate2D)fromCoordinate
                                to:(CLLocationCoordinate2D)toCoordinate;

+ (CLLocationCoordinate2D)shift:(CLLocationCoordinate2D)coordinate
                        heading:(CLLocationDegrees)heading
                       distance:(CLLocationDistance)distance;

+ (NSString *)degreesMinutesSecondsFor:(CLLocationDegrees)value;

@end

@protocol NavigatorDelegate <NSObject>

@optional

- (void)navigator:(Navigator *)navigator
coordinateDidChange:(CLLocationCoordinate2D)coordinate;

- (void)navigator:(Navigator *)navigator
directionDidChangeFrom:(CLLocationDirection)oldDirection
                    to:(CLLocationDirection)newDirection;

@end

/******************************************************************************/
/*                                                                            */
/******************************************************************************/

@interface CLLocation(Navigator)

- (NSInteger)floorlevel;

- (CLLocation *)locationWithShiftFor:(CLLocationDistance)distance
                           direction:(CLLocationDegrees)direction;

- (CLLocationDirection)directionFrom:(CLLocation *)fromLocation;

- (CLLocationDirection)directionRelativeFrom:(CLLocation *)fromLocation
                                     heading:(CLLocationDirection)heading;

@end
