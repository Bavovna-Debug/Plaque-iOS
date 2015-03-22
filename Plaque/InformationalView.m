//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "InformationalView.h"
#import "Plaques.h"
#import "CapturedPlaquePanel.h"

@interface InformationalView () <PlaqueCaptureDelegate>

@property (weak, nonatomic) CapturedPlaquePanel *capturedPlaquePanel;

@end

@implementation InformationalView

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [[Plaques sharedPlaques] setCaptureDelegate:self];

    return self;
}

#pragma mark - Plaque capture delegate

- (void)plaqueCaptured:(Plaque *)plaque
{
    if (self.capturedPlaquePanel != nil)
        [self.capturedPlaquePanel removeFromSuperview];

    if (plaque != nil) {
        CGRect bounds = self.bounds;
        CGSize panelSize = CGSizeMake(280.0f, 200.0f);
        CGRect panelFrame = CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
                                       CGRectGetMaxY(bounds) - panelSize.height - 80.0f,
                                       panelSize.width,
                                       panelSize.height);
        CapturedPlaquePanel *capturedPlaquePanel = [[CapturedPlaquePanel alloc] initWithFrame:panelFrame];
        [capturedPlaquePanel setPlaque:plaque];

        [self addSubview:capturedPlaquePanel];

        self.capturedPlaquePanel = capturedPlaquePanel;
    }
}

@end
