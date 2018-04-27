//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProfileDelegate;

@interface Authentificator : NSObject

@property (strong, nonatomic, readwrite) id<ProfileDelegate> profileDelegate;

@property (strong, nonatomic, readwrite) NSUUID *deviceToken;
@property (strong, nonatomic, readwrite) NSUUID *sessionToken;
@property (strong, nonatomic, readwrite) NSUUID *profileToken;
@property (strong, nonatomic, readwrite) NSData *notificationsToken;

+ (Authentificator *)sharedAuthentificator;

- (Boolean)deviceRegistered;

- (Boolean)profileRegistered;

- (NSMutableData *)prepareAnticipant;

- (void)validateNotificationsToken:(NSData *)notificationsToken;

- (void)processAnticipant:(NSMutableData *)anticipant;

- (void)checkWhetherProfileNameIsFree:(NSString *)profileName;

- (void)createProfileWithName:(NSString *)profileName;

@end

@protocol ProfileDelegate <NSObject>

@required

- (void)authentificatorBusyForTooLongTime:(Authentificator *)authentificator;

@optional

- (void)authentificator:(Authentificator *)authentificator
      profileNameIsFree:(NSString *)profileName;

- (void)authentificator:(Authentificator *)authentificator
profileNameAlreadyInUse:(NSString *)profileName;

- (void)profileCreated:(Authentificator *)authentificator;

@end
