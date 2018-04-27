//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "Navigator.h"
#import "Panel.h"

@implementation Panel
{
    UIImageView *backgroundImage;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview != nil)
    {
        [self didOpenPanel];
    }
    else
    {
        [self didClosePanel];
    }
}

- (void)didOpenPanel
{
    //[self setBackgroundColor:[UIColor colorWithRed:0.784f green:0.784f blue:0.784f alpha:0.750f]];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.layer setBorderWidth:2.0f];
    [self.layer setBorderColor:[[UIColor colorWithRed:0.416f green:0.416f blue:0.416f alpha:0.8f] CGColor]];
    [self.layer setCornerRadius:4.0f];
}

- (void)didClosePanel
{
}

- (void)setBackground:(NSString *)backgroundImageName
{
    if (backgroundImage != nil)
    {
        [backgroundImage removeFromSuperview];
    }

    backgroundImage =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:backgroundImageName]];

    [backgroundImage setFrame:CGRectInset(self.bounds, 2.0f, 2.0f)];
    [backgroundImage setAlpha:0.8f];

    [self insertSubview:backgroundImage atIndex:0];
}

- (void)removeSubviews
{
    for (UIView *subview in self.subviews)
    {
        if (subview != backgroundImage)
        {
            [subview removeFromSuperview];
        }
    }
}

- (void)translate:(CGFloat)direction
{
    CGFloat rotateX = DegreesToRadians(20.0f);
    CGFloat rotateY = DegreesToRadians(25.0f);
    CGFloat rotateZ = DegreesToRadians(8.0f);
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f / 750.0f;
    transform = CATransform3DRotate(transform, rotateX, 1, 0, 0);
    transform = CATransform3DRotate(transform, rotateY, 0, -direction, 0);
    transform = CATransform3DRotate(transform, rotateZ, 0, 0, direction);

    [self.layer setTransform:transform];
}

- (void)addCloseButton
{
    UIImage *closeButtonImage = [UIImage imageNamed:@"EditModeCloseButton"];
    CGSize closeButtonSize = closeButtonImage.size;
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:closeButtonImage
                 forState:UIControlStateNormal];
    [closeButton setBounds:CGRectMake(CGRectGetMaxX(self.bounds) - closeButtonSize.width,
                                      CGRectGetMinY(self.bounds) - closeButtonSize.height,
                                      closeButtonSize.width,
                                      closeButtonSize.height)];
    [closeButton addTarget:self
                    action:@selector(closeButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:closeButton];
}

- (void)closeButtonPressed:(id)sender
{
    [self removeFromSuperview];
}

@end
