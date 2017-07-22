//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "Servers.h"

#include "API.h"

@implementation Servers
{
    unsigned int currentServerNumber;
}

+ (Servers *)sharedServers
{
    static dispatch_once_t onceToken;
    static Servers *servers;

    dispatch_once(&onceToken, ^
    {
        servers = [[Servers alloc] init];
    });

    return servers;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    currentServerNumber = 0;

    return self;
}

- (NSString *)serverAddress
{
    if ((currentServerNumber % 2) == 0)
    {
        return @"144.76.27.237";
    }
    else
    {
        return @"2a01:4f8:191:13ec::2";
    }
}

- (UInt32)serverPort
{
    if ((currentServerNumber % 2) == 0)
    {
        return TCP_PortNumberIPv4;
    }
    else
    {
        return TCP_PortNumberIPv6;
    }
}

- (void)nextServer
{
    currentServerNumber++;
}

@end
