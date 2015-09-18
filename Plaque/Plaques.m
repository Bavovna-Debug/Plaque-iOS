//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Authentificator.h"
#import "Communicator.h"
#import "Paquet.h"
#import "Navigator.h"
#import "Plaques.h"
#import "Database.h"
#import "Profiles.h"
#import "Settings.h"
#import "StatusBar.h"
#import "XML.h"

#include "API.h"

#ifdef DEBUG
#define VERBOSE_BROADCAST
#define VERBOSE_LOCATION_MANAGER
#define VERBOSE_RADAR
#define VERBOSE_RADAR_DETAILS
#define VERBOSE_PLAQUES
#undef VERBOSE_ADD_PLAQUE
#define VERBOSE_WORKDESK
#undef VERBOSE_DATABASE
#endif

#define MinimumDistanceForInSightRefresh    500.0f
#define DistanceToNewPlaqueOnCreation       20.0f
#define RangeForInSightRefresh              5000.0f

#define SaveToDatabaseInterval              3.0f
#define WorkdeskUploadInterval              2.0f

#define MaxPlaquesPerDownloadRequest        100

#define PlaquesCacheKey                     @"PlaquesCache"
#define PlaquesOnWorkdeskKey                @"PlaquesOnWorkdesk"
#define PlaquesXMLTarget                    @"vp"
#define PlaquesXMLVersion                   @"1.0"

@interface Plaques () <CLLocationManagerDelegate, ConnectionDelegate, PaquetDelegate>

@property (strong, nonatomic, readwrite) NSLock          *paquetHandlerLock;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesCache;
@property (strong, nonatomic, readwrite) NSLock          *plaquesCacheLock;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesInSight;
@property (strong, nonatomic, readwrite) NSLock          *plaquesInSightLock;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesOnMap;
@property (strong, nonatomic, readwrite) NSLock          *plaquesOnMapLock;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesOnWorkdesk;
@property (strong, nonatomic, readwrite) NSLock          *plaquesOnWorkdeskLock;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesAwaitingDownload;
@property (strong, nonatomic, readwrite) NSMutableArray  *plaquesAwaitingDatabase;
@property (strong, nonatomic, readwrite) NSLock          *plaquesAwaitingDatabaseLock;

@property (strong, nonatomic)            NSTimer         *databaseTimer;
@property (strong, nonatomic)            NSTimer         *workdeskTimer;

@property (strong, nonatomic)            CLLocationManager  *locationManager;
@property (strong, nonatomic)            CLLocation         *locationOfLastInSightRefresh;

@end

@implementation Plaques
{
    Settings *settings;
    Communicator *communicator;

    BOOL inBackground;
}

@synthesize plaqueUnderEdit = _plaqueUnderEdit;
@synthesize capturedPlaque = _capturedPlaque;

+ (Plaques *)sharedPlaques
{
    static dispatch_once_t onceToken;
    static Plaques *plaques;

    dispatch_once(&onceToken, ^{
        plaques = [[Plaques alloc] init];
    });

    return plaques;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    settings = [Settings defaultSettings];
    communicator = [Communicator sharedCommunicator];

    self.paquetHandlerLock              = [[NSLock alloc] init];
    self.plaquesCache                   = [NSMutableArray array];
    self.plaquesCacheLock               = [[NSLock alloc] init];
    self.plaquesInSight                 = [NSMutableArray array];
    self.plaquesInSightLock             = [[NSLock alloc] init];
    self.plaquesOnMap                   = [NSMutableArray array];
    self.plaquesOnMapLock               = [[NSLock alloc] init];
    self.plaquesOnWorkdesk              = [NSMutableArray array];
    self.plaquesOnWorkdeskLock          = [[NSLock alloc] init];
    self.plaquesAwaitingDownload        = [NSMutableArray array];
    self.plaquesAwaitingDatabase        = [NSMutableArray array];
    self.plaquesAwaitingDatabaseLock    = [[NSLock alloc] init];

    [self prepareLocationManager];

    [communicator setConnectionDelegate:self];

    return self;
}

- (void)prepareLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDistanceFilter:100.0f];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [self.locationManager setHeadingFilter:1.0f];
    [self.locationManager setDelegate:self];

    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }

    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)switchToBackground
{
    inBackground = YES;
    [self.locationManager stopUpdatingHeading];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDistanceFilter:50.0f];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    [self.locationManager startUpdatingLocation];

    NSTimer *databaseTimer = self.databaseTimer;
    if (databaseTimer != nil)
        [databaseTimer invalidate];

    NSTimer *workdeskTimer = self.workdeskTimer;
    if (workdeskTimer != nil)
        [workdeskTimer invalidate];
}

