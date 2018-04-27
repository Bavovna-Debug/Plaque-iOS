//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "TapMenuItem.h"

@interface TapMenuItem ()

@property (strong, nonatomic) NSString *iconName;
@property (strong, nonatomic) NSString *title;

@end

@implementation TapMenuItem

- (id)initWithIconName:(NSString *)iconName
                 title:(NSString *)title
               command:(TapMenuCommand)command;
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.iconName = iconName;
    self.title = title;
    self.command = command;

    return self;
}

- (TapMenuItemView *)prepareViewFor:(UIView *)superview
{
    TapMenuItemView *view = [[TapMenuItemView alloc] initWithOwner:self];

    [view setFrame:CGRectMake(0.0f, CGRectGetMaxY(superview.bounds), 1.0f, 1.0f)];

    self.view = view;

    return view;
}

+ (CGSize)fullSize
{
    return CGSizeMake(280.0f, 64.0);
}

@end

@interface TapMenuItemView ()

@property (strong, nonatomic) UIImageView   *icon;
@property (strong, nonatomic) UILabel       *label;

@end

@implementation TapMenuItemView

- (id)initWithOwner:(id)owner
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.owner = owner;

    TapMenuItem *item = (TapMenuItem *) owner;

    [self setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self setBackgroundColor:[UIColor colorWithWhite:0.25f alpha:0.6f]];
    [self.layer setCornerRadius:8.0f];
    [self.layer setZPosition:100.0f];

    self.icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:item.iconName]];
    [self.icon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.icon];

    self.label = [[UILabel alloc] init];
    [self.label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.label setBackgroundColor:[UIColor clearColor]];
    [self.label setTextColor:[UIColor whiteColor]];
    [self.label setFont:[UIFont systemFontOfSize:16.0f]];
    [self.label setText:item.title];
    [self addSubview:self.label];

    NSDictionary *viewsDictionary = @{@"tapMenuItemIcon":self.icon, @"tapMenuItemLabel":self.label};

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-8-[tapMenuItemIcon]-8-[tapMenuItemLabel]"
                          options:NSLayoutFormatAlignAllBaseline
                          metrics:nil
                          views:viewsDictionary]];

    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"V:|-0-[tapMenuItemLabel]-0-|"
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

    [self.layer setShadowColor:[[UIColor whiteColor] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [self.layer setShadowOpacity:1.0f];

    return self;
}
/*
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.owner = owner;

    [self setBackgroundColor:[UIColor colorWithWhite:1.0f
                                               alpha:0.4f]];
    
    [self setAlpha:0.0f];

    TapMenuItem *item = (TapMenuItem *) owner;
    
    self.icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:item.iconName]];
    [self.icon setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.icon];

    {
        NSDictionary *viewsDictionary = @{@"icon":self.icon};

        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:|-0-[icon]-0-|"
                              options:NSLayoutFormatAlignAllBaseline
                              metrics:nil
                              views:viewsDictionary]];

        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"V:|-0-[icon]-0-|"
                              options:NSLayoutFormatAlignAllBaseline
                              metrics:nil
                              views:viewsDictionary]];
    }

    [self.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [self.layer setBorderWidth:2.0f];
    [self.layer setCornerRadius:self.icon.image.size.width / 2];
    [self.layer setShadowColor:[[UIColor whiteColor] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [self.layer setShadowOpacity:1.0f];

    return self;
}
*/

@end
