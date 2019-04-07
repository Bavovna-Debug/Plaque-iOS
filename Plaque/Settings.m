//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Settings.h"

#include "Definitions.h"

@interface Settings ()

@property (assign, atomic, readwrite) NSUInteger lastOwnObjectId;

@end

@implementation Settings
{
    NSUserDefaults *defaults;
}

+ (Settings *)sharedSettings
{
    static dispatch_once_t onceToken;
    static Settings *settings;

    dispatch_once(&onceToken, ^
    {
        settings = [[Settings alloc] init];
    });

    return settings;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    defaults = [NSUserDefaults standardUserDefaults];

    return self;
}

- (NSUInteger)lastApplicationVersion
{
    NSUInteger lastApplicationVersion = [defaults integerForKey:LastApplicationVersionKey];

    return lastApplicationVersion;
}

- (void)setLastApplicationVersion:(NSUInteger)lastApplicationVersion
{
    [defaults setInteger:lastApplicationVersion
                  forKey:LastApplicationVersionKey];
}

- (NSUInteger)lastDatabaseVersion
{
    NSUInteger lastDatabaseVersion = [defaults integerForKey:LastDatabaseVersionKey];

    return lastDatabaseVersion;
}

- (void)setLastDatabaseVersion:(NSUInteger)lastDatabaseVersion
{
    [defaults setInteger:lastDatabaseVersion
                  forKey:LastDatabaseVersionKey];
}

- (Boolean)tapMenuOnlyIcons
{
    Boolean tapMenuOnlyIcons = [defaults boolForKey:TapMenuOnlyIconsKey];

    return tapMenuOnlyIcons;
}

- (void)setTapMenuOnlyIcons:(Boolean)tapMenuOnlyIcons
{
    [defaults setBool:tapMenuOnlyIcons
               forKey:TapMenuOnlyIconsKey];
}

- (NSUInteger)lastOwnObjectId
{
    NSUInteger lastOwnObjectId = [defaults integerForKey:LastOwnObjectIdKey];

    lastOwnObjectId++;

    [defaults setInteger:lastOwnObjectId
                  forKey:LastOwnObjectIdKey];

    return lastOwnObjectId;
}

- (void)setLastOwnObjectId:(NSUInteger)lastOwnObjectId
{
}

- (Boolean)confirmedUsageOfGPS
{
    Boolean confirmedUsageOfGPS = [defaults boolForKey:ConfirmedUsageOfGPSKey];

    return confirmedUsageOfGPS;
}

- (void)setConfirmedUsageOfGPS:(Boolean)confirmedUsageOfGPS
{
    [defaults setBool:confirmedUsageOfGPS
               forKey:ConfirmedUsageOfGPSKey];
}

- (Boolean)confirmedUsageOfCamera
{
    Boolean confirmedUsageOfCamera = [defaults boolForKey:ConfirmedUsageOfCameraKey];

    return confirmedUsageOfCamera;
}

- (void)setConfirmedUsageOfCamera:(Boolean)confirmedUsageOfCamera
{
    [defaults setBool:confirmedUsageOfCamera
               forKey:ConfirmedUsageOfCameraKey];
}

/*
- (UInt32)radarOnRadarRevision
{
    UInt32 radarOnRadarRevision = (UInt32) [defaults integerForKey:OnRadarRevisionKey];

    return radarOnRadarRevision;
}

- (void)setRadarOnRadarRevision:(UInt32)radarOnRadarRevision
{
    [defaults setInteger:radarOnRadarRevision
                  forKey:OnRadarRevisionKey];
}

- (UInt32)radarInSightRevision
{
    UInt32 radarInSightRevision = (UInt32) [defaults integerForKey:InSightRevisionKey];

    return radarInSightRevision;
}

- (void)setRadarInSightRevision:(UInt32)radarInSightRevision
{
    [defaults setInteger:radarInSightRevision
                  forKey:InSightRevisionKey];
}

- (UInt32)radarOnMapRevision
{
    UInt32 radarOnMapRevision = (UInt32) [defaults integerForKey:OnMapRevisionKey];
 
    return radarOnMapRevision;
}

- (void)setRadarOnMapRevision:(UInt32)radarOnMapRevision
{
    [defaults setInteger:radarOnMapRevision
                  forKey:OnMapRevisionKey];
}
*/

@end
