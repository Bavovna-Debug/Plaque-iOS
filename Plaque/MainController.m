//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
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
    
    //[self simulatePlaques];

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
    [self.surroundingView switchToInSightView];
}

- (void)switchToOnMap
{
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
        ApplicationDelegate *application = [[UIApplication sharedApplication] delegate];
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

#pragma mark -

- (void)simulatePlaques
{
    Plaques *plaqueCache = [Plaques sharedPlaques];

    CLLocationManager *cl = [[CLLocationManager alloc] init];
    [cl startUpdatingLocation];
    CLLocation *location = [cl location];
    [cl stopUpdatingLocation];

    CLLocationCoordinate2D c = [[Navigator sharedNavigator] deviceCoordinate];
    c = [Navigator shift:c heading:270.0f distance:100.0f];
    Plaque *platte = [[Plaque alloc] initWithCoordinate:[location locationWithShiftFor:20.0f
                                                                              direction:180.0f].coordinate
                                          direction:140.0f
                                               text:@"Hier könnte Ihre Werbung sein"
                                              color:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];
    platte.altitude = [location altitude] - 2.0f;
    platte.tilt = 90.0f;
    platte.width = 5.0f;
    platte.height = 10.0f;
    [plaqueCache addPlaque:platte];

    Plaque *platte2 = [[Plaque alloc] initWithCoordinate:[location locationWithShiftFor:20.0f
                                                                             direction:180.0f].coordinate
                                              direction:140.0f
                                                   text:@"Hier könnte Ihre Werbung sein"
                                                  color:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];
    platte2.altitude = [location altitude] + 4.0f;
    platte2.tilt = -90.0f;
    platte2.width = 5.0f;
    platte2.height = 10.0f;
    [plaqueCache addPlaque:platte2];

    Plaque *p1 = [[Plaque alloc] initWithCoordinate:c//CLLocationCoordinate2DMake(48.647208f - 0.0001f, 9.008868f)
                                                    direction:45.0f
                                                         text:@"First 1"
                                                        color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p2 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 2"
                                              color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p3 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 3"
                                              color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p4 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 4"
                                              color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p5 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 5"
                                              color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p6 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 6"
                                              color:[UIColor redColor]];
    c = [Navigator shift:c heading:0.0f distance:200.0f];
    Plaque *p7 = [[Plaque alloc] initWithCoordinate:c
                                          direction:p1.direction
                                               text:@"First 7"
                                              color:[UIColor redColor]];

    [plaqueCache addPlaque:p3];
    [plaqueCache addPlaque:p4];
    [plaqueCache addPlaque:p5];
    [plaqueCache addPlaque:p6];
    [plaqueCache addPlaque:p7];
    [plaqueCache addPlaque:p2];
    [plaqueCache addPlaque:p1];

    p1 = [p1 copy]; p1.altitude += p1.size.height; [plaqueCache addPlaque:p1];
    p1 = [p1 copy]; p1.altitude += p1.size.height; [plaqueCache addPlaque:p1];
    p1 = [p1 copy]; p1.altitude += p1.size.height; [plaqueCache addPlaque:p1];

    p4 = [p4 copy]; p4.altitude += p4.size.height*2; [plaqueCache addPlaque:p4];
    p4 = [p4 copy]; p4.altitude += p4.size.height*2; [plaqueCache addPlaque:p4];
    p4 = [p4 copy]; p4.altitude += p4.size.height*2; [plaqueCache addPlaque:p4];
    p4 = [p4 copy]; p4.altitude += p4.size.height*2; [plaqueCache addPlaque:p4];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.646340f, 9.011490f)
                                                    direction:180.0f
                                                         text:@"REWE 1"
                                                        color:[UIColor redColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.646225f, 9.011580f)
                                                    direction:270.0f
                                                         text:@"REWE 2"
                                                        color:[UIColor redColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.645865f, 9.011580f)
                                                    direction:270.0f
                                                         text:@"REWE 3"
                                                        color:[UIColor redColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.645865f, 9.011580f)
                                                    direction:270.0f
                                                         text:@"REWE 3"
                                                        color:[UIColor blueColor]]];
    Plaque *l = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    l.altitude = 4.0f;
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.648016f, 9.009673f)
                                                    direction:180.0f
                                                         text:@"Second"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:500.0f];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.647816f, 9.009473f)
                                                    direction:160.0f
                                                         text:@"Third"
                                                        color:[UIColor greenColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:500.0f];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.648438f, 9.004909f)
                                                    direction:120.0f
                                                         text:@"Feld"
                                                        color:[UIColor blueColor]]];

    Plaque *gauss = [[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.647154f, 9.008953f)
                                                    direction:90.0f
                                                         text:@"GAUSS"
                                                        color:[UIColor yellowColor]];
    UIColor *x = gauss.backgroundColor;
    //NSLog(@"R:%d-%f G:%d-%f B:%d-%f A:%d-%f", red, red / 255.0f, green, green / 255.0f, blue, blue / 255.0f, alpha, alpha / 255.0f);

    [gauss setSize:CGSizeMake(4.0f, 4.0f)];
    gauss.altitude += 10.0f;
    [plaqueCache addPlaque:gauss];
    Plaque *gauss2 = [gauss clone];
    gauss2.altitude += 5.0f;
    [plaqueCache addPlaque:gauss2];

    Plaque *gauss3 = [gauss clone];
    gauss3.coordinate = [Navigator shift:gauss3.coordinate heading:270.0f distance:20.0f];
    gauss3.backgroundColor = [UIColor greenColor];
    [plaqueCache addPlaque:gauss3];
    Plaque *gauss4 = [gauss clone];
    gauss4.altitude += 5.0f;
    [plaqueCache addPlaque:gauss4];

    Plaque *gauss3b = [gauss clone];
    gauss3b.coordinate = [Navigator shift:gauss3b.coordinate heading:270.0f distance:40.0f];
    gauss3b.backgroundColor = [UIColor cyanColor];
    [plaqueCache addPlaque:gauss3b];
    Plaque *gauss4b = [gauss clone];
    gauss4b.altitude += 5.0f;
    [plaqueCache addPlaque:gauss4b];

    Plaque *office1 = [[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.647202f, 9.0081f)
                                             direction:110.0f
                                                  text:@"Office Nord"
                                                 color:[UIColor colorWithRed:0.400f green:0.400f blue:0.400f alpha:1.0f]];
    office1.altitude = 491.0f;
    [office1 setSize:CGSizeMake(25.0f, 15.0f)];

    Plaque *office2 = [[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.64685f, 9.00762f)
                                               direction:110.0f
                                                    text:@"Office Süd"
                                                   color:[UIColor colorWithRed:0.400f green:0.400f blue:0.400f alpha:1.0f]];
    office2.altitude = 491.0f;
    [office2 setSize:CGSizeMake(25.0f, 15.0f)];

    [plaqueCache addPlaque:office1];
    [plaqueCache addPlaque:office2];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.666343f, 9.039118f)
                                                    direction:340.0f
                                                         text:@"IBM Marktplatz"
                                                        color:[UIColor blueColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(20.0f, 12.0f)];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.666818f, 9.037713f)
                                                    direction:160.0f
                                                         text:@"IBM Haupttor"
                                                        color:[UIColor blueColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665550f, 9.036061f)
                                                    direction:310.0f
                                                         text:@"Rauchen führt zu einem langsamen und schmerzhaften Tod!"
                                                        color:[UIColor redColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664090f, 9.034730f)
                                                    direction:70.0f
                                                         text:@"RFI"
                                                        color:[UIColor greenColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.668154f, 9.03669f)
                                                    direction:160.0f
                                                         text:@"IBM Klub"
                                                        color:[UIColor blueColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.667686f, 9.040036f)
                                                    direction:240.0f
                                                         text:@"Ampel"
                                                        color:[UIColor yellowColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.666000f, 9.033893f)
                                                    direction:110.0f
                                                         text:@"Im Wald"
                                                        color:[UIColor blueColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:530.0f];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665642f, 9.034548f)
                                                    direction:70.0f
                                                         text:@"Gebäude 19"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:530.0f];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 500"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:500.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    [plaqueCache addPlaque:[(Plaque *)[plaqueCache.plaquesOnMap lastObject] copy]];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 510"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:510.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 515"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:515.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 525"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:525.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 530"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:530.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664713f, 9.035385f)
                                                    direction:70.0f
                                                         text:@"Gebäude 6 - 540"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setAltitude:540.0f];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(5.0f, 5.0f)];
    p1 = (Plaque *)[plaqueCache.plaquesOnMap lastObject];
    p1.location = [p1.location locationWithShiftFor:50.0f direction:180.0f];
    [plaqueCache addPlaque:p1];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665450f, 9.035444f)
                                                    direction:70.0f
                                                         text:@"Gebäude 5"
                                                        color:[UIColor purpleColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665139f, 9.035910f)
                                                    direction:70.0f
                                                         text:@"Gebäude 4"
                                                        color:[UIColor purpleColor]]];
    [(Plaque *)[plaqueCache.plaquesOnMap lastObject] setSize:CGSizeMake(10.0f, 10.0f)];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.664802f, 9.036688f)
                                                    direction:70.0f
                                                         text:@"Gebäude 3"
                                                        color:[UIColor purpleColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665287f, 9.037343f)
                                                    direction:70.0f
                                                         text:@"Gebäude 2"
                                                        color:[UIColor purpleColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665149f, 9.038314f)
                                                    direction:70.0f
                                                         text:@"Gebäude 1"
                                                        color:[UIColor purpleColor]]];
    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.665224f, 9.036189f)
                                                    direction:320.0f
                                                         text:@"Mijo zockt hier!"
                                                        color:[UIColor cyanColor]]];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.686881f, 9.003440f)
                                                    direction:90.0f
                                                         text:@"Böblingen Bahnhof"
                                                        color:[UIColor colorWithRed:0.400f green:0.400f blue:0.400f alpha:1.0f]]];

    [plaqueCache addPlaque:[[Plaque alloc] initWithCoordinate:CLLocationCoordinate2DMake(48.783559f, 9.181649f)
                                                    direction:180.0f
                                                         text:@"Stuttgart 21"
                                                        color:[UIColor colorWithRed:0.400f green:0.400f blue:0.400f alpha:1.0f]]];
}

@end
