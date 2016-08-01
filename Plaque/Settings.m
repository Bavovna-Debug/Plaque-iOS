//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Settings.h"

#ifdef DEBUG
#define TapMenuOnlyIconsKey         @"TapMenuOnlyIcons"
#define LastOwnObjectIdKey          @"LastOwnObjectId"
/*
#define OnRadarRevisionKey          @"OnRadarRevision2"
#define InSightRevisionKey          @"InSightRevision2"
#define OnMapRevisionKey            @"OnMapRevision2"
*/
#else
#define TapMenuOnlyIconsKey         @"TapMenuOnlyIcons"
#define LastOwnObjectIdKey          @"LastOwnObjectId"
/*
#define OnRadarRevisionKey          @"OnRadarRevision"
#define InSightRevisionKey          @"InSightRevision"
#define OnMapRevisionKey            @"OnMapRevision"
*/
#endif

@implementation Settings
{
    NSUserDefaults *defaults;
}

+ (Settings *)defaultSettings
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
        return nil;

    defaults = [NSUserDefaults standardUserDefaults];

    return self;
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
    Boolean lastOwnObjectId = [defaults integerForKey:LastOwnObjectIdKey];

    lastOwnObjectId++;

    [defaults setInteger:lastOwnObjectId
                  forKey:LastOwnObjectIdKey];

    return lastOwnObjectId;
}

/*
- (UInt32)radarOnRadarRevision
{
    UInt32 radarOnRadarRevision = (UInt32)[defaults integerForKey:OnRadarRevisionKey];
    return radarOnRadarRevision;
}

- (void)setRadarOnRadarRevision:(UInt32)radarOnRadarRevision
{
    [defaults setInteger:radarOnRadarRevision
                  forKey:OnRadarRevisionKey];
}

- (UInt32)radarInSightRevision
{
    UInt32 radarInSightRevision = (UInt32)[defaults integerForKey:InSightRevisionKey];
    return radarInSightRevision;
}

- (void)setRadarInSightRevision:(UInt32)radarInSightRevision
{
    [defaults setInteger:radarInSightRevision
                  forKey:InSightRevisionKey];
}

- (UInt32)radarOnMapRevision
{
    UInt32 radarOnMapRevision = (UInt32)[defaults integerForKey:OnMapRevisionKey];
    return radarOnMapRevision;
}

- (void)setRadarOnMapRevision:(UInt32)radarOnMapRevision
{
    [defaults setInteger:radarOnMapRevision
                  forKey:OnMapRevisionKey];
}
*/

@end