- (void)switchToForeground
{
    inBackground = NO;
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDistanceFilter:10.0f];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];

    self.databaseTimer =
    [NSTimer scheduledTimerWithTimeInterval:SaveToDatabaseInterval
                                     target:self
                                   selector:@selector(fireSaveToDatabase:)
                                   userInfo:nil
                                    repeats:YES];

    self.workdeskTimer =
    [NSTimer scheduledTimerWithTimeInterval:WorkdeskUploadInterval
                                     target:self
                                   selector:@selector(fireWorkdeskUpload:)
                                   userInfo:nil
                                    repeats:YES];
}

#pragma mark - XML storage

- (void)savePlaquesCache
{
    XMLDocument *document = [XMLDocument documentWithTarget:PlaquesXMLTarget
                                                    version:PlaquesXMLVersion];

    XMLElement *plaquesXML = [XMLElement elementWithName:@"plaques_cache"];

    [document setForest:plaquesXML];

    [self.plaquesCacheLock lock];
    [self.plaquesInSightLock lock];
    [self.plaquesOnMapLock lock];
    for (Plaque *plaque in self.plaquesCache)
    {
        XMLElement *plaqueXML = [XMLElement elementWithName:@"plaque"];

        NSUUID *plaqueToken = [plaque plaqueToken];
        NSString *plaqueTokenString = [plaqueToken UUIDString];
        [plaqueXML.attributes setObject:plaqueTokenString
                                 forKey:@"plaque_token"];

        NSString *isInSight = ([self.plaquesInSight containsObject:plaque] == YES) ? @"yes" : @"no";
        [plaqueXML.attributes setObject:isInSight
                                 forKey:@"in_sight"];

        NSString *isOnMap = ([self.plaquesOnMap containsObject:plaque] == YES) ? @"yes" : @"no";
        [plaqueXML.attributes setObject:isOnMap
                                 forKey:@"on_map"];

        [plaquesXML addElement:plaqueXML];
    }
    [self.plaquesOnMapLock unlock];
    [self.plaquesInSightLock unlock];
    [self.plaquesCacheLock unlock];

    NSData *plaquesData = [document xmlData];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:plaquesData
                 forKey:PlaquesCacheKey];
    [defaults synchronize];
}

- (void)loadPlaquesCache
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *plaquesData = [defaults objectForKey:PlaquesCacheKey];
    XMLDocument *document = [XMLDocument documentFromData:plaquesData];

    XMLElement *plaquesXML = [document forest];

    [self.plaquesCacheLock lock];
    [self.plaquesInSightLock lock];
    [self.plaquesOnMapLock lock];
    for (XMLElement *plaqueXML in [plaquesXML elements])
    {
        NSString *plaqueTokenString = [plaqueXML.attributes objectForKey:@"plaque_token"];
        NSUUID *plaqueToken = [[NSUUID alloc] initWithUUIDString:plaqueTokenString];
        Plaque *plaque = [[Plaque alloc] initWithToken:plaqueToken];
        if (plaque == nil)
            continue;

        [self.plaquesCache addObject:plaque];

        // Restore this plaque to "InSight" if it was there before.
        //
        NSString *isInSight = [plaqueXML.attributes objectForKey:@"in_sight"];
        if ([isInSight isEqualToString:@"yes"] == YES)
            [self.plaquesInSight addObject:plaque];

        // Restore this plaque to "OnMap" if it was there before.
        //
        NSString *isOnMap = [plaqueXML.attributes objectForKey:@"on_map"];
        if ([isOnMap isEqualToString:@"yes"] == YES)
            [self.plaquesOnMap addObject:plaque];
    }
    [self.plaquesOnMapLock unlock];
    [self.plaquesInSightLock unlock];
    [self.plaquesCacheLock unlock];
}

- (void)saveWorkdesk
{
    XMLDocument *document = [XMLDocument documentWithTarget:PlaquesXMLTarget
                                                    version:PlaquesXMLVersion];

    XMLElement *plaquesXML = [XMLElement elementWithName:@"plaques_on_workdesk"];

    [document setForest:plaquesXML];

    [self.plaquesOnWorkdeskLock lock];
    for (Plaque *plaque in self.plaquesOnWorkdesk)
    {
        XMLElement *plaqueXML = [plaque xml];

        [plaquesXML addElement:plaqueXML];
    }
    [self.plaquesOnWorkdeskLock unlock];

    NSData *plaquesData = [document xmlData];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:plaquesData
                 forKey:PlaquesOnWorkdeskKey];
    [defaults synchronize];
}

