//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Panel.h"

@interface PanelTwin : UIView

@property (strong, nonatomic, readonly) Panel *leftPanel;
@property (strong, nonatomic, readonly) Panel *rightPanel;

- (void)movePanelsLeft;

- (void)movePanelsRight;

@end
