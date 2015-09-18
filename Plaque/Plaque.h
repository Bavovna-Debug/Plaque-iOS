//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "XML.h"

typedef enum {
    PlaqueDimension2D,
    PlaqueDimension3D,
    PlaqueDimension4D
} PlaqueDimension;

@interface Plaque : NSObject

@property (assign, nonatomic) UInt64                  rowId;
@property (assign, nonatomic) NSUInteger              ownPlaqueId;
@property (assign, nonatomic) Boolean                 captured;

@property (weak,   nonatomic) Plaque                  *cloneChain;

@property (strong, nonatomic) NSUUID                  *plaqueToken;
@property (strong, nonatomic) NSUUID                  *profileToken;
@property (assign, nonatomic) int                     plaqueRevision;
@property (strong, nonatomic) NSDate                  *creationStamp;
@property (strong, nonatomic) CLLocation              *location;
@property (assign, nonatomic) CLLocationCoordinate2D  coordinate;
@property (assign, nonatomic) CLLocationDistance      altitude;
@property (assign, nonatomic) Boolean                 directed;
@property (assign, nonatomic) CLLocationDirection     direction;
@property (assign, nonatomic) Boolean                 tilted;
@property (assign, nonatomic) CGFloat                 tilt;
@property (assign, nonatomic) CGSize                  size;
@property (assign, nonatomic) CGFloat                 width;
@property (assign, nonatomic) CGFloat                 height;
@property (strong, nonatomic) UIColor                 *backgroundColor;
@property (strong, nonatomic) UIColor                 *foregroundColor;
@property (assign, nonatomic) CGFloat                 fontSize;
@property (strong, nonatomic) NSString                *inscription;
@property (strong, nonatomic) UIImage                 *image;

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
