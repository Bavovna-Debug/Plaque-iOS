//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "PlaqueAnnotation.h"
#import "Plaque.h"
#import "Plaques.h"
#import "PlaquesOnMapView.h"
#import "MainController.h"
#import "Navigator.h"

#include "Definitions.h"

@interface PlaquesOnMapView () <MKMapViewDelegate, PlaquesDelegate>

@property (weak,   nonatomic) MainController    *controller;
@property (strong, nonatomic) NSLock            *refreshLock;
@property (strong, nonatomic) MKMapView         *mapView;

@end

@implementation PlaquesOnMapView
{
    Boolean centeredToUser;
    Boolean regionSet;
}

- (id)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.controller = (MainController *) controller;

    self.refreshLock = [[NSLock alloc] init];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    [self prepareMap];

    return self;
}

- (void)prepareMap
{
    MKMapView *mapView = [[MKMapView alloc] init];
    [mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mapView setExclusiveTouch:NO];
    [mapView setShowsUserLocation:YES];
    [mapView setMapType:MKMapTypeSatellite];
    [mapView setZoomEnabled:YES];
    [mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    [mapView setRotateEnabled:NO];
    [mapView setShowsBuildings:YES];
    [mapView setShowsPointsOfInterest:YES];

    [self addSubview:mapView];

    NSDictionary *viewsDictionary = @{@"mapView":mapView};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[mapView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    self.mapView = mapView;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    [self resume];
}

- (void)pause
{
    [super pause];

    [self.mapView setDelegate:nil];

    [[Plaques sharedPlaques] setPlaquesDelegate:nil];
}

- (void)resume
{
    [super resume];
    
    [self refreshAllPlaques];

    [self.mapView setDelegate:self];

    [[Plaques sharedPlaques] setPlaquesDelegate:self];
}

- (void)refreshAllPlaques
{
    if ([self.refreshLock tryLock] == NO)
    {
        return;
    }

    Plaques *plaques = [Plaques sharedPlaques];

    for (Plaque *plaque in plaques.plaquesOnMap)
    {
        [self refreshPlaqueAnnotation:plaque];
    }

    for (Plaque *plaque in plaques.plaquesOnWorkdesk)
    {
        [self refreshPlaqueAnnotation:plaque];
    }

/* TODO
    Plaque *currentPlaque = [plaques currentPlaque];
    if (currentPlaque != nil)
    {
        [self refreshPlaqueAnnotation:currentPlaque];
    }
*/

    [self.refreshLock unlock];
}

- (void)refreshPlaque:(Plaque *)plaque
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshLock lock];

        [self refreshPlaqueAnnotation:plaque];

        [self.refreshLock unlock];
    });
}

- (void)refreshPlaqueAnnotation:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
    if (plaqueAnnotation == nil)
    {
        plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
        [self.mapView addAnnotation:plaqueAnnotation];
    }
    else
    {
        /* TODO
        PlaqueAnnotation *annotation = (PlaqueAnnotation *) plaque.presentationOnMap;
        [self.mapView removeAnnotation:annotation];
        annotation.coordinate = plaque.coordinate;
        [self.mapView addAnnotation:annotation];*/
    }
}

/*
- (void)pin4
{
    CLLocationCoordinate2D coord;
    coord.latitude = 48.647208f;
    coord.longitude = 9.008869f;
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = coord;
    point.title = @"Where am I?";
    point.subtitle = @"I'm here!!!";

    [self.mapView addAnnotation:point];
}
*/

- (PlaqueAnnotation *)plaqueAnnotationByPlaque:(Plaque *)plaque
{
    for (id<MKAnnotation>annotation in self.mapView.annotations)
    {
        if ([annotation isKindOfClass:[PlaqueAnnotation class]])
        {
            PlaqueAnnotation *plaqueAnnotation = (PlaqueAnnotation *) annotation;
            if (plaqueAnnotation.plaque == plaque)
            {
                return plaqueAnnotation;
            }
        }
    }

    return nil;
}

#pragma mark - MapView delegate

- (void)mapView:(MKMapView *)mapView
didSelectAnnotationView:(MKAnnotationView *)view
{
    Plaque *selectedPlaque;

    PlaqueAnnotation *annotation = (PlaqueAnnotation *) view.annotation;
    if ([annotation isKindOfClass:[PlaqueAnnotation class]])
    {
        selectedPlaque = annotation.plaque;
        [[Plaques sharedPlaques] setCapturedPlaque:selectedPlaque];
    }
    else
    {
        [[Plaques sharedPlaques] setCapturedPlaque:nil];
    }
}

- (void)mapView:(MKMapView *)mapView
didDeselectAnnotationView:(MKAnnotationView *)view
{
    [[Plaques sharedPlaques] setCapturedPlaque:nil];
}

- (void)mapView:(MKMapView *)mapView
regionWillChangeAnimated:(BOOL)animated
{
    MKCoordinateRegion region = mapView.region;

    if (CLLocationCoordinate2DIsValid(region.center) == NO)
    {
        return;
    }

    CLLocation *centerLocation = [[CLLocation alloc]
                                  initWithLatitude:region.center.latitude
                                  longitude:region.center.longitude];
    CLLocation *borderLocation = [[CLLocation alloc]
                                  initWithLatitude:region.center.latitude
                                  longitude:region.center.longitude + region.span.latitudeDelta];

    CLLocationDistance rangeInMeters = [centerLocation distanceFromLocation:borderLocation];

    [[Plaques sharedPlaques] changeDisplacement:centerLocation
                                          range:rangeInMeters
                                    destination:OnMap];

#ifdef VERBOSE
    NSLog(@"[PlaquesOnMapView] Switched to region (%f x %f) with range %f",
          region.center.latitude,
          region.center.longitude,
          rangeInMeters);
#endif
}

