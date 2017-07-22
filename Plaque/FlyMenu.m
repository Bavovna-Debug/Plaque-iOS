//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "FlyMenu.h"
#import "Navigator.h"

#include "Definitions.h"

@interface FlyMenu ()

@property (assign, nonatomic, readwrite) Boolean menuOpenned;

@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) UIImageView *mainButton;

@end

@implementation FlyMenu
{
    BOOL initialized;
}

@synthesize menuOpenned = _menuOpenned;

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    self.items = [NSMutableArray array];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor clearColor]];

    self.mainButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TapMenu"]];
    [self.mainButton setFrame:CGRectZero];
    [self.mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.mainButton];

    NSDictionary *viewsDictionary = @{@"flyMenuMainButton":self.mainButton};
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[flyMenuMainButton(48)]"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:[flyMenuMainButton(48)]-0-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeMenuNotification:)
                                                 name:@"CloseFlyMenu"
                                               object:nil];
    return self;
}

- (void)layoutSubviews
{
    if (initialized == NO) {
        initialized = YES;
        [self.mainButton setFrame:CGRectMake(0.0f, CGRectGetHeight(self.frame), 0.0f, 0.0f)];
    }

    [super layoutSubviews];

    [self closeMenu];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch == nil) {
        NSLog(@"NIX");
        return;
    }
    CGPoint point = [touch locationInView:[touch view]];
    if (CGRectContainsPoint(self.bounds, point) == NO)
        return;

    if ([self menuOpenned] == YES) {
        [self closeMenu];
    } else {
        [self openMenu];
    }
}

- (void)closeMenuNotification:(NSNotification *)notification
{
    [self closeMenu];
}

- (void)clearMenu
{
    [self closeMenu];

    for (FlyMenuItem *item in self.items)
        [item removeFromSuperview];

    [self.items removeAllObjects];
}

- (void)addMenuItem:(FlyMenuItem *)item
{
    [self.items addObject:item];
    [self.superview addSubview:item];
}

- (void)openMenu
{
    if ([self menuOpenned] == YES)
        return;

    [self setMenuOpenned:YES];

    CGSize mainButtonSize = self.mainButton.image.size;
    CGRect mainButtonFrame = CGRectMake(0.0f,
                                        CGRectGetMaxY(self.bounds) - mainButtonSize.height * 0.8f,
                                        mainButtonSize.width * 0.8f,
                                        mainButtonSize.height * 0.8f);
    CGRect nullFrame = CGRectMake(0.0f, CGRectGetHeight(self.superview.bounds), 0.0f, 0.0f);

    [self.mainButton setAlpha:0.4f];

    for (FlyMenuItem *item in self.items)
    {
        [item setHidden:NO];
        [item setFrame:nullFrame];
    }

    CGRect itemFrame = CGRectMake(mainButtonSize.width * 0.6f,
                                  CGRectGetMaxY(self.frame) - 80.0f,
                                  300.0f,
                                  64.0f);
    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:FlyMenuAnimationDurationOpen];

    [self.mainButton setFrame:mainButtonFrame];
    [self.mainButton setAlpha:0.8f];

    CGFloat angle = -4.0f;
    for (FlyMenuItem *item in self.items)
    {
        [item setAlpha:1.0f];
        [item setFrame:itemFrame];

        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1.0f / 500.0f;
        //transform = CATransform3DTranslate(transform, transX, -transY, -transZ);
        transform = CATransform3DRotate(transform, DegreesToRadians(angle), 0, 0, -1);
        transform = CATransform3DRotate(transform, DegreesToRadians(25.0f), 0, -1, 0);
        //transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);

        [item.layer setTransform:transform];

        CGFloat offset = sinf(1.0f - (CGRectGetMaxY(itemFrame) / CGRectGetMaxY(self.frame))) * 45.0f;
        itemFrame = CGRectOffset(itemFrame, -offset, -CGRectGetHeight(itemFrame) * 1.1f);
        angle += 3.0f;
    }

    [UIView commitAnimations];
}

- (void)closeMenu
{
    if ([self menuOpenned] == NO)
        return;

    [self setMenuOpenned:NO];

    CGSize mainButtonSize = self.mainButton.image.size;
    CGRect mainButtonFrame = CGRectMake(0.0f,
                                        CGRectGetMaxY(self.bounds) - mainButtonSize.height,
                                        mainButtonSize.width,
                                        mainButtonSize.height);
    CGRect nullFrame = CGRectMake(0.0f, CGRectGetHeight(self.superview.bounds), 0.0f, 0.0f);

    [self.mainButton setAlpha:0.4f];

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:FlyMenuAnimationDurationClose];

    [self.mainButton setFrame:mainButtonFrame];
    [self.mainButton setAlpha:1.0f];

    for (FlyMenuItem *item in self.items)
    {
        [item setAlpha:0.0f];
        [item setFrame:nullFrame];
    }

    [UIView commitAnimations];
}

@end
