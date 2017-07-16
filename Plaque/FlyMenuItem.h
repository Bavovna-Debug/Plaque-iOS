//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlyMenuItem : UIView

@property (strong, nonatomic) NSString  *name;

- (id)initWithName:(NSString *)name
      notification:(NSString *)notification;

@end