- (void)loadWorkdesk
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *plaquesData = [defaults objectForKey:PlaquesOnWorkdeskKey];
    XMLDocument *document = [XMLDocument documentFromData:plaquesData];

    XMLElement *plaquesXML = [document forest];

    [self.plaquesOnWorkdeskLock lock];
    for (XMLElement *plaqueXML in [plaquesXML elements])
    {
        Plaque *plaque = [[Plaque alloc] initFromXML:plaqueXML];

        if (plaque == nil)
            continue;

        [self.plaquesOnWorkdesk addObject:plaque];

        // If the original plaque exist in cache ...
        //
        Plaque *plaqueInCache = [self plaqueInCacheByToken:[plaque plaqueToken]];
        if (plaqueInCache != nil) {
            //
            // ... then chain it with the one on workdesk.
            //
            plaque.cloneChain = plaqueInCache;
            plaqueInCache.cloneChain = plaque;
        }
    }
    [self.plaquesOnWorkdeskLock unlock];
}

#pragma mark - API

- (Plaque *)createNewPlaqueAtUserLocation
{
    CLLocation *deviceLocation = [self.locationManager location];
    CLHeading *deviceHeading = [self.locationManager heading];
    CLLocation *plaqueLocation = [deviceLocation locationWithShiftFor:DistanceToNewPlaqueOnCreation
                                                            direction:[deviceHeading trueHeading]];

    Plaque *newPlaque = [[Plaque alloc] initWithLocation:plaqueLocation
                                               direction:floorf(oppositeDirection([deviceHeading trueHeading]))
                                             inscription:@"Hier könnte Ihre Werbung sein"];

    [self addPlaqueToOnWorkdesk:newPlaque];

    self.plaqueUnderEdit = newPlaque;

    return newPlaque;
}

- (void)setPlaqueUnderEdit:(Plaque *)plaqueUnderEdit
{
    // If there is some plaque captured, then release it.
    //
    [self setCapturedPlaque:nil];

    Plaque *previousPlaqueUnderEdit = _plaqueUnderEdit;
    Plaque *newPlaqueUnderEdit = plaqueUnderEdit;

    // First make sure no plaque is hanging: if there is any plaque already set as current plaque then release it.
    //
    if (previousPlaqueUnderEdit != nil) {
    }

    if (newPlaqueUnderEdit == nil ) {
        _plaqueUnderEdit = nil;
    } else {
        Plaque *plaqueOnWorkdesk = nil;

        [self.plaquesOnWorkdeskLock lock];

        // If this plaque is not on workdesk yet then clone it and put the clone on workdesk.
        //
        if ([self.plaquesOnWorkdesk containsObject:plaqueUnderEdit] == NO) {
            plaqueOnWorkdesk = [plaqueUnderEdit clone];
            [self.plaquesOnWorkdesk addObject:plaqueOnWorkdesk];

            // Notify delegate a cloned plaque did appear on workdesk and must be shown.
            //
            id<PlaquesDelegate> delegate = self.plaquesDelegate;
            if ((delegate != nil) && [delegate respondsToSelector:@selector(plaqueDidAppearOnWorkdesk:)])
                [delegate plaqueDidAppearOnWorkdesk:plaqueOnWorkdesk];
        } else {
            //
            // If selected plaque is the one that is on workdesk then take it.
            //
            plaqueOnWorkdesk = plaqueUnderEdit;
        }

        [self.plaquesOnWorkdeskLock unlock];

        _plaqueUnderEdit = plaqueOnWorkdesk;

        id<PlaqueEditDelegate> editDelegate = self.editDelegate;
        [editDelegate plaqueDidHaveTakenForEdit:plaqueOnWorkdesk];
    }
}

- (void)setCapturedPlaque:(Plaque *)capturedPlaque
{
    if (self.plaqueUnderEdit != nil)
        capturedPlaque = nil;

    Plaque *previousCapturedPlaque = _capturedPlaque;

    if (capturedPlaque != previousCapturedPlaque) {
        _capturedPlaque = capturedPlaque;

        id<PlaquesDelegate> delegate = self.plaquesDelegate;

        if (previousCapturedPlaque != nil) {
            [previousCapturedPlaque setCaptured:NO];
            if (delegate != nil)
                [delegate plaqueDidReleaseCaptured:previousCapturedPlaque];
        }

        if (capturedPlaque != nil) {
            [capturedPlaque setCaptured:YES];
            if (delegate != nil)
                [delegate plaqueDidBecomeCaptured:capturedPlaque];
        }

        id<PlaqueCaptureDelegate> captureDelegate = self.captureDelegate;
        [captureDelegate plaqueCaptured:capturedPlaque];
    }
}

