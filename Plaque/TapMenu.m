//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "ControlPanel.h"
#import "FullScreenShield.h"
#import "TapMenu.h"
#import "Navigator.h"
#import "Settings.h"
#import "SurroundingSelector.h"

#include "Definitions.h"

@interface TapMenu () <FullScreenSchieldDelegate>

@property (assign, nonatomic, readwrite) Boolean menuOpened;

@property (weak,   nonatomic) FullScreenShield *shield;
@property (strong, nonatomic) NSMutableArray *rows;
@property (strong, nonatomic) UIButton *mainButton;
//@property (strong, nonatomic) UIButton *exitButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation TapMenu

@synthesize menuOpened = _menuOpened;

+ (TapMenu *)mainTapMenu
{
    static dispatch_once_t onceToken;
    static TapMenu *tapMenu;

    dispatch_once(&onceToken, ^{
        tapMenu = [[TapMenu alloc] init];
    });

    return tapMenu;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    UIImage *mainButtonImage = [UIImage imageNamed:@"TapMenu"];
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mainButton setImage:mainButtonImage
                     forState:UIControlStateNormal];
    [self.mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.mainButton];

/*
    self.exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.exitButton setImage:[UIImage imageNamed:@"TapMenuQuit"]
                     forState:UIControlStateNormal];
    [self.exitButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.exitButton setHidden:YES];
    [self addSubview:self.exitButton];
*/
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicator setFrame:CGRectMake(0.0f, CGRectGetMaxY(self.bounds) - 40.0f, 40.0f, 40.0f)];
    [self addSubview:self.activityIndicator];

    NSDictionary *viewsDictionary = @{@"tapMenuMainButton":self.mainButton,
                                      /*@"tapMenuExitButton":self.exitButton*/};
    
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-[tapMenuMainButton]-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-[tapMenuMainButton]-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];
/*
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-[tapMenuExitButton]-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-[tapMenuExitButton]-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];
*/
    [self.mainButton addTarget:self
                        action:@selector(mainButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
/*
    [self.exitButton addTarget:self
                        action:@selector(exitButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
*/
    return self;
}

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    UIView* view = [super hitTest:point withEvent:event];

    return (view == self) ? nil : view;
}

- (void)mainButtonPressed:(id)sender
{
    ControlPanel *controlPanel = [ControlPanel sharedControlPanel];
    [controlPanel open];
    NSLog(@"TapMenu %f %f", self.frame.origin.y, self.frame.size.height);
/*
    if ([self menuOpened] == YES) {
        [self closeMenu];
    } else {
        [self openMenu];
    }

    [self.delegate mainButtonPressed];
*/
}

/*
- (void)exitButtonPressed:(id)sender
{
    [self closeMenu];

    [self.delegate exitButtonPressed];
}
*/

- (void)tapMenuItemPressed:(id)sender
{
    [self closeMenu];
    TapMenuItemView *itemView = (TapMenuItemView *)sender;
    TapMenuItem *item = (TapMenuItem *)itemView.owner;
    [self.delegate tapMenuItemPressed:item.command];
}

- (void)clearMenu
{
    [self closeMenu];

    [self.rows removeAllObjects];
}

- (void)addItemWithIconName:(NSString *)iconName
                    command:(TapMenuCommand)command
{
    [self addItemWithIconName:iconName
                      command:command
                    rowNumber:0];
}

- (void)addItemWithIconName:(NSString *)iconName
                    command:(TapMenuCommand)command
                  rowNumber:(NSUInteger)rowNumber
{
    if (self.rows == nil)
        self.rows = [NSMutableArray array];

    NSMutableArray *row;
    if ([self.rows count] > rowNumber) {
        row = [self.rows objectAtIndex:rowNumber];
    } else {
        row = [NSMutableArray array];
        [self.rows addObject:row];
    }

    TapMenuItem *item = [[TapMenuItem alloc] initWithIconName:iconName
                                                      command:command
                                                    rowNumber:rowNumber];
    [row addObject:item];
}

