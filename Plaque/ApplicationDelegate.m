//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "ApplicationDelegate.h"
#import "ApplicationSetup.h"
#import "Authentificator.h"
#import "Database.h"
#import "Navigator.h"
#import "Plaques.h"
#import "MainController.h"
#import "ProfileViewController.h"
#import "TapMenu.h"
#import "Communicator.h"
#import "Servers.h"
#import "Settings.h"
#import "SQLite.h"
#import "StatusBar.h"

#include "Definitions.h"

@interface ApplicationDelegate () <CLLocationManagerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) MainController    *controller;
@property (weak,   nonatomic) FullScreenShield  *shield;

@end

@implementation ApplicationDelegate
{
    BOOL inBackground;
    UIBackgroundTaskIdentifier backgroundTaskId;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self upgradeIfNecessary];

    [application setIdleTimerDisabled:YES];

    [application setMinimumBackgroundFetchInterval:MinimumBackgroundFetchInterval];

#if 0
    UIUserNotificationType types =
    UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;

    UIUserNotificationSettings *notificationSettings =
    [UIUserNotificationSettings settingsForTypes:types
                                      categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
#endif
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

    NSDictionary *remoteNotif =
    [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif != nil)
    {
        [self application:application didReceiveRemoteNotification:remoteNotif];
    }

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    //[SQLiteDatabase removeDatabase:@"plaque"];

    [Database mainDatabase];

    [Authentificator sharedAuthentificator];

    [Servers sharedServers];
    
    Communicator *communicator = [Communicator sharedCommunicator];
    [communicator switchToForeground];

    Plaques *plaques = [Plaques sharedPlaques];
    [plaques switchToForeground];
    [plaques loadPlaquesCache];
    [plaques loadWorkdesk];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.controller = [[MainController alloc] init];
    [self.window setRootViewController:self.controller];

    [self.window makeKeyAndVisible];

    [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];

    //[[ApplicationSetup sharedApplicationSetup] goThroughQuestionsAndAnswers];

    return YES;
}

- (void)upgradeIfNecessary
{
    Settings *sharedSettings = [Settings sharedSettings];

    // Validate application version.
    //
    {
        NSUInteger lastApplicationVersion = [sharedSettings lastApplicationVersion];

        if (lastApplicationVersion < ApplicationVersion)
        {
            NSLog(@"Application resources need to be upgraded from version %lu",
                  (unsigned long) lastApplicationVersion);

            [sharedSettings setLastApplicationVersion:ApplicationVersion];

            NSLog(@"Application resources have been upgraded to version %u",
                  ApplicationVersion);
        }
    }

    // Validate database version.
    //
    {
        NSUInteger lastDatabaseVersion = [sharedSettings lastDatabaseVersion];

        if (lastDatabaseVersion < DatabaseVersion)
        {
            NSLog(@"Database resources need to be upgraded from version %lu",
                  (unsigned long) lastDatabaseVersion);

            [Database upgradeDatabase];

            [sharedSettings setLastDatabaseVersion:DatabaseVersion];

            NSLog(@"Database resources have been upgraded to version %u",
                  DatabaseVersion);
        }
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
#ifdef VERBOSE
    NSLog(@"[ApplicationDelegate] Out of memory");
#endif
}

- (void)applicationWillResignActive:(UIApplication *)application
{
#ifdef VERBOSE
    NSLog(@"[ApplicationDelegate] Application will resign active");
#endif

    inBackground = TRUE;
    [self.controller switchToBackground];

    Plaques *plaques = [Plaques sharedPlaques];
    [plaques switchToBackground];
    [plaques savePlaquesCache];
    [plaques saveWorkdesk];

    [[Communicator sharedCommunicator] switchToBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
#ifdef VERBOSE
    NSLog(@"[ApplicationDelegate] Application will enter foreground");
#endif

    [[Communicator sharedCommunicator] switchToForeground];

    [[Plaques sharedPlaques] switchToForeground];

    [self.controller switchToForeground];

    inBackground = FALSE;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[Authentificator sharedAuthentificator] validateNotificationsToken:deviceToken];
}

- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
#ifdef VERBOSE
    NSLog(@"[ApplicationDelegate] Failed to get token, error: %@", error);
#endif
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
#ifdef VERBOSE
    NSLog(@"[ApplicationDelegate] Remote notification: %@", userInfo);
#endif

    if (inBackground == TRUE)
    {
        UILocalNotification *notification = [[UILocalNotification alloc] init];

        [notification setFireDate:[NSDate date]];
        [notification setAlertBody:[NSString stringWithFormat:@"%@", userInfo]];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setApplicationIconBadgeNumber:0];

        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    else
    {
        UILocalNotification *notification = [[UILocalNotification alloc] init];

        [[StatusBar sharedStatusBar] postMessage:[notification alertBody]];
    }
}

- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification
{
}

- (FullScreenShield *)fullScreenSchield:(id<FullScreenSchieldDelegate>)delegate
                           closeOnTouch:(Boolean)closeOnTouch
{
    if (self.shield != nil)
    {
        [self.shield removeFromSuperview];
    }

    FullScreenShield *shield =
    [[FullScreenShield alloc] initWithCloseOnTouch:closeOnTouch];

    [shield setFrame:self.controller.view.frame];
    [shield setDelegate:delegate];

    TapMenu *tapMenu = [TapMenu mainTapMenu];

    [self.controller.view insertSubview:shield
                           belowSubview:tapMenu];

    self.shield = shield;

    return shield;
}

- (void)askToCreateProfile
{
    NSString *title = NSLocalizedString(@"DO_YOU_WANT_TO_CREATE_PROFILE_TITLE", nil);
    NSString *message = NSLocalizedString(@"DO_YOU_WANT_TO_CREATE_PROFILE_MESSAGE", nil);
    NSString *noButton = NSLocalizedString(@"DO_YOU_WANT_TO_CREATE_PROFILE_NOT_YET", nil);
    NSString *yesButton = NSLocalizedString(@"DO_YOU_WANT_TO_CREATE_PROFILE_YES_BUTTON", nil);

    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:title
                               message:message
                              delegate:self
                     cancelButtonTitle:noButton
                     otherButtonTitles:yesButton, nil];

    [alertView setTag:AlertDoYouWantToCreateProfile];
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

- (void)openProfileForm
{
    ProfileViewController *profileController = [[ProfileViewController alloc] init];

    [self.controller presentViewController:profileController
                                  animated:YES
                                completion:nil];
}

/*
- (void)takePicture:(id)delegate
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];

    [picker setDelegate:delegate];

    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;

    [self.controller presentViewController:picker
                                  animated:YES
                                completion:nil];
}
*/

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch ([alertView tag])
    {
        case AlertDoYouWantToCreateProfile:
        {
            if (buttonIndex == 1)
            {
                [self openProfileForm];
            }
            break;
        }

        default:
            break;
    }
}

@end