- (void)fireSaveToDatabase:(NSTimer *)timer
{
    // Quit if this procedure already running.
    //
    if ([self.plaquesAwaitingDatabaseLock tryLock] == NO)
        return;

    // Execute main part dispatched because of SQLite latecy.
    //
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSMutableArray *savedPlaques = [NSMutableArray array];

        // Go through all plaques awaiting store in local database.
        //
        for (Plaque *plaque in self.plaquesAwaitingDatabase)
        {
            // If this plaque has not being stored in local database yet ..
            //
            if (plaque.rowId == 0) {
                //
                // Then execute store procedure ...
                //
                [plaque saveToDatabase];

                // ... and check afterwards whether it did store itself saccessfully.
                //
                if (plaque.rowId != 0) {
                    //
                    // If yes, then notice this plaque as processed.
                    //
                    [savedPlaques addObject:plaque];
#ifdef VERBOSE_DATABASE
                    NSLog(@"Plaque %@ stored in database", [[plaque plaqueToken] UUIDString]);
#endif
                } else {
#ifdef VERBOSE_DATABASE
                    NSLog(@"Plaque %@ cannot be stored in database", [[plaque plaqueToken] UUIDString]);
#endif
                }
            } else {
                //
                // This plaque was already stored in local database before - just notice it as processed.
                //
                [savedPlaques addObject:plaque];
            }
        }
#ifdef VERBOSE_DATABASE
        NSLog(@"Save to database proceeded: %lu awaiting %lu saved",
              (unsigned long)[self.plaquesAwaitingDatabase count],
              (unsigned long)[savedPlaques count]);
#endif

        // Remove stored plaques from awaiting list.
        //
        for (Plaque *plaque in savedPlaques)
            [self.plaquesAwaitingDatabase removeObject:plaque];

        [self.plaquesAwaitingDatabaseLock unlock];
    });
}

- (void)fireWorkdeskUpload:(NSTimer *)timer
{
    if ([self.plaquesOnWorkdesk count] == 0)
        return;
    
    NSMutableArray *completedWorkdeskPlaques = [NSMutableArray array];

    [self.plaquesOnWorkdeskLock lock];

    for (Plaque *plaqueOnWorkdesk in self.plaquesOnWorkdesk)
    {
        BOOL uploadNecessary = [plaqueOnWorkdesk uploadToCloudIfNecessary];
        if ((uploadNecessary == NO) && (plaqueOnWorkdesk != self.plaqueUnderEdit))
            [completedWorkdeskPlaques addObject:plaqueOnWorkdesk];
    }

#ifdef VERBOSE_WORKDESK
    NSLog(@"Plaques on workdesk: %lu total, %lu complete",
          (unsigned long)[self.plaquesOnWorkdesk count],
          (unsigned long)[completedWorkdeskPlaques count]);
#endif

    for (Plaque *plaqueOnWorkdesk in completedWorkdeskPlaques)
    {
        [self.plaquesOnWorkdesk removeObject:plaqueOnWorkdesk];

        // Notify delegate that plaque from workdesk did disappear.
        //
        id<PlaquesDelegate> delegate = self.plaquesDelegate;
        if ((delegate != nil) && [delegate respondsToSelector:@selector(plaqueDidDisappearFromWorkdesk:)])
            [delegate plaqueDidDisappearFromWorkdesk:plaqueOnWorkdesk];
    }

    [self.plaquesOnWorkdeskLock unlock];
}

#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = (CLLocation *)[locations lastObject];

    if ((self.locationOfLastInSightRefresh == nil)
        || ([self.locationOfLastInSightRefresh distanceFromLocation:location] > MinimumDistanceForInSightRefresh)) {
        [self refreshPlaquesForLocation:location
                                  range:RangeForInSightRefresh
                            destination:InSight];

        self.locationOfLastInSightRefresh = location;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
#ifdef VERBOSE_LOCATION_MANAGER
    NSLog(@"%@", error);
#endif
}

#pragma mark - Radar

- (Plaque *)plaqueByToken:(NSUUID *)plaqueToken
{
    Plaque *plaque;

    // First look if this plaque is already in cache.
    //
    plaque = [self plaqueInCacheByToken:plaqueToken];

    // If it is not cache then search for it in local database.
    //
    if (plaque == nil) {
        plaque = [[Plaque alloc] initWithToken:plaqueToken];

        // If plaque was found in local database then add it to cache.
        //
        if (plaque != nil) {
            [self.plaquesCacheLock lock];
            [self.plaquesCache addObject:plaque];
            [self.plaquesCacheLock unlock];
        }
    }

    return plaque;
}

- (Plaque *)plaqueInCacheByToken:(NSUUID *)plaqueToken
{
    for (Plaque *plaque in self.plaquesCache)
    {
        if ([plaque.plaqueToken isEqual:plaqueToken] == YES)
            return plaque;
    }

    return nil;
}

- (Plaque *)plaqueOnWorkdeskByToken:(NSUUID *)plaqueToken
{
    for (Plaque *plaque in self.plaquesOnWorkdesk)
    {
        if ([plaque.plaqueToken isEqual:plaqueToken] == YES)
            return plaque;
    }

    return nil;
}

