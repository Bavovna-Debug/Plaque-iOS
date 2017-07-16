//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InformationalView.h"
#import "SurroundingSubview.h"

@interface InSightView : SurroundingSubview

@property (assign, nonatomic) CGFloat fullScreenWidth;
@property (assign, nonatomic) CGFloat fullScreenMeterDistance;
@property (assign, nonatomic) CGFloat fullScreenAngle;
@property (assign, nonatomic) CGFloat rangeInSight;

@property (strong, nonatomic) CALayer *container;

- (id)initWithController:(UIViewController *)controller;

@end
