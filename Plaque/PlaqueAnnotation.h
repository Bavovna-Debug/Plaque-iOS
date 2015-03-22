//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Plaque.h"

@interface PlaqueAnnotation : NSObject <MKAnnotation>

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