- (Plaque *)plaqueInSightByToken:(NSUUID *)plaqueToken
{
    for (Plaque *plaque in self.plaquesInSight)
    {
        if ([plaque.plaqueToken isEqual:plaqueToken] == YES)
            return plaque;
    }

    return nil;
}

- (Plaque *)plaqueOnMapByToken:(NSUUID *)plaqueToken
{
    for (Plaque *plaque in self.plaquesOnMap)
    {
        if ([plaque.plaqueToken isEqual:plaqueToken] == YES)
            return plaque;
    }

    return nil;
}

- (void)addPlaqueToCache:(Plaque *)plaque
{
    if (plaque == nil)
        return;
    
    [self.plaquesCacheLock lock];
    [self.plaquesCache addObject:plaque];
    [self.plaquesCacheLock unlock];

    if (plaque.rowId == 0)
        [self.plaquesAwaitingDatabase addObject:plaque];

#ifdef VERBOSE_ADD_PLAQUE
    NSLog(@"Added to cache <%@>", [plaque inscription]);
#endif
}

- (void)addPlaqueToOnWorkdesk:(Plaque *)plaque
{
    @try {
        [self.plaquesOnWorkdeskLock lock];

        [self.plaquesOnWorkdesk addObject:plaque];

        // Notify delegate we have some new plaque on workdesk.
        //
        id<PlaquesDelegate> delegate = self.plaquesDelegate;
        if ((delegate != nil) && [delegate respondsToSelector:@selector(plaqueDidAppearOnWorkdesk:)])
            [delegate plaqueDidAppearOnWorkdesk:plaque];

#ifdef VERBOSE_ADD_PLAQUE
        NSLog(@"Added to OnWorkdesk <%@> with delegate %@",
              [plaque inscription],
              (delegate == nil) ? @"NIL" : @"NOT NIL");
#endif

    }
    @catch (NSException *exception) {
        NSLog(@"%s: %@", __FUNCTION__, exception);
    }
    @finally {
        [self.plaquesOnWorkdeskLock unlock];

    }
}

- (void)addPlaqueToInSight:(Plaque *)plaque
{
    @try {
        NSLog(@"AAADDDDDD: %@ %@", (self.plaquesDelegate == nil) ? @"NIX" : @"GIBS", plaque.inscription);
        [self.plaquesInSightLock lock];

        [self.plaquesInSight addObject:plaque];

        // Notify delegate we have some new plaque in sight.
        //
        id<PlaquesDelegate> delegate = self.plaquesDelegate;
        if ((delegate != nil) && [delegate respondsToSelector:@selector(plaqueDidAppearInSight:)])
            [delegate plaqueDidAppearInSight:plaque];

#ifdef VERBOSE_ADD_PLAQUE
        NSLog(@"Added to InSight <%@> with delegate %@", [plaque inscription], (delegate == nil) ? @"NIL" : @"NOT NIL");
#endif
    }
    @catch (NSException *exception) {
        NSLog(@"%s: %@", __FUNCTION__, exception);
    }
    @finally {
        [self.plaquesInSightLock unlock];
    }
}

- (void)addPlaqueToOnMap:(Plaque *)plaque
{
    @try {
        [self.plaquesOnMapLock lock];

        [self.plaquesOnMap addObject:plaque];

        // Notify delegate we have some new plaque on map.
        //
        id<PlaquesDelegate> delegate = self.plaquesDelegate;
        if ((delegate != nil) && [delegate respondsToSelector:@selector(plaqueDidAppearOnMap:)])
            [delegate plaqueDidAppearOnMap:plaque];

#ifdef VERBOSE_ADD_PLAQUE
        NSLog(@"Added to OnMap <%@> with delegate %@", [plaque inscription], (delegate == nil) ? @"NIL" : @"NOT NIL");
#endif

    }
    @catch (NSException *exception) {
        NSLog(@"%s: %@", __FUNCTION__, exception);
    }
    @finally {
        [self.plaquesOnMapLock unlock];
    }
}

#pragma mark - 

- (void)downloadPlaque:(NSUUID *)plaqueToken
{
    [self downloadPlaques:[NSMutableArray arrayWithObject:plaqueToken]
              destination:InSight];
}

- (void)downloadPlaques:(NSMutableArray *)missingPlaques
            destination:(PlaqueDestination)destination
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"STATUS_BAR_DOWNLOAD_PLAQUES", nil),
                         [missingPlaques count]];
    [[StatusBar sharedStatusBar] postMessage:message];

    UInt32 paquetCommand;

    switch (destination)
    {
        case InSight:
            paquetCommand = PaquetDownloadPlaquesInSight;
            break;

        case OnMap:
            paquetCommand = PaquetDownloadPlaquesOnMap;
            break;

        default:
            return;
    }

    Paquet *paquet = [[Paquet alloc] initWithCommand:paquetCommand];

    [paquet setDelegate:self];

    [paquet putUInt32:(int)[missingPlaques count]];

    for (NSUUID *plaqueToken in missingPlaques)
        [paquet putToken:plaqueToken];

    [paquet send];
}

