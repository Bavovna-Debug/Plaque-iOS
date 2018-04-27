//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Definitions.h"
#import "EditModeFontSubview.h"
#import "Plaques.h"

#include "Definitions.h"

@interface EditModeFontSubview ()

@property (weak,   nonatomic) Plaque    *plaque;
@property (strong, nonatomic) UIView    *controlsView;
@property (strong, nonatomic) CALayer   *plaqueLayer;
@property (strong, nonatomic) UIView    *touchPad;
@property (assign, nonatomic) Boolean   moving;
@property (strong, nonatomic) NSTimer   *touchPadTimer;
@property (strong, nonatomic) NSTimer   *controlsTimer;

@end

@implementation EditModeFontSubview
{
    Boolean controlsAnimationDirection;
    CGFloat changeFontSizePerTimerTick;
}

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    self.moving = NO;

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
        self.controlsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeFontControls"]];
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

    CGRect touchPadFrame =
    CGRectMake(CGRectGetMaxX(bounds) - 80.0f,
               CGRectGetMinY(bounds),
               80.0f,
               CGRectGetHeight(bounds));


    UIView *touchPad = [[UIView alloc] initWithFrame:touchPadFrame];
    [touchPad setBackgroundColor:[UIColor clearColor]];
    [touchPad setOpaque:YES];
    [self addSubview:touchPad];

    self.touchPad = touchPad;

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
    if (self.moving == NO)
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

- (void)recalculateTiltParameters:(CGPoint)fingerPoint
{
    CGRect padBounds = self.touchPad.bounds;
    CGFloat padCenter = CGRectGetMidY(padBounds);
    CGFloat moveVector = fingerPoint.y - padCenter;

    changeFontSizePerTimerTick = -(moveVector / padCenter);
    changeFontSizePerTimerTick *= 0.02f;
}

- (void)fireTouchPadTimer:(NSTimer *)timer
{
    if (self.moving == YES)
    {
        CGFloat fontSize = [self.plaque fontSize];

        fontSize += changeFontSizePerTimerTick;

        fontSize = nearbyintf(fontSize * 100.0f);
        fontSize /= 100.0f;

        if (fontSize < EditModeMinFontSize)
        {
            fontSize = EditModeMinFontSize;
        }

        if (fontSize > EditModeMaxFontSize)
        {
            fontSize = EditModeMaxFontSize;
        }

        [self.plaque setFontSize:fontSize];

        [self refreshValues];
    }
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:[touch view]];

    point = [[touch view] convertPoint:point toView:self];

    if (CGRectContainsPoint(self.touchPad.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPad];

        [self recalculateTiltParameters:point];

        self.moving = YES;

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

    self.moving = NO;
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:[touch view]];

    point = [[touch view] convertPoint:point toView:self];

    if (CGRectContainsPoint(self.touchPad.frame, point) == YES)
    {
        point = [touch locationInView:self.touchPad];

        [self recalculateTiltParameters:point];
    }
    else
    {
        self.moving = NO;
    }
}

- (void)refreshValues
{
    if (self.plaqueLayer != nil)
    {
        [self.plaqueLayer removeFromSuperlayer];
    }

    self.plaqueLayer = [self.plaque layerWithFrameToFit:CGRectMake(15.0f, 15.0f, 225.0f, 170.0f)];
    [self.plaque inscriptionLayerForLayer:self.plaqueLayer];
    [self.layer addSublayer:self.plaqueLayer];
}

@end
