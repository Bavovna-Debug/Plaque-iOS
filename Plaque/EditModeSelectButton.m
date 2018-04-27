//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "EditModeSelectButton.h"

@implementation EditModeSelectButton

@synthesize down = _down;

+ (EditModeSelectButton *)button:(EditMode)editMode
{
    EditModeSelectButton *editModeButton = [[EditModeSelectButton alloc] initWithEditMode:editMode];

    return editModeButton;
}

+ (CGSize)buttonSize
{
    return CGSizeMake(64.0f, 64.0f);
}

+ (CGSize)buttonMargin
{
    return CGSizeMake(10.0f, 10.0f);
}

- (instancetype)initWithEditMode:(EditMode)editMode
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.editMode = editMode;

    CGSize buttonSize = [EditModeSelectButton buttonSize];

    [self setBounds:CGRectMake(0.0f,
                               0.0f,
                               buttonSize.width,
                               buttonSize.height)];

    NSString *logoName;
    NSString *labelText;

    switch (self.editMode)
    {
        case EditModeCoordinate:
            logoName = @"EditModeCoordinate";
            labelText = NSLocalizedString(@"EDIT_MODE_COORDINATE_BUTTON", nil);
            break;

        case EditModeAltitude:
            logoName = @"EditModeAltitude";
            labelText = NSLocalizedString(@"EDIT_MODE_ALTITUDE_BUTTON", nil);
            break;

        case EditModeDirection:
            logoName = @"EditModeDirection";
            labelText = NSLocalizedString(@"EDIT_MODE_DIRECTION_BUTTON", nil);
            break;

        case EditModeTilt:
            logoName = @"EditModeTilt";
            labelText = NSLocalizedString(@"EDIT_MODE_TILT_BUTTON", nil);
            break;

        case EditModeSize:
            logoName = @"EditModeSize";
            labelText = NSLocalizedString(@"EDIT_MODE_SIZE_BUTTON", nil);
            break;

        case EditModeBackgroundColor:
            logoName = @"EditModeBackgroundColor";
            labelText = NSLocalizedString(@"EDIT_MODE_BACKGROUND_BUTTON", nil);
            break;

        case EditModeForegroundColor:
            logoName = @"EditModeForegroundColor";
            labelText = NSLocalizedString(@"EDIT_MODE_FOREGROUND_BUTTON", nil);
            break;

        case EditModeFont:
            logoName = @"EditModeFont";
            labelText = NSLocalizedString(@"EDIT_MODE_FONT_BUTTON", nil);
            break;

        case EditModeInscription:
            logoName = @"EditModeInscription";
            labelText = NSLocalizedString(@"EDIT_MODE_INSCRIPTION_BUTTON", nil);
            break;

        case EditModeFortify:
            logoName = @"EditModeFortify";
            labelText = NSLocalizedString(@"EDIT_MODE_FORTIFY_BUTTON", nil);
            break;
    }

    [self setBackgroundImage:[UIImage imageNamed:logoName] forState:UIControlStateNormal];

    CGRect labelFrame = CGRectMake(CGRectGetMinX(self.bounds),
                                   CGRectGetMaxY(self.bounds),
                                   CGRectGetWidth(self.bounds),
                                   10.0f);
    
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor darkTextColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:9.0f]];
    [label setText:labelText];
    [self addSubview:label];

    return self;
}

@end
