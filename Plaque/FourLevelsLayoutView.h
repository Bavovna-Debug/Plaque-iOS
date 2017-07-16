//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MainController.h"

@interface FourLevelsLayoutView : UIView

@property (weak, nonatomic) MainController *controller;

- (void)switchToBackground;

- (void)switchToForeground;

- (void)flushSubviews;

@end
