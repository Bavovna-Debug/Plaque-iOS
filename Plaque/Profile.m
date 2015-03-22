//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Profile.h"
#import "Database.h"

#ifdef DEBUG
#undef VERBOSE_PROFILES_DB_SELECT
#undef VERBOSE_PROFILES_DB_INSERT
#endif

@implementation Profile
{
    Boolean storedInDatabase;
}

- (id)initWithToken:(NSUUID *)profileToken
{
    self = [super init];
    if (self == nil)
        return nil;

    SQLiteDatabase *database = [Database mainDatabase];

    NSString *query = [NSString stringWithFormat:@"SELECT rowid, profile_revision, profile_name, user_name FROM profiles WHERE profile_token = '%@'",
                       [profileToken UUIDString]];

    SQLiteDataReader *reader = [[SQLiteDataReader alloc] initWithDatabase:database
                                                                    query:query];
    if (reader == nil)
        return nil;

    if ([reader next] == FALSE)
        return nil;

    int rowId               = [reader getInt:0];
    int profileRevision     = [reader getInt:1];
    NSString *profileName   = [reader getString:2];
    NSString *userName      = [reader getString:3];

    self.rowId              = rowId;
    self.profileToken       = profileToken;
    self.profileRevision    = profileRevision;
    self.profileName        = profileName;
    self.userName           = userName;

    // Should be set to 'yes' only after all properties are set up.
    // Otherwise setter methods of properties would cause writing to database.
    //
    storedInDatabase = YES;

#ifdef VERBOSE_PROFILES_DB_SELECT
    NSLog(@"Loaded profile: %llu <%@>", self.rowId, self.profileName);
#endif

    return self;
}

- (void)save
{
    SQLiteDatabase *database = [Database mainDatabase];

    NSString *query = [NSString stringWithFormat:@"INSERT INTO profiles (profile_token, profile_revision, profile_name, user_name) VALUES ('%@', %d, '%@', '%@')",
                       [self.profileToken UUIDString],
                       self.profileRevision,
                       self.profileName,
                       self.userName];
    self.rowId = [database executeINSERT:query ignoreConstraints:YES];

    if (self.rowId != 0) {
        //
        // Should be set to 'yes' only if record been successfully saved in local database.
        // Otherwise setter methods of properties would cause writing to database.
        //
        storedInDatabase = YES;
    }

#ifdef VERBOSE_PROFILES_DB_INSERT
    NSLog(@"Saved profile: %llu %@", self.rowId, self.profileName);
#endif
}

@end
