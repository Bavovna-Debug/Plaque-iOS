//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "EditModeInscriptionView.h"
#import "Plaques.h"

@interface EditModeInscriptionView () /*<UINavigationControllerDelegate, UIImagePickerControllerDelegate>*/

@property (weak,   nonatomic) Plaque        *plaque;
@property (strong, nonatomic) UITextField   *inscriptionField;

@end

@implementation EditModeInscriptionView

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }

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

    CGFloat keyboardHeight;
    CGSize panelSize;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        keyboardHeight = 264;

        panelSize = CGSizeMake(320.0f, 320.0f);
    }
    else
    {
        keyboardHeight = 216;

        panelSize = CGSizeMake(CGRectGetWidth(self.bounds) * 0.8f,
                               (CGRectGetHeight(self.bounds) - keyboardHeight) * 0.5f);
    }

    CGRect panelFrame =
    CGRectMake((CGRectGetWidth(self.bounds) - panelSize.width) / 2,
               (CGRectGetMaxY(self.bounds) - keyboardHeight - panelSize.height) / 2,
               panelSize.width,
               panelSize.height);

    UIColor *backgroundColor = [self.plaque backgroundColor];
    UIColor *foregroundColor = [self.plaque foregroundColor];

    UInt32 backgroundARGB = [backgroundColor argb];
    UInt32 foregroundARGB = [foregroundColor argb];
    if (backgroundARGB == foregroundARGB)
    {
        UIColor *blackColor = [UIColor blackColor];
        UIColor *whiteColor = [UIColor whiteColor];
        
        if (foregroundARGB == [whiteColor argb])
        {
            foregroundColor = blackColor;
        }
        else
        {
            foregroundColor = whiteColor;
        }
    }

    UIView *panel = [[UIView alloc] initWithFrame:panelFrame];
    [panel setBackgroundColor:backgroundColor];
    [panel.layer setBorderColor:[[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor]];
    [panel.layer setBorderWidth:2.0f];
    [panel.layer setCornerRadius:6.0f];


    UITextField *inscriptionField = [[UITextField alloc] initWithFrame:CGRectInset(panel.bounds, 8.0f, 8.0f)];
    [inscriptionField setInputAccessoryView:self.inputView];
    [inscriptionField setBackgroundColor:[UIColor clearColor]];
    [inscriptionField setTextColor:foregroundColor];
    [inscriptionField setFont:[UIFont systemFontOfSize:16.0f]];
    [inscriptionField setTextAlignment:NSTextAlignmentCenter];
    [inscriptionField setKeyboardType:UIKeyboardTypeDefault];
    [inscriptionField setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [inscriptionField setReturnKeyType:UIReturnKeyDone];
    [panel addSubview:inscriptionField];

    // Close button.
    //
    UIImage *closeButtonImage = [UIImage imageNamed:@"EditModeCloseButton"];
    CGSize closeButtonSize = closeButtonImage.size;
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:closeButtonImage
                 forState:UIControlStateNormal];
    [closeButton setBounds:CGRectMake(0.0f, 0.0f,
                                     closeButtonSize.width,
                                     closeButtonSize.height)];
    [closeButton setCenter:CGPointMake(CGRectGetMaxX(panelFrame), CGRectGetMinY(panelFrame))];
    [closeButton addTarget:self
                    action:@selector(closeButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:panel];
    [self addSubview:closeButton];

    self.inscriptionField = inscriptionField;

    [inscriptionField setText:[self.plaque inscription]];
    [inscriptionField becomeFirstResponder];
}

- (void)closeButtonPressed:(id)sender
{
    [self.plaque setInscription:[self.inscriptionField text]];
    [self removeFromSuperview];
}

/*
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];

    [picker dismissViewControllerAnimated:YES
                               completion:nil];

    [self.plaque setImage:pickedImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES
                               completion:nil];
}
*/

@end
