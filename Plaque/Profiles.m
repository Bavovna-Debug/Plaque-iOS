//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Paquet.h"
#import "Profile.h"
#import "Profiles.h"
#import "SQLite.h"

#include "API.h"

#ifdef DEBUG
#undef VERBOSE
#endif

@interface Profiles () <PaquetSenderDelegate>

@property (strong, nonatomic) NSMutableArray *profilesCache;

@end

@implementation Profiles

+ (Profiles *)sharedProfiles
{
    static dispatch_once_t onceToken;
    static Profiles *profiles;

    dispatch_once(&onceToken, ^
    {
        profiles = [[Profiles alloc] init];
    });

    return profiles;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.profilesCache = [NSMutableArray array];

    return self;
}

- (Profile *)profileByToken:(NSUUID *)profileToken
{
    Profile *profile;

    // First look if this profile is already in cache.
    //
    profile = [self lookForProfileInCache:profileToken];

    // If it is not cache then search for it in local database.
    //
    if (profile == nil)
    {
        profile = [[Profile alloc] initWithToken:profileToken];

        // If it does not exist in local database ...
        //
        if (profile == nil)
        {
            // ... then require a download.
            //
            [self requestProfileDownload:profileToken];
        }
        else
        {
            // ... otherwise put it in cache.
            //
            [self.profilesCache addObject:profile];
        }
    }

    return profile;
}

- (Profile *)lookForProfileInCache:(NSUUID *)profileToken
{
    for (Profile *profile in self.profilesCache)
    {
        if ([profile.profileToken isEqual:profileToken] == YES)
        {
            return profile;
        }
    }

    return nil;
}

- (void)requestProfileDownload:(NSUUID *)profileToken
{
    Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetDownloadProfiles];

    [paquet setSenderDelegate:self];

    [paquet putUInt32:1];
    [paquet putToken:profileToken];

    [paquet send];
}

#pragma mark - Paquet delegate

- (void)paquetComplete:(Paquet *)paquet
{
    NSUUID *profileToken = [paquet getToken];
    UInt32 profileRevision = [paquet getUInt32];
    NSString *profileName = [paquet getString];
    NSString *userName = [paquet getString];

#ifdef VERBOSE
    NSLog(@"[Profiles] Received profile %@ revision %d '%@' '%@'",
          profileToken,
          profileRevision,
          profileName,
          userName);
#endif

    Profile *profile = [[Profile alloc] init];
    [profile setProfileToken:profileToken];
    [profile setProfileRevision:profileRevision];
    [profile setProfileName:profileName];
    [profile setUserName:userName];
    [profile save];
}

@end
