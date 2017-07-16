//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "XML.h"

typedef enum
{
    PlaqueDimension2D,
    PlaqueDimension3D,
    PlaqueDimension4D
}
PlaqueDimension;

@interface Plaque : NSObject

@property (assign, nonatomic, readwrite) UInt64                 rowId;
@property (assign, nonatomic, readwrite) NSUInteger             ownPlaqueId;
@property (assign, nonatomic, readwrite) Boolean                captured;

@property (weak,   nonatomic, readwrite) Plaque                 *cloneChain;

@property (strong, nonatomic, readwrite) NSUUID                 *plaqueToken;
@property (strong, nonatomic, readwrite) NSUUID                 *profileToken;
@property (assign, nonatomic, readwrite) int                    plaqueRevision;
@property (strong, nonatomic, readwrite) NSDate                 *creationStamp;
@property (strong, nonatomic, readwrite) CLLocation             *location;
@property (assign, nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (assign, nonatomic, readwrite) CLLocationDistance     altitude;
@property (assign, nonatomic, readwrite) Boolean                directed;
@property (assign, nonatomic, readwrite) CLLocationDirection    direction;
@property (assign, nonatomic, readwrite) Boolean                tilted;
@property (assign, nonatomic, readwrite) CGFloat                tilt;
@property (assign, nonatomic, readwrite) CGSize                 size;
@property (assign, nonatomic, readwrite) CGFloat                width;
@property (assign, nonatomic, readwrite) CGFloat                height;
@property (strong, nonatomic, readwrite) UIColor                *backgroundColor;
@property (strong, nonatomic, readwrite) UIColor                *foregroundColor;
@property (assign, nonatomic, readwrite) CGFloat                fontSize;
@property (strong, nonatomic, readwrite) NSString               *inscription;
@property (strong, nonatomic, readwrite) UIImage                *image;

- (id)initWithToken:(NSUUID *)plaqueToken;

- (id)initWithLocation:(CLLocation *)location
             direction:(CLLocationDirection)direction
           inscription:(NSString *)inscription;

- (id)initFromXML:(XMLElement *)plaqueXML;

- (XMLElement *)xml;

- (id)clone;

- (id)copy;

- (void)saveToDatabase;

- (BOOL)uploadToCloudIfNecessary;

- (CALayer *)layerWithFrameToFit:(CGRect)frame;

- (CALayer *)inscriptionLayerForLayer:(CALayer *)plaqueLayer;

- (void)resizeInscriptionLayer:(CALayer *)inscriptionLayer
                      forLayer:(CALayer *)plaqueLayer;

@end
