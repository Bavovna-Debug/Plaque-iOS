//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

@property (assign, nonatomic) Boolean tapMenuOnlyIcons;
@property (assign, nonatomic) NSUInteger lastOwnObjectId;
@property (assign, nonatomic) NSUInteger radarInSightRevision;

+ (Settings *)defaultSettings;

@end
