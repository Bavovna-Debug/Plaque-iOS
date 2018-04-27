//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditModeColorSubview : UIView

typedef enum
{
    EditModeColorBackground,
    EditModeColorForeground
}
EditModeColor;

- (id)initWithEditMode:(EditModeColor)editModeColor;

@end
