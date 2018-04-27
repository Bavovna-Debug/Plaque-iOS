//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ApplicationSetup.h"

#include "Definitions.h"

@interface ApplicationSetup ()

@end

@implementation ApplicationSetup
{
    Boolean 
}
+ (ApplicationSetup *)sharedApplicationSetup
{
    static dispatch_once_t onceToken;
    static ApplicationSetup *applicationSetup;

    dispatch_once(&onceToken, ^
    {
        applicationSetup = [[ApplicationSetup alloc] init];
    });

    return applicationSetup;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    [self setEverythingOK:YES];

    return self;
}

- (void)goThroughQuestionsAndAnswers
{
    [self askToEnableGPS];
    [self askToEnableCamera];
    [self askToEnableNotifications];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark - UIAlertView creator

- (void)askToEnableGPS
{
    NSString *title = NSLocalizedString(@"SETUP_QUESTION_ABOUT_GPS_TITLE", nil);
    NSString *message = NSLocalizedString(@"SETUP_QUESTION_ABOUT_GPS_MESSAGE", nil);
    NSString *noButton = NSLocalizedString(@"ALERT_BUTTON_NO", nil);
    NSString *yesButton = NSLocalizedString(@"ALERT_BUTTON_YES", nil);

    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:title
                               message:message
                              delegate:self
                     cancelButtonTitle:noButton
                     otherButtonTitles:yesButton, nil];

    [alertView setTag:AlertDoYouWantToEnableGPS];
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

- (void)askToEnableCamera
{
    NSString *title = NSLocalizedString(@"SETUP_QUESTION_ABOUT_CAMERA_TITLE", nil);
    NSString *message = NSLocalizedString(@"SETUP_QUESTION_ABOUT_CAMERA_MESSAGE", nil);
    NSString *noButton = NSLocalizedString(@"ALERT_BUTTON_NO", nil);
    NSString *yesButton = NSLocalizedString(@"ALERT_BUTTON_YES", nil);

    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:title
                               message:message
                              delegate:self
                     cancelButtonTitle:noButton
                     otherButtonTitles:yesButton, nil];

    [alertView setTag:AlertDoYouWantToEnableCamera];
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

- (void)askToEnableNotifications
{
    NSString *title = NSLocalizedString(@"SETUP_QUESTION_ABOUT_NOTIFICATIONS_TITLE", nil);
    NSString *message = NSLocalizedString(@"SETUP_QUESTION_ABOUT_NOTIFICATIONS_MESSAGE", nil);
    NSString *noButton = NSLocalizedString(@"ALERT_BUTTON_NO", nil);
    NSString *yesButton = NSLocalizedString(@"ALERT_BUTTON_YES", nil);

    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:title
                               message:message
                              delegate:self
                     cancelButtonTitle:noButton
                     otherButtonTitles:yesButton, nil];

    [alertView setTag:AlertDoYouWantToEnableNotifications];
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch ([alertView tag])
    {
        case AlertDoYouWantToEnableGPS:
        {
            if (buttonIndex == 0)
            {
                [self setEverythingOK:NO];
            }
            break;
        }

        case AlertDoYouWantToEnableCamera:
        {
            if (buttonIndex == 0)
            {
                [self setEverythingOK:NO];
            }
            break;
        }

        case AlertDoYouWantToEnableNotifications:
        {
            if (buttonIndex == 0)
            {
                [self setEverythingOK:NO];
            }
            break;
        }

        default:
            break;
    }
}

@end
