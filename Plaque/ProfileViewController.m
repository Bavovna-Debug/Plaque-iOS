//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Paquet.h"
#import "ProfileViewController.h"
#import "Authentificator.h"
#import "XML.h"

#include "API.h"

#define ProfileNameValidateInterval 2.0f

@interface ProfileViewController () <UITableViewDataSource, UITableViewDelegate, PaquetSenderDelegate>

@property (strong, nonatomic) UITableView               *tableView;
@property (strong, nonatomic) NSMutableArray            *cells;
@property (strong, nonatomic) UITextField               *profileNameField;
@property (strong, nonatomic) UIActivityIndicatorView   *profileNameValidationIndicator;
@property (strong, nonatomic) UILabel                   *profileNameValidationMessage;
@property (strong, nonatomic) UITextField               *userFullNameField;
@property (strong, nonatomic) UITextField               *passwordField;
@property (strong, nonatomic) UITextField               *passwordRepeatField;
@property (strong, nonatomic) UITextField               *emailAddressField;
@property (strong, nonatomic) UIButton                  *cancelButton;
@property (strong, nonatomic) UIButton                  *submitButton;

@property (strong, nonatomic) NSString                  *previousProfileName;
@property (strong, nonatomic) NSTimer                   *profileNameValdateTimer;
@property (strong, nonatomic) NSLock                    *profileNameValdateLock;

@property (strong, nonatomic) Paquet                    *paquet;

@end

@implementation ProfileViewController
{
    Boolean didLayoutSubviews;
}

- (instancetype)init
{
    self = [super init];
    if (self == nil)
        return nil;

    [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self setModalPresentationStyle:UIModalPresentationOverCurrentContext];

    self.profileNameValdateLock = [[NSLock alloc] init];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor colorWithWhite:0.4f alpha:0.4f]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
/*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
*/
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
/*
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
*/
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (didLayoutSubviews == NO) {
        self.cells = [NSMutableArray array];

        [self.cells addObject:[self paddingCell:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 40.0f : 100.0f]];
        [self.cells addObject:[self buttonsCell]];
        [self.cells addObject:[self profileNameCell]];
        //[self.cells addObject:[self userFullNameCell]];
        //[self.cells addObject:[self passwordCell]];
        [self.cells addObject:[self paddingCell:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 216.0f : 264.0f]];
        
        [self setupMainView];
        [self setupTableView];

        didLayoutSubviews = YES;
    }
}

- (void)setupMainView
{
    [self.view setBackgroundColor:[UIColor clearColor]];
/*
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.view setBackgroundColor:[UIColor clearColor]];
    } else {
        [self.view setBackgroundColor:[UIColor colorWithRed:0.784f green:0.784f blue:0.784f alpha:0.750f]];
    }
    [self.view.layer setBorderWidth:2.0f];
    [self.view.layer setBorderColor:[[UIColor colorWithRed:0.416f green:0.416f blue:0.416f alpha:0.9f] CGColor]];
    [self.view.layer setCornerRadius:4.0f];
*/
}

- (void)setupTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectInset(self.view.bounds, 5.0f, 5.0f)
                                                  style:UITableViewStylePlain];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 7.0f) {
        [self.tableView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
    }

    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];

    [self.view addSubview:self.tableView];
}

- (UIView *)paddingCell:(CGFloat)paddingHeight
{
    CGRect cellViewFrame = CGRectMake(0.0f, 0.0f, 280.0f, paddingHeight);
    cellViewFrame = CGRectOffset(cellViewFrame, (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(cellViewFrame)) / 2, 0.0f);

    UIView *paddingView = [[UIView alloc] initWithFrame:cellViewFrame];
    return paddingView;
}

