//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "FullScreenShield.h"
#import "EditModeCoordinateView.h"
#import "EditModeAltitudeView.h"
#import "EditModeSizeView.h"
#import "PlaqueEditView.h"

@interface PlaqueEditView () <FullScreenSchieldDelegate>

@property (strong, nonatomic) UIView *buttonsView;
@property (strong, nonatomic) NSArray *editModeButtons;
@property (strong, nonatomic) UIView *currentEditModeView;

@end

@implementation PlaqueEditView

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self setBackgroundColor:[UIColor clearColor]];

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [self setFrame:newSuperview.bounds];

    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];

    [self prepareEditModeButtons];
}

- (void)actionButtonPressed:(id)sender
{
    EditModeButton *pressedButton = (EditModeButton *)sender;
    for (EditModeButton *button in self.editModeButtons)
        [button setDown:(button == pressedButton)];

    if (self.currentEditModeView != nil) {
        [self.currentEditModeView removeFromSuperview];
        self.currentEditModeView = nil;
    }

    switch (pressedButton.editMode)
    {
        case EditModeCoordinate:
        {
            //self.currentEditModeView = [[EditModeCoordinateView alloc] initWithPlaque:self.plaque];
            break;
        }

        case EditModeAltitude:
        {
            //self.currentEditModeView = [[EditModeAltitudeView alloc] initWithPlaque:self.plaque];
            break;
        }

        case EditModeDirection:
        {
            break;
        }

        case EditModeSize:
        {
            //self.currentEditModeView = [[EditModeSizeView alloc] initWithPlaque:self.plaque];
            break;
        }
    }

    CGRect editorFrame = CGRectMake(0.0f,
                                    CGRectGetMaxY(self.bounds) - CGRectGetHeight(self.buttonsView.bounds) - 200.0f,
                                    CGRectGetWidth(self.bounds),
                                    200.0f);
    [self.currentEditModeView setFrame:editorFrame];
    [self addSubview:self.currentEditModeView];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    InSightView *inSightView = (InSightView *)self.superview;

    [self removeFromSuperview];

    [inSightView action:ActionNoAction];
}

#pragma mark - FullScreenSchieldDelegate delegate

- (void)shieldWillDisappear
{
}

@end
