//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Profile.h"

@interface Profiles : NSObject

+ (Profiles *)sharedProfiles;

- (Profile *)profileByToken:(NSUUID *)profileToken;

@end
