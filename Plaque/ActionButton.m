//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "ActionButton.h"

@implementation ActionButton

+ (ActionButton *)button:(ActionCode)actionCode
{
    ActionButton *actionButton = [[ActionButton alloc] init];
    [actionButton setActionCode:actionCode];
    return actionButton;
}

+ (CGSize)buttonSize
{
    return CGSizeMake(64.0f, 64.0f);
}

+ (CGSize)buttonMargin
{
    return CGSizeMake(8.0f, 8.0f);
}

- (instancetype)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self setBackgroundImage:[UIImage imageNamed:@"Pick"] forState:UIControlStateNormal];
    [self.layer setBorderWidth:2.0f];
    [self.layer setBorderColor:[[UIColor darkTextColor] CGColor]];
    [self.layer setCornerRadius:8.0f];
    [self.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [self.layer setShadowColor:[[UIColor whiteColor] CGColor]];
    [self.layer setShadowOpacity:0.8f];

    return self;
}

@end
