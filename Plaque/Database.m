//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Database.h"

@implementation Database

+ (SQLiteDatabase *)mainDatabase
{
    static dispatch_once_t onceToken;
    static SQLiteDatabase *database;

    dispatch_once(&onceToken, ^{
        database = [[SQLiteDatabase alloc] initWithDatabaseName:@"plaque"
                                      createDatabaseIfNotExists:YES];
        [database executeSQL:@"ALTER TABLE plaques ADD COLUMN dimension INTEGER NOT NULL DEFAULT 2"
           ignoreConstraints:YES];
        [database executeSQL:@"ALTER TABLE plaques ADD COLUMN font_size REAL NOT NULL DEFAULT 0.25"
           ignoreConstraints:YES];
    });

    return database;
}

@end