- (void)refreshPlaquesForLocation:(CLLocation *)location
                            range:(CLLocationDistance)range
                      destination:(PlaqueDestination)destination
{
    if ([[Authentificator sharedAuthentificator] deviceRegistered] == NO)
        return;

    if (CLLocationCoordinate2DIsValid(location.coordinate) == NO)
        return;

    if (location.coordinate.latitude == 0.0f)
        return;

    if (location.coordinate.longitude == 0.0f)
        return;

    UInt32 paquetCommand;
    NSUInteger radarRevision;

    switch (destination)
    {
        case InSight:
            paquetCommand = PaquetListOfPlaquesInSight;
            radarRevision = [settings radarInSightRevision];
            break;

        case OnMap:
            paquetCommand = PaquetListOfPlaquesOnMap;
            radarRevision = [settings radarOnMapRevision];
            break;

        default:
            return;
    }

    Paquet *paquet = [[Paquet alloc] initWithCommand:paquetCommand];

    [paquet setDelegate:self];

    CLLocationCoordinate2D coordinate = location.coordinate;
    CLLocationDistance altitude = location.altitude;
    CLLocationDirection course = location.course;
    NSInteger floorlevel = [location floorlevel];

    [paquet putUInt32:(UInt32)radarRevision];
    [paquet putDouble:coordinate.latitude];
    [paquet putDouble:coordinate.longitude];
    [paquet putFloat:altitude];
    [paquet putBoolean:(course == -1.0f) ? FALSE : TRUE];
    [paquet putFloat:course];
    [paquet putBoolean:(floorlevel == NSIntegerMax) ? FALSE : TRUE];
    [paquet putUInt32:(UInt32)floorlevel];
    [paquet putFloat:range];
    
    [paquet send];

    NSLog(@"REVISION: %lu", (unsigned long)radarRevision);
}

- (void)addPlaque:(Plaque *)plaque
{
    [self addPlaqueToCache:plaque];
    [self addPlaqueToInSight:plaque];
    [self addPlaqueToOnMap:plaque];
}

#pragma mark - Plaque notifications

- (void)notifyPlaqueDidChangeLocation:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidChangeLocation:plaque];
}

- (void)notifyPlaqueDidChangeOrientation:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidChangeOrientation:plaque];
}

- (void)notifyPlaqueDidResize:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidResize:plaque];
}

- (void)notifyPlaqueDidChangeColor:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidChangeColor:plaque];
}

- (void)notifyPlaqueDidChangeFont:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidChangeFont:plaque];
}

- (void)notifyPlaqueDidChangeInscription:(Plaque *)plaque
{
    id<PlaquesDelegate> delegate = self.plaquesDelegate;
    if (delegate != nil)
        [delegate plaqueDidChangeInscription:plaque];
}

#pragma mark - Broadcast

- (void)generateBroadcast:(UInt32)commandCode
{
    Paquet *paquet = [[Paquet alloc] initWithCommand:commandCode];
    [paquet setDelegate:self];
    [paquet send];

#ifdef VERBOSE_BROADCAST
    NSLog(@"Broadcast request sent");
#endif
}

#pragma mark - Communicator delegate

- (void)communicatorDidEstablishDialogue
{
    [self generateBroadcast:PaquetBroadcastForInSight];
    [self generateBroadcast:PaquetBroadcastForOnRadar];
}

#pragma mark - Paquet delegate

- (void)paquetComplete:(Paquet *)paquet
{
    switch (paquet.commandCode)
    {
        case PaquetBroadcastForInSight:
            [self processRadar:paquet
                   destination:InSight];
            [self generateBroadcast:PaquetBroadcastForInSight];
            break;

        case PaquetBroadcastForOnRadar:
            [self processRadar:paquet
                   destination:InSight];
            [self generateBroadcast:PaquetBroadcastForOnRadar];
            break;

        case PaquetListOfPlaquesInSight:
            [self processRadar:paquet
                   destination:InSight];
            break;

        case PaquetListOfPlaquesOnMap:
            [self processRadar:paquet
                   destination:OnMap];
            break;

        case PaquetDownloadPlaquesInSight:
            [self processPlaques:paquet
                     destination:InSight];
            break;

        case PaquetDownloadPlaquesOnMap:
            [self processPlaques:paquet
                     destination:OnMap];
            break;

        default:
            break;
    }
}

#pragma mark - Process completed paquets

