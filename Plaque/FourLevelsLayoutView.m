//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "FourLevelsLayoutView.h"

@interface FourLevelsLayoutView ()

@end

@implementation FourLevelsLayoutView

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    return self;
}

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    [self touched];

    UIView* view = [super hitTest:point withEvent:event];

    return (view == self) ? nil : view;
}

- (void)touched { }

- (void)switchToBackground { }

- (void)switchToForeground { }

- (void)flushSubviews
{
    while ([self.subviews count] > 0)
    {
        UIView *subview = [self.subviews lastObject];
        [subview removeFromSuperview];
    }
}

@end
