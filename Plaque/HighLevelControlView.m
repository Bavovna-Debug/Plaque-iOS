//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "HighLevelControlView.h"
#import "TapMenu.h"

#include "Definitions.h"

@interface HighLevelControlView () <TapMenuDelegate>

@property (strong, nonatomic) TapMenu *tapMenu;

@end

@implementation HighLevelControlView

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    self.tapMenu = [TapMenu mainTapMenu];
    [self.tapMenu setDelegate:self];

    [self addSubview:self.tapMenu];
/*
    self.surroundingSelector = [SurroundingSelector panel];
    [self.surroundingSelector setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.surroundingSelector setHidden:YES];
    [self addSubview:self.surroundingSelector];
*/
    NSDictionary *viewsDictionary = @{@"tapMenu":self.tapMenu/*,
                                      @"surroundingSelector":self.surroundingSelector*/};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-[tapMenu]-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:[tapMenu]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

/*
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
*/

    [self openViewModePanel];

    [self switchTapMenuToMain];
}

#pragma mark - Tap menu

- (void)switchTapMenuToMain
{
    [self.tapMenu clearMenu];

    [self.tapMenu addItemWithIconName:@"TapMenuMainCreateNewPlaque"
                              command:TapMenuMainCreateNewPlaque
                            rowNumber:0];

    [self.tapMenu addItemWithIconName:@"ViewModeOnMap"
                              command:TapMenuMainProfile
                            rowNumber:0];

    /*[self.tapMenu addItemWithIconName:@"ViewModeOnMap"
                              command:TapMenuViewOnRadar
                            rowNumber:0];*/
}

- (void)openViewModePanel
{
/*
    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:HighLevelAnimationDurationOpen];

    [self.surroundingSelector setHidden:NO];

    CGRect frame = [self.surroundingSelector frame];
    frame = CGRectOffset(frame, -40.0f, -CGRectGetHeight(frame));
    [self.surroundingSelector setFrame:frame];
    [self.surroundingSelector setAlpha:1.0f];

    [UIView commitAnimations];
*/
}

- (void)closeViewModePanel
{
/*
    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:HighLevelAnimationDurationClose];

    [self.surroundingSelector setHidden:YES];

    CGRect frame = [self.surroundingSelector frame];
    frame = CGRectOffset(frame, 40.0f, CGRectGetHeight(frame));
    [self.surroundingSelector setFrame:frame];
    [self.surroundingSelector setAlpha:0.0f];

    [UIView commitAnimations];
*/
}

#pragma mark - TapMenu delegate

- (void)tapMenuItemPressed:(TapMenuCommand)command
{
    switch (command)
    {
        case TapMenuMainProfile:
        {
            ApplicationDelegate *application = (ApplicationDelegate *)[[UIApplication sharedApplication] delegate];
            [application openProfileForm];

            break;
        }

        case TapMenuMainCreateNewPlaque:
        {
            [self.controller createNewPlaquePressed];

            break;
        }

        default:
            break;
    }
}

@end
