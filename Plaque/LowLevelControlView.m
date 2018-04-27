//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "LowLevelControlView.h"
#import "CreatePlaquePanel.h"
#import "EditModeView.h"
#import "CapturedPlaquePanel.h"
#import "NavigationPanel.h"
#import "Plaques.h"

@interface LowLevelControlView () <PlaqueCaptureDelegate, PlaqueEditDelegate>

@property (strong, nonatomic) UIView *specialPanel;

@end

@implementation LowLevelControlView

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }
    
    [[Plaques sharedPlaques] setCaptureDelegate:self];
    [[Plaques sharedPlaques] setEditDelegate:self];

    return self;
}

- (void)switchToBackground
{
    [super switchToBackground];

    [self flushSubviews];
}

- (void)switchToManualNavigation
{
    [self flushSubviews];

    NavigationPanel *panel = [[NavigationPanel alloc] init];
    [self addSubview:panel];

    self.specialPanel = panel;
}

- (void)createNewPlaqueMode
{
    [self flushSubviews];

    CreatePlaquePanel *panel = [[CreatePlaquePanel alloc] initWithFrame:self.bounds];
    [panel setController:self.controller];
    [self addSubview:panel];

    self.specialPanel = panel;
}

#pragma mark - Plaque capture delegate

- (void)plaqueCaptured:(Plaque *)plaque
{
    if (self.specialPanel != nil)
    {
        return;
    }

    [self flushSubviews];

    if (plaque != nil)
    {
        CapturedPlaquePanel *capturedPlaquePanel = [[CapturedPlaquePanel alloc] init];
        [capturedPlaquePanel setPlaque:plaque];

        [self addSubview:capturedPlaquePanel];
    }
}

#pragma mark - Plaque edit delegate

- (void)plaqueDidHaveTakenForEdit:(Plaque *)plaque
{
    [self flushSubviews];

    EditModeView *editModeView = [[EditModeView alloc] init];
    [editModeView setFrame:self.bounds];
    [self addSubview:editModeView];
}

@end
