//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

@property (assign, nonatomic) Boolean       tapMenuOnlyIcons;
@property (assign, nonatomic) NSUInteger    lastOwnObjectId;
/*
@property (assign, nonatomic) UInt32        radarOnRadarRevision;
@property (assign, nonatomic) UInt32        radarInSightRevision;
@property (assign, nonatomic) UInt32        radarOnMapRevision;
*/

+ (Settings *)defaultSettings;

@end