- (void)mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated
{
    if (centeredToUser == YES)
    {
        MKCoordinateRegion region = mapView.region;
        if ((region.span.latitudeDelta < 0.1f) || (region.span.longitudeDelta < 0.1f))
        {
            if (regionSet == NO)
            {
                regionSet = YES;
            }
        }

        NSLog(@"[PlaquesOnMapView] Region %f %f %@",
              region.span.latitudeDelta,
              region.span.longitudeDelta,
              (regionSet == NO) ? @"NO" : @"YES");
    }
}

- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (centeredToUser == NO)
    {
        CLLocationCoordinate2D userCoordinate = userLocation.coordinate;

        MKCoordinateRegion completeRegion = //MKCoordinateRegionMakeWithDistance(userCoordinate, 1000.0f, 1000.0f);
            MKCoordinateRegionMake(userCoordinate, MKCoordinateSpanMake(0.005f, 0.005f));

        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:completeRegion];

        [self.mapView setRegion:adjustedRegion animated:YES];

        centeredToUser = YES;
    }
    else
    {
        /* TODO
        [self.mapView setCenterCoordinate:userLocation.coordinate
                                 animated:YES];
        */
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }

    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        return nil;
    }

    if ([annotation isKindOfClass:[PlaqueAnnotation class]])
    {
        PlaqueAnnotation *plaqueAnnotation = (PlaqueAnnotation *) annotation;

        Plaque *plaque = [plaqueAnnotation plaque];

        NSString* AnnotationIdentifier = [[plaque plaqueToken] UUIDString];

        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
        if (annotationView == nil)
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:AnnotationIdentifier];
        }

        [plaqueAnnotation createLayer];
        CALayer *annotationLayer = [plaqueAnnotation annotationLayer];

        if (annotationLayer != nil)
        {
            [annotationView.layer addSublayer:annotationLayer];

#if 0
            annotationView.image = [UIImage imageNamed:@"Annotation"];
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:self action:@selector(writeSomething:)
                  forControlEvents:UIControlEventTouchUpInside];
            [rightButton setTitle:annotation.title forState:UIControlStateNormal];
            annotationView.rightCalloutAccessoryView = rightButton;
            annotationView.canShowCallout = YES;
            annotationView.draggable = YES;
#endif

            return annotationView;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

/*
- (void)mapView:(MKMapView *)mapView
didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView *annotationView in views)
    {
        id<MKAnnotation> annotation = annotationView.annotation;

        if ([annotation isKindOfClass:[MKUserLocation class]])
            continue;

        if ([annotation isKindOfClass:[PlaqueAnnotation class]])
            continue;

        MKPointAnnotation *pointAnnotation = annotation;
 
        NSLog(@"[PlaquesOnMapView] Annotation '%@'", 
              pointAnnotation.title);
    }
}
*/

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
}

#pragma mark - Plaques delegate

- (void)plaqueDidAppearOnMap:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
    [self.mapView addAnnotation:plaqueAnnotation];
}

- (void)plaqueDidAppearOnWorkdesk:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
    [self.mapView addAnnotation:plaqueAnnotation];
}

- (void)plaqueDidChangeLocation:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
    [plaqueAnnotation createLayer];
    /*
    // Remove old annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
        if (plaqueAnnotation != nil)
        {
            [self.mapView removeAnnotation:plaqueAnnotation];
        }
    }

    // Create new annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
        [self.mapView addAnnotation:plaqueAnnotation];
    }*/
}

- (void)plaqueDidChangeOrientation:(Plaque *)plaque
{
}

- (void)plaqueDidResize:(Plaque *)plaque
{
    // Remove old annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
        if (plaqueAnnotation != nil)
        {
            [self.mapView removeAnnotation:plaqueAnnotation];
        }
    }

    // Create new annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
        [self.mapView addAnnotation:plaqueAnnotation];
    }
}

- (void)plaqueDidChangeColor:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
    if (plaqueAnnotation != nil)
    {
        [plaqueAnnotation didChangeColor];
    }
}

- (void)plaqueDidChangeFont:(Plaque *)plaque
{
    // Remove old annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
        if (plaqueAnnotation != nil)
        {
            [self.mapView removeAnnotation:plaqueAnnotation];
        }
    }

    // Create new annotation.
    //
    {
        PlaqueAnnotation *plaqueAnnotation = [[PlaqueAnnotation alloc] initWithPlaque:plaque];
        [self.mapView addAnnotation:plaqueAnnotation];
    }
}

- (void)plaqueDidChangeInscription:(Plaque *)plaque
{
    PlaqueAnnotation *plaqueAnnotation = [self plaqueAnnotationByPlaque:plaque];
    if (plaqueAnnotation != nil)
    {
        [plaqueAnnotation didChangeInscription];
    }
}

- (void)plaqueDidBecomeCaptured:(Plaque *)plaque
{
}

- (void)plaqueDidReleaseCaptured:(Plaque *)plaque
{
}

@end
