//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SurroundingSelectorDelegate;

@interface SurroundingSelector : UIView

typedef enum {
    SurroundingInSight,
    SurroundingOnMap,
    SurroundingRadar
} SurroundingViewMode;

@property (strong, nonatomic, readwrite) id<SurroundingSelectorDelegate> delegate;

@property (assign, nonatomic, readonly)  SurroundingViewMode surroundingViewMode;

+ (SurroundingSelector *)panel;

@end

@protocol SurroundingSelectorDelegate <NSObject>

@required

- (void)surroundingViewModeChanged:(SurroundingViewMode)surroundingViewMode;

@end