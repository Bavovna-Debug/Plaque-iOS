//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Paquet.h"
#import "Plaque.h"

#define MinimalIntervalBetweenDisplacementsOnRadar  3.0f
#define MinimalIntervalBetweenDisplacementsInSight  3.0f
#define MinimalIntervalBetweenDisplacementsOnMap    1.0f

typedef enum
{
    Workdesk,
    OnRadar,
    InSight,
    OnMap
} PlaqueDestination;

@protocol PlaquesDelegate;

@protocol PlaqueCaptureDelegate;

@protocol PlaqueEditDelegate;

@interface Plaques : NSObject

@property (weak,   nonatomic, readwrite) id<PlaquesDelegate>        plaquesDelegate;
@property (weak,   nonatomic, readwrite) id<PlaqueCaptureDelegate>  captureDelegate;
@property (weak,   nonatomic, readwrite) id<PlaqueEditDelegate>     editDelegate;

@property (strong, nonatomic, readonly)  NSMutableArray     *plaquesOnRadar;
@property (strong, nonatomic, readonly)  NSMutableArray     *plaquesInSight;
@property (strong, nonatomic, readonly)  NSMutableArray     *plaquesOnMap;
@property (strong, nonatomic, readonly)  NSMutableArray     *plaquesOnWorkdesk;

@property (weak,   atomic,    readwrite) Plaque             *plaqueUnderEdit;
@property (weak,   atomic,    readwrite) Plaque             *capturedPlaque;
@property (weak,   atomic,    readwrite) Plaque             *plaqueUnderFortification;

+ (Plaques *)sharedPlaques;

- (void)switchToBackground;

- (void)switchToForeground;

- (void)savePlaquesCache;

- (void)loadPlaquesCache;

- (void)saveWorkdesk;

- (void)loadWorkdesk;

- (void)removeAllPlaques;

- (Plaque *)createNewPlaqueAtUserLocation;

- (Plaque *)plaqueByToken:(NSUUID *)plaqueToken;

- (void)changeDisplacement:(CLLocation *)location
                     range:(CLLocationDistance)range
               destination:(PlaqueDestination)destination;

// Plaque notifications.

- (void)notifyPlaqueDidChangeLocation:(Plaque *)plaque;

- (void)notifyPlaqueDidChangeOrientation:(Plaque *)plaque;

- (void)notifyPlaqueDidResize:(Plaque *)plaque;

- (void)notifyPlaqueDidChangeColor:(Plaque *)plaque;

- (void)notifyPlaqueDidChangeFont:(Plaque *)plaque;

- (void)notifyPlaqueDidChangeInscription:(Plaque *)plaque;

- (void)downloadPlaque:(NSUUID *)plaqueToken;

@end

@protocol PlaquesDelegate <NSObject>

@optional

- (void)plaqueDidAppearOnRadar:(Plaque *)plaque;

- (void)plaqueDidDisappearFromOnRadar:(Plaque *)plaque;

- (void)plaqueDidAppearInSight:(Plaque *)plaque;

- (void)plaqueDidDisappearFromInSight:(Plaque *)plaque;

- (void)plaqueDidAppearOnMap:(Plaque *)plaque;

- (void)plaqueDidDisappearFromOnMap:(Plaque *)plaque;

- (void)plaqueDidAppearOnWorkdesk:(Plaque *)plaque;

- (void)plaqueDidDisappearFromWorkdesk:(Plaque *)plaque;

- (void)plaqueDidBecomeCaptured:(Plaque *)plaque;

- (void)plaqueDidReleaseCaptured:(Plaque *)plaque;

- (void)plaqueDidChangeLocation:(Plaque *)plaque;

- (void)plaqueDidChangeOrientation:(Plaque *)plaque;

- (void)plaqueDidResize:(Plaque *)plaque;

- (void)plaqueDidChangeColor:(Plaque *)plaque;

- (void)plaqueDidChangeFont:(Plaque *)plaque;

- (void)plaqueDidChangeInscription:(Plaque *)plaque;

@end

@protocol PlaqueCaptureDelegate <NSObject>

@required

- (void)plaqueCaptured:(Plaque *)plaque;

@end

@protocol PlaqueEditDelegate <NSObject>

@required

- (void)plaqueDidHaveTakenForEdit:(Plaque *)plaque;

@end
