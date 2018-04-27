//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SQLite.h"

@interface Database : NSObject

+ (SQLiteDatabase *)mainDatabase;

+ (void)upgradeDatabase;

@end
