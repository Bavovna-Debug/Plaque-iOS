//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Panel.h"

@interface PanelTwin : UIView

@property (strong, nonatomic) Panel *leftPanel;
@property (strong, nonatomic) Panel *rightPanel;

- (void)movePanelsLeft;

- (void)movePanelsRight;

@end
