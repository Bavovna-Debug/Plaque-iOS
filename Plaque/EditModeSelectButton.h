//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
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
}
EditMode;

@property (assign, nonatomic, readwrite) EditMode   editMode;
@property (assign, nonatomic, readwrite) Boolean    down;

+ (EditModeSelectButton *)button:(EditMode)editMode;

+ (CGSize)buttonSize;

+ (CGSize)buttonMargin;

@end
