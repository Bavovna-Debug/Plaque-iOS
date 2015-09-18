//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Paquet.h"

@protocol ConnectionDelegate;

@interface Communicator : NSObject

@property (strong, nonatomic, readwrite) id<ConnectionDelegate> connectionDelegate;

+ (Communicator *)sharedCommunicator;

- (void)switchToBackground;

- (void)switchToForeground;

- (void)send:(Paquet *)paquet;

@end

@protocol ConnectionDelegate <NSObject>

@required

- (void)communicatorDidEstablishDialogue;

@end