- (UIView *)buttonsCell
{
    CGFloat dataViewWidth = 290.0f;

    CGRect cellViewFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 64.0f);

    UIView *cellView = [[UIView alloc] init];
    [cellView setFrame:cellViewFrame];
    [cellView setBackgroundColor:[UIColor clearColor]];

    CGRect dataViewFrame = CGRectMake((CGRectGetWidth(cellViewFrame) - dataViewWidth) / 2,
                                      4.0f,
                                      dataViewWidth,
                                      CGRectGetHeight(cellViewFrame) - 8.0f);

    UIView *dataView = [[UIView alloc] init];
    [dataView setFrame:dataViewFrame];
    [dataView setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:0.8f]];
    [dataView.layer setCornerRadius:4.0f];
    [cellView addSubview:dataView];

    NSString *cancelButtonText = NSLocalizedString(@"PROFILE_FORM_CANCEL_BUTTON", nil);
    NSString *submitButtonText = NSLocalizedString(@"PROFILE_FORM_SUBMIT_BUTTON", nil);

    CGRect cancelButtonRect = CGRectMake(0.0f,
                                         0.0f,
                                         100.0f,
                                         CGRectGetHeight(dataViewFrame));
    CGRect submitButtonRect = CGRectMake(CGRectGetWidth(dataViewFrame) - 100.0f,
                                         0.0f,
                                         100.0f,
                                         CGRectGetHeight(dataViewFrame));

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:cancelButtonRect];
    [cancelButton setTitle:cancelButtonText
                  forState:UIControlStateNormal];
    [cancelButton addTarget:self
                     action:@selector(cancelButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [dataView addSubview:cancelButton];

    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton setFrame:submitButtonRect];
    [submitButton setTitle:submitButtonText
                  forState:UIControlStateNormal];
    [submitButton setEnabled:NO];
    [submitButton addTarget:self
                     action:@selector(submitButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [dataView addSubview:submitButton];

    self.cancelButton = cancelButton;
    self.submitButton = submitButton;

    return cellView;
}

- (UIView *)profileNameCell
{
    CGFloat dataViewWidth = 290.0f;

    CGRect cellViewFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 160.0f);

    UIView *cellView = [[UIView alloc] init];
    [cellView setFrame:cellViewFrame];
    [cellView setBackgroundColor:[UIColor clearColor]];

    CGRect dataViewFrame = CGRectMake((CGRectGetWidth(cellViewFrame) - dataViewWidth) / 2,
                                      4.0f,
                                      dataViewWidth,
                                      CGRectGetHeight(cellViewFrame) - 8.0f);

    UIView *dataView = [[UIView alloc] init];
    [dataView setFrame:dataViewFrame];
    [dataView setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:0.8f]];
    [dataView.layer setCornerRadius:4.0f];
    [cellView addSubview:dataView];

    NSString *profileNameLabelText = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_LABEL", nil);
    NSString *profileNameHelpText = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_HELP", nil);

    CGSize margin = CGSizeMake(20.0f, 8.0f);

    UIColor *labelTextColor = [UIColor lightTextColor];
    UIColor *fieldTextColor = [UIColor darkTextColor];
    UIColor *helpTextColor = [UIColor lightTextColor];
    UIFont *validatorFont = [UIFont systemFontOfSize:14.0f];
    UIFont *labelFont = [UIFont systemFontOfSize:15.0f];
    UIFont *fieldFont = [UIFont systemFontOfSize:15.0f];
    UIFont *helpFont = [UIFont systemFontOfSize:13.0f];

    CGSize labelTextSize = [profileNameLabelText sizeWithFont:labelFont];
    labelTextSize.width += margin.width * 2;
    CGRect validatorRect = CGRectMake(0.0f, 00.0f, CGRectGetWidth(cellViewFrame), 40.0f);
    CGRect labelRect = CGRectMake(0.0f, 40.0f, labelTextSize.width, 32.0f);
    CGRect fieldRect = CGRectMake(labelTextSize.width,
                                  32.0f,
                                  CGRectGetWidth(dataViewFrame) - CGRectGetMaxX(labelRect),
                                  40.0f);
    CGRect helpRect = CGRectMake(0.0f,
                                 CGRectGetMaxY(labelRect),
                                 CGRectGetWidth(dataViewFrame),
                                 CGRectGetMaxY(dataViewFrame) - CGRectGetMaxY(labelRect));
    NSLog(@"%@ %@ %@", NSStringFromCGRect(labelRect), NSStringFromCGRect(fieldRect), NSStringFromCGRect(helpRect));

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(labelRect, margin.width, margin.height)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:labelTextColor];
    [label setFont:labelFont];
    [label setText:profileNameLabelText];
    [dataView addSubview:label];

    UITextField *field = [[UITextField alloc] initWithFrame:CGRectInset(fieldRect, margin.width, margin.height)];
    [field setInputAccessoryView:self.inputView];
    [field setBorderStyle:UITextBorderStyleRoundedRect];
    [field setFont:fieldFont];
    [field setTextColor:fieldTextColor];
    [field setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [field setKeyboardType:UIKeyboardTypeASCIICapable];
    [field setKeyboardAppearance:UIKeyboardAppearanceDark];
    [field setSpellCheckingType:UITextSpellCheckingTypeNo];
    [field setAutocorrectionType:UITextAutocorrectionTypeNo];
    [field addTarget:self
              action:@selector(profileNameChanged:)
    forControlEvents:UIControlEventEditingChanged];
    [dataView addSubview:field];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [indicator setCenter:CGPointMake(CGRectGetMidX(dataViewFrame), CGRectGetMidY(dataViewFrame))];
    [dataView addSubview:indicator];

    UILabel *validationMessageLabel = [[UILabel alloc] initWithFrame:CGRectInset(validatorRect, margin.width, margin.height)];
    [validationMessageLabel setBackgroundColor:[UIColor clearColor]];
    [validationMessageLabel setTextColor:labelTextColor];
    [validationMessageLabel setFont:validatorFont];
    [validationMessageLabel setText:@""];
    [dataView addSubview:validationMessageLabel];

    UILabel *help = [[UILabel alloc] initWithFrame:CGRectInset(helpRect, margin.width, margin.height)];
    [help setBackgroundColor:[UIColor clearColor]];
    [help setTextColor:helpTextColor];
    [help setLineBreakMode:NSLineBreakByWordWrapping];
    [help setNumberOfLines:0];
    [help setFont:helpFont];
    [help setText:profileNameHelpText];
    [dataView addSubview:help];

    self.profileNameField = field;
    self.profileNameValidationIndicator = indicator;
    self.profileNameValidationMessage = validationMessageLabel;

    return cellView;
}

