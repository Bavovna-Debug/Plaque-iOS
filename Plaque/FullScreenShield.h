//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FullScreenSchieldDelegate;

@interface FullScreenShield : UIView

@property (strong, nonatomic, readwrite) id<FullScreenSchieldDelegate> delegate;

- (id)initWithCloseOnTouch:(Boolean)closeOnTouch;

- (void)remove;

@end

@protocol FullScreenSchieldDelegate <NSObject>

@optional

- (void)shieldWillDisappear;

@end
