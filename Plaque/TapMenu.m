//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
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

@property (strong, nonatomic) UIButton *mainButton;
@property (weak,   nonatomic) FullScreenShield *shield;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation TapMenu

+ (TapMenu *)mainTapMenu
{
    static dispatch_once_t  onceToken;
    static TapMenu          *tapMenu;

    dispatch_once(&onceToken, ^
    {
        tapMenu = [[TapMenu alloc] init];
    });

    return tapMenu;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.items = [NSMutableArray array];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    UIImage *mainButtonImage = [UIImage imageNamed:@"TapMenu"];
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mainButton setImage:mainButtonImage
                     forState:UIControlStateNormal];
    [self.mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.mainButton];

    {
        self.activityIndicator =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

        [self.activityIndicator setFrame:CGRectMake(0.0f,
                                                    CGRectGetMaxY(self.bounds) - 40.0f,
                                                    40.0f,
                                                    40.0f)];

        [self addSubview:self.activityIndicator];
    }

    {
        NSDictionary *viewsDictionary = @{@"tapMenuMainButton":self.mainButton};

        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:|-0-[tapMenuMainButton(48)]-|"
                              options:NSLayoutFormatAlignAllBaseline
                              metrics:nil
                              views:viewsDictionary]];

        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"V:|-[tapMenuMainButton(48)]-0-|"
                              options:NSLayoutFormatAlignAllBaseline
                              metrics:nil
                              views:viewsDictionary]];
    }

    [self.mainButton addTarget:self
                        action:@selector(mainButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];

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
    /*
    ControlPanel *controlPanel = [ControlPanel sharedControlPanel];
    [controlPanel open];
*/

    if ([self menuOpened] == YES) 
    {
        [self closeMenu];
    } 
    else 
    {
        [self openMenu];
    }

    //[self.delegate mainButtonPressed];
}

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

    [self.items removeAllObjects];
}

- (void)addItemWithIconName:(NSString *)iconName
                      title:(NSString *)title
                    command:(TapMenuCommand)command;
{
    TapMenuItem *item = [[TapMenuItem alloc] initWithIconName:iconName
                                                        title:title
                                                      command:command];

    [self.items addObject:item];
}

- (void)openMenu
{
    if ([self menuOpened] == YES)
    {
        return;
    }

    [self setMenuOpened:YES];

    ApplicationDelegate *application =
    (ApplicationDelegate *) [[UIApplication sharedApplication] delegate];

    FullScreenShield *shield = [application fullScreenSchield:self
                                                 closeOnTouch:YES];

    CGSize mainButtonSize = self.mainButton.bounds.size;

    CGRect nullFrame = CGRectMake(0.0f, CGRectGetHeight(self.superview.bounds), 0.0f, 0.0f);

    CGRect itemFrame = CGRectMake(mainButtonSize.width * 0.4f,
                                  CGRectGetMaxY(self.frame) - mainButtonSize.height * 0.8f,
                                  [TapMenuItem fullSize].width,
                                  [TapMenuItem fullSize].height);

    for (TapMenuItem *item in self.items)
    {
        [shield addSubview:[item prepareViewFor:shield]];

        [item.view setAlpha:5.0f];
        [item.view setFrame:nullFrame];
    }

    CGFloat angle = -4.0f;

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:TapMenuAnimationDurationOpen];

    [self.mainButton setAlpha:AlphaMainButtonOpenned];

    for (TapMenuItem *item in self.items)
    {
        [item.view setAlpha:1.0f];
        [item.view setFrame:itemFrame];
        [item.view addTarget:self
                      action:@selector(tapMenuItemPressed:)
            forControlEvents:UIControlEventTouchUpInside];

        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1.0f / 500.0f;
        //transform = CATransform3DTranslate(transform, transX, -transY, -transZ);
        transform = CATransform3DRotate(transform, DegreesToRadians(angle), 0, 0, -1);
        transform = CATransform3DRotate(transform, DegreesToRadians(25.0f), 0, -1, 0);
        //transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);

        [item.view.layer setTransform:transform];

        CGFloat offset = sinf(1.0f - (CGRectGetMaxY(itemFrame) / CGRectGetMaxY(self.frame))) * 45.0f;
        itemFrame = CGRectOffset(itemFrame, -offset, -CGRectGetHeight(itemFrame) * 1.2f);
        angle += 4.0f;
    }

    [UIView commitAnimations];

    self.shield = shield;
}

/*
- (void)openMenu
{
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
    //[self.exitButton setHidden:NO];

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

        CGFloat angleOverDown = RadiandsToDegrees(atan2f(overboarderY, deltaX));
        CGFloat angleOverUp = RadiandsToDegrees(atan2f(overboarderX, deltaY));

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
                                     sin(DegreesToRadians(currentAngle)) * radius,
                                     -cos(DegreesToRadians(currentAngle)) * radius);

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
}
*/

- (void)closeMenu
{
    if ([self menuOpened] == NO)
    {
        return;
    }

    [self setMenuOpened:NO];

    CGRect nullFrame = CGRectMake(0.0f, CGRectGetHeight(self.superview.bounds), 0.0f, 0.0f);

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:FlyMenuAnimationDurationClose];

    [self.mainButton setAlpha:AlphaMainButtonNormal];

    for (TapMenuItem *item in self.items)
    {
        [item.view setAlpha:0.0f];
        [item.view setFrame:nullFrame];
    }

    [UIView commitAnimations];

    [self.shield remove];
}

/*
- (void)closeMenu
{
    if ([self menuOpened] == NO)
    {
        return;
    }

    [self setMenuOpened:NO];

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:TapMenuAnimationDurationClose];

    //[self.exitButton setHidden:YES];
    [self.mainButton setAlpha:AlphaMainButtonNormal];

    [[SurroundingSelector panel] setHidden:YES];

    [UIView commitAnimations];

    [self.shield remove];
}
*/

#pragma mark - FullScreenSchield delegate

- (void)shieldWillDisappear
{
    [self closeMenu];
}

@end
