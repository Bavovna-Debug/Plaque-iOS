//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "StatusBar.h"

@interface StatusBar ()

@property (strong, nonatomic) UIImageView *cloudImageView;

@end

@implementation StatusBar

+ (StatusBar *)sharedStatusBar
{
    static dispatch_once_t onceToken;
    static StatusBar *statusBar;

    dispatch_once(&onceToken, ^{
        statusBar = [[StatusBar alloc] init];
    });

    return statusBar;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    [self setBackgroundColor:[UIColor blackColor]];

    UIImage *cloudImage = [UIImage imageNamed:@"Cloud"];
    UIImageView *cloudImageView = [[UIImageView alloc] initWithImage:cloudImage];
    [cloudImageView setCenter:CGPointMake(CGRectGetMinX(self.bounds) + cloudImage.size.width / 2,
                                          CGRectGetMaxY(self.bounds) - 10.0f)];
    [self addSubview:cloudImageView];

    self.cloudImageView = cloudImageView;
}

@end
