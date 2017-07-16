//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface EditModeDirectionSubview : UIView <CLLocationManagerDelegate>

- (id)initWithLocationManager:(CLLocationManager *)locationManager;

@end
