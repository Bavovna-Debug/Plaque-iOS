//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#import "PlaqueEditView.h"
#import "Authentificator.h"
#import "Navigator.h"
#import "Plaques.h"
#import "MainController.h"
#import "InSightView.h"
#import "Paquet.h"
#import "InSightPlaque.h"

#ifdef DEBUG
#undef VERBOSE_CAMERA
#define PLAQUE_DID_APPEAR
#endif

#define TiltAccuracy 0.5f
#define TurnAccuracy 0.5f

#define CaptureInterval                         1.0f
#define CaptureOffAfterSelectionByUserInterval  5.0f

@interface InSightView () <CLLocationManagerDelegate, PlaquesDelegate>

@property (weak,   nonatomic) MainController *controller;
@property (strong, nonatomic) UIImagePickerController *cameraController;
@property (assign, nonatomic) Boolean cameraAuthorized;
@property (assign, nonatomic) CGFloat cameraScaleFactor;

@property (strong, nonatomic) NSMutableArray *inSightPlaques;
@property (strong, nonatomic) NSLock *recalculateLock;
@property (strong, nonatomic) NSLock *refreshLock;
@property (strong, nonatomic) NSLock *tiltLock;
@property (strong, nonatomic) NSLock *turnLock;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) CLHeading *heading;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, nonatomic) CGFloat tilt;
@property (assign, nonatomic) CGFloat turn;

@property (strong, nonatomic) NSTimer *captureTimer;

@end

@implementation InSightView
{
    BOOL running;
    CGFloat tiltFactor;
    CGFloat tiltOffset;
}

- (id)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self == nil)
        return nil;

    self.controller = (MainController *)controller;

    self.inSightPlaques = [NSMutableArray array];

    self.recalculateLock = [[NSLock alloc] init];
    self.refreshLock = [[NSLock alloc] init];
    self.tiltLock = [[NSLock alloc] init];
    self.turnLock = [[NSLock alloc] init];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:1.0f]];

    [self checkCameraAuthorization];

    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager setDistanceFilter:1.0f];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager setHeadingFilter:1.0f];
    self.locationManager = locationManager;

    self.motionManager = [[CMMotionManager alloc] init];

    self.rangeInSight = 2000.0f;

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil) {
        self.container = [CALayer layer];
        [self.container setBackgroundColor:[[UIColor clearColor] CGColor]];

        [self.layer addSublayer:self.container];

        [self resume];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.superview != nil) {
        CGRect containterFrame = self.bounds;
        containterFrame.origin.y = -containterFrame.size.height;
        containterFrame.size.height *= 3.0f;

        if (CGRectEqualToRect(self.container.frame, containterFrame) == NO)
            [self.container setFrame:containterFrame];

        self.fullScreenWidth = floorf(CGRectGetWidth(self.bounds) / 10.0f);
        self.fullScreenMeterDistance = 1.5f;
        self.fullScreenAngle = 35.0f;
    }
}

- (void)pause
{
    [super pause];

    if (running == NO)
        return;

    [self stopCapturer];

    [[Plaques sharedPlaques] setPlaquesDelegate:nil];

    [self stopLocationManager];
    [self stopMotionManager];

    [self switchCameraOff];

    running = NO;
}

- (void)resume
{
    [super resume];
    
    if (running == YES)
        return;

    [self switchCameraOn];

    [self startLocationManager];
    [self startMotionManager];

    [[Plaques sharedPlaques] setPlaquesDelegate:self];

    [self startCapturerWithInterval:CaptureInterval];

    [self refreshPlaquesInSight];

    [self redrawPlaquesInSight];

    running = YES;
}

- (void)startLocationManager
{
    [self.locationManager setDelegate:self];
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];

    self.location = self.locationManager.location;
    self.heading = self.locationManager.heading;
}

- (void)stopLocationManager
{
    [self.locationManager setDelegate:nil];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

- (void)startMotionManager
{
    [self.motionManager setAccelerometerUpdateInterval:0.25f];

    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
     {
         //CGFloat tilt = correctDegrees(radiandsToDegrees(-atan2f(accelerometerData.acceleration.y, accelerometerData.acceleration.z)) - 90.0f);
         CGFloat tilt = atan2f(accelerometerData.acceleration.y, accelerometerData.acceleration.z) + M_PI_2;

         CGFloat turn = correctDegrees(radiandsToDegrees(-atan2f(accelerometerData.acceleration.x, accelerometerData.acceleration.y)) - 180.0f);

         //if (round(tilt / TiltAccuracy) != round(self.tilt / TiltAccuracy))
         //{
             self.tilt = tilt;
             [self tiltUp];
         //}

         if (round(turn / TurnAccuracy) != round(self.turn / TurnAccuracy))
         {
             self.turn = turn;
         }

         if (error)
             NSLog(@"%@", error);
     }];
}

