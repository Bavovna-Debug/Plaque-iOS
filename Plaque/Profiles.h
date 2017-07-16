//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Profile.h"

@interface Profiles : NSObject

+ (Profiles *)sharedProfiles;

- (Profile *)profileByToken:(NSUUID *)profileToken;

@end
