//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Definitions.h"
#import "EditModeSizeSubview.h"
#import "Plaques.h"

#include "Definitions.h"

@interface EditModeSizeSubview ()

@property (weak,   nonatomic) Plaque    *plaque;
@property (strong, nonatomic) UIView    *backgroundView;
@property (strong, nonatomic) UIView    *controlsView;
@property (strong, nonatomic) CALayer   *plaqueLayer;
@property (strong, nonatomic) UILabel   *widthValue;
@property (strong, nonatomic) UILabel   *heightValue;
@property (strong, nonatomic) UIView    *touchPadWidth;
@property (strong, nonatomic) UIView    *touchPadHeight;
@property (assign, nonatomic) Boolean   resizing;
@property (strong, nonatomic) NSTimer   *touchPadTimer;
@property (strong, nonatomic) NSTimer   *controlsTimer;

@end

@implementation EditModeSizeSubview
{
    Boolean controlsAnimationDirection;
    CGFloat changeWidthPerTimerTick;
    CGFloat changeHeightPerTimerTick;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    self.resizing = NO;

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil)
    {
        [self preparePanel];
    }
    else
    {
        [self destroyPanel];
    }
}

- (void)preparePanel
{
    [self setBackgroundColor:[UIColor clearColor]];

    // Setup backround.
    //
    {
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeSizeBackground"]];
        [self addSubview:self.backgroundView];

        self.controlsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeSizeControls"]];
        [self addSubview:self.controlsView];

        controlsAnimationDirection = FALSE;

        [self.controlsView setAlpha:EditModeControlsAnimationAlphaLow];

        [self.controlsView.layer setShadowColor:[[UIColor blueColor] CGColor]];
        [self.controlsView.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
        [self.controlsView.layer setShadowOpacity:EditModeControlsShadowOpacity];

        self.controlsTimer =
        [NSTimer scheduledTimerWithTimeInterval:EditModeControlsAnimationDuration
                                         target:self
                                       selector:@selector(fireControlsTimer:)
                                       userInfo:nil
                                        repeats:YES];
        [self.controlsTimer fire];
    }

    CGRect bounds = self.bounds;
    CGRect valueFrame = CGRectMake(0.0f, 0.0f, 96.0f, 20.0f);
    CGPoint widthValuePoint = CGPointMake(95.0f, 115.0f);
    CGPoint heightValuePoint = CGPointMake(210.0f, 55.0f);

    CGRect touchPadWidthFrame =
    CGRectMake(CGRectGetMinX(bounds),
               CGRectGetMaxY(bounds) - 80.0f,
               CGRectGetMaxX(bounds) - 80.0f,
               80.0f);

    CGRect touchPadHeightFrame =
    CGRectMake(CGRectGetMaxX(bounds) - 80.0f,
               CGRectGetMinY(bounds),
               80.0f,
               CGRectGetHeight(bounds));

    UILabel *widthValue = [[UILabel alloc] init];
    [widthValue setFrame:valueFrame];
    [widthValue setCenter:widthValuePoint];
    [widthValue setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [widthValue setTextAlignment:NSTextAlignmentCenter];
    [widthValue setBackgroundColor:[UIColor clearColor]];
    [widthValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:widthValue];

    UILabel *heightValue = [[UILabel alloc] init];
    [heightValue setFrame:valueFrame];
    [heightValue setCenter:heightValuePoint];
    [heightValue setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [heightValue setTextAlignment:NSTextAlignmentCenter];
    [heightValue setBackgroundColor:[UIColor clearColor]];
    [heightValue setTextColor:[UIColor darkTextColor]];
    [self addSubview:heightValue];

    UIView *touchPadWidth = [[UIView alloc] initWithFrame:touchPadWidthFrame];
    [touchPadWidth setBackgroundColor:[UIColor clearColor]];
    [touchPadWidth setOpaque:YES];
    [self addSubview:touchPadWidth];

    UIView *touchPadHeight = [[UIView alloc] initWithFrame:touchPadHeightFrame];
    [touchPadHeight setBackgroundColor:[UIColor clearColor]];
    [touchPadHeight setOpaque:YES];
    [self addSubview:touchPadHeight];

    self.widthValue = widthValue;
    self.heightValue = heightValue;
    self.touchPadWidth = touchPadWidth;
    self.touchPadHeight = touchPadHeight;

    self.touchPadTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.1f
                                     target:self
                                   selector:@selector(fireTouchPadTimer:)
                                   userInfo:nil
                                    repeats:YES];
    [self.touchPadTimer fire];

    [self refreshValues];
}

- (void)destroyPanel
{
    NSTimer *touchPadTimer = self.touchPadTimer;
    if (touchPadTimer != nil)
    {
        [touchPadTimer invalidate];
    }
}

- (void)fireControlsTimer:(NSTimer *)timer
{
    if (self.resizing == NO)
    {
        [UIView beginAnimations:nil
                        context:nil];
        [UIView setAnimationDuration:EditModeControlsAnimationDuration];

        if (controlsAnimationDirection == FALSE)
        {
            [self.controlsView setAlpha:EditModeControlsAnimationAlphaHigh];

            controlsAnimationDirection = TRUE;
        }
        else
        {
            [self.controlsView setAlpha:EditModeControlsAnimationAlphaLow];

            controlsAnimationDirection = FALSE;
        }

        [UIView commitAnimations];
    }
}

- (void)recalculateWidthParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPadWidth.bounds;
    CGFloat padCenter = CGRectGetMidX(padBounds);
    CGFloat moveVector = fingerPoint.x - padCenter;

    changeWidthPerTimerTick = moveVector / padCenter;

    changeHeightPerTimerTick = 0.0f;
}

- (void)recalculateHeightParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPadHeight.bounds;
    CGFloat padCenter = CGRectGetMidY(padBounds);
    CGFloat moveVector = fingerPoint.y - padCenter;

    changeHeightPerTimerTick = -(moveVector / padCenter);

    changeWidthPerTimerTick = 0.0f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.resizing == YES)
    {
        Plaque *plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

        CGSize plaqueSize = [plaque size];

        plaqueSize.width += changeWidthPerTimerTick;
        plaqueSize.height += changeHeightPerTimerTick;

        plaqueSize.width = nearbyintf(plaqueSize.width * 100.0f);
        plaqueSize.width /= 100.0f;
        plaqueSize.height = nearbyintf(plaqueSize.height * 100.0f);
        plaqueSize.height /= 100.0f;

        if (plaqueSize.width < EditModeMinPlaqueWidth)
        {
            plaqueSize.width = EditModeMinPlaqueWidth;
        }

        if (plaqueSize.width > EditModeMaxPlaqueWidth)
        {
            plaqueSize.width = EditModeMaxPlaqueWidth;
        }

        if (plaqueSize.height < EditModeMinPlaqueHeight)
        {
            plaqueSize.height = EditModeMinPlaqueHeight;
        }

        if (plaqueSize.height > EditModeMaxPlaqueHeight)
        {
            plaqueSize.height = EditModeMaxPlaqueHeight;
        }

        [plaque setSize:plaqueSize];

        [self refreshValues];
    }
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:[touch view]];

    point = [[touch view] convertPoint:point toView:self];

    if (CGRectContainsPoint(self.touchPadWidth.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPadWidth];

        [self recalculateWidthParameters:point];

        self.resizing = YES;

        [self.touchPadTimer fire];
    }
    else if (CGRectContainsPoint(self.touchPadHeight.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPadHeight];

        [self recalculateHeightParameters:point];

        self.resizing = YES;

        [self.touchPadTimer fire];
    }

    [self.controlsView setAlpha:EditModeControlsAnimationAlphaAction];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    /*
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];
    */

    self.resizing = NO;
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:[touch view]];

    point = [[touch view] convertPoint:point toView:self];

    if (CGRectContainsPoint(self.touchPadWidth.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPadWidth];

        [self recalculateWidthParameters:point];
    }
    else if (CGRectContainsPoint(self.touchPadHeight.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPadHeight];

        [self recalculateHeightParameters:point];
    }
    else
    {
        self.resizing = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    self.resizing = NO;
}

- (void)refreshValues
{
    CGFloat width = [self.plaque width];
    CGFloat height = [self.plaque height];

    NSString *widthText = [NSString stringWithFormat:@"%0.02f m", width];
    NSString *heightText = [NSString stringWithFormat:@"%0.02f m", height];

    [self.widthValue setText:widthText];
    [self.heightValue setText:heightText];

    if (self.plaqueLayer != nil)
    {
        [self.plaqueLayer removeFromSuperlayer];
    }

    self.plaqueLayer = [self.plaque layerWithFrameToFit:CGRectMake(15.0f, 15.0f, 160.0f, 80.0f)];
    [self.plaque inscriptionLayerForLayer:self.plaqueLayer];
    [self.layer addSublayer:self.plaqueLayer];
}

@end
