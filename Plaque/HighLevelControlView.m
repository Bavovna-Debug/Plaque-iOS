//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "HighLevelControlView.h"
#import "SurroundingSelector.h"
#import "TapMenu.h"

#include "Definitions.h"

#undef WithSurroundingSelector

@interface HighLevelControlView () <TapMenuDelegate>

#ifdef WithSurroundingSelector
@property (strong, nonatomic) SurroundingSelector *surroundingSelector;
#endif

@property (strong, nonatomic) TapMenu *tapMenu;

@end

@implementation HighLevelControlView

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    self.tapMenu = [TapMenu mainTapMenu];
    [self.tapMenu setDelegate:self];

    [self addSubview:self.tapMenu];

#ifdef WithSurroundingSelector

    self.surroundingSelector = [SurroundingSelector panel];
    [self.surroundingSelector setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.surroundingSelector setHidden:YES];
    [self addSubview:self.surroundingSelector];

#endif

#ifdef WithSurroundingSelector

    NSDictionary *viewsDictionary = @{@"tapMenu":self.tapMenu,
                                      @"surroundingSelector":self.surroundingSelector};

#else

    NSDictionary *viewsDictionary = @{@"tapMenu":self.tapMenu};

#endif

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[tapMenu]"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:[tapMenu]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

#ifdef WithSurroundingSelector

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:[surroundingSelector(140)]-0-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:[surroundingSelector(64)]-0-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

#endif

    [self openViewModePanel];

    [self switchTapMenuToMain];
}

#pragma mark - Tap menu

- (void)switchTapMenuToMain
{
    [self.tapMenu clearMenu];

    [self.tapMenu addItemWithIconName:@"TapMenuViewModeOnMap"
                                title:NSLocalizedString(@"TAP_MENU_ON_MAP_MODE", nil)
                              command:TapMenuViewOnMap];

    [self.tapMenu addItemWithIconName:@"TapMenuViewModeInSight"
                                title:NSLocalizedString(@"TAP_MENU_IN_SIGHT_MODE", nil)
                              command:TapMenuViewInSight];

    [self.tapMenu addItemWithIconName:@"TapMenuCreateNewPlaque"
                                title:NSLocalizedString(@"TAP_MENU_CREATE_PLAQUE", nil)
                              command:TapMenuMainCreateNewPlaque];
}

- (void)switchTapMenuToMapMode
{
    [self.tapMenu clearMenu];

    [self.tapMenu addItemWithIconName:@"TapMenuViewModeOnMap"
                                title:NSLocalizedString(@"TAP_MENU_ON_MAP_MODE", nil)
                              command:TapMenuViewOnMap];

    [self.tapMenu addItemWithIconName:@"TapMenuViewModeInSight"
                                title:NSLocalizedString(@"TAP_MENU_IN_SIGHT_MODE", nil)
                              command:TapMenuViewInSight];
}

- (void)openViewModePanel
{
#ifdef WithSurroundingSelector

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:HighLevelAnimationDurationOpen];

    [self.surroundingSelector setHidden:NO];

    CGRect frame = [self.surroundingSelector frame];
    frame = CGRectOffset(frame, -40.0f, -CGRectGetHeight(frame));
    [self.surroundingSelector setFrame:frame];
    [self.surroundingSelector setAlpha:1.0f];

    [UIView commitAnimations];

#endif
}

- (void)closeViewModePanel
{
#ifdef WithSurroundingSelector

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:HighLevelAnimationDurationClose];

    [self.surroundingSelector setHidden:YES];

    CGRect frame = [self.surroundingSelector frame];
    frame = CGRectOffset(frame, 40.0f, CGRectGetHeight(frame));
    [self.surroundingSelector setFrame:frame];
    [self.surroundingSelector setAlpha:0.0f];

    [UIView commitAnimations];

#endif
}

#pragma mark - TapMenu delegate

- (void)tapMenuItemPressed:(TapMenuCommand)command
{
    switch (command)
    {
        case TapMenuMainProfile:
        {
            ApplicationDelegate *application =
            (ApplicationDelegate *) [[UIApplication sharedApplication] delegate];
            
            [application openProfileForm];

            break;
        }

        case TapMenuMainCreateNewPlaque:
        {
            [self.controller createNewPlaquePressed];

            break;
        }

        case TapMenuViewInSight:
        {
            [self switchTapMenuToMain];

            [self.controller switchToInSight];

            break;
        }

        case TapMenuViewOnMap:
        {
            [self switchTapMenuToMapMode];

            [self.controller switchToOnMap];

            break;
        }
            
        default:
            break;
    }
}

@end
