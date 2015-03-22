//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "CreatePlaquePanel.h"

@implementation CreatePlaquePanel

- (void)didOpenPanel
{
    [super didOpenPanel];

    CGRect bounds = self.superview.bounds;

    CGSize panelSize = CGSizeMake(200.0f, 160.0f);
    CGRect panelFrame = CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
                                   CGRectGetMaxY(bounds) - panelSize.height - 64.0f,
                                   panelSize.width,
                                   panelSize.height);
    [self setFrame:panelFrame];

    /*UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(100.0f, 300.0f, 100.0f, 50.0f)];
    [cancelButton setTitle:@"Cancel"
                  forState:UIControlStateNormal];
    [cancelButton addTarget:self
                     action:@selector(cancelButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cancelButton];*/

    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton setFrame:CGRectMake(100.0f, 100.0f, 100.0f, 50.0f)];
    [submitButton setTitle:@"Fire"
                  forState:UIControlStateNormal];
    [submitButton addTarget:self
                     action:@selector(submitButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:submitButton];

    [self addCloseButton];
}

/*- (void)cancelButtonPressed
{
    [self.controller createNewPlaqueCancelled];

    [self removeFromSuperview];
}*/

- (void)submitButtonPressed
{
    [self.controller createNewPlaqueConfirmed];

    [self removeFromSuperview];
}

@end
