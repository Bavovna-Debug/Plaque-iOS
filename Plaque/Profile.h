//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject

@property (assign, nonatomic) UInt64    rowId;

@property (strong, nonatomic) NSUUID    *profileToken;
@property (assign, nonatomic) int       profileRevision;
@property (strong, nonatomic) NSString  *profileName;
@property (strong, nonatomic) NSString  *userName;

- (id)initWithToken:(NSUUID *)profileToken;

- (void)save;

@end
