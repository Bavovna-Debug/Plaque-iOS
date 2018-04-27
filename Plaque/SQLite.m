//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <sqlite3.h>

#import "SQLite.h"

@interface SQLiteDatabase ()

@property (assign, nonatomic) sqlite3   *databaseHandler;
@property (strong, nonatomic) NSString  *databaseName;
@property (strong, nonatomic) NSLock    *lock;

@end

@implementation SQLiteDatabase

+ (void)removeDatabase:(NSString *)databaseName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:databasePath error:&error];
    if (error != nil)
    {
        NSLog(@"[SQLite] Cannot remove database: %@",
              [error localizedDescription]);
    }
}

- (id)initWithDatabaseName:(NSString *)databaseName
              templateName:(NSString *)templateName
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.databaseName = databaseName;

    self.lock = [[NSLock alloc] init];

    if (templateName != nil)
    {
        if ([self databaseExists] == NO)
        {
            if ([self createDatabase:templateName] == FALSE)
            {
                return nil;
            }
        }
    }

    if ([self openDatabase] == FALSE)
    {
        return nil;
    }

    return self;
}

- (NSString *)databaseFullPath
{
    // Get the documents directory path.
    //
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *documentsDirectory = [paths objectAtIndex:0];

    // Set the database file path.
    //
    NSString *databasePath =
    [documentsDirectory stringByAppendingPathComponent:[self databaseName]];

    return databasePath;
}

- (Boolean)databaseExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self databaseFullPath]];
}

- (Boolean)createDatabase:(NSString *)templateName
{
    NSString *templateFileName =
    [NSString stringWithFormat:@"%@.db", templateName];

    NSString *templateFilePath =
    [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:templateFileName];

    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:templateFilePath
                                            toPath:[self databaseFullPath]
                                             error:&error];
    if (error != nil)
    {
        NSLog(@"[SQLite] %@",
              [error localizedDescription]);

        return FALSE;
    }
    else
    {
        NSLog(@"[SQLite] Database created from %@",
              templateFilePath);

        return TRUE;
    }
}

- (Boolean)openDatabase
{
    NSLog(@"[SQLite] Open database: %@",
          [self databaseFullPath]);

    sqlite3 *databaseHandler;

    SQLITE_API int openDatabaseResult =
    sqlite3_open([[self databaseFullPath] UTF8String], &databaseHandler);

    if (openDatabaseResult != SQLITE_OK)
    {
        NSLog(@"[SQLite] Cannot open database");

        return FALSE;
    }
    else
    {
        self.databaseHandler = databaseHandler;

        return TRUE;
    }
}

- (void)setForeignKeys:(Boolean)support
{
    if (support == NO)
    {
        [self executeSQL:@"[SQLite] PRAGMA foreign_keys = OFF"
       ignoreConstraints:YES];
    }
    else
    {
        [self executeSQL:@"[SQLite] PRAGMA foreign_keys = ON"
       ignoreConstraints:YES];
    }
}

- (Boolean)executeSQL:(NSString *)query
    ignoreConstraints:(Boolean)ignoreConstraints
{
    sqlite3_stmt *statement;

    [self.lock lock];

    int prepareStatementResult =
    sqlite3_prepare_v2(self.databaseHandler,
                       [query UTF8String],
                       -1,
                       &statement,
                       NULL);

    if (prepareStatementResult != SQLITE_OK)
    {
        [self.lock unlock];

        NSLog(@"[SQLite] Prepare query error %d: %s (%@)",
              prepareStatementResult,
              sqlite3_errmsg(self.databaseHandler),
              query);

        return 0;
    }

    int executeQueryResults = sqlite3_step(statement);

    [self.lock unlock];

    switch (executeQueryResults)
    {
        case SQLITE_DONE:
            return TRUE;

        case SQLITE_CONSTRAINT:
            return (ignoreConstraints == YES);

        default:
            NSLog(@"[SQLite] Error %d: %s (%@)",
                  executeQueryResults,
                  sqlite3_errmsg(self.databaseHandler),
                  query);
            return FALSE;
    }
}

