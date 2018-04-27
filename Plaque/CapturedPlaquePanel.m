//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "Authentificator.h"
#import "CapturedPlaquePanel.h"
#import "Profiles.h"
#import "Navigator.h"
#import "Plaques.h"

#define CapturedPlaqueEditButtonSize 48.0f

@implementation CapturedPlaquePanel

- (void)didOpenPanel
{
    [super didOpenPanel];

    Plaque *plaque = self.plaque;
    Profile *profile = [[Profiles sharedProfiles] profileByToken:plaque.profileToken];

    CGRect bounds = self.superview.bounds;

    CGSize panelSize = CGSizeMake(300.0f, 200.0f);

    CGRect panelFrame =
    CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
               CGRectGetMaxY(bounds) - panelSize.height - CapturedPlaqueEditButtonSize,
               panelSize.width,
               panelSize.height);

    [self setFrame:panelFrame];

    [self setBackground:@"PanelCapturedBackground"];

    /*
     [self setBackgroundColor:[UIColor colorWithRed:0.400f green:0.400f blue:1.000f alpha:0.750f]];
     [self.layer setBorderWidth:2.0f];
     [self.layer setBorderColor:[[UIColor colorWithRed:0.400f green:0.400f blue:1.000f alpha:1.0f] CGColor]];
     [self.layer setCornerRadius:8.0f];
     */

    CGRect contentsBounds = CGRectInset(self.bounds, 12.0f, 10.0f);

    CGRect plaqueLayerFrame =
    CGRectMake(CGRectGetMinX(contentsBounds),
               CGRectGetMinY(contentsBounds),
               CGRectGetWidth(contentsBounds) - CapturedPlaqueEditButtonSize - 8.0f,
               CGRectGetHeight(contentsBounds) / 2.0f);

    CGRect editButtonFrame =
    CGRectMake(CGRectGetMaxX(contentsBounds) - CapturedPlaqueEditButtonSize,
               CGRectGetMinY(contentsBounds),
               CapturedPlaqueEditButtonSize,
               CapturedPlaqueEditButtonSize);

    CGRect inscriptionFrame =
    CGRectMake(CGRectGetMinX(contentsBounds),
               CGRectGetHeight(contentsBounds) / 2.0f,
               CGRectGetWidth(contentsBounds),
               (CGRectGetHeight(contentsBounds) / 2.0f) - 14.0f);

    CGRect profileNameFrame =
    CGRectMake(CGRectGetMinX(contentsBounds),
               CGRectGetMaxY(contentsBounds) - 14.0f,
               CGRectGetWidth(contentsBounds),
               14.0f);

    {
        CALayer *plaqueLayer = [plaque layerWithFrameToFit:plaqueLayerFrame];
        [self.plaque inscriptionLayerForLayer:plaqueLayer];
        [self.layer addSublayer:plaqueLayer];
    }

    {
        UILabel *inscriptionLabel = [[UILabel alloc] initWithFrame:inscriptionFrame];
        [inscriptionLabel setText:plaque.inscription];
        [inscriptionLabel setTextColor:[UIColor colorWithWhite:0.2f alpha:1.0f]];
        [inscriptionLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [inscriptionLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [inscriptionLabel setNumberOfLines:0];
        [self addSubview:inscriptionLabel];
    }

    if (profile != nil)
    {
        NSString *profileNameText = NSLocalizedString(@"CAPTURED_PLAQUE_AUTHOR", nil);
        profileNameText = [NSString stringWithFormat:profileNameText, profile.profileName];

        UILabel *profileNameLabel = [[UILabel alloc] initWithFrame:profileNameFrame];
        [profileNameLabel setText:profileNameText];
        [profileNameLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [profileNameLabel setTextColor:[UIColor lightTextColor]];
        [self addSubview:profileNameLabel];
    }

    if ([plaque fortified] == NO)
    {
        UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [editButton.layer setBorderWidth:1.0f];
        [editButton.layer setBorderColor:[[UIColor colorWithRed:0.416f green:0.416f blue:0.416f alpha:1.0f] CGColor]];
        [editButton.layer setCornerRadius:4.0f];

        [editButton setBackgroundImage:[UIImage imageNamed:@"EditModeEnterButton"] forState:UIControlStateNormal];
        [editButton setFrame:editButtonFrame];

        CGRect labelFrame = CGRectMake(CGRectGetMinX(editButton.bounds),
                                       CGRectGetMaxY(editButton.bounds),
                                       CGRectGetWidth(editButton.bounds),
                                       10.0f);

        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor darkTextColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont systemFontOfSize:9.0f]];
        [label setText:NSLocalizedString(@"EDIT_MODE_EDIT_BUTTON", nil)];
        [editButton addSubview:label];

        [self addSubview:editButton];

        [editButton addTarget:self
                       action:@selector(editButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
    }

    [self translate:-1.0f];
}

- (void)didClosePanel
{
    [super didClosePanel];

    Plaques *plaques = [Plaques sharedPlaques];
    Plaque *capturedPlaque = [plaques capturedPlaque];
    if (capturedPlaque == self.plaque)
    {
        [plaques setCapturedPlaque:nil];
    }
}

- (void)editButtonPressed:(id)sender
{
    if ([[Authentificator sharedAuthentificator] profileRegistered] == NO)
    {
        ApplicationDelegate *application = (ApplicationDelegate *) [[UIApplication sharedApplication] delegate];
        [application askToCreateProfile];
    }
    else
    {
        [[Plaques sharedPlaques] setPlaqueUnderEdit:self.plaque];
    }
}

@end
