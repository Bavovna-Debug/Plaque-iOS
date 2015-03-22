//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Panel : UIView

- (void)didOpenPanel;

- (void)didClosePanel;

- (void)translate:(CGFloat)direction;

- (void)addCloseButton;

@end
