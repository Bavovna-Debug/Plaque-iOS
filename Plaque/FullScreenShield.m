//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "FullScreenShield.h"

#include "Definitions.h"

@implementation FullScreenShield
{
    NSTimer *disappearTimer;
}

- (id)initWithCloseOnTouch:(Boolean)closeOnTouch
{
    self = [super init];
    if (self == nil)
        return nil;

    if (closeOnTouch == NO)
    {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    else
    {
        [self setBackgroundColor:[UIColor colorWithWhite:0.1f
                                                   alpha:0.5f]];

        UITapGestureRecognizer *tapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tapped:)];

        [self addGestureRecognizer:tapRecognizer];
    }

    return self;
}

- (void)tapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self remove];
    }
}

- (void)remove
{
    id<FullScreenSchieldDelegate> delegate = self.delegate;
    if ((delegate != nil) && [delegate respondsToSelector:@selector(shieldWillDisappear)])
    {
        [delegate shieldWillDisappear];
    }

    [UIView beginAnimations:nil
                    context:nil];
    
    [UIView setAnimationDuration:DisappearDuration];

    for (UIView *subview in self.subviews)
    {
        [subview setAlpha:0.0f];
    }

    [UIView commitAnimations];

    disappearTimer =
    [NSTimer scheduledTimerWithTimeInterval:DisappearDuration
                                     target:self
                                   selector:@selector(removeFromSuperview)
                                   userInfo:nil
                                    repeats:NO];
}

@end
