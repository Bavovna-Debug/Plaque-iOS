//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface EditModeCoordinateSubview : UIView <CLLocationManagerDelegate>

@property (weak, nonatomic) CLLocationManager *locationManager;

@end
