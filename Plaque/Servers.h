//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Servers : NSObject

+ (Servers *)sharedServers;

- (id)init;

- (NSString *)serverAddress;

- (UInt32)serverPort;

- (void)nextServer;

@end
