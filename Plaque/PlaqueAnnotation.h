//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Plaque.h"

@interface PlaqueAnnotation : NSObject <CALayerDelegate, MKAnnotation>

@property (assign, nonatomic, readonly)  CLLocationCoordinate2D coordinate;
@property (copy,   nonatomic, readonly)  NSString               *inscription;
@property (weak,   nonatomic, readwrite) Plaque                 *plaque;
@property (strong, nonatomic, readwrite) CALayer                *annotationLayer;
@property (strong, nonatomic, readwrite) CATextLayer            *annotationTextLayer;

- (id)initWithPlaque:(Plaque *)plaque;

- (void)createLayer;

- (void)destroyLayer;

- (void)didChangeColor;

- (void)didChangeInscription;

@end
