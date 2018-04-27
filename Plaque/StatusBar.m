//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "StatusBar.h"

#include "Definitions.h"

@interface StatusBarMessage : NSObject

@property (strong, nonatomic) NSString *text;

@end

@implementation StatusBarMessage

@end

@interface StatusBar ()

@property (strong, nonatomic) NSMutableArray  *messageQueue;
@property (strong, nonatomic) NSLock          *messageQueueLock;
@property (strong, nonatomic) NSDate          *lastMessageStamp;
@property (strong, nonatomic) NSTimer         *nextMessageTimer;
@property (strong, nonatomic) NSTimer         *lastMessageTimer;
@property (strong, nonatomic) UIImageView     *cloudImageView;
@property (strong, nonatomic) UILabel         *lastMessageLabel;
@property (strong, nonatomic) UILabel         *thisMessageLabel;

@end

@implementation StatusBar

+ (StatusBar *)sharedStatusBar
{
    static dispatch_once_t onceToken;
    static StatusBar *statusBar;

    dispatch_once(&onceToken, ^{
        statusBar = [[StatusBar alloc] init];
    });

    return statusBar;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    self.messageQueue = [NSMutableArray array];
    self.messageQueueLock = [[NSLock alloc] init];
    self.lastMessageStamp = [NSDate date];

    [self setBackgroundColor:[UIColor blackColor]];

    UIImage *cloudImage = [UIImage imageNamed:@"Cloud"];
    UIImageView *cloudImageView = [[UIImageView alloc] initWithImage:cloudImage];
    [cloudImageView setCenter:CGPointMake(CGRectGetMinX(self.bounds) + cloudImage.size.width / 2,
                                          CGRectGetMaxY(self.bounds) - 10.0f)];
    [self addSubview:cloudImageView];

    self.cloudImageView = cloudImageView;
}

- (void)postMessage:(NSString *)text
{
#ifdef VerboseStatusBarMessages
    NSLog(@"Enqueue message: %@ (%f seconds since last message)",
          text,
          (self.lastMessageStamp == nil) ? 0.0f : [self.lastMessageStamp timeIntervalSinceNow]);
#endif

    [self.messageQueueLock lock];

    // If there is already such message in a queue, then skip this one.
    //
    for (StatusBarMessage *message in self.messageQueue)
    {
        if ([text isEqualToString:[message text]] == YES)
        {
            [self.messageQueueLock unlock];
            return;
        }
    }

    StatusBarMessage *message = [[StatusBarMessage alloc] init];
    [message setText:text];

    [self.messageQueue addObject:message];

    if (self.nextMessageTimer == nil) {
        if (self.lastMessageStamp == nil) {
            [self showNextMessage];
        } else {
            if ([self.lastMessageStamp timeIntervalSinceNow] < -(NextMessageInterval)) {
                [self showNextMessage];
            } else {
                [self.nextMessageTimer invalidate];

                self.nextMessageTimer =
                [NSTimer scheduledTimerWithTimeInterval:NextMessageInterval
                                                 target:self
                                               selector:@selector(fireNextMessage:)
                                               userInfo:nil
                                                repeats:NO];
            }
        }
    }

    [self.messageQueueLock unlock];
}

- (void)fireNextMessage:(NSTimer *)timer
{
    [self.messageQueueLock lock];

    [self showNextMessage];

    if ([self.messageQueue count] > 0) {
        self.nextMessageTimer =
        [NSTimer scheduledTimerWithTimeInterval:NextMessageInterval
                                         target:self
                                       selector:@selector(fireNextMessage:)
                                       userInfo:nil
                                        repeats:NO];
    } else {
        if (timer != self.lastMessageTimer) {
            self.nextMessageTimer = nil;

            self.lastMessageTimer =
            [NSTimer scheduledTimerWithTimeInterval:LastMessageInterval
                                             target:self
                                           selector:@selector(fireNextMessage:)
                                           userInfo:nil
                                            repeats:NO];
        }
    }

    [self.messageQueueLock unlock];
}

- (void)showNextMessage
{
#ifdef VerboseStatusBarMessages
    NSLog(@"Show next message");
#endif

    if ([self.lastMessageStamp timeIntervalSinceNow] > -(NextMessageInterval))
        return;

    if (self.lastMessageLabel != nil)
        [self.lastMessageLabel removeFromSuperview];

    if ([self.messageQueue count] == 0) {
        self.lastMessageLabel = self.thisMessageLabel;
        self.thisMessageLabel = nil;
    } else {
        StatusBarMessage *message = [self.messageQueue firstObject];
        [self.messageQueue removeObjectAtIndex:0];

        CGRect messageFrame = CGRectMake(28.0f,
                                         20.0f,
                                         CGRectGetWidth([self frame]) - 32.0f,
                                         16.0f);
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:messageFrame];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [messageLabel setText:[message text]];
        [messageLabel setAlpha:0.0f];
        [self addSubview:messageLabel];

        self.lastMessageLabel = self.thisMessageLabel;
        self.thisMessageLabel = messageLabel;

        self.lastMessageStamp = [NSDate date];

#ifdef VerboseStatusBarMessages
        NSLog(@"Show message: %@", [message text]);
#endif
    }

    [UIView beginAnimations:nil
                    context:nil];
    [UIView setAnimationDuration:SlideMessageOffInterval];

    if (self.lastMessageLabel != nil)
    {
        [self.lastMessageLabel setFrame:CGRectOffset([self.lastMessageLabel frame], 0.0f, -32.0f)];
        [self.lastMessageLabel setAlpha:0.0f];
    }

    if (self.thisMessageLabel != nil)
    {
        [self.thisMessageLabel setAlpha:1.0f];
    }

    [UIView commitAnimations];
}

@end
