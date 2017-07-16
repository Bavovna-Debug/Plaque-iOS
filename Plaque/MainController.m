//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ApplicationDelegate.h"
#import "ControlPanel.h"
#import "FullScreenShield.h"
#import "Navigator.h"
#import "Plaques.h"
#import "MainController.h"
#import "PlaqueEditView.h"
#import "Authentificator.h"
#import "EditModeCoordinateSubview.h"
#import "EditModeAltitudeSubview.h"
#import "EditModeSizeSubview.h"
#import "HighLevelControlView.h"
#import "LowLevelControlView.h"
//#import "InformationalView.h"
#import "StatusBar.h"
#import "SurroundingView.h"

@interface MainController ()

@property (strong, nonatomic) StatusBar *statusBarView;
@property (strong, nonatomic) HighLevelControlView *highLevelControlView;
@property (strong, nonatomic) LowLevelControlView *lowLevelControlView;
//@property (strong, nonatomic) InformationalView *informationalView;
@property (strong, nonatomic) SurroundingView *surroundingView;

@end

@implementation MainController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor clearColor]];

    [[ControlPanel sharedControlPanel] setController:self];
    
/*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //[self prepareTapMenu];

    [self.view setBackgroundColor:[UIColor blackColor]];

    self.statusBarView = [StatusBar sharedStatusBar];

    self.highLevelControlView = [[HighLevelControlView alloc] init];
    self.lowLevelControlView = [[LowLevelControlView alloc] init];
    //self.informationalView = [[InformationalView alloc] init];
    self.surroundingView = [[SurroundingView alloc] init];

    CGRect statusBarFrame;

    statusBarFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 20.0f);

    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    if ([deviceVersion floatValue] >= 7.0f)
        statusBarFrame.size.height += 20.0f;

    [self.statusBarView setFrame:statusBarFrame];

    [self.highLevelControlView setController:self];
    [self.lowLevelControlView setController:self];
    //[self.informationalView setController:self];
    [self.surroundingView setController:self];

    //[self.statusBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.highLevelControlView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.lowLevelControlView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //[self.informationalView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.surroundingView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.view insertSubview:self.statusBarView atIndex:0];
    [self.view insertSubview:self.highLevelControlView atIndex:0];
    [self.view insertSubview:self.lowLevelControlView atIndex:0];
    //[self.view insertSubview:self.informationalView atIndex:0];
    [self.view insertSubview:self.surroundingView atIndex:0];

    NSDictionary *viewsDictionary = @{@"statusBarView":self.statusBarView,
                                      @"highLevelControlView":self.highLevelControlView,
                                      @"lowLevelControlView":self.lowLevelControlView,
                                      //@"informationalView":self.informationalView,
                                      @"surroundingView":self.surroundingView};

    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[highLevelControlView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[statusBarView]-0-[highLevelControlView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];

    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[lowLevelControlView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[statusBarView]-0-[lowLevelControlView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
/*
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[informationalView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[statusBarView]-0-[informationalView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
*/
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[surroundingView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[statusBarView]-0-[surroundingView]-0-|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];

    //[self switchTapMenuToMain];
}

- (void)switchToBackground
{
    [self.highLevelControlView switchToBackground];
    [self.lowLevelControlView switchToBackground];
//    [self.informationalView switchToBackground];
    [self.surroundingView switchToBackground];
}

- (void)switchToForeground
{
    [self.highLevelControlView switchToForeground];
    [self.lowLevelControlView switchToForeground];
//    [self.informationalView switchToForeground];
    [self.surroundingView switchToForeground];
}

- (void)switchToInSight
{
    [[Plaques sharedPlaques] setCapturedPlaque:nil];
    [self.surroundingView switchToInSightView];
}

- (void)switchToOnMap
{
    [[Plaques sharedPlaques] setCapturedPlaque:nil];
    [self.surroundingView switchToOnMapView];
}

- (void)switchToManualNavigation
{
    [self.lowLevelControlView switchToManualNavigation];
}

- (void)createNewPlaquePressed
{
//    [self.informationalView setHidden:YES];
//    [self.lowLevelControlView setHidden:NO];

    [self.lowLevelControlView createNewPlaqueMode];
}


- (void)createNewPlaqueCancelled
{
//    [self.informationalView setHidden:NO];
//    [self.lowLevelControlView setHidden:YES];
}

- (void)createNewPlaqueConfirmed
{
    if ([[Authentificator sharedAuthentificator] profileRegistered] == NO) {
        ApplicationDelegate *application = (ApplicationDelegate *) [[UIApplication sharedApplication] delegate];
        [application askToCreateProfile];
    } else {
        Plaque *plaque = [[Plaques sharedPlaques] createNewPlaqueAtUserLocation];
        [[Plaques sharedPlaques] setPlaqueUnderEdit:plaque];

        //[self.lowLevelControlView editPlaqueMode:plaque];
    }
}