- (void)stopMotionManager
{
    [self.motionManager stopAccelerometerUpdates];
}

- (void)startCapturerWithInterval:(NSTimeInterval)interval
{
    self.captureTimer =
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(fireCapture:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)stopCapturer
{
    NSTimer *captureTimer = self.captureTimer;
    if (captureTimer != nil) {
        self.captureTimer = nil;
        [captureTimer invalidate];
    }
}

- (void)fireCapture:(NSTimer *)timer
{
    Plaque *capturedPlaque = nil;
    CGFloat closedDistanceToAim = CGRectGetWidth(self.bounds) / 2;

    for (InSightPlaque *inSightPlaque in self.inSightPlaques)
    {
        Plaque *plaque = inSightPlaque.plaque;

        // If corresponding plaque is chained ...
        //
        if (plaque.cloneChain != nil) {
            Plaques *plaques = [Plaques sharedPlaques];

            // ... then skip this plaque if it is not the one on workdesk.
            //
            if ([plaques.plaquesOnWorkdesk containsObject:plaques] == NO)
                continue;
        }
        CGFloat distanceToAim = [inSightPlaque distanceToAimWithTiltOffset:tiltOffset];
        if (distanceToAim < closedDistanceToAim) {
            closedDistanceToAim = distanceToAim;
            capturedPlaque = inSightPlaque.plaque;
        }
    }

    [[Plaques sharedPlaques] setCapturedPlaque:capturedPlaque];

    if (timer.timeInterval == CaptureOffAfterSelectionByUserInterval) {
        [self stopCapturer];
        [self startCapturerWithInterval:CaptureInterval];
    }
}

#pragma mark -

- (void)tiltUp
{
    if ([self.tiltLock tryLock] == FALSE)
        return;

    if ((self.tilt < -(M_PI_2 / 90.0f * 50.0f)) || (self.tilt > (M_PI_2 / 90.0f * 40.0f))) {
        [self.tiltLock unlock];
        return;
    }

    CGRect bounds = self.bounds;
    tiltFactor = sinf(self.tilt);
    tiltOffset = roundf(CGRectGetHeight(bounds) * tiltFactor);
    [self.container setPosition:CGPointMake(CGRectGetMidX(bounds),
                                            CGRectGetMidY(bounds) + tiltOffset)];

    [self.tiltLock unlock];
}

- (void)refreshPlaquesInSight
{
    [self.refreshLock lock];

    NSMutableArray *plaquesAlreadyInSight = [NSMutableArray arrayWithArray:self.inSightPlaques];
    NSMutableArray *plaquesNewInSight = [NSMutableArray array];

    Plaques *plaques = [Plaques sharedPlaques];

    for (Plaque *plaque in plaques.plaquesInSight)
    {
        InSightPlaque *existingInSightPlaque = nil;
        for (InSightPlaque *inSightPlaque in plaquesAlreadyInSight)
        {
            if (inSightPlaque.plaque == plaque) {
                existingInSightPlaque = inSightPlaque;
                break;
            }
        }

        if (existingInSightPlaque == nil) {
            InSightPlaque *inSightPlaque = [[InSightPlaque alloc] initWithParentView:self];
            [inSightPlaque setPlaque:plaque];
            [plaquesNewInSight addObject:inSightPlaque];
        } else {
            [plaquesAlreadyInSight removeObject:existingInSightPlaque];
        }
    }

    for (Plaque *plaque in plaques.plaquesOnWorkdesk)
    {
        InSightPlaque *existingInSightPlaque = nil;
        for (InSightPlaque *inSightPlaque in plaquesAlreadyInSight)
        {
            if (inSightPlaque.plaque == plaque) {
                existingInSightPlaque = inSightPlaque;
                break;
            }
        }

        if (existingInSightPlaque == nil) {
            InSightPlaque *inSightPlaque = [[InSightPlaque alloc] initWithParentView:self];
            [inSightPlaque setPlaque:plaque];
            [plaquesNewInSight addObject:inSightPlaque];
        } else {
            [plaquesAlreadyInSight removeObject:existingInSightPlaque];
        }
    }

    for (InSightPlaque *inSightPlaqueToDelete in plaquesAlreadyInSight)
    {
        [inSightPlaqueToDelete.plaqueLayer removeFromSuperlayer];
        [self.inSightPlaques removeObject:inSightPlaqueToDelete];
    }

    for (InSightPlaque *inSightPlaqueToInsert in plaquesNewInSight)
    {
        [inSightPlaqueToInsert setNeedRedraw:YES];
        [self.inSightPlaques addObject:inSightPlaqueToInsert];
    }

    [plaquesAlreadyInSight removeAllObjects];
    [plaquesNewInSight removeAllObjects];

    [self.refreshLock unlock];

    [self recalculateAllInSightPlaquesForLocation:self.locationManager.location];
    [self recalculateAllInSightPlaquesForHeading:self.locationManager.heading];
}

- (void)recalculateAllInSightPlaquesForLocation:(CLLocation *)location
{
    [self.recalculateLock lock];

    for (InSightPlaque *inSightPlaque in self.inSightPlaques)
        [self recalculateInSightPlaque:inSightPlaque
                           forLocation:location];

    [self.recalculateLock unlock];
}

- (void)recalculateInSightPlaque:(InSightPlaque *)inSightPlaque
                     forLocation:(CLLocation *)location
{
    Plaque *plaque = inSightPlaque.plaque;

    CLLocationDirection directionFromUser;
    CLLocationDistance distanceToUser;
    CLLocationDistance altitudeOverUser;

    directionFromUser = [plaque.location directionRelativeFrom:self.location
                                                       heading:self.heading.trueHeading];

    distanceToUser = [plaque.location distanceFromLocation:self.location];

    if ([plaque altitude] == 0.0f) {
        altitudeOverUser = 0.0f;
    } else {
        altitudeOverUser = [plaque altitude] - self.location.altitude;
    }

    [inSightPlaque setDirectionFromUser:directionFromUser];
    [inSightPlaque setDistanceToUser:distanceToUser];
    [inSightPlaque setAltitudeOverUser:altitudeOverUser];
}

- (void)recalculateAllInSightPlaquesForHeading:(CLHeading *)heading
{
    [self.recalculateLock lock];

    for (InSightPlaque *inSightPlaque in self.inSightPlaques)
        [self recalculateInSightPlaque:inSightPlaque
                            forHeading:heading];

    [self.recalculateLock unlock];
}

- (void)recalculateInSightPlaque:(InSightPlaque *)inSightPlaque
                      forHeading:(CLHeading *)heading
{
    Plaque *plaque = inSightPlaque.plaque;

    CLLocationDirection directionFromUser = [plaque.location directionRelativeFrom:self.location
                                                                           heading:self.heading.trueHeading];

    [inSightPlaque setDirectionFromUser:directionFromUser];

    if ([plaque directed] == YES) {
        CLLocationDirection rotationOnScreen;

        rotationOnScreen = correctDegrees(plaque.direction - oppositeDirection(self.heading.trueHeading));

        [inSightPlaque setRotationOnScreen:rotationOnScreen];
    }
}

- (void)redrawPlaquesInSight
{
    [self.refreshLock lock];

    for (InSightPlaque *inSightPlaque in self.inSightPlaques)
    {
        if ([inSightPlaque needRedraw] == YES)
            [inSightPlaque redraw];
    }

    [self.refreshLock unlock];
}

- (void)redrawPlaqueInSight:(InSightPlaque *)inSightPlaque
{
    [self.refreshLock lock];

    [inSightPlaque redraw];

    [self.refreshLock unlock];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:nil];

    CALayer *layer = [(CALayer *)self.layer.presentationLayer hitTest:point];
    layer = layer.modelLayer;
    if (layer != self.container) {
        //
        // Get the high level layer.
        //
        while (layer.delegate == nil) {
            layer = layer.superlayer;
            if (layer == nil)
                break;
        }

        // If a layer under touch belongs to some InSightPlaque then capture it
        // and deactivate automatic capturer for a while.
        //
        if ((layer != nil) && (layer.superlayer == self.container)) {
            [self stopCapturer];
            [self startCapturerWithInterval:CaptureOffAfterSelectionByUserInterval];

            InSightPlaque *touchedInSightPlaque = layer.delegate;
            [[Plaques sharedPlaques] setCapturedPlaque:touchedInSightPlaque.plaque];
        }
    }
}

