//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Database.h"

#ifdef DEBUG
#define DATABASE_NAME   @"plaque3"
#define TEMPLATE_NAME   @"plaque"
#else
#define DATABASE_NAME   @"plaque"
#define TEMPLATE_NAME   @"plaque"
#endif

@implementation Database

+ (SQLiteDatabase *)mainDatabase
{
    static dispatch_once_t onceToken;
    static SQLiteDatabase *database;

    dispatch_once(&onceToken, ^
    {
        database = [[SQLiteDatabase alloc] initWithDatabaseName:DATABASE_NAME
                                                   templateName:TEMPLATE_NAME];
        
        //[database executeSQL:@"DELETE FROM plaques" ignoreConstraints:YES];

        //[database executeSQL:@"ALTER TABLE plaques ADD COLUMN dimension INTEGER NOT NULL DEFAULT 2" ignoreConstraints:YES];
    });

    return database;
}

@end
