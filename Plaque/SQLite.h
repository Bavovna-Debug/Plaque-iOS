//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLiteDatabase : NSObject

+ (void)removeDatabase:(NSString *)databaseName;

- (id)initWithDatabaseName:(NSString *)databaseName
 createDatabaseIfNotExists:(Boolean)createDatabaseIfNotExists;

- (Boolean)executeSQL:(NSString *)query
    ignoreConstraints:(Boolean)ignoreConstraints;

- (UInt64)executeINSERT:(NSString *)query
      ignoreConstraints:(Boolean)ignoreConstraints;

- (UInt32)executeUPDATE:(NSString *)query
      ignoreConstraints:(Boolean)ignoreConstraints;

@end

@interface SQLiteDataReader : NSObject

- (id)initWithDatabase:(SQLiteDatabase *)database
                 query:(NSString *)query;

- (Boolean)next;

- (Boolean)isNull:(int)columnNumber;

- (Boolean)isInteger:(int)columnNumber;

- (Boolean)isFloat:(int)columnNumber;

- (Boolean)isText:(int)columnNumber;

- (Boolean)isBLOB:(int)columnNumber;

- (bool)getBoolean:(int)columnNumber;

- (int)getInt:(int)columnNumber;

- (double)getDouble:(int)columnNumber;

- (NSString *)getString:(int)columnNumber;

@end