//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FullScreenShield.h"

@interface ApplicationDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic, readwrite) UIWindow *window;

- (FullScreenShield *)fullScreenSchield:(id<FullScreenSchieldDelegate>)delegate
                           closeOnTouch:(Boolean)closeOnTouch;

- (void)askToCreateProfile;

- (void)openProfileForm;

//- (void)takePicture:(id)delegate;

@end

