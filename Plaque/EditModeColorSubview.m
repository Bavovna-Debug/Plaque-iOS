//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "EditModeColorSubview.h"
#import "Plaques.h"

@interface EditModeColorSubview ()

@property (assign, nonatomic) EditModeColor editModeColor;
@property (weak,   nonatomic) Plaque        *plaque;
@property (weak,   nonatomic) UIButton      *transparentButton;

@end

@implementation EditModeColorSubview

- (id)initWithEditMode:(EditModeColor)editModeColor
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

    self.editModeColor = editModeColor;

    self.plaque = [[Plaques sharedPlaques] plaqueUnderEdit];

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil)
    {
        [self preparePanel];
    }
}

- (void)preparePanel
{
    [self setBackgroundColor:[UIColor clearColor]];

    NSMutableArray *buttons = [NSMutableArray array];
    for (NSUInteger i = 0; i < 20; i++)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundColor:[UIColor blackColor]];
        [buttons addObject:button];
    }

    NSArray *buttonColors = [NSArray arrayWithObjects:
                             [UIColor colorWithRed:1.000f green:0.000f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:0.502f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:0.800f blue:0.400f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:1.000f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:0.400f blue:0.400f alpha:1.0f],
                             [UIColor colorWithRed:0.502f green:0.000f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:0.251f green:0.502f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:0.000f green:1.000f blue:0.000f alpha:1.0f],
                             [UIColor colorWithRed:0.000f green:0.502f blue:0.502f alpha:1.0f],
                             [UIColor colorWithRed:0.000f green:1.000f blue:1.000f alpha:1.0f],
                             [UIColor colorWithRed:0.400f green:0.800f blue:1.000f alpha:1.0f],
                             [UIColor colorWithRed:0.400f green:0.400f blue:1.000f alpha:1.0f],
                             [UIColor colorWithRed:0.502f green:0.000f blue:0.502f alpha:1.0f],
                             [UIColor colorWithRed:0.000f green:0.000f blue:1.000f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:0.435f blue:0.812f alpha:1.0f],
                             [UIColor colorWithRed:1.000f green:1.000f blue:1.000f alpha:1.0f],
                             [UIColor colorWithRed:0.800f green:0.800f blue:0.800f alpha:1.0f],
                             [UIColor colorWithRed:0.502f green:0.502f blue:0.502f alpha:1.0f],
                             [UIColor colorWithRed:0.298f green:0.298f blue:0.298f alpha:1.0f],
                             [UIColor colorWithRed:0.000f green:0.000f blue:0.000f alpha:1.0f],
                             nil];

    CGRect zeroButtonFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.bounds) / 5, CGRectGetHeight(self.bounds) / 4);

    NSUInteger columnNumber = 0;
    NSUInteger rowNumber = 0;
    NSUInteger buttonColorIndex = 0;
    
    for (UIButton *button in buttons)
    {
        CGRect buttonFrame;
        buttonFrame = CGRectOffset(zeroButtonFrame,
                                   CGRectGetWidth(zeroButtonFrame) * columnNumber,
                                   CGRectGetHeight(zeroButtonFrame) * rowNumber);
        buttonFrame = CGRectInset(buttonFrame, 4.0f, 4.0f);

        UIColor *buttonColor = [buttonColors objectAtIndex:buttonColorIndex];

        [button setFrame:buttonFrame];
        [button setBackgroundColor:buttonColor];
        [button.layer setBorderWidth:1.0f];
        [button.layer setBorderColor:[[UIColor darkTextColor] CGColor]];
        [button.layer setCornerRadius:4.0f];
        [button.layer setShadowOffset:CGSizeMake(4.0f, 4.0f)];
        [button.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
        [button.layer setShadowOpacity:0.8f];
        [self addSubview:button];

        [button addTarget:self
                   action:@selector(colorPressed:)
         forControlEvents:UIControlEventTouchUpInside];

        columnNumber++;
        if (columnNumber == 5)
        {
            columnNumber = 0;
            rowNumber++;
        }

        buttonColorIndex++;
    }

    if (self.editModeColor == EditModeColorBackground)
    {
        self.transparentButton = (UIButton *)[buttons lastObject];
        [self.transparentButton setTitle:@"∅" forState:UIControlStateNormal];
    }
}

- (void)colorPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    UIColor *color = [button backgroundColor];

    switch (self.editModeColor)
    {
        case EditModeColorBackground:
        {
            if (button == self.transparentButton)
            {
                [self.plaque setBackgroundColor:[UIColor clearColor]];
            }
            else
            {
                [self.plaque setBackgroundColor:color];
            }

            break;
        }

        case EditModeColorForeground:
        {
            [self.plaque setForegroundColor:color];

            break;
        }
    }
}

@end
