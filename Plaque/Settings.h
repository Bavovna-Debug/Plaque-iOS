//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

@property (assign, nonatomic, readwrite) Boolean    tapMenuOnlyIcons;
@property (assign, atomic,    readonly)  NSUInteger lastOwnObjectId;

/*
@property (assign, nonatomic) UInt32        radarOnRadarRevision;
@property (assign, nonatomic) UInt32        radarInSightRevision;
@property (assign, nonatomic) UInt32        radarOnMapRevision;
*/

+ (Settings *)defaultSettings;

@end