- (UIView *)userFullNameCell
{
    CGFloat dataViewWidth = 300.0f;

    CGRect cellViewFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 120.0f);

    UIView *cellView = [[UIView alloc] init];
    [cellView setFrame:cellViewFrame];
    [cellView setBackgroundColor:[UIColor clearColor]];

    CGRect dataViewFrame = CGRectMake((CGRectGetWidth(cellViewFrame) - dataViewWidth) / 2,
                                      4.0f,
                                      dataViewWidth,
                                      CGRectGetHeight(cellViewFrame) - 8.0f);

    UIView *dataView = [[UIView alloc] init];
    [dataView setFrame:dataViewFrame];
    [dataView setBackgroundColor:[UIColor lightGrayColor]];
    [dataView.layer setCornerRadius:4.0f];
    [cellView addSubview:dataView];

    NSString *userFullNameLabelText = NSLocalizedString(@"PROFILE_FORM_USER_NAME_LABEL", nil);
    //NSString *userFullNameHelp = NSLocalizedString(@"PROFILE_FORM_USER_NAME_HELP", nil);

    CGSize margin = CGSizeMake(12, 4);

    UIColor *labelTextColor = [UIColor darkTextColor];
    UIColor *fieldTextColor = [UIColor darkTextColor];
    UIFont *labelFont = [UIFont systemFontOfSize:15.0f];
    UIFont *fieldFont = [UIFont systemFontOfSize:15.0f];

    CGSize labelTextSize = [userFullNameLabelText sizeWithFont:labelFont];

    labelTextSize.width += 8.0f;

    CGRect labelRect = CGRectMake(8.0f, 8.0f, labelTextSize.width, 32.0f);
    CGRect fieldRect = CGRectMake(labelTextSize.width,
                                  8.0f,
                                  CGRectGetWidth(dataViewFrame) - CGRectGetMaxX(labelRect),
                                  32.0f);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(labelRect, margin.width, margin.height)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:labelTextColor];
    [label setFont:labelFont];
    [label setText:userFullNameLabelText];
    [dataView addSubview:label];

    UITextField *field = [[UITextField alloc] initWithFrame:CGRectInset(fieldRect, 0, margin.height)];
    [field setInputAccessoryView:self.inputView];
    [field setBorderStyle:UITextBorderStyleRoundedRect];
    [field setFont:fieldFont];
    [field setTextColor:fieldTextColor];
    [field setKeyboardType:UIKeyboardTypeDefault];
    [field setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [field addTarget:self
              action:@selector(profileNameChanged:)
    forControlEvents:UIControlEventEditingChanged];
    [dataView addSubview:field];

    self.userFullNameField = field;

    return cellView;
}

