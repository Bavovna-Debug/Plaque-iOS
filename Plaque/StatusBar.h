//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusBar : UIView

+ (StatusBar *)sharedStatusBar;

- (void)postMessage:(NSString *)text;

@end
