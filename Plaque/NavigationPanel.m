//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <MapKit/MapKit.h>

#import "NavigationPanel.h"
#import "Navigator.h"

#include "Definitions.h"

@interface NavigationPanel () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) NSLock                *refreshLock;
@property (strong, nonatomic) NSLock                *mapViewLock;
@property (strong, nonatomic) MKMapView             *mapView;
@property (strong, nonatomic) NSTimer               *cameraTimer;

@property (strong, nonatomic) CLLocationManager     *locationManager;
@property (assign, atomic)    CLLocationDirection   heading;

@property (strong, nonatomic) CMMotionManager       *motionManager;
@property (assign, atomic)    CGFloat               tilt;

@end

@implementation NavigationPanel
{
    Boolean centeredToUser;
    Boolean regionSet;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.refreshLock = [[NSLock alloc] init];

    return self;
}

- (void)didOpenPanel
{
    [super didOpenPanel];

    CGRect bounds = self.superview.bounds;

    CGSize panelSize = CGSizeMake(280.0f, 200.0f);

    CGRect panelFrame =
    CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
               CGRectGetMaxY(bounds) - panelSize.height - 64.0f,
               panelSize.width,
               panelSize.height);

    [self setFrame:panelFrame];

    self.refreshLock = [[NSLock alloc] init];
    self.mapViewLock = [[NSLock alloc] init];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager setDistanceFilter:1.0f];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager setHeadingFilter:1.0f];
    self.locationManager = locationManager;

    self.motionManager = [[CMMotionManager alloc] init];

    [self prepareMap];

    [self startLocationManager];
    [self startMotionManager];

    self.cameraTimer =
    [NSTimer scheduledTimerWithTimeInterval:CameraUpdateInterval
                                     target:self
                                   selector:@selector(fireCameraUpdate:)
                                   userInfo:nil
                                    repeats:YES];

    [self translate:+1.0f];
}

- (void)didClosePanel
{
    [super didClosePanel];

    NSTimer *cameraTimer = self.cameraTimer;
    if (cameraTimer != nil)
    {
        [cameraTimer invalidate];
    }

    [self stopLocationManager];
    [self stopMotionManager];
}

- (void)prepareMap
{
    MKMapView *mapView = [[MKMapView alloc] init];
    [mapView setFrame:self.bounds];
    [mapView setExclusiveTouch:NO];
    [mapView setShowsUserLocation:YES];
    [mapView setMapType:MKMapTypeStandard];
    [mapView setZoomEnabled:NO];
    [mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];

    [mapView setRotateEnabled:NO];
    [mapView setShowsBuildings:YES];
    [mapView setShowsPointsOfInterest:YES];

    self.mapView = mapView;

    [self addSubview:mapView];

    [mapView setDelegate:self];
}

- (void)startLocationManager
{
    [self.locationManager setDelegate:self];
    [self.locationManager startUpdatingHeading];
}

- (void)stopLocationManager
{
    [self.locationManager setDelegate:nil];
    [self.locationManager stopUpdatingHeading];
}

- (void)startMotionManager
{
    [self.motionManager setAccelerometerUpdateInterval:0.25f];

    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:
     ^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        CGFloat tilt = atan2f(accelerometerData.acceleration.y, accelerometerData.acceleration.z) + M_PI_2;
        tilt = RadiandsToDegrees(tilt);
        tilt = nearbyintf(tilt);

        if (tilt != self.tilt)
        {
            self.tilt = tilt;

            //[self updateCamera];
        }

        if (error)
        {
            NSLog(@"[NavigationPanel] %@", error);
        }
    }];
}

- (void)stopMotionManager
{
    [self.motionManager stopAccelerometerUpdates];
}

- (void)fireCameraUpdate:(NSTimer *)timer
{
    if (regionSet == NO)
    {
        return;
    }

    if ([self.mapViewLock tryLock] == FALSE)
    {
        return;
    }

    CGFloat pitch;
    CLLocationDistance altitude;

    pitch = CorrectDegrees(90.0f + self.tilt);
    if (pitch > 180.0f)
    {
        pitch = 10.0f;
    }
    else if (pitch > 80.0f)
    {
        pitch = 80.0f;
    }
    else if (pitch < 10.0f)
    {
        pitch = 10.0f;
    }

    altitude = 100.0f;// - pitch;

    NSLog(@"[NavigationPanel] Pitch=%f, altitude=%f", pitch, altitude);

    MKMapCamera *mapCamera = [[self.mapView camera] copy];
    [mapCamera setHeading:self.heading];
    [mapCamera setPitch:pitch];
    [mapCamera setAltitude:altitude];
    [mapCamera setCenterCoordinate:self.mapView.userLocation.coordinate];
    [self.mapView setCamera:mapCamera animated:YES];

    [self.mapViewLock unlock];
}

#pragma mark - MapView delegate

/*
- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (centeredToUser == NO) 
    {
        centeredToUser = YES;

        CLLocationCoordinate2D userCoordinate = userLocation.coordinate;
        MKCoordinateRegion completeRegion = //MKCoordinateRegionMakeWithDistance(userCoordinate, 1000.0f, 1000.0f);
            MKCoordinateRegionMake(userCoordinate, MKCoordinateSpanMake(0.005f, 0.005f));
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:completeRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
    }
}
*/

- (void)mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated
{
    if (regionSet == NO)
    {
        MKCoordinateRegion region = mapView.region;
        if ((region.span.latitudeDelta < 0.1f) || (region.span.longitudeDelta < 0.1f))
        {
            regionSet = YES;
        }
    }
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    self.heading = newHeading.trueHeading;
}

@end
