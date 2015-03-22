//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "SurroundingSelector.h"

@interface SurroundingSelector ()

@property (assign, nonatomic, readwrite) SurroundingViewMode  surroundingViewMode;

@property (strong, nonatomic)            UIButton             *inSightButton;
@property (strong, nonatomic)            UIButton             *onMapButton;

@end

@implementation SurroundingSelector

+ (SurroundingSelector *)panel
{
    static dispatch_once_t onceToken;
    static SurroundingSelector *viewModePanel;

    dispatch_once(&onceToken, ^{
        viewModePanel = [[SurroundingSelector alloc] init];
    });

    return viewModePanel;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    self.surroundingViewMode = SurroundingInSight;

    [self setBackgroundColor:[UIColor clearColor]];

    return self;
}

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    UIView* view = [super hitTest:point withEvent:event];

    return (view == self) ? nil : view;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    /*
    CALayer *tableLayer = [CALayer layer];
    [tableLayer setBackgroundColor:[[UIColor colorWithWhite:0.4f alpha:0.8f] CGColor]];
    [tableLayer setBorderColor:[[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor]];
    [tableLayer setBorderWidth:3.0f];
    [tableLayer setCornerRadius:8.0f];
    [tableLayer setFrame:CGRectOffset(self.bounds, 0.0f, CGRectGetMidY(self.bounds) * 0.7f)];
    [self.layer addSublayer:tableLayer];

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 250;
    transform = CATransform3DRotate(transform, 78.0f * (M_PI / 180.0f), 1, 0, 0);
    transform = CATransform3DScale(transform, 0.8f, 1.0f, 1.0f);
    [tableLayer setTransform:transform];
     */

    UIImage *inSightImage = [UIImage imageNamed:@"ViewModeInSight"];
    UIImage *onMapImage = [UIImage imageNamed:@"ViewModeOnMap"];

    self.inSightButton = [self buttonWithIcon:inSightImage];
    [self addSubview:self.inSightButton];

    self.onMapButton = [self buttonWithIcon:onMapImage];
    [self addSubview:self.onMapButton];

    [self.inSightButton setCenter:CGPointMake(round(CGRectGetWidth(self.bounds) / 3),
                                              CGRectGetMidY(self.bounds))];
    [self.onMapButton setCenter:CGPointMake(round(CGRectGetWidth(self.bounds) / 3 * 2),
                                            CGRectGetMidY(self.bounds))];

    [self.inSightButton addTarget:self
                           action:@selector(inSightButtonPressed:)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.onMapButton addTarget:self
                         action:@selector(onMapButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)buttonWithIcon:(UIImage *)buttonIcon
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:buttonIcon
            forState:UIControlStateNormal];
    [button setBounds:(CGRect){ CGPointZero, buttonIcon.size }];

    [button.layer setBackgroundColor:[[UIColor lightGrayColor] CGColor]];
    [button.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    [button.layer setBorderWidth:2.0f];
    [button.layer setCornerRadius:buttonIcon.size.width / 2];
/*
    [button.layer setShadowColor:[[UIColor lightGrayColor] CGColor]];
    [button.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [button.layer setShadowOpacity:1.0f];
*/

    return button;
}

- (void)inSightButtonPressed:(id)sender
{
    self.surroundingViewMode = SurroundingInSight;
    [self.delegate surroundingViewModeChanged:self.surroundingViewMode];
}

- (void)onMapButtonPressed:(id)sender
{
    self.surroundingViewMode = SurroundingOnMap;
    [self.delegate surroundingViewModeChanged:self.surroundingViewMode];
}

@end
