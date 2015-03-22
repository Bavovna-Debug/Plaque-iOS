//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditModeSelectButton : UIButton

typedef enum
{
    EditModeCoordinate,
    EditModeAltitude,
    EditModeDirection,
    EditModeTilt,
    EditModeSize,
    EditModeBackgroundColor,
    EditModeForegroundColor,
    EditModeFont,
    EditModeInscription
} EditMode;

@property (assign, nonatomic) EditMode editMode;
@property (assign, nonatomic) Boolean down;

+ (EditModeSelectButton *)button:(EditMode)editMode;

+ (CGSize)buttonSize;

+ (CGSize)buttonMargin;

@end