- (UInt64)executeINSERT:(NSString *)query
      ignoreConstraints:(Boolean)ignoreConstraints
{
    sqlite3_stmt *statement;

    [self.lock lock];

    int prepareStatementResult =
    sqlite3_prepare_v2(self.databaseHandler,
                       [query UTF8String],
                       -1,
                       &statement,
                       NULL);

    if (prepareStatementResult != SQLITE_OK)
    {
        [self.lock unlock];
        NSLog(@"[SQLite] Prepare query error %d: %s (%@)",
              prepareStatementResult,
              sqlite3_errmsg(self.databaseHandler),
              query);

        return 0;
    }

    int executeQueryResults = sqlite3_step(statement);

    sqlite3_int64 rowId = sqlite3_last_insert_rowid(self.databaseHandler);

    [self.lock unlock];

    switch (executeQueryResults)
    {
        case SQLITE_DONE:
            return rowId;

        case SQLITE_CONSTRAINT:
            return rowId;

        default:
            NSLog(@"[SQLite] Error %d: %s (%@)",
                  executeQueryResults,
                  sqlite3_errmsg(self.databaseHandler),
                  query);
            return 0;
    }
}

- (UInt32)executeUPDATE:(NSString *)query
      ignoreConstraints:(Boolean)ignoreConstraints
{
    sqlite3_stmt *statement;

    [self.lock lock];

    int prepareStatementResult =
    sqlite3_prepare_v2(self.databaseHandler,
                       [query UTF8String],
                       -1,
                       &statement,
                       NULL);

    if (prepareStatementResult != SQLITE_OK)
    {
        [self.lock unlock];
        NSLog(@"[SQLite] Prepare query error %d: %s (%@)",
              prepareStatementResult,
              sqlite3_errmsg(self.databaseHandler),
              query);

        return 0;
    }

    int executeQueryResults = sqlite3_step(statement);

    int affectedRows = sqlite3_changes(self.databaseHandler);

    [self.lock unlock];

    switch (executeQueryResults)
    {
        case SQLITE_DONE:
            return affectedRows;

        case SQLITE_CONSTRAINT:
            return affectedRows;

        default:
            NSLog(@"[SQLite] Error %d: %s (%@)",
                  executeQueryResults,
                  sqlite3_errmsg(self.databaseHandler),
                  query);
            return 0;
    }
}

@end

@interface SQLiteDataReader ()

@property (assign, nonatomic) sqlite3_stmt *statement;

@end

@implementation SQLiteDataReader

- (id)initWithDatabase:(SQLiteDatabase *)database
                 query:(NSString *)query
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    sqlite3_stmt *statement;

    int prepareStatementResult =
    sqlite3_prepare_v2(database.databaseHandler,
                       [query UTF8String],
                       -1,
                       &statement,
                       NULL);

    if (prepareStatementResult != SQLITE_OK)
    {
        NSLog(@"[SQLite] Prepare query error %d: %s (%@)",
              prepareStatementResult,
              sqlite3_errmsg(database.databaseHandler),
              query);
        return nil;
    }

    self.statement = statement;

    return self;
}

- (int)numberOfColumns
{
    return sqlite3_column_count(self.statement);
}

- (Boolean)next
{
    return (sqlite3_step(self.statement) == SQLITE_ROW);
}

- (Boolean)isNull:(int)columnNumber
{
    return sqlite3_column_type(self.statement, columnNumber) == SQLITE_NULL;
}

- (Boolean)isInteger:(int)columnNumber
{
    return sqlite3_column_type(self.statement, columnNumber) == SQLITE_INTEGER;
}

- (Boolean)isFloat:(int)columnNumber
{
    return sqlite3_column_type(self.statement, columnNumber) == SQLITE_FLOAT;
}

- (Boolean)isText:(int)columnNumber
{
    return sqlite3_column_type(self.statement, columnNumber) == SQLITE_TEXT;
}

- (Boolean)isBLOB:(int)columnNumber
{
    return sqlite3_column_type(self.statement, columnNumber) == SQLITE_BLOB;
}

- (bool)getBoolean:(int)columnNumber
{
    return ([self getInt:columnNumber] == 0) ? FALSE : TRUE;
}

- (int)getInt:(int)columnNumber
{
    return sqlite3_column_int(self.statement, columnNumber);
}

- (double)getDouble:(int)columnNumber
{
    return sqlite3_column_double(self.statement, columnNumber);
}

- (NSString *)getString:(int)columnNumber
{
    char *chars = (char *) sqlite3_column_text(self.statement, columnNumber);

    if (chars == NULL)
    {
        return nil;
    }
    else
    {
        return [NSString stringWithUTF8String:chars];
    }
}

@end
