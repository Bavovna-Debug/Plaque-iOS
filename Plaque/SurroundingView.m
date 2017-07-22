//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ControlPanel.h"
#import "InSightView.h"
#import "PlaquesOnMapView.h"
#import "SurroundingSelector.h"
#import "SurroundingSubview.h"
#import "SurroundingView.h"

@interface SurroundingView ()

@property (strong, nonatomic) InSightView       *plaquesInSightView;
@property (strong, nonatomic) PlaquesOnMapView  *plaquesOnMapView;

@end

@implementation SurroundingView

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    [self switchToInSightView];
}

- (void)prepareInSightView
{
    self.plaquesInSightView = [[InSightView alloc] initWithController:self.controller];
    [self addSubview:self.plaquesInSightView];

    NSDictionary *viewsDictionary = @{@"plaquesInSightView":self.plaquesInSightView};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[plaquesInSightView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-0-[plaquesInSightView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];
}

- (void)prepareOnMapView
{
    self.plaquesOnMapView = [[PlaquesOnMapView alloc] initWithController:self.controller];
    [self addSubview:self.plaquesOnMapView];

    NSDictionary *viewsDictionary = @{@"plaquesOnMapView":self.plaquesOnMapView};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[plaquesOnMapView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-0-[plaquesOnMapView]-0-|"
                          options:0
                          metrics:nil
                          views:viewsDictionary]];
}

- (void)switchToInSightView
{
    if (self.plaquesInSightView == nil)
    {
        [self prepareInSightView];
    }

    if (self.plaquesOnMapView != nil)
    {
        [self.plaquesOnMapView pause];
    }

    if (self.plaquesInSightView != nil)
    {
        [self.plaquesInSightView resume];
    }

    [self bringSubviewToFront:self.plaquesInSightView];
}

- (void)switchToOnMapView
{
    if (self.plaquesOnMapView == nil)
    {
        [self prepareOnMapView];
    }

    if (self.plaquesInSightView != nil)
    {
        [self.plaquesInSightView pause];
    }

    if (self.plaquesOnMapView != nil)
    {
        [self.plaquesOnMapView resume];
    }

    [self bringSubviewToFront:self.plaquesOnMapView];
}

- (void)switchToBackground
{
    [super switchToBackground];

    SurroundingSubview *currentView = (SurroundingSubview *) [self.subviews lastObject];
    [currentView pause];
}

- (void)switchToForeground
{
    [super switchToForeground];

    SurroundingSubview *currentView = (SurroundingSubview *) [self.subviews lastObject];
    [currentView resume];
}

/*
#pragma mark - Control panel surrounding delegate

- (void)surroundingViewModeChanged:(SurroundingViewMode)surroundingViewMode
{
    switch (surroundingViewMode)
    {
        case SurroundingInSight:
            [self switchToInSightView];
            break;

        case SurroundingOnMap:
            [self switchToOnMapView];
            break;

        case SurroundingRadar:
            break;
    }
}
*/

@end
