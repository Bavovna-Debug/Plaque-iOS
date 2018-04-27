//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "ControlPanel.h"
#import "FullScreenShield.h"

#include "Definitions.h"

@interface ControlPanel ()

@property (weak, nonatomic) FullScreenShield *shield;

@end

@implementation ControlPanel

+ (ControlPanel *)sharedControlPanel
{
    static dispatch_once_t  onceToken;
    static ControlPanel     *controlPanel;

    dispatch_once(&onceToken, ^
    {
        controlPanel = [[ControlPanel alloc] init];
    });

    return controlPanel;
}

- (void)open
{
    ApplicationDelegate *application = (ApplicationDelegate *)[[UIApplication sharedApplication] delegate];
    FullScreenShield *shield = [application fullScreenSchield:nil
                                                 closeOnTouch:YES];

    CGRect mainViewFrame = CGRectMake(CGRectGetMidX(shield.bounds) - 160.0f,
                                      CGRectGetMaxY(shield.bounds),
                                      320.0f,
                                      0.0f);

    UIView *mainView = [[UIView alloc] initWithFrame:mainViewFrame];

    [mainView setBackgroundColor:[UIColor grayColor]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [mainView.layer setBorderWidth:1.0f];
        [mainView.layer setBorderColor:[[UIColor colorWithWhite:0.5f alpha:0.5f] CGColor]];
        [mainView.layer setCornerRadius:4.0f];
    }

    UIView *surroundingSelector = [self surroundingSelector:mainView];
    mainViewFrame.size.height += CGRectGetHeight(surroundingSelector.bounds);
    [mainView addSubview:surroundingSelector];

    [mainView setFrame:mainViewFrame];

    [shield addSubview:mainView];

    [UIView beginAnimations:nil
                    context:nil];

    [UIView setAnimationDuration:ControlPanelOpenDuration];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [mainView setFrame:CGRectOffset(mainViewFrame, 0.0f, -CGRectGetHeight(mainViewFrame) - 10.0f)];
    }
    else
    {
        [mainView setFrame:CGRectOffset(mainViewFrame, 0.0f, -CGRectGetHeight(mainViewFrame))];
    }

    [UIView commitAnimations];

    self.shield = shield;
}

- (void)close
{
    FullScreenShield *shield = self.shield;

    if (shield != nil)
    {
        [shield remove];
    }
}

- (UIView *)surroundingSelector:(UIView *)mainView
{
    CGRect frame = CGRectMake(CGRectGetMinX(mainView.bounds),
                              CGRectGetMaxY(mainView.bounds),
                              CGRectGetWidth(mainView.bounds),
                              80.0f);

    UIView *surroundingSelectorView = [[UIView alloc] initWithFrame:frame];

    UIImage *inSightImage = [UIImage imageNamed:@"ViewModeInSight"];
    UIImage *onMapImage = [UIImage imageNamed:@"ViewModeOnMap"];

    UIButton *inSightButton = [self buttonWithIcon:inSightImage];
    [surroundingSelectorView addSubview:inSightButton];

    UIButton *onMapButton = [self buttonWithIcon:onMapImage];
    [surroundingSelectorView addSubview:onMapButton];

    //UIButton *manualNavigationButtonButton = [self buttonWithIcon:onMapImage];
    //[surroundingSelectorView addSubview:manualNavigationButtonButton];

    [inSightButton setCenter:CGPointMake(round(CGRectGetWidth(frame) / 4),
                                         CGRectGetMidY(frame))];

    [onMapButton setCenter:CGPointMake(round(CGRectGetWidth(frame) / 4 * 2),
                                       CGRectGetMidY(frame))];

    /*[manualNavigationButtonButton setCenter:CGPointMake(round(CGRectGetWidth(frame) / 4 * 3),
                                                        CGRectGetMidY(frame))];*/

    [inSightButton addTarget:self
                      action:@selector(inSightButtonPressed:)
            forControlEvents:UIControlEventTouchUpInside];

    [onMapButton addTarget:self
                    action:@selector(onMapButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];

    /*[manualNavigationButtonButton addTarget:self
                                     action:@selector(manualNavigationButtonButtonPressed:)
                           forControlEvents:UIControlEventTouchUpInside];*/

    return surroundingSelectorView;
}

- (UIButton *)buttonWithIcon:(UIImage *)buttonIcon
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    [button setImage:buttonIcon
            forState:UIControlStateNormal];

    [button setBounds:(CGRect){ CGPointZero, buttonIcon.size }];

    [button.layer setBackgroundColor:[[UIColor lightGrayColor] CGColor]];
    [button.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    [button.layer setBorderWidth:2.0f];
    [button.layer setCornerRadius:buttonIcon.size.width / 2];

    /*
     [button.layer setShadowColor:[[UIColor lightGrayColor] CGColor]];
     [button.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
     [button.layer setShadowOpacity:1.0f];
     */

    return button;
}

- (void)inSightButtonPressed:(id)sender
{
    [self.controller switchToInSight];

    [self close];
}

- (void)onMapButtonPressed:(id)sender
{
    [self.controller switchToOnMap];

    [self close];
}

- (void)manualNavigationButtonButtonPressed:(id)sender
{
    [self.controller switchToManualNavigation];

    [self close];
}

@end
