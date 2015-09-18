//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "EditModeView.h"
#import "EditModeSelectButton.h"
#import "EditModeCoordinateSubview.h"
#import "EditModeAltitudeSubview.h"
#import "EditModeDirectionSubview.h"
#import "EditModeTiltSubview.h"
#import "EditModeSizeSubview.h"
#import "EditModeColorSubview.h"
#import "EditModeFontSubview.h"
#import "EditModeInscriptionView.h"
#import "Plaques.h"

@interface EditModeView ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIView *panelsView;
@property (strong, nonatomic) Panel *selectorPanel;
@property (strong, nonatomic) Panel *controlsPanel;

@end

@implementation EditModeView

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self initLocationManager];

    return self;
}

- (void)initLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDistanceFilter:1.0f];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    [self.locationManager setHeadingFilter:1.0f];
}

- (void)startLocationManager
{
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
}

- (void)stopLocationManager
{
    [self.locationManager setDelegate:nil];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil) {
        [self startLocationManager];

        self.selectorPanel = self.leftPanel;
        self.controlsPanel = self.rightPanel;

        [self prepareSelectorPanel];
    } else {
        [self stopLocationManager];

        [[Plaques sharedPlaques] setPlaqueUnderEdit:nil];
    }
}

- (void)prepareSelectorPanel
{
    //CGSize buttonSize = [EditModeSelectButton buttonSize];
    //CGRect buttonFrame = CGRectMake(0.0f, 0.0f, buttonSize.width, buttonSize.height);

    EditModeSelectButton *coordinateButton = [EditModeSelectButton button:EditModeCoordinate];
    EditModeSelectButton *altitudeButton = [EditModeSelectButton button:EditModeAltitude];
    EditModeSelectButton *directionButton = [EditModeSelectButton button:EditModeDirection];
    EditModeSelectButton *tiltButton = [EditModeSelectButton button:EditModeTilt];
    EditModeSelectButton *sizeButton = [EditModeSelectButton button:EditModeSize];
    EditModeSelectButton *backgroundColorButton = [EditModeSelectButton button:EditModeBackgroundColor];
    EditModeSelectButton *foregroundColorButton = [EditModeSelectButton button:EditModeForegroundColor];
    EditModeSelectButton *fontButton = [EditModeSelectButton button:EditModeFont];
    EditModeSelectButton *inscriptionButton = [EditModeSelectButton button:EditModeInscription];

    [self.selectorPanel addSubview:coordinateButton];
    [self.selectorPanel addSubview:altitudeButton];
    [self.selectorPanel addSubview:directionButton];
    [self.selectorPanel addSubview:tiltButton];
    [self.selectorPanel addSubview:sizeButton];
    [self.selectorPanel addSubview:backgroundColorButton];
    [self.selectorPanel addSubview:foregroundColorButton];
    [self.selectorPanel addSubview:fontButton];
    [self.selectorPanel addSubview:inscriptionButton];

    [coordinateButton setCenter:CGPointMake(32.0f, 48.0f)];
    [altitudeButton setCenter:CGPointMake(96.0f, 48.0f)];
    [directionButton setCenter:CGPointMake(160.0f, 48.0f)];
    [tiltButton setCenter:CGPointMake(224.0f, 48.0f)];
    [sizeButton setCenter:CGPointMake(288.0f, 48.0f)];
    [backgroundColorButton setCenter:CGPointMake(64.0f, 144.0f)];
    [foregroundColorButton setCenter:CGPointMake(128.0f, 144.0f)];
    [fontButton setCenter:CGPointMake(192.0f, 144.0f)];
    [inscriptionButton setCenter:CGPointMake(256.0f, 144.0f)];

    NSArray *buttons = [NSArray arrayWithObjects:coordinateButton,
                        altitudeButton,
                        directionButton,
                        tiltButton,
                        sizeButton,
                        backgroundColorButton,
                        foregroundColorButton,
                        fontButton,
                        inscriptionButton,
                        nil];

    for (EditModeSelectButton *button in buttons)
    {
        [button addTarget:self
                   action:@selector(editModeButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)editModeButtonPressed:(id)sender
{
    EditModeSelectButton *button = sender;

    EditMode editMode = button.editMode;

    if (editMode != EditModeInscription)
        [self movePanelsLeft];

    for (UIView *controlsPanelSubview in self.controlsPanel.subviews)
        [controlsPanelSubview removeFromSuperview];

    CGRect controlsPanelSubviewFrame = self.controlsPanel.bounds;

    switch (editMode)
    {
        case EditModeCoordinate:
        {
            EditModeCoordinateSubview *subview = [[EditModeCoordinateSubview alloc] init];

            subview.locationManager = self.locationManager;
            [self.locationManager setDelegate:subview];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeAltitude:
        {
            EditModeAltitudeSubview *subview = [[EditModeAltitudeSubview alloc] init];

            subview.locationManager = self.locationManager;
            [self.locationManager setDelegate:subview];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeDirection:
        {
            EditModeDirectionSubview *subview = [[EditModeDirectionSubview alloc] init];

            subview.locationManager = self.locationManager;
            [self.locationManager setDelegate:subview];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeTilt:
        {
            EditModeTiltSubview *subview = [[EditModeTiltSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeSize:
        {
            EditModeSizeSubview *subview = [[EditModeSizeSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeBackgroundColor:
        {
            EditModeColorSubview *subview = [[EditModeColorSubview alloc] init];
            subview.editModeColor = EditModeColorBackground;

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeForegroundColor:
        {
            EditModeColorSubview *subview = [[EditModeColorSubview alloc] init];
            subview.editModeColor = EditModeColorForeground;

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeFont:
        {
            EditModeFontSubview *subview = [[EditModeFontSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            break;
        }

        case EditModeInscription:
        {
            EditModeInscriptionView *subview = [[EditModeInscriptionView alloc] init];

            [subview setFrame:self.bounds];
            [self addSubview:subview];

            break;
        }
    }
}

@end