#pragma mark - LocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];

    self.location = location;

    [self recalculateAllInSightPlaquesForLocation:location];

    [self redrawPlaquesInSight];
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    self.heading = newHeading;

    [self recalculateAllInSightPlaquesForHeading:newHeading];

    [self redrawPlaquesInSight];
}

- (InSightPlaque *)inSightPlaqueByPlaque:(Plaque *)plaque
{
    for (InSightPlaque *inSightPlaque in self.inSightPlaques)
        if (inSightPlaque.plaque == plaque)
            return inSightPlaque;

    return nil;
}

#pragma mark - Plaques delegate

- (void)plaqueDidAppearInSight:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [[InSightPlaque alloc] initWithParentView:self];
    [inSightPlaque setPlaque:plaque];

    [self recalculateInSightPlaque:inSightPlaque
                       forLocation:self.location];
    [self recalculateInSightPlaque:inSightPlaque
                        forHeading:self.heading];

    [self redrawPlaqueInSight:inSightPlaque];

    [self.inSightPlaques addObject:inSightPlaque];

#ifdef PLAQUE_DID_APPEAR
    NSLog(@"Plaque did appear in sight %@",
          [inSightPlaque.plaque.plaqueToken UUIDString]);
#endif
}

- (void)plaqueDidDisappearFromInSight:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil) {
        [self.refreshLock lock];
        [inSightPlaque didDisappear];
        [self.inSightPlaques removeObject:inSightPlaque];
        [self.refreshLock unlock];
    }
}

