//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "PanelTwin.h"

#include "Definitions.h"

@interface PanelTwin ()

@property (strong, nonatomic, readwrite) Panel  *leftPanel;
@property (strong, nonatomic, readwrite) Panel  *rightPanel;

@property (strong, nonatomic)            UIView *panelsView;

@end

@implementation PanelTwin
{
    Boolean bothFitOnScreen;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    bothFitOnScreen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil)
    {
        [self setFrame:self.superview.bounds];

        [self setBackgroundColor:[UIColor clearColor]];

        [self createPanels];

        [self.leftPanel setBackground:@"PanelSelectorBackground"];
        [self.rightPanel setBackground:@"PanelControlsBackground"];
    }
}

- (void)createPanels
{
    CGRect panelsViewFrame = self.bounds;
    if (bothFitOnScreen == NO)
    {
        panelsViewFrame.size.width *= 2;
    }

    UIView *panelsView = [[UIView alloc] initWithFrame:panelsViewFrame];
    [panelsView setBackgroundColor:[UIColor clearColor]];
    [panelsView setCenter:self.center];

    CGSize panelSize = CGSizeMake(320.0f, 200.0f);

    CGRect selectorPanelRect =
    CGRectMake(CGRectGetMidX(panelsViewFrame) - panelSize.width / 2,
               CGRectGetMaxY(panelsViewFrame) - panelSize.height - 64.0f,
               panelSize.width,
               panelSize.height);

    CGRect controlsPanelRect = selectorPanelRect;

    if (bothFitOnScreen == YES)
    {
        CGFloat distancer = panelSize.width / 2 + 4.0f;
        selectorPanelRect = CGRectOffset(selectorPanelRect, -distancer, 0.0f);
        controlsPanelRect = CGRectOffset(controlsPanelRect, +distancer, 0.0f);
    }
    else
    {
        CGFloat distancer = CGRectGetWidth(self.bounds) / 2 - 8.0f;
        selectorPanelRect = CGRectOffset(selectorPanelRect, -distancer, 0.0f);
        controlsPanelRect = CGRectOffset(controlsPanelRect, +distancer, 0.0f);
    }

    Panel *leftPanel = [[Panel alloc] init];
    Panel *rightPanel = [[Panel alloc] init];

    [leftPanel setFrame:selectorPanelRect];
    [rightPanel setFrame:controlsPanelRect];

    [leftPanel translate:-1.0f];
    [rightPanel translate:+1.0f];

    // Close button.
    //
    UIImage *closeButtonImage = [UIImage imageNamed:@"EditModeCloseButton"];
    CGSize closeButtonSize = closeButtonImage.size;
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:closeButtonImage
                 forState:UIControlStateNormal];
    [closeButton addTarget:self
                    action:@selector(closeButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];
    [panelsView addSubview:closeButton];

    if (bothFitOnScreen == YES)
    {
        [closeButton setFrame:CGRectMake(CGRectGetMidX(self.bounds) - closeButtonSize.width / 2,
                                         CGRectGetMinY(selectorPanelRect),
                                         closeButtonSize.width,
                                         closeButtonSize.height)];
    }
    else
    {
        [closeButton setFrame:CGRectMake(CGRectGetMaxX(self.bounds) - closeButtonSize.width,
                                         CGRectGetMinY(selectorPanelRect),
                                         closeButtonSize.width,
                                         closeButtonSize.height)];
    }

    // Back button should be available only on small screen.
    //
    if (bothFitOnScreen == NO)
    {
        UIImage *backButtonImage = [UIImage imageNamed:@"EditModeBackButton"];

        CGSize backButtonSize = backButtonImage.size;

        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [backButton setImage:backButtonImage
                    forState:UIControlStateNormal];

        [backButton setFrame:CGRectMake(CGRectGetMaxX(self.bounds),
                                        CGRectGetMinY(selectorPanelRect),
                                        backButtonSize.width,
                                        backButtonSize.height)];

        [backButton addTarget:self
                       action:@selector(backButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];

        [panelsView addSubview:backButton];
    }

    [panelsView addSubview:leftPanel];
    [panelsView addSubview:rightPanel];
    [self addSubview:panelsView];

    self.panelsView = panelsView;
    self.leftPanel = leftPanel;
    self.rightPanel = rightPanel;

    if (bothFitOnScreen == NO)
    {
        CGPoint panelsCenter = [panelsView center];
        panelsCenter.x += CGRectGetWidth(self.bounds) / 2;
        [panelsView setCenter:panelsCenter];
    }
}

- (void)movePanelsLeft
{
    if (bothFitOnScreen == FALSE)
    {
        [UIView beginAnimations:nil
                        context:nil];
        [UIView setAnimationDuration:PanelTwinMoveLeftDuration];

        CGPoint panelsCenter = [self.panelsView center];
        panelsCenter.x -= CGRectGetWidth(self.bounds);
        [self.panelsView setCenter:panelsCenter];
        
        [UIView commitAnimations];
    }
}

- (void)movePanelsRight
{
    if (bothFitOnScreen == FALSE)
    {
        [UIView beginAnimations:nil
                        context:nil];
        [UIView setAnimationDuration:PanelTwinMoveRightDuration];

        CGPoint panelsCenter = [self.panelsView center];
        panelsCenter.x += CGRectGetWidth(self.bounds);
        [self.panelsView setCenter:panelsCenter];
        
        [UIView commitAnimations];
    }
}

- (void)closeButtonPressed:(id)sender
{
    [self removeFromSuperview];
}

- (void)backButtonPressed:(id)sender
{
    [self movePanelsRight];
}

@end
