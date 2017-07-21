//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    TapMenuMainCreateNewPlaque,
    TapMenuMainProfile,

    TapMenuViewInSight,
    TapMenuViewOnMap,
    TapMenuViewOnRadar,

    TapMenuMainPlaques,
    TapMenuMainBeacons,

    TapMenuPlaquesAddNew,
    TapMenuPlaquesSearch,

    //TapMenuPlaqueEditModeQuit,
    TapMenuPlaqueEditModeInscription,
    TapMenuPlaqueEditModeCoordinate,
    TapMenuPlaqueEditModeAltitude,
    TapMenuPlaqueEditModeDirection,
    TapMenuPlaqueEditModeSize,
    TapMenuPlaqueEditModeBackgroundColor,
    TapMenuPlaqueEditModeForegroundColor,
    TapMenuPlaqueEditModeRemove
}
TapMenuCommand;

@interface TapMenuItemView : UIButton

@property (weak, nonatomic) id owner;

- (id)initWithOwner:(id)owner;

- (CGSize)fullSize;

@end

@interface TapMenuItem : NSObject

@property (assign, nonatomic) TapMenuCommand command;
@property (assign, nonatomic) NSUInteger rowNumber;
@property (weak,   nonatomic) TapMenuItemView *view;

- (id)initWithIconName:(NSString *)iconName
               command:(TapMenuCommand)command
             rowNumber:(NSUInteger)rowNumber;

- (TapMenuItemView *)prepareViewFor:(UIView *)superview;

@end
