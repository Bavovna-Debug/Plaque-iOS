//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "CreatePlaquePanel.h"

@implementation CreatePlaquePanel

- (void)didOpenPanel
{
    [super didOpenPanel];

    CGRect bounds = self.superview.bounds;

    CGSize panelSize = CGSizeMake(300.0f, 200.0f);

    CGRect panelFrame =
    CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
               CGRectGetMaxY(bounds) - panelSize.height - 64.0f,
               panelSize.width,
               panelSize.height);

    [self setFrame:panelFrame];

    [self setBackground:@"PanelCapturedBackground"];

    CGSize margin = CGSizeMake(20.0f, 8.0f);

    {
        UIColor *helpTextColor = [UIColor darkTextColor];
        UIFont *helpFont = [UIFont systemFontOfSize:16.0f];

        CGRect helpRect =
        CGRectMake(0.0f,
                   0.0f,
                   CGRectGetWidth(panelFrame),
                   CGRectGetHeight(panelFrame) - 40.0f);

        UILabel *help = [[UILabel alloc] initWithFrame:CGRectInset(helpRect, margin.width, margin.height)];
        [help setBackgroundColor:[UIColor clearColor]];
        [help setTextColor:helpTextColor];
        [help setLineBreakMode:NSLineBreakByWordWrapping];
        [help setNumberOfLines:0];
        [help setFont:helpFont];
        [help setText:NSLocalizedString(@"CREATE_PLAQUE_HELP_TEXT", nil)];
        [self addSubview:help];
    }

    {
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [cancelButton setFrame:CGRectMake(CGRectGetMinX(self.bounds),
                                          CGRectGetMaxY(self.bounds) - 40.0f,
                                          120.0f,
                                          40.0f)];

        [cancelButton setTitle:NSLocalizedString(@"CREATE_PLAQUE_CANCEL_BUTTON", nil)
                      forState:UIControlStateNormal];

        [cancelButton addTarget:self
                         action:@selector(cancelButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:cancelButton];
    }

    {
        UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [submitButton setFrame:CGRectMake(CGRectGetMaxX(self.bounds) - 120.0f,
                                          CGRectGetMaxY(self.bounds) - 40.0f,
                                          120.0f,
                                          40.0f)];

        [submitButton setTitle:NSLocalizedString(@"CREATE_PLAQUE_FIRE_BUTTON", nil)
                      forState:UIControlStateNormal];

        [submitButton addTarget:self
                         action:@selector(submitButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:submitButton];
    }

    [self translate:+0.2f];
}

- (void)cancelButtonPressed
{
    [self.controller createNewPlaqueCancelled];

    [self removeFromSuperview];
}

- (void)submitButtonPressed
{
    [self.controller createNewPlaqueConfirmed];

    [self removeFromSuperview];
}

@end
