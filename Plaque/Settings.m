//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Settings.h"

#define TapMenuOnlyIconsKey         @"TapMenuOnlyIcons"
#define LastOwnObjectIdKey          @"LastOwnObjectId"
#define RadarInSightRevisionKey     @"RadarInSightRevision"

@implementation Settings
{
    NSUserDefaults *defaults;
}

+ (Settings *)defaultSettings
{
    static dispatch_once_t onceToken;
    static Settings *settings;

    dispatch_once(&onceToken, ^{
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

- (NSUInteger)radarInSightRevision
{
    NSUInteger radarInSightRevision = [defaults integerForKey:RadarInSightRevisionKey];
    return radarInSightRevision;
}

- (void)setRadarInSightRevision:(NSUInteger)radarInSightRevision
{
    [defaults setInteger:radarInSightRevision
                  forKey:RadarInSightRevisionKey];
}

@end