- (void)plaqueDidAppearOnWorkdesk:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [[InSightPlaque alloc] initWithParentView:self];
    [inSightPlaque setPlaque:plaque];

    [self recalculateInSightPlaque:inSightPlaque
                       forLocation:self.location];
    [self recalculateInSightPlaque:inSightPlaque
                        forHeading:self.heading];

    [self redrawPlaqueInSight:inSightPlaque];

    [self.inSightPlaques addObject:inSightPlaque];
}

- (void)plaqueDidDisappearFromWorkdesk:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil) {
        [self.refreshLock lock];
        [inSightPlaque didDisappear];
        [self.inSightPlaques removeObject:inSightPlaque];
        [self.refreshLock unlock];
    }
}

- (void)plaqueDidChangeLocation:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil) {
        [self recalculateInSightPlaque:inSightPlaque
                           forLocation:nil];

        [inSightPlaque didChangeLocation];

        [self redrawPlaqueInSight:inSightPlaque];
    }
}

- (void)plaqueDidChangeOrientation:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil) {
        [self recalculateInSightPlaque:inSightPlaque
                            forHeading:nil];

        [inSightPlaque didChangeOrientation];

        [self redrawPlaqueInSight:inSightPlaque];
    }
}

- (void)plaqueDidResize:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didResize];
}

- (void)plaqueDidChangeColor:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didChangeColor];
}

- (void)plaqueDidChangeFont:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didChangeFont];
}

- (void)plaqueDidChangeInscription:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didChangeInscription];
}

- (void)plaqueDidBecomeCaptured:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didBecomeCaptured];
}

- (void)plaqueDidReleaseCaptured:(Plaque *)plaque
{
    InSightPlaque *inSightPlaque = [self inSightPlaqueByPlaque:plaque];
    if (inSightPlaque != nil)
        [inSightPlaque didReleaseCaptured];
}

#pragma mark - Camera

- (void)checkCameraAuthorization
{
    NSString *mediaType = AVMediaTypeVideo;

    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted) {
                self.cameraAuthorized = YES;
            } else {
                self.cameraAuthorized = NO;
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [[[UIAlertView alloc] initWithTitle:@"AVCam!"
                                                message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                });
            }
        }];
    }
}

- (void)switchCameraOn
{
    if (self.cameraController != nil)
        return;

    @try {
        self.cameraController = [[UIImagePickerController alloc] init];
        [self.cameraController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self.cameraController setCameraDevice:UIImagePickerControllerCameraDeviceRear];
        [self.cameraController setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
        [self.cameraController setShowsCameraControls:NO];
        [self.cameraController setToolbarHidden:YES];
        [self.cameraController setNavigationBarHidden:YES];
        [self.cameraController setWantsFullScreenLayout:YES];
        [self.cameraController.view setAlpha:0.4f];

        CGRect screenBounds = [[UIScreen mainScreen] bounds];

        CGFloat cameraAspectRatio = 4.0f / 3.0f;

        CGFloat cameraViewHeight = CGRectGetWidth(screenBounds) * cameraAspectRatio;

        self.cameraScaleFactor = CGRectGetHeight(screenBounds) / cameraViewHeight;

        CGAffineTransform transform = CGAffineTransformMakeTranslation(0, (CGRectGetHeight(screenBounds) - cameraViewHeight) / 2.0);
        transform = CGAffineTransformScale(transform, self.cameraScaleFactor, self.cameraScaleFactor);
        [self.cameraController setCameraViewTransform:transform];

        [self.cameraController.view setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self insertSubview:self.cameraController.view atIndex:0];

        NSDictionary *viewsDictionary = @{@"cameraView":self.cameraController.view};
        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:|-0-[cameraView]-0-|"
                              options:0
                              metrics:nil
                              views:viewsDictionary]];
        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"V:|-0-[cameraView]-0-|"
                              options:0
                              metrics:nil
                              views:viewsDictionary]];

#ifdef VERBOSE_CAMERA
        NSLog(@"Camera aspect ratio: %f", cameraAspectRatio);
#endif
    }
    @catch (NSException *exception) {
        NSLog(@"Camera exception: %@", exception);
    }
}

- (void)switchCameraOff
{
    if (self.cameraController != nil) {
        [self.cameraController.view removeFromSuperview];
        self.cameraController = nil;
    }
}

@end
