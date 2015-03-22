//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Plaque.h"

@interface MainController : UIViewController

typedef enum
{
    PlaqueEditModeMotionControlled,
    PlaqueEditModeCoordinate,
    PlaqueEditModeAltitude,
    PlaqueEditModeDirection,
    PlaqueEditModeSize
} PlaqueEditMode;

- (void)switchToBackground;

- (void)switchToForeground;

- (void)switchToInSight;

- (void)switchToOnMap;

- (void)switchToManualNavigation;

- (void)createNewPlaquePressed;

- (void)createNewPlaqueCancelled;

- (void)createNewPlaqueConfirmed;

@end
