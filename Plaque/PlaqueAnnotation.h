//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Plaque.h"

@interface PlaqueAnnotation : NSObject <CALayerDelegate, MKAnnotation>

@property (copy,   nonatomic) NSString                  *title;
@property (assign, nonatomic) CLLocationCoordinate2D    coordinate;
@property (weak,   nonatomic) Plaque                    *plaque;
@property (strong, nonatomic) CALayer                   *annotationLayer;
@property (strong, nonatomic) CATextLayer               *annotationTextLayer;

- (id)initWithPlaque:(Plaque *)plaque;

- (void)createLayer;

- (void)destroyLayer;

- (void)didChangeColor;

- (void)didChangeInscription;

@end
