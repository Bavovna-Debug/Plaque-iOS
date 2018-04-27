//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface EditModeAltitudeSubview : UIView <CLLocationManagerDelegate>

- (id)initWithLocationManager:(CLLocationManager *)locationManager;

@end