- (void)processRadar:(Paquet *)paquet
         destination:(PlaqueDestination)destination
{
    @try
    {
        [self.paquetHandlerLock lock];

        UInt32 radarInSightRevision = [paquet getUInt32];
        UInt32 numberOfPlaques = [paquet getUInt32];

        [settings setRadarInSightRevision:radarInSightRevision];

#ifdef VERBOSE_RADAR
        NSLog(@"Received %d plaques for radar revision %d",
              (unsigned int)numberOfPlaques,
              (unsigned int)radarInSightRevision);
#endif

        if (numberOfPlaques > 0)
        {
            NSString *message = [NSString stringWithFormat:
                                 NSLocalizedString(@"STATUS_BAR_PROCESS_RADAR", nil),
                                 (unsigned int)numberOfPlaques];
            [[StatusBar sharedStatusBar] postMessage:message];
        }

        NSMutableArray *missingPlaques = [NSMutableArray array];

        for (int i = 0; i < numberOfPlaques; i++)
        {
            NSUUID *plaqueToken = [paquet getToken];
            UInt32 plaqueRevision = [paquet getUInt32];

            Plaque *plaque = nil;

            // Look if the corresponding plaque is already in cache.
            //
            plaque = [self plaqueInCacheByToken:plaqueToken];

            // If it doesn't ...
            //
            if (plaque == nil)
            {
                // ... then search for it in local database.
                //
                plaque = [[Plaque alloc] initWithToken:plaqueToken];
            }

            // If the plaque exists already in local database ...
            //
            if (plaque != nil)
            {
                //
                // ... then add it to cache ...
                //
                [self addPlaqueToCache:plaque];

                // ... and accordingly to "InSight" or "OnMap" or both.
                //
                switch (paquet.commandCode)
                {
                    case PaquetListOfPlaquesInSight:
                        if ([self plaqueInSightByToken:plaqueToken] == nil)
                            [self addPlaqueToInSight:plaque];
                        if ([self plaqueOnMapByToken:plaqueToken] == nil)
                            [self addPlaqueToOnMap:plaque];
                        break;

                    case PaquetListOfPlaquesOnMap:
                        if ([self plaqueOnMapByToken:plaqueToken] == nil)
                            [self addPlaqueToOnMap:plaque];
                        break;

                    default:
                        break;
                }
            }

            // So, now, if the plaque exists
#ifdef VERBOSE_RADAR_DETAILS
            NSLog(@"Token %@ revision %d <%@>",
                  [plaqueToken UUIDString],
                  plaqueRevision,
                  (plaque == nil) ? @"NULL" : [plaque inscription]);
#endif

            // If it does not exist in local database then ...
            //
            if (plaque == nil)
            {
                // ... request download ...
                //
                [missingPlaques addObject:plaqueToken];

                // ... and put it on a list of plaques awaiting download.
                //
                [self.plaquesAwaitingDownload addObject:plaqueToken];
            }

            // If plaque on server is newer than in local database then flag it for update.
            //
            if (plaque != nil) {
                if ([plaque plaqueRevision] < plaqueRevision)
                    [missingPlaques addObject:plaqueToken];
            }

            // If there are already too much candidates for download in a queue ...
            //
            if ([missingPlaques count] == MaxPlaquesPerDownloadRequest)
            {
                // ... then send a download request.
                //
                [self downloadPlaques:missingPlaques
                          destination:destination];
                [missingPlaques removeAllObjects];
            }
        }

        // Are there still any candidates for download in a queue ...
        //
        if ([missingPlaques count] > 0) {
            //
            // ... then send download request.
            //
            [self downloadPlaques:missingPlaques
                      destination:destination];
            [missingPlaques removeAllObjects];
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"%@: %@", exception.name, exception.reason);
    }
    @finally
    {
        [self.paquetHandlerLock unlock];
    }
}

