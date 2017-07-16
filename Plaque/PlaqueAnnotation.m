//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "PlaqueAnnotation.h"

#include "Definitions.h"

@implementation PlaqueAnnotation

- (id)initWithPlaque:(Plaque *)plaque
{
    self = [super init];
    if (self == nil)
        return nil;

    self.plaque = plaque;

    return self;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.plaque.location.coordinate;
}

- (NSString *)title
{
    return self.plaque.inscription;
}

- (void)createLayer
{
    CALayer *plaqueLayer;

    // Remove layer if it already exists.
    //
    plaqueLayer = self.annotationLayer;
    if (plaqueLayer != nil)
        [plaqueLayer removeFromSuperlayer];

    // Create new layer.
    //
    plaqueLayer = [CALayer layer];

    [plaqueLayer setBackgroundColor:[self.plaque.backgroundColor CGColor]];
    [plaqueLayer setBorderColor:[[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor]];
    [plaqueLayer setBorderWidth:1.0f];
    [plaqueLayer setCornerRadius:5.0f];

    CGSize plaqueViewSize = CGSizeMake(self.plaque.size.width * PlaqueSizeFixedScaleFactor,
                                       self.plaque.size.height * PlaqueSizeFixedScaleFactor);

    CGRect frame = CGRectMake(-plaqueViewSize.width / 2,
                              -plaqueViewSize.height / 2,
                              plaqueViewSize.width,
                              plaqueViewSize.height);

    [plaqueLayer setFrame:frame];

    CATextLayer *plaqueTextLayer = [CATextLayer layer];
    [plaqueTextLayer setFrame:CGRectInset(plaqueLayer.bounds, 2.0f, 2.0f)];
    [plaqueTextLayer setFontSize:5.0f];
    [plaqueTextLayer setForegroundColor:[self.plaque.foregroundColor CGColor]];
    [plaqueTextLayer setAlignmentMode:kCAAlignmentCenter];
    [plaqueTextLayer setString:self.plaque.inscription];

    [plaqueLayer addSublayer:plaqueTextLayer];
    [plaqueLayer setDelegate:self];

    self.annotationLayer = plaqueLayer;
    self.annotationTextLayer = plaqueTextLayer;
}

- (void)destroyLayer
{
    CALayer *annotationLayer = self.annotationLayer;
    if (annotationLayer != nil)
        [annotationLayer removeFromSuperlayer];
}

#pragma mark -

- (void)didChangeColor
{
    [self.annotationLayer setBackgroundColor:[self.plaque.backgroundColor CGColor]];
    [self.annotationTextLayer setForegroundColor:[self.plaque.foregroundColor CGColor]];
}

- (void)didChangeInscription
{
    [self.annotationTextLayer setString:[self.plaque inscription]];
}

@end
