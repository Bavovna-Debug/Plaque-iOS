//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "Authentificator.h"
#import "CapturedPlaquePanel.h"
#import "Profiles.h"
#import "Navigator.h"
#import "Plaques.h"

@interface CapturedPlaquePanel ()

@end

@implementation CapturedPlaquePanel

- (void)didOpenPanel
{
    [super didOpenPanel];

    CGRect bounds = self.superview.bounds;

    CGSize panelSize = CGSizeMake(280.0f, 200.0f);

    CGRect panelFrame =
    CGRectMake(CGRectGetMidX(bounds) - panelSize.width / 2,
               CGRectGetMaxY(bounds) - panelSize.height - 64.0f,
               panelSize.width,
               panelSize.height);

    [self setFrame:panelFrame];

    /*
     [self setBackgroundColor:[UIColor colorWithRed:0.400f green:0.400f blue:1.000f alpha:0.750f]];
     [self.layer setBorderWidth:2.0f];
     [self.layer setBorderColor:[[UIColor colorWithRed:0.400f green:0.400f blue:1.000f alpha:1.0f] CGColor]];
     [self.layer setCornerRadius:8.0f];
     */
    Plaque *plaque = self.plaque;
    Profile *profile = [[Profiles sharedProfiles] profileByToken:plaque.profileToken];

    CGRect inscriptionFrame = self.bounds;
    CGRect profileNameFrame = CGRectOffset(inscriptionFrame, 0.0f, 30.0f);
    CGRect userNameFrame = CGRectOffset(inscriptionFrame, 0.0f, 60.0f);

    UILabel *inscriptionLabel = [[UILabel alloc] initWithFrame:inscriptionFrame];
    [inscriptionLabel setText:plaque.inscription];
    [self addSubview:inscriptionLabel];

    if (profile != nil)
    {
        UILabel *profileNameLabel = [[UILabel alloc] initWithFrame:profileNameFrame];
        [profileNameLabel setText:profile.profileName];
        [self addSubview:profileNameLabel];

        UILabel *userNameLabel = [[UILabel alloc] initWithFrame:userNameFrame];
        [userNameLabel setText:profile.userName];
        [self addSubview:userNameLabel];
    }

    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [editButton setFrame:CGRectMake(200.0f, 50.0f, 80.0f, 40.0f)];
    [editButton setTitle:@"Edit"
                forState:UIControlStateNormal];
    [self addSubview:editButton];

    [editButton addTarget:self
                   action:@selector(editButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];

    [self translate:-1];

    // FIXME: As long the close button has "layer problems".
    //[self addCloseButton];
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
