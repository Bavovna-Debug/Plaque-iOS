//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Paquet.h"

@interface Communicator : NSObject

+ (Communicator *)sharedCommunicator;

- (void)switchToBackground;

- (void)switchToForeground;

- (void)send:(Paquet *)paquet;

@end
