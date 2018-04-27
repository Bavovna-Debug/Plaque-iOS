//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TapMenuItem.h"

@protocol TapMenuDelegate;

@interface TapMenu : UIView

@property (strong, nonatomic, readwrite) id<TapMenuDelegate> delegate;

@property (assign, nonatomic, readonly) Boolean menuOpened;

+ (TapMenu *)mainTapMenu;

- (void)clearMenu;

- (void)addItemWithIconName:(NSString *)iconName
                      title:(NSString *)title
                    command:(TapMenuCommand)command;

- (void)openMenu;

- (void)closeMenu;

@end

@protocol TapMenuDelegate <NSObject>

@required

/*
- (void)mainButtonPressed;

- (void)exitButtonPressed;
*/

- (void)tapMenuItemPressed:(TapMenuCommand)command;

@end
