//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Servers : NSObject

+ (Servers *)sharedServers;

- (NSString *)serverAddress;

- (UInt32)serverPort;

- (void)nextServer;

@end
