//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MainController.h"
#import "SurroundingSelector.h"

@protocol ControlPanelSurroundingDelegate;

@interface ControlPanel : NSObject

@property (weak, nonatomic) MainController *controller;

+ (ControlPanel *)sharedControlPanel;

- (void)open;

@end