- (UIView *)passwordCell
{
    CGFloat dataViewWidth = 300.0f;

    CGRect cellViewFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 120.0f);

    UIView *cellView = [[UIView alloc] init];
    [cellView setFrame:cellViewFrame];
    [cellView setBackgroundColor:[UIColor clearColor]];

    CGRect dataViewFrame = CGRectMake((CGRectGetWidth(cellViewFrame) - dataViewWidth) / 2,
                                      4.0f,
                                      dataViewWidth,
                                      CGRectGetHeight(cellViewFrame) - 8.0f);

    UIView *dataView = [[UIView alloc] init];
    [dataView setFrame:dataViewFrame];
    [dataView setBackgroundColor:[UIColor lightGrayColor]];
    [dataView.layer setCornerRadius:4.0f];
    [cellView addSubview:dataView];

    NSString *profileNameLabelText = NSLocalizedString(@"PROFILE_FORM_PASSWORD_LABEL", nil);
    //NSString *profileNameHelpText = NSLocalizedString(@"PROFILE_FORM_PASSWORD_HELP", nil);

    CGSize margin = CGSizeMake(12, 4);

    UIColor *labelTextColor = [UIColor darkTextColor];
    UIColor *fieldTextColor = [UIColor darkTextColor];
    UIFont *labelFont = [UIFont systemFontOfSize:15.0f];
    UIFont *fieldFont = [UIFont systemFontOfSize:15.0f];

    CGSize labelTextSize = [profileNameLabelText sizeWithFont:labelFont];
    labelTextSize.width += 8.0f;
    CGRect labelRect = CGRectMake(8.0f, 8.0f, labelTextSize.width, 32.0f);
    CGRect fieldRect = CGRectMake(labelTextSize.width,
                                  8.0f,
                                  CGRectGetWidth(dataViewFrame) - CGRectGetMaxX(labelRect),
                                  32.0f);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(labelRect, margin.width, margin.height)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:labelTextColor];
    [label setFont:labelFont];
    [label setText:profileNameLabelText];
    [dataView addSubview:label];

    UITextField *field = [[UITextField alloc] initWithFrame:CGRectInset(fieldRect, 0, margin.height)];
    [field setInputAccessoryView:self.inputView];
    [field setBorderStyle:UITextBorderStyleRoundedRect];
    [field setFont:fieldFont];
    [field setTextColor:fieldTextColor];
    [field setKeyboardType:UIKeyboardTypeDefault];
    [field setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [field setSecureTextEntry:YES];
    [field addTarget:self
              action:@selector(profileNameChanged:)
    forControlEvents:UIControlEventEditingChanged];
    [dataView addSubview:field];

    self.passwordField = field;
    self.passwordRepeatField = field;

    return cellView;
}

