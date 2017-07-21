//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InformationalView.h"
#import "SurroundingSubview.h"

@interface InSightView : SurroundingSubview

@property (assign, nonatomic, readwrite) CGFloat fullScreenWidth;
@property (assign, nonatomic, readwrite) CGFloat fullScreenMeterDistance;
@property (assign, nonatomic, readwrite) CGFloat fullScreenAngle;
@property (assign, nonatomic, readwrite) CGFloat rangeInSight;

@property (strong, nonatomic, readwrite) CALayer *container;

- (id)initWithController:(UIViewController *)controller;

@end
