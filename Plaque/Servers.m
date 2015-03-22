//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Servers.h"

@implementation Servers

+ (Servers *)sharedServers
{
    static dispatch_once_t onceToken;
    static Servers *servers;

    dispatch_once(&onceToken, ^{
        servers = [[Servers alloc] init];
    });

    return servers;
}

- (NSString *)serverAddress
{
    return @"144.76.27.237";
}

- (UInt32)serverPort
{
    return 12004;
}

- (void)nextServer
{
}

@end
