//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FlyMenuItem.h"

@interface FlyMenu : UIView

@property (assign, nonatomic, readonly) Boolean menuOpenned;

- (void)clearMenu;

- (void)addMenuItem:(FlyMenuItem *)item;

- (void)openMenu;

- (void)closeMenu;

@end
