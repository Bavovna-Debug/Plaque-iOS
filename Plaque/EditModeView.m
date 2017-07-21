//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "AppStore.h"
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

#undef FORTIFICATION

@interface EditModeView ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIView            *panelsView;
@property (strong, nonatomic) Panel             *selectorPanel;
@property (strong, nonatomic) Panel             *controlsPanel;

@end

@implementation EditModeView

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

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

    if (self.superview != nil)
    {
        [self startLocationManager];

        self.selectorPanel = self.leftPanel;
        self.controlsPanel = self.rightPanel;

        [self prepareSelectorPanel];
    }
    else
    {
        [self stopLocationManager];

        [[Plaques sharedPlaques] setPlaqueUnderEdit:nil];
    }
}

- (void)prepareSelectorPanel
{
    //CGSize buttonSize = [EditModeSelectButton buttonSize];
    //CGRect buttonFrame = CGRectMake(0.0f, 0.0f, buttonSize.width, buttonSize.height);

    EditModeSelectButton *coordinateButton      = [EditModeSelectButton button:EditModeCoordinate];
    EditModeSelectButton *altitudeButton        = [EditModeSelectButton button:EditModeAltitude];
    EditModeSelectButton *directionButton       = [EditModeSelectButton button:EditModeDirection];
    EditModeSelectButton *tiltButton            = [EditModeSelectButton button:EditModeTilt];
    EditModeSelectButton *sizeButton            = [EditModeSelectButton button:EditModeSize];
    EditModeSelectButton *backgroundColorButton = [EditModeSelectButton button:EditModeBackgroundColor];
    EditModeSelectButton *foregroundColorButton = [EditModeSelectButton button:EditModeForegroundColor];
    EditModeSelectButton *fontButton            = [EditModeSelectButton button:EditModeFont];
    EditModeSelectButton *inscriptionButton     = [EditModeSelectButton button:EditModeInscription];
#ifdef FORTIFICATION
    EditModeSelectButton *fortifyButton         = [EditModeSelectButton button:EditModeFortify];
#endif

    [self.selectorPanel addSubview:coordinateButton];
    [self.selectorPanel addSubview:altitudeButton];
    [self.selectorPanel addSubview:directionButton];
    [self.selectorPanel addSubview:tiltButton];
    [self.selectorPanel addSubview:sizeButton];
    [self.selectorPanel addSubview:backgroundColorButton];
    [self.selectorPanel addSubview:foregroundColorButton];
    [self.selectorPanel addSubview:fontButton];
    [self.selectorPanel addSubview:inscriptionButton];
#ifdef FORTIFICATION
    [self.selectorPanel addSubview:fortifyButton];
#endif

    [coordinateButton       setCenter:CGPointMake(32.0f, 48.0f)];
    [altitudeButton         setCenter:CGPointMake(96.0f, 48.0f)];
    [directionButton        setCenter:CGPointMake(160.0f, 48.0f)];
    [tiltButton             setCenter:CGPointMake(224.0f, 48.0f)];
    [sizeButton             setCenter:CGPointMake(288.0f, 48.0f)];
#ifdef FORTIFICATION
    [backgroundColorButton  setCenter:CGPointMake(32.0f, 144.0f)];
    [foregroundColorButton  setCenter:CGPointMake(96.0f, 144.0f)];
    [fontButton             setCenter:CGPointMake(160.0f, 144.0f)];
    [inscriptionButton      setCenter:CGPointMake(224.0f, 144.0f)];
    [fortifyButton          setCenter:CGPointMake(288.0f, 144.0f)];
#else
    [backgroundColorButton  setCenter:CGPointMake(64.0f, 144.0f)];
    [foregroundColorButton  setCenter:CGPointMake(128.0f, 144.0f)];
    [fontButton             setCenter:CGPointMake(192.0f, 144.0f)];
    [inscriptionButton      setCenter:CGPointMake(256.0f, 144.0f)];
#endif

    NSArray *buttons = [NSArray arrayWithObjects:coordinateButton,
                        altitudeButton,
                        directionButton,
                        tiltButton,
                        sizeButton,
                        backgroundColorButton,
                        foregroundColorButton,
                        fontButton,
                        inscriptionButton,
#ifdef FORTIFICATION
                        fortifyButton,
#endif
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

    [self.controlsPanel removeSubviews];

    CGRect controlsPanelSubviewFrame = self.controlsPanel.bounds;

    switch (button.editMode)
    {
        case EditModeCoordinate:
        {
            EditModeCoordinateSubview *subview =
            [[EditModeCoordinateSubview alloc] initWithLocationManager:self.locationManager];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeAltitude:
        {
            EditModeAltitudeSubview *subview =
            [[EditModeAltitudeSubview alloc] initWithLocationManager:self.locationManager];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeDirection:
        {
            EditModeDirectionSubview *subview =
            [[EditModeDirectionSubview alloc] initWithLocationManager:self.locationManager];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeTilt:
        {
            EditModeTiltSubview *subview =
            [[EditModeTiltSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeSize:
        {
            EditModeSizeSubview *subview =
            [[EditModeSizeSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeBackgroundColor:
        {
            EditModeColorSubview *subview =
            [[EditModeColorSubview alloc] initWithEditMode:EditModeColorBackground];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeForegroundColor:
        {
            EditModeColorSubview *subview =
            [[EditModeColorSubview alloc] initWithEditMode:EditModeColorForeground];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeFont:
        {
            EditModeFontSubview *subview =
            [[EditModeFontSubview alloc] init];

            [subview setFrame:controlsPanelSubviewFrame];
            [self.controlsPanel addSubview:subview];

            [self movePanelsLeft];

            break;
        }

        case EditModeInscription:
        {
            EditModeInscriptionView *subview =
            [[EditModeInscriptionView alloc] init];

            [subview setFrame:self.bounds];
            [self addSubview:subview];

            break;
        }

        case EditModeFortify:
        {
#if 0
            Plaques *plaques = [Plaques sharedPlaques];
            if ([plaques plaqueUnderFortification] != nil)
            {
                NSString *message = NSLocalizedString(@"MESSAGE_FORTIFICATION_IN_PROCESS", nil);
                NSString *okButton = NSLocalizedString(@"ALERT_BUTTON_OK", nil);

                UIAlertView *alertView =
                [[UIAlertView alloc] initWithTitle:nil
                                           message:message
                                          delegate:nil
                                 cancelButtonTitle:okButton
                                 otherButtonTitles:nil];
                
                [alertView setAlertViewStyle:UIAlertViewStyleDefault];
                [alertView show];
            }
            else
            {
                [plaques setPlaqueUnderFortification:self.plaque];

                [[AppStore sharedAppStore] purchaseFortification];
            }
#endif

            break;
        }
    }
}

@end
