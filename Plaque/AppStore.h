//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppStore : NSObject

@property (nonatomic, strong, readwrite) id delegate;

+ (AppStore *)sharedAppStore;

/*
- (void)purchaseUnlock;

- (void)restorePurchasedUnlock;
*/

@end

@protocol AppStoreDelegate <NSObject>

@required

- (void)gameWasUnlocked;

@end
