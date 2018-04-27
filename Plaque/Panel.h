//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Panel : UIView

- (void)setBackground:(NSString *)backgroundImageName;

- (void)removeSubviews;

- (void)didOpenPanel;

- (void)didClosePanel;

- (void)translate:(CGFloat)direction;

- (void)addCloseButton;

@end