- (void)revalidate
{
    BOOL cancelButtonEnabled = YES;

    if (self.paquet != nil) {
        cancelButtonEnabled = NO;
    }

    [self.cancelButton setEnabled:cancelButtonEnabled];
}

- (void)profileNameChanged:(UITextField *)textField
{
    [self.submitButton setEnabled:NO];

    if (self.profileNameValdateTimer != nil)
        [self.profileNameValdateTimer invalidate];
    
    self.profileNameValdateTimer =
    [NSTimer scheduledTimerWithTimeInterval:ProfileNameValidateInterval
                                     target:self
                                   selector:@selector(fireProfileNameValidation:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)fireProfileNameValidation:(NSTimer *)timer
{
    if ([self.profileNameValdateLock tryLock] == FALSE)
        return;

    NSString *currentProfileName = [self.profileNameField text];
    if ([currentProfileName length] < MinimumProfileNameLength) {
        [self.profileNameValidationMessage setText:@""];
        [self.profileNameValdateLock unlock];
    } else if ([currentProfileName isEqualToString:self.previousProfileName] == YES) {
        [self.profileNameValdateLock unlock];
    } else {
        NSString *message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_VALIDATING_MESSAGE", nil);
        message = [NSString stringWithFormat:message, currentProfileName];

        [self.profileNameValidationIndicator startAnimating];
        [self.profileNameValidationMessage setTextColor:[UIColor yellowColor]];
        [self.profileNameValidationMessage setText:message];

        Paquet *paquet = [[Paquet alloc] initWithCommand:PaquetValidateProfileName];

        [paquet setSenderDelegate:self];

        [paquet putFixedString:currentProfileName
                        length:BonjourProfileNameLength];

        [paquet send];

        self.previousProfileName = currentProfileName;

        [self revalidate];
    }
}

- (void)paquetProfileNameValidation:(Paquet *)paquet
{
    if (paquet == nil) {
        NSString *message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_VALIDATION_ERROR_MESSAGE", nil);

        [self.profileNameValidationIndicator stopAnimating];
        [self.profileNameValidationMessage setText:message];
        [self.profileNameValidationMessage setTextColor:[UIColor redColor]];
    } else {
        UInt32 statusCode = [paquet getUInt32];

        NSString *message;
        UIColor *messageColor;
        switch (statusCode)
        {
            case PaquetProfileNameAvailable:
                message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_IS_AVAILABLE_MESSAGE", nil);
                message = [NSString stringWithFormat:message, self.previousProfileName];
                messageColor = [UIColor greenColor];

                [self.submitButton setEnabled:YES];

                break;

            case PaquetProfileNameAlreadyInUse:
                message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_ALREADY_IN_USE_MESSAGE", nil);
                message = [NSString stringWithFormat:message, self.previousProfileName];
                messageColor = [UIColor redColor];
                break;

            default:
                message = @"";
                messageColor = [UIColor clearColor];
                break;
        }

        [self.profileNameValidationIndicator stopAnimating];
        [self.profileNameValidationMessage setText:message];
        [self.profileNameValidationMessage setTextColor:messageColor];
    }

    [self.profileNameValdateLock unlock];
}

- (void)createProfile
{
    NSString *profileName;
    NSString *userFullName;
    NSString *passwordMD5;
    NSString *emailAddress;

    profileName = [self.profileNameField text];
    userFullName = [self.userFullNameField text];
    emailAddress = @"";//[self.passwordField text];

    if ([[self.passwordField text] length] == 0)
        passwordMD5 = @"";
    else
        passwordMD5 = [passwordMD5 MD5];

    Paquet *paquet = [[Paquet alloc] initWithCommand:PaquetCreateProfile];
    self.paquet = paquet;

    [paquet setSenderDelegate:self];

    [paquet putFixedString:profileName
                    length:BonjourProfileNameLength];
    [paquet putFixedString:userFullName
                    length:BonjourUserNameLength];
    [paquet putFixedString:passwordMD5
                    length:BonjourMD5Length];
    [paquet putFixedString:emailAddress
                    length:BonjourEmailAddressLength];

    [paquet send];
}

- (void)paquetCreateProfile:(Paquet *)paquet
{
    UInt32 paquetStatus = [paquet getUInt32];

    switch (paquetStatus)
    {
        case BonjourCreateSucceeded:
        {
            NSUUID *profileToken = [paquet getToken];
            [[Authentificator sharedAuthentificator] setProfileToken:profileToken];
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
            break;
        }

        case BonjourCreateProfileNameAlreadyInUse:
        {
            NSString *message;
            UIColor *messageColor;
            message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_ALREADY_IN_USE_MESSAGE", nil);
            message = [NSString stringWithFormat:message, self.previousProfileName];
            messageColor = [UIColor redColor];
            [self.profileNameValidationIndicator stopAnimating];
            [self.profileNameValidationMessage setText:message];
            [self.profileNameValidationMessage setTextColor:messageColor];
            break;
        }

        case BonjourCreateProfileNameConstraint:
        {
            NSString *message;
            UIColor *messageColor;
            message = NSLocalizedString(@"PROFILE_FORM_PROFILE_NAME_CONSTRAINT_MESSAGE", nil);
            message = [NSString stringWithFormat:message, self.previousProfileName];
            messageColor = [UIColor redColor];
            [self.profileNameValidationIndicator stopAnimating];
            [self.profileNameValidationMessage setText:message];
            [self.profileNameValidationMessage setTextColor:messageColor];
            break;
        }

        case BonjourCreateProfileEmailAlreadyInUse:
            NSLog(@"BonjourCreateProfileEmailAlreadyInUse");
            break;

        case BonjourCreateProfileEmailConstraint:
            NSLog(@"BonjourCreateProfileEmailConstraint");
            break;

        default:
            NSLog(@"Unknown bonjour status code: 0x%X", (unsigned int)paquetStatus);
            break;
    }
}

- (void)cancelButtonPressed
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)submitButtonPressed
{
    //if ([[Authentificator sharedAuthentificator] profileRegistered] == NO) {
        [self createProfile];
    //}
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.cells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *cellView = (UIView *)[self.cells objectAtIndex:indexPath.row];

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
    [cell.contentView addSubview:cellView];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *cellView = (UIView *)[self.cells objectAtIndex:indexPath.row];
    return CGRectGetHeight(cellView.bounds);
}

- (BOOL)tableView:(UITableView *)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Paquet delegate

- (void)paquetComplete:(Paquet *)paquet
{
    if (paquet == self.paquet)
        self.paquet = nil;

    switch (paquet.commandCode)
    {
        case PaquetValidateProfileName:
            [self paquetProfileNameValidation:paquet];
            break;

        case PaquetCreateProfile:
            [self paquetCreateProfile:paquet];
            break;

        default:
            break;
    }

    [self revalidate];
}

- (void)paquetFailed:(Paquet *)paquet
{
    if (paquet == self.paquet)
        self.paquet = nil;

    switch (paquet.commandCode)
    {
        case PaquetValidateProfileName:
            [self paquetProfileNameValidation:nil];
            break;

        case PaquetCreateProfile:
            [self paquetCreateProfile:nil];
            break;

        default:
            break;
    }

    [self revalidate];
}

#pragma mark - Notifications handlers

/*
- (void)keyboardWillShow
{
    CGSize contentSize = [self.tableView contentSize];
    contentSize.height += (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 264 : 216;
    [self.tableView setContentSize:contentSize];
}

- (void)keyboardWillHide
{
    CGSize contentSize = [self.tableView contentSize];
    contentSize.height -= (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 264 : 216;
    [self.tableView setContentSize:contentSize];
}
*/

@end
