//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "FlyMenuItem.h"

@interface FlyMenuItem ()

@property (strong, nonatomic) UIImageView *icon;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) NSString *notification;

@end

@implementation FlyMenuItem

- (id)initWithName:(NSString *)name
      notification:(NSString *)notification
{
    self = [super init];
    if (self == nil)
        return nil;

    self.notification = notification;

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setAlpha:0.0f];
    [self setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:0.8f]];
    [self.layer setCornerRadius:8.0f];
    [self.layer setZPosition:100.0f];

    self.icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Annotation"]];
    [self.icon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.icon];

    self.label = [[UILabel alloc] init];
    [self.label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.label setBackgroundColor:[UIColor clearColor]];
    [self.label setTextColor:[UIColor whiteColor]];
    [self.label setFont:[UIFont systemFontOfSize:20.0f]];
    [self addSubview:self.label];

    NSDictionary *viewsDictionary = @{@"flyMenuItemIcon":self.icon, @"flyMenuItemLabel":self.label};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[flyMenuItemIcon]-0-[flyMenuItemLabel]"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-0-[flyMenuItemLabel]-0-|"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraint:[NSLayoutConstraint
                         constraintWithItem:self.icon
                         attribute:NSLayoutAttributeCenterY
                         relatedBy:NSLayoutRelationEqual
                         toItem:self.label
                         attribute:NSLayoutAttributeCenterY
                         multiplier:1.0f
                         constant:0.0f]];

    [self setName:name];

    return self;
}

- (NSString *)name
{
    return [self.label text];
}

- (void)setName:(NSString *)name
{
    [self.label setText:name];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    if (CGRectContainsPoint(self.bounds, point) == NO)
        return;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseFlyMenu"
                                                        object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notification
                                                        object:nil];
}

@end
