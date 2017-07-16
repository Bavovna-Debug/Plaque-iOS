//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#ifndef Definitions_h
#define Definitions_h

#define INSIGHTVIEW_TILT_BY_ACCURACY
#define INSIGHTVIEW_TURN_BY_ACCURACY

#ifdef DEBUG

#define VERBOSE

// Communicator
//
#define VerboseCommunicationSocketConnection
#define VerboseCommunicationSocket
#define VerboseCommunicationDialogue
#define VerboseCommunicationEnqueue
#define VerboseCommunicationReadData
#define VerboseCommunicationProcessCards
#define VerboseCommunicationDumpReceivedPayload

// InSightView
//
#undef VerboseInSightViewCamera
#define VerboseInSightViewPlaqueDidAppear
#undef VerboseInSightPlaqueRedraw

// Plaque
//
#undef VerbosePlaqueDbSelect
#define VerbosePlaqueDbInsert
#define VerbosePlaqueUpload
#define VerbosePlaqueChange

// Plaques
//
#define VerbosePlaquesBroadcast
#define VerbosePlaquesLocationManager
#define VerbosePlaquesRadar
#define VerbosePlaquesRadarDetails
#define VerbosePlaques
#define VerbosePlaquesAddPlaque
#define VerbosePlaquesWorkdesk
#define VerbosePlaquesDatabase

// StatusBar
#define VerboseStatusBarMessages

#endif // DEBUG

// ApplicationDelegate
//
#define MinimumBackgroundFetchInterval      120.0f
#define AlertDoYouWantToCreateProfile       15

// AppStore
//
//#define RemoveAdsProductIdentifier          @"Zeppelinium.Plaque.Unlock"

// Authentificator
//
#ifdef DEBUG
#define DeviceTokenKey                      @"DeviceToken2"
#define SessionTokenKey                     @"SessionToken2"
#define ProfileTokenKey                     @"ProfileToken2"
#define NotificationsTokenKey               @"NotificationsToken2"
#else
#define DeviceTokenKey                      @"DeviceToken"
#define SessionTokenKey                     @"SessionToken"
#define ProfileTokenKey                     @"ProfileToken"
#define NotificationsTokenKey               @"NotificationsToken"
#endif

// Communicator
//
#define ReconnectIntervalIfHandshakeFailed  1.0f

#define BytesPerSendFragment                512

#define FlushQueueBackgroundInterval        1800.0f
#define FlushQueueForegroundInterval        5.0f

#define TimeoutOnDialogueTransmit           5.0f
#define TimeoutOnAnticipantTransmit         5.0f
#define TimeoutOnWaitingForPaquetTransmit   20.0f
#define TimeoutOnWaitingForPaquetReceive    60.0f

#define TimerIntervalProcessInputPieces     3.0f

// Control Panel
//
#define ControlPanelOpenDuration            0.25f

// Database
//
#ifdef DEBUG
#define DatabaseName                        @"plaque3"
#define TemplateName                        @"plaque"
#else
#define DatabaseName                        @"plaque"
#define TemplateName                        @"plaque"
#endif

// EditModeFontSubview
//
#define EditModeMinFontSize                 0.05f
#define EditModeMaxFontSize                 0.6f

// EditModeSizeSubview
//
#define EditModeMinPlaqueWidth              0.5f
#define EditModeMaxPlaqueWidth              12.0f
#define EditModeMinPlaqueHeight             0.5f
#define EditModeMaxPlaqueHeight             12.0f

// FullScreenShield
//
#define DisappearDuration                   0.2f

// Gyro
//
#ifdef INSIGHTVIEW_TILT_BY_ACCURACY
#define TiltAccuracy                        0.05f
#endif

#ifdef INSIGHTVIEW_TURN_BY_ACCURACY
#define TurnAccuracy                        0.05f
#endif

// FlyMenu
//
#define FlyMenuAnimationDurationOpen        0.2f
#define FlyMenuAnimationDurationClose       0.4f

// HighLevelControlView
//
#define HighLevelAnimationDurationOpen      0.4f
#define HighLevelAnimationDurationClose     0.4f

// InSightView
//
#define CaptureInterval                     1.0f
#define CaptureOffAfterSelectionByUserInterval  5.0f

// NavigationPanel
//
#define CameraUpdateInterval                0.5f

// Navigator
//
#define ForegroundAccuracy                  kCLLocationAccuracyBestForNavigation
#define ForegroundDistance                  1.0f
#define BackgroundAccuracy                  kCLLocationAccuracyHundredMeters
#define BackgroundDistance                  100.0f

// PanelTwin
//
#define PanelTwinMoveLeftDuration           0.3f
#define PanelTwinMoveRightDuration          0.3f

// Plaque
//
#define PlaqueBorderWidth                   2.0f
#define PlaqueCornerRadius                  5.0f

#define DefaultPlaqueWidth                  4.0f
#define DefaultPlaqueHeight                 2.0f

// PlaqueAnnotation
//
#define PlaqueSizeFixedScaleFactor          5.0f

// Plaques
//
#define MinimumDistanceForDisplacement      500.0f
#define DistanceToNewPlaqueOnCreation       20.0f
#define DefaultOnRadarRange                 10000.0f
#define DefaultInSightRange                 2000.0f

#define SaveToDatabaseInterval              3.0f
#define WorkdeskUploadInterval              2.0f

#define MaxPlaquesPerDownloadRequest        20

#ifdef DEBUG
#define PlaquesCacheKey                     @"PlaquesCache6"
#define PlaquesOnWorkdeskKey                @"PlaquesOnWorkdesk8"
#else
#define PlaquesCacheKey                     @"PlaquesCache"
#define PlaquesOnWorkdeskKey                @"PlaquesOnWorkdesk"
#endif

#define PlaquesXMLTarget                    @"vp"
#define PlaquesXMLVersion                   @"1.0"

// ProfileViewController
//
#define ProfileNameValidateInterval         2.0f

// Settings
//
#ifdef DEBUG
#define TapMenuOnlyIconsKey                 @"TapMenuOnlyIcons"
#define LastOwnObjectIdKey                  @"LastOwnObjectId"
/*
 #define OnRadarRevisionKey                  @"OnRadarRevision2"
 #define InSightRevisionKey                  @"InSightRevision2"
 #define OnMapRevisionKey                    @"OnMapRevision2"
 */
#else
#define TapMenuOnlyIconsKey                 @"TapMenuOnlyIcons"
#define LastOwnObjectIdKey                  @"LastOwnObjectId"
/*
 #define OnRadarRevisionKey                  @"OnRadarRevision"
 #define InSightRevisionKey                  @"InSightRevision"
 #define OnMapRevisionKey                    @"OnMapRevision"
 */
#endif

// StatusBarMessage
//
#define NextMessageInterval                 2.0f
#define LastMessageInterval                 5.0f
#define SlideMessageOffInterval             0.5f

// TapMenu
//
#define AlphaMainButtonNormal               1.0f
#define AlphaMainButtonOpenned              0.4f
#define TapMenuAnimationDurationOpen        0.4f
#define TapMenuAnimationDurationClose       0.4f

#define DistanceBetweenRows                 8.0f

#endif /* Definitions_h */
