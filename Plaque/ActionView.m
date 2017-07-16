//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ActionButton.h"
#import "ActionView.h"
#import "InSightView.h"

@interface ActionView ()

@property (strong, nonatomic) NSArray *actionButtons;

@end

@implementation ActionView

- (id)initWithButtons:(NSArray *)actionButtons
{
    self = [super init];
    if (self == nil)
        return nil;

    self.actionButtons = actionButtons;

    [self setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.2f]];

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [self setFrame:newSuperview.bounds];
    
    [super willMoveToSuperview:newSuperview];

    CGRect bounds = self.bounds;
    CGSize buttonSize = [ActionButton buttonSize];
    CGSize buttonMargin = [ActionButton buttonMargin];
    CGRect buttonBounds = (CGRect){ CGPointZero, buttonSize };

    CGFloat buttonsTotal = [self.actionButtons count];
    CGFloat buttonsPerRow = floor(CGRectGetWidth(bounds) / (buttonSize.width + buttonMargin.width * 2));

    NSUInteger rowNumber = 0;
    CGFloat columnNumber = 0;
    for (ActionButton *actionButton in self.actionButtons)
    {
        CGFloat buttonsInThisRow = MIN(buttonsTotal - rowNumber * buttonsPerRow, buttonsPerRow);
        CGPoint buttonCenter = CGPointMake(CGRectGetMidX(bounds) + (-((buttonsInThisRow - 1) / 2.0f) + columnNumber) * (buttonSize.width + buttonMargin.width * 2.0f),
                                           CGRectGetMidY(bounds) + rowNumber * (buttonSize.height + buttonMargin.height * 2));

        [actionButton setBounds:buttonBounds];
        [actionButton setCenter:buttonCenter];
        [self addSubview:actionButton];

        [actionButton addTarget:self
                         action:@selector(actionButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];

        columnNumber++;
        if (columnNumber == buttonsPerRow) {
            columnNumber = 0;
            rowNumber++;
        }
    }
}

- (void)actionButtonPressed:(id)sender
{
    InSightView *inSightView = (InSightView *)self.superview;

    [self removeFromSuperview];

    ActionButton *actionButton = (ActionButton *)sender;
    [inSightView action:actionButton.actionCode];
}


- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    InSightView *inSightView = (InSightView *)self.superview;

    [self removeFromSuperview];

    [inSightView action:ActionNoAction];
}

@end
