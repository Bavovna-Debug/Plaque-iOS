//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TapMenuItem.h"

@protocol TapMenuDelegate;

@interface TapMenu : UIView

@property (strong, nonatomic, readwrite) id<TapMenuDelegate> delegate;

@property (assign, nonatomic, readonly) Boolean menuOpenned;

+ (TapMenu *)mainTapMenu;

- (void)clearMenu;

- (void)addItemWithIconName:(NSString *)iconName
                    command:(TapMenuCommand)command;

- (void)addItemWithIconName:(NSString *)iconName
                    command:(TapMenuCommand)command
                  rowNumber:(NSUInteger)rowNumber;

- (void)openMenu;

- (void)closeMenu;

@end

@protocol TapMenuDelegate <NSObject>

@required

- (void)mainButtonPressed;

- (void)exitButtonPressed;

- (void)tapMenuItemPressed:(TapMenuCommand)command;

@end
