//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApplicationSetup : NSObject

+ (ApplicationSetup *)sharedApplicationSetup;

- (void)goThroughQuestionsAndAnswers;

@end
