//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Database.h"

#include "Definitions.h"

@implementation Database

+ (SQLiteDatabase *)mainDatabase
{
    static dispatch_once_t  onceToken;
    static SQLiteDatabase   *database;

    dispatch_once(&onceToken, ^
    {
        database = [[SQLiteDatabase alloc] initWithDatabaseName:DatabaseName
                                                   templateName:TemplateName];
        
        //[database executeSQL:@"DELETE FROM plaques" ignoreConstraints:YES];

        //[database executeSQL:@"ALTER TABLE plaques ADD COLUMN dimension INTEGER NOT NULL DEFAULT 2" ignoreConstraints:YES];
    });

    return database;
}

+ (void)upgradeDatabase
{
#if 0
    SQLiteDatabase *database = [Database mainDatabase];

    [database executeSQL:@"ALTER TABLE plaques ADD COLUMN fortified INTEGER NOT NULL DEFAULT 0"
       ignoreConstraints:YES];
#endif
}

@end
