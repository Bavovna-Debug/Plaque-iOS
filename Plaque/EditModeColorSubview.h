//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditModeColorSubview : UIView

typedef enum
{
    EditModeColorBackground,
    EditModeColorForeground
} EditModeColor;

@property (assign, nonatomic) EditModeColor editModeColor;

@end