/*
- (void)switchTapMenuToPlaques
{
    [self.tapMenu clearMenu];

    [self.tapMenu addItemWithIconName:@"Annotation"
                              command:TapMenuPlaquesAddNew];
    [self.tapMenu addItemWithIconName:@"Annotation"
                              command:TapMenuPlaquesSearch];
}

- (void)switchTapMenuToPlaqueEditMode
{
    [self.tapMenu clearMenu];

    [self.tapMenu addItemWithIconName:@"ViewModeInSight"
                              command:TapMenuViewInSight
                            rowNumber:0];
    [self.tapMenu addItemWithIconName:@"ViewModeOnMap"
                              command:TapMenuViewOnMap
                            rowNumber:0];
    [self.tapMenu addItemWithIconName:@"ViewModeOnMap"
                              command:TapMenuViewOnRadar
                            rowNumber:0];

    [self.tapMenu addItemWithIconName:@"EditModeCoordinate"
                              command:TapMenuPlaqueEditModeCoordinate
                            rowNumber:1];
    [self.tapMenu addItemWithIconName:@"EditModeAltitude"
                              command:TapMenuPlaqueEditModeAltitude
                            rowNumber:1];
    [self.tapMenu addItemWithIconName:@"EditModeDirection"
                              command:TapMenuPlaqueEditModeDirection
                            rowNumber:1];
    [self.tapMenu addItemWithIconName:@"EditModeSize"
                              command:TapMenuPlaqueEditModeSize
                            rowNumber:1];

    [self.tapMenu addItemWithIconName:@"EditModeInscription"
                              command:TapMenuPlaqueEditModeInscription
                            rowNumber:2];
    [self.tapMenu addItemWithIconName:@"EditModeForegroundColor"
                              command:TapMenuPlaqueEditModeForegroundColor
                            rowNumber:2];
    [self.tapMenu addItemWithIconName:@"EditModeBackgroundColor"
                              command:TapMenuPlaqueEditModeBackgroundColor
                            rowNumber:2];
    [self.tapMenu addItemWithIconName:@"EditModeRemove"
                              command:TapMenuPlaqueEditModeRemove
                            rowNumber:2];
}
*/

#pragma mark - Edit mode
/*
- (void)openPlaqueEditMode:(PlaqueEditMode)editMode
{
    UIView *editModeView;
    CGRect bounds = self.view.bounds;
    CGSize editModeSize = CGSizeMake(280.0f, 240.0f);
    CGRect editModeFrame = CGRectMake(20.0f,
                                      CGRectGetHeight(bounds) - editModeSize.height - 72.0f,
                                      editModeSize.width,
                                      editModeSize.height);
    switch (editMode)
    {
        case PlaqueEditModeMotionControlled:
            editModeView = [[EditModeCoordinateView alloc] initWithFrame:editModeFrame];
            break;

        case PlaqueEditModeCoordinate:
            editModeView = [[EditModeCoordinateView alloc] initWithFrame:editModeFrame];
            break;

        case PlaqueEditModeAltitude:
            editModeView = [[EditModeAltitudeView alloc] initWithFrame:editModeFrame];
            break;

        case PlaqueEditModeDirection:
            editModeView = [[EditModeCoordinateView alloc] initWithFrame:editModeFrame];
            break;

        case PlaqueEditModeSize:
            editModeView = [[EditModeSizeView alloc] initWithFrame:editModeFrame];
            break;
    }

    [self.editModeView removeFromSuperview];

    self.editModeView = editModeView;

    [self.view insertSubview:self.editModeView
                belowSubview:self.tapMenu];

}
*/
/*
#pragma mark - TapMenu delegate

- (void)mainButtonPressed
{
    if (self.editModeView != nil)
        [self.editModeView removeFromSuperview];
}

- (void)exitButtonPressed
{
//    [self switchTapMenuToMain];

    if (self.editModeView != nil) {
        [self.editModeView removeFromSuperview];
        [[PlaqueCache sharedPlaqueCache] releaseCurrentPlaque];
    }
}


- (void)tapMenuItemPressed:(TapMenuCommand)command
{
    switch (command)
    {
        case TapMenuViewInSight:
            [self hidePlaquesOnMap];
            [self showPlaquesInSight];

            break;

        case TapMenuViewOnMap:
            [self hidePlaquesInSight];
            [self showPlaquesOnMap];

            break;

        case TapMenuViewOnRadar:
            [self hidePlaquesInSight];
            [self showPlaquesOnMap];

            break;

        case TapMenuMainPlaques:
            [self switchTapMenuToPlaques];
            [self.tapMenu openMenu];
            break;

        case TapMenuMainProfile:
        {
            ApplicationDelegate *application = (ApplicationDelegate *)[[UIApplication sharedApplication] delegate];
            [application openProfileForm];
            break;
        }

        case TapMenuPlaquesAddNew:
        {
            [self.tapMenu closeMenu];

            if ([[Authentificator sharedAuthentificator] profileRegistered] == NO) {
                ApplicationDelegate *application = [[UIApplication sharedApplication] delegate];
                [application askToCreateProfile];
            } else {
                //EditModeView *editModeView = [[EditModeView alloc] init];
                //ApplicationDelegate *application = (ApplicationDelegate *)[[UIApplication sharedApplication] delegate];
                //FullScreenSchield *shield = [application fullScreenSchield:editModeView];
                //[shield addSubview:editModeView];
                [self switchTapMenuToPlaqueEditMode];

                [[PlaqueCache sharedPlaqueCache] createNewPlaqueAtUserLocation];
                [self openPlaqueEditMode:PlaqueEditModeMotionControlled];
            }
            break;
        }

        case TapMenuPlaqueEditModeCoordinate:
            [self.tapMenu closeMenu];
            [self openPlaqueEditMode:PlaqueEditModeCoordinate];
            break;

        case TapMenuPlaqueEditModeAltitude:
            [self.tapMenu closeMenu];
            [self openPlaqueEditMode:PlaqueEditModeAltitude];
            break;

        case TapMenuPlaqueEditModeSize:
            [self.tapMenu closeMenu];
            [self openPlaqueEditMode:PlaqueEditModeSize];
            break;

        default:
            break;
    }
}
*/

@end
