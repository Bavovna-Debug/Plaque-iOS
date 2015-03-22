//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FullScreenShield.h"

@interface ApplicationDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (FullScreenShield *)fullScreenSchield:(id<FullScreenSchieldDelegate>)delegate
                           closeOnTouch:(Boolean)closeOnTouch;

- (void)askToCreateProfile;

- (void)openProfileForm;

//- (void)takePicture:(id)delegate;

@end

