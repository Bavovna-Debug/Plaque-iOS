//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApplicationSetup : NSObject

@property (assign, nonatomic, readwrite) Boolean everythingOK;

+ (ApplicationSetup *)sharedApplicationSetup;

- (void)goThroughQuestionsAndAnswers;

@end
