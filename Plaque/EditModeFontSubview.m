//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "EditModeFontSubview.h"
#import "Plaques.h"

#define MinFontSize 0.05f
#define MaxFontSize 0.6f

@interface EditModeFontSubview ()

@property (weak,   nonatomic) Plaque *plaque;
@property (strong, nonatomic) CALayer *plaqueLayer;
@property (strong, nonatomic) UIView *touchPad;
@property (assign, nonatomic) Boolean moving;
@property (strong, nonatomic) NSTimer *touchPadTimer;

@end

@implementation EditModeFontSubview
{
    CGFloat changeFontSizePerTimerTick;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil) {
        [self preparePanel];
    } else {
        [self destroyPanel];
    }
}

- (void)preparePanel
{
    [self setBackgroundColor:[UIColor clearColor]];

    UIView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditModeFontSubview"]];
    [self addSubview:backgroundView];

    CGRect bounds = self.bounds;
    CGRect touchPadFrame = CGRectMake(CGRectGetMaxX(bounds) - 80.0f,
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
        [touchPadTimer invalidate];
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

        if (fontSize < MinFontSize)
            fontSize = MinFontSize;

        if (fontSize > MaxFontSize)
            fontSize = MaxFontSize;

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
    if (CGRectContainsPoint(self.touchPad.frame, point) == YES) {
        point = [touch locationInView:self.touchPad];
        [self recalculateTiltParameters:point];
        self.moving = YES;
        [self.touchPadTimer fire];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];

    self.moving = NO;
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    point = [[touch view] convertPoint:point toView:self];
    if (CGRectContainsPoint(self.touchPad.frame, point) == YES) {
        point = [touch locationInView:self.touchPad];
        [self recalculateTiltParameters:point];
    } else {
        self.moving = NO;
    }
}

- (void)refreshValues
{
    if (self.plaqueLayer != nil)
        [self.plaqueLayer removeFromSuperlayer];

    self.plaqueLayer = [self.plaque layerWithFrameToFit:CGRectMake(15.0f, 15.0f, 225.0f, 170.0f)];
    [self.plaque inscriptionLayerForLayer:self.plaqueLayer];
    [self.layer addSublayer:self.plaqueLayer];
}

@end
