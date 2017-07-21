//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "TapMenuItem.h"

@interface TapMenuItem ()

@property (strong, nonatomic) NSString *iconName;

@end

@implementation TapMenuItem

- (id)initWithIconName:(NSString *)iconName
               command:(TapMenuCommand)command
             rowNumber:(NSUInteger)rowNumber;
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.iconName = iconName;
    self.command = command;
    self.rowNumber = rowNumber;

    return self;
}

- (TapMenuItemView *)prepareViewFor:(UIView *)superview
{
    TapMenuItemView *view = [[TapMenuItemView alloc] initWithOwner:self];

    [view setFrame:CGRectMake(0.0f, CGRectGetMaxY(superview.bounds), 1.0f, 1.0f)];

    self.view = view;

    return view;
}

@end

@interface TapMenuItemView ()

@property (strong, nonatomic) UIImageView *icon;

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

    [self setBackgroundColor:[UIColor colorWithWhite:1.0f
                                               alpha:0.4f]];
    
    [self setAlpha:0.0f];

    TapMenuItem *item = (TapMenuItem *)owner;
    
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

- (CGSize)fullSize
{
    return self.icon.image.size;
}

@end
