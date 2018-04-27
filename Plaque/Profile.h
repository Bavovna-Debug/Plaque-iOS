//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject

@property (assign, nonatomic, readwrite) UInt64     rowId;

@property (strong, nonatomic, readwrite) NSUUID     *profileToken;
@property (assign, nonatomic, readwrite) int        profileRevision;
@property (strong, nonatomic, readwrite) NSString   *profileName;
@property (strong, nonatomic, readwrite) NSString   *userName;

- (id)initWithToken:(NSUUID *)profileToken;

- (void)save;

@end
