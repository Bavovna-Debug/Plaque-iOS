//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActionButton : UIButton

typedef enum
{
    ActionNoAction,
    ActionNewPlaque1,
    ActionNewPlaque2,
    ActionNewPlaque3,
    ActionNewPlaque4,
    ActionEditMode,
    ActionTest
} ActionCode;

@property (assign, nonatomic) ActionCode actionCode;

+ (ActionButton *)button:(ActionCode)actionCode;

+ (CGSize)buttonSize;

+ (CGSize)buttonMargin;

@end