- (void)openMenu
{
/*
    if ([self menuOpened] == YES)
        return;

    [self setMenuOpened:YES];

    ApplicationDelegate *application = (ApplicationDelegate *)[[UIApplication sharedApplication] delegate];
    FullScreenShield *shield = [application fullScreenSchield:self
                                                 closeOnTouch:YES];

    NSMutableArray *itemViewsKeeper = [NSMutableArray array];

    for (NSMutableArray *row in self.rows)
        for (TapMenuItem *item in row)
            [itemViewsKeeper addObject:[item prepareViewFor:shield]];

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:TapMenuAnimationDurationOpen];

    [self.mainButton setAlpha:AlphaMainButtonOpenned];
    [self.exitButton setHidden:NO];

    CGFloat lastRowRadius;

    lastRowRadius = sqrtf(powf(CGRectGetMidX(self.mainButton.bounds), 2) + powf(CGRectGetMidY(self.mainButton.bounds), 2));

    CGPoint center = CGPointMake(CGRectGetMinX(shield.bounds) + CGRectGetMidX(self.mainButton.bounds),
                                 CGRectGetMaxY(shield.bounds) - CGRectGetMidY(self.mainButton.bounds));
    for (NSUInteger rowNumber = 0; rowNumber < [self.rows count]; rowNumber++)
    {
        NSMutableArray *row = [self.rows objectAtIndex:rowNumber];

        CGFloat biggestItemRadius = 0.0f;
        CGFloat radiantLength = 0.0f;
        for (TapMenuItem *item in row)
        {
            biggestItemRadius = MAX(biggestItemRadius, item.view.fullSize.width);
            radiantLength += [item.view fullSize].width;
        }

        CGFloat radius = radiantLength * M_1_PI;
        radius = MAX(radius, lastRowRadius + biggestItemRadius / 2);

        CGFloat overboarderX = center.x - CGRectGetMinX(shield.bounds);
        CGFloat overboarderY = CGRectGetMaxY(shield.bounds) - center.y;
        CGFloat deltaX = sqrtf(powf(radius, 2) - powf(overboarderY, 2));
        CGFloat deltaY = sqrtf(powf(radius, 2) - powf(overboarderX, 2));

        CGFloat angleOverDown = radiandsToDegrees(atan2f(overboarderY, deltaX));
        CGFloat angleOverUp = radiandsToDegrees(atan2f(overboarderX, deltaY));

        CGFloat fromAngle = -angleOverDown;
        CGFloat toAngle = 90.0f + angleOverUp;
        CGFloat angleStep = (toAngle - fromAngle) / [row count];
        CGFloat currentAngle = fromAngle + angleStep * 0.5f;

        for (TapMenuItem *item in row)
        {
            TapMenuItemView *itemView = item.view;

            [shield addSubview:itemView];

            CGSize itemSize = [itemView fullSize];
            CGRect itemFrame = CGRectMake(center.x - itemSize.width / 2,
                                          center.y - itemSize.height / 2,
                                          itemSize.width,
                                          itemSize.height);
            itemFrame = CGRectOffset(itemFrame,
                                     sin(degreesToRadians(currentAngle)) * radius,
                                     -cos(degreesToRadians(currentAngle)) * radius);

            [itemView setAlpha:1.0f];
            [itemView setFrame:itemFrame];
            [itemView addTarget:self
                         action:@selector(tapMenuItemPressed:)
               forControlEvents:UIControlEventTouchUpInside];

            currentAngle += angleStep;
        }

        lastRowRadius = radius + biggestItemRadius * 0.5f + DistanceBetweenRows;
    }

    [[SurroundingSelector panel] setHidden:NO];

    [UIView commitAnimations];

    self.shield = shield;
*/
}

- (void)closeMenu
{
/*
    if ([self menuOpened] == NO)
        return;

    [self setMenuOpened:NO];

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:TapMenuAnimationDurationClose];

    [self.exitButton setHidden:YES];
    [self.mainButton setAlpha:AlphaMainButtonNormal];

    [[SurroundingSelector panel] setHidden:YES];

    [UIView commitAnimations];

    [self.shield remove];
*/}

#pragma mark - FullScreenSchield delegate

- (void)shieldWillDisappear
{
    [self closeMenu];
}

@end