- (void)processPlaques:(Paquet *)paquet
           destination:(PlaqueDestination)destination
{
    @try
    {
        [self.paquetHandlerLock lock];

        Profiles *profiles = [Profiles sharedProfiles];

        while ([paquet payloadEOF] == NO)
        {
            // Extract all plaque properties out of the paquet.
            //
            NSUUID *plaqueToken = [paquet getToken];
            UInt32 revision = [paquet getUInt32];
            NSUUID *profileToken = [paquet getToken];
            NSString *dimension = [paquet getFixedString:2];
            double latitude = [paquet getDouble];
            double longitude = [paquet getDouble];
            float altitude = [paquet getFloat];
            Boolean directed = [paquet getBoolean];
            float direction = [paquet getFloat];
            Boolean tilted = [paquet getBoolean];
            float tilt = [paquet getFloat];
            float width = [paquet getFloat];
            float height = [paquet getFloat];
            UIColor *backgroundColor = [UIColor colorWithCGColor:[paquet getColor]];
            UIColor *foregroundColor = [UIColor colorWithCGColor:[paquet getColor]];
            float fontSize = [paquet getFloat];
            NSString *inscription = [paquet getString];

#ifdef VERBOSE_PLAQUES
            NSLog(@"Plaque: %@ %@ (%f x %f) (%f x %f) <%@>",
                  [plaqueToken UUIDString],
                  dimension,
                  latitude,
                  longitude,
                  width,
                  height,
                  inscription);
#endif

            //NSString *message = NSLocalizedString(@"STATUS_BAR_PROCESS_PLAQUES", nil);
            //[[StatusBar sharedStatusBar] postMessage:message];

            Plaque *plaque = nil;

            // Look if the corresponding plaque is already in cache.
            //
            plaque = [self plaqueInCacheByToken:plaqueToken];

            // If it doesn't ...
            //
            if (plaque == nil)
            {
                // ... then search for it in local database.
                //
                plaque = [[Plaque alloc] initWithToken:plaqueToken];

                // If it doesn't exist in local database ...
                //
                if (plaque == nil)
                {
                    // ... then create a new plaque instance for it
                    // so that it will be stored in local database on schedule.
                    //
                    plaque = [[Plaque alloc] init];
                    [plaque setPlaqueToken:plaqueToken];
                    [plaque setPlaqueRevision:revision];
                    [plaque setProfileToken:profileToken];
                    [plaque setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
                    [plaque setAltitude:altitude];
                    [plaque setDirected:directed];
                    [plaque setDirection:direction];
                    [plaque setTilted:tilted];
                    [plaque setTilt:tilt];
                    [plaque setWidth:width];
                    [plaque setHeight:height];
                    [plaque setSize:CGSizeMake(width, height)];
                    [plaque setBackgroundColor:backgroundColor];
                    [plaque setForegroundColor:foregroundColor];
                    [plaque setFontSize:fontSize];
                    [plaque setInscription:inscription];

                    // Flag it as needs to be stored in local database ...
                    //
                    //[plaque saveInDatabase];

                    // ... then add it to cache.
                    //
                    [self addPlaqueToCache:plaque];

                    // If this plaque is still on workdesk ...
                    //
                    Plaque *plaqueOnWorkdesk = [self plaqueOnWorkdeskByToken:plaqueToken];
                    if (plaqueOnWorkdesk != nil) {
                        //
                        // ... then chain it with its original.
                        //
                        plaque.cloneChain = plaqueOnWorkdesk;
                        plaqueOnWorkdesk.cloneChain = plaque;
                    }
                }
            }

            // Check whether revision of this plaque has changed on a server.
            //
            if ([plaque plaqueRevision] != revision)
            {
                // If yes, then just set all plaque properties provided by server to the plaque object
                // and let the plaque object itself to do neccessary updates in local database.
                //
                [plaque setProfileToken:profileToken];
                [plaque setPlaqueRevision:revision];
                [plaque setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
                [plaque setAltitude:altitude];
                [plaque setDirected:directed];
                [plaque setDirection:direction];
                [plaque setTilted:tilted];
                [plaque setTilt:tilt];
                [plaque setWidth:width];
                [plaque setHeight:height];
                [plaque setBackgroundColor:backgroundColor];
                [plaque setForegroundColor:foregroundColor];
                [plaque setFontSize:fontSize];
                [plaque setInscription:inscription];
            }

            // If this plaque is on a list of plaques awaiting download then remove it from the list.
            //
            for (NSUUID *awaitingPlaqueToken in self.plaquesAwaitingDownload)
            {
                if ([awaitingPlaqueToken isEqual:plaqueToken] == YES) {
                    //
                    // Remove corresponding entry from awaiting download list.
                    //
                    [self.plaquesAwaitingDownload removeObject:awaitingPlaqueToken];

                    break;
                }
            }

            // Add this plaque according to type of paquet to "InSight" or "OnMap" or both.
            //
            switch (paquet.commandCode)
            {
                case PaquetDownloadPlaquesInSight:
                    if ([self plaqueInSightByToken:plaqueToken] == nil)
                        [self addPlaqueToInSight:plaque];
                    if ([self plaqueOnMapByToken:plaqueToken] == nil)
                        [self addPlaqueToOnMap:plaque];
                    break;

                case PaquetDownloadPlaquesOnMap:
                    if ([self plaqueOnMapByToken:plaqueToken] == nil)
                        [self addPlaqueToOnMap:plaque];
                    break;

                default:
                    break;
            }

            // Let profiles manager to handle profile by token. If profile is not known then it should be downloaded.
            //
            [profiles profileByToken:profileToken];
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"%@: %@", exception.name, exception.reason);
    }
    @finally
    {
        [self.paquetHandlerLock unlock];
    }
}

@end
