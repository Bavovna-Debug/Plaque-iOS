//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import "Authentificator.h"
#import "Database.h"
#import "Navigator.h"
#import "Paquet.h"
#import "Plaque.h"
#import "Plaques.h"
#import "Settings.h"
#import "StatusBar.h"

#include "API.h"

#ifdef DEBUG
#undef VERBOSE_PLAQUES_DB_SELECT
#define VERBOSE_PLAQUES_DB_INSERT
#define VERBOSE_PLAQUE_UPLOAD
#define VERBOSE_PLAQUE_CHANGE
#endif

#define DefaultPlaqueWidth      4.0f
#define DefaultPlaqueHeight     2.0f

#define ModificationsUploadInterval 3.0f

@interface Plaque () <PaquetSenderDelegate>

@property (weak, nonatomic) Paquet *uploadPaquet;
@property (weak, nonatomic) Paquet *locationPaquet;
@property (weak, nonatomic) Paquet *orientationPaquet;
@property (weak, nonatomic) Paquet *sizePaquet;
@property (weak, nonatomic) Paquet *colorPaquet;
@property (weak, nonatomic) Paquet *fontPaquet;
@property (weak, nonatomic) Paquet *inscriptionPaquet;

@end

@implementation Plaque
{
    Boolean storedInDatabase;
}

@synthesize profileToken        = _profileToken;
@synthesize plaqueRevision      = _plaqueRevision;
@synthesize directed            = _directed;
@synthesize direction           = _direction;
@synthesize width               = _width;
@synthesize height              = _height;
@synthesize backgroundColor     = _backgroundColor;
@synthesize foregroundColor     = _foregroundColor;
@synthesize fontSize            = _fontSize;
@synthesize inscription         = _inscription;
//@synthesize captured            = _captured;

- (id)initForClone
{
    self = [super init];
    if (self == nil)
        return nil;

    self.ownPlaqueId = [[Settings defaultSettings] lastOwnObjectId];

    storedInDatabase = NO;

    return self;
}

- (id)initWithToken:(NSUUID *)plaqueToken
{
    self = [super init];
    if (self == nil)
        return nil;

    SQLiteDatabase *database = [Database mainDatabase];

    NSString *query = [NSString stringWithFormat:@"SELECT rowid, profile_token, revision, creation_stamp, latitude, longitude, altitude, direction, tilt, width, height, background_color, foreground_color, font_size, inscription FROM plaques WHERE plaque_token = '%@'",
                       [plaqueToken UUIDString]];

    SQLiteDataReader *reader = [[SQLiteDataReader alloc] initWithDatabase:database
                                                                    query:query];
    if (reader == nil)
        return nil;

    if ([reader next] == FALSE)
        return nil;

    int rowId               = [reader getInt:0];
    NSString *profileToken  = [reader getString:1];
    int plaqueRevision      = [reader getInt:2];
    int creationStampInt    = [reader getInt:3];
    double latitude         = [reader getDouble:4];
    double longitude        = [reader getDouble:5];
    double altitude         = [reader getDouble:6];
    bool directed           = ([reader isNull:7] == TRUE) ? NO : YES;
    double direction        = [reader getDouble:7];
    bool tilted             = ([reader isNull:8] == TRUE) ? NO : YES;
    double tilt             = [reader getDouble:8];
    double width            = [reader getDouble:9];
    double height           = [reader getDouble:10];
    UInt32 backgroundColor  = [reader getInt:11];
    UInt32 foregroundColor  = [reader getInt:12];
    double fontSize         = [reader getDouble:13];
    NSString *inscription   = [reader getString:14];

    NSDate *creationStamp = [NSDate dateWithTimeIntervalSince1970:creationStampInt];

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                                         altitude:altitude
                                               horizontalAccuracy:0
                                                 verticalAccuracy:0
                                                           course:direction
                                                            speed:0.0f
                                                        timestamp:[NSDate date]];

    self.rowId              = rowId;
    self.plaqueToken        = plaqueToken;
    self.profileToken       = [[NSUUID alloc] initWithUUIDString:profileToken];
    self.plaqueRevision     = plaqueRevision;
    self.creationStamp      = creationStamp;
    self.location           = location;
    self.directed           = directed;
    self.direction          = direction;
    self.tilted             = tilted;
    self.tilt               = tilt;
    self.width              = width;
    self.height             = height;
    self.backgroundColor    = [UIColor colorWithARGB:backgroundColor];
    self.foregroundColor    = [UIColor colorWithARGB:foregroundColor];
    self.fontSize           = fontSize;
    self.inscription        = inscription;

    // Should be set to 'yes' only after all properties are set up.
    // Otherwise setter methods of properties would cause writing to database.
    //
    storedInDatabase = YES;

#ifdef VERBOSE_PLAQUES_DB_SELECT
    NSLog(@"Loaded plaque: %llu <%@>", self.rowId, self.inscription);
#endif

    return self;
}

- (id)initWithLocation:(CLLocation *)location
             direction:(CLLocationDirection)direction
           inscription:(NSString *)inscription
{
    self = [super init];
    if (self == nil)
        return nil;

    self.rowId              = 0;
    self.plaqueToken        = nil;
    self.profileToken       = [[[Authentificator sharedAuthentificator] profileToken] copy];
    self.plaqueRevision     = 0;
    self.creationStamp      = [NSDate date];
    self.location           = location;
    self.directed           = YES;
    self.direction          = direction;
    self.tilted             = NO;
    self.tilt               = 0.0f;
    self.width              = DefaultPlaqueWidth;
    self.height             = DefaultPlaqueHeight;
    self.backgroundColor    = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f];
    self.foregroundColor    = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    self.fontSize           = 0.25f;
    self.inscription        = inscription;

    storedInDatabase = NO;

    return self;
}

#pragma mark - XML

- (id)initFromXML:(XMLElement *)plaqueXML
{
    self = [super init];
    if (self == nil)
        return nil;

    // Plaque token.
    //
    XMLElement *plaqueTokenXML = [XMLElement elementWithName:@"plaque_token"];
    NSUUID *plaqueToken = [[NSUUID alloc] initWithUUIDString:[plaqueTokenXML content]];
    self.plaqueToken = plaqueToken;

    // Creation stamp.
    //
    XMLElement *creationStampXML = [plaqueXML elementByPath:@"creation_stamp"];
    NSString *unixCreationStamp = [creationStampXML content];
    NSTimeInterval since1970 = [unixCreationStamp doubleValue];
    NSDate *creationStamp = [NSDate dateWithTimeIntervalSince1970:since1970];
    self.creationStamp = creationStamp;

    // Coordinate.
    //
    XMLElement *coordinateXML = [plaqueXML elementByPath:@"coordinate2d"];
    @try {
        NSArray *coordinates2d = [[coordinateXML content] componentsSeparatedByString:@";"];
        if ([coordinates2d count] != 2)
            return nil;

        double latitude;
        double longitude;

        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:[coordinates2d objectAtIndex:0]];
        [scanner scanDouble:&latitude];

        scanner = [NSScanner scannerWithString:[coordinates2d objectAtIndex:1]];
        [scanner scanDouble:&longitude];

        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot extract coordinate");
    }

    // Altitude.
    //
    XMLElement *altitudeXML = [XMLElement elementWithName:@"altitude"];
    NSString *altitudeString = [altitudeXML content];
    @try {
        double altitude;

        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:altitudeString];
        [scanner scanDouble:&altitude];

        self.altitude = altitude;
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot extract direction");
    }

    // Direction.
    //
    XMLElement *directionXML = [plaqueXML elementByPath:@"direction"];
    NSString *directionString = [directionXML content];
    if ([directionString isEqualToString:@"null"] == YES) {
        self.directed = NO;
    } else {
        self.directed = YES;

        @try {
            double direction;

            NSScanner *scanner;

            scanner = [NSScanner scannerWithString:directionString];
            [scanner scanDouble:&direction];

            self.direction = direction;
        }
        @catch (NSException *exception) {
            NSLog(@"Cannot extract direction");
        }
    }

    // Tilt.
    //
    XMLElement *tiltXML = [plaqueXML elementByPath:@"tilt"];
    NSString *tiltString = [tiltXML content];
    if ([tiltString isEqualToString:@"null"] == YES) {
        self.tilted = NO;
    } else {
        self.tilted = YES;

        @try {
            double tilt;

            NSScanner *scanner;

            scanner = [NSScanner scannerWithString:tiltString];
            [scanner scanDouble:&tilt];

            self.tilt = tilt;
        }
        @catch (NSException *exception) {
            NSLog(@"Cannot extract tilt");
        }
    }

    // Size.
    //
    XMLElement *sizeXML = [plaqueXML elementByPath:@"size"];
    @try {
        NSArray *sizeValues = [[sizeXML content] componentsSeparatedByString:@";"];
        if ([sizeValues count] != 2)
            return nil;

        double width;
        double height;

        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:[sizeValues objectAtIndex:0]];
        [scanner scanDouble:&width];

        scanner = [NSScanner scannerWithString:[sizeValues objectAtIndex:1]];
        [scanner scanDouble:&height];

        self.size = CGSizeMake(width, height);
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot extract size");
    }

    // Background and foreground colors.
    //
    XMLElement *colorsXML = [plaqueXML elementByPath:@"colors"];
    @try {
        NSArray *colorValues = [[colorsXML content] componentsSeparatedByString:@";"];
        if ([colorValues count] != 2)
            return nil;

        NSInteger backgroundColor;
        NSInteger foregroundColor;

        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:[colorValues objectAtIndex:0]];
        [scanner scanInteger:&backgroundColor];

        scanner = [NSScanner scannerWithString:[colorValues objectAtIndex:1]];
        [scanner scanInteger:&foregroundColor];

        self.backgroundColor = [UIColor colorWithARGB:(UInt32)backgroundColor];
        self.foregroundColor = [UIColor colorWithARGB:(UInt32)foregroundColor];
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot extract colors");
    }

    // Font size.
    //
    XMLElement *fontSizeXML = [XMLElement elementWithName:@"font_size"];
    @try {
        double fontSize;

        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:[fontSizeXML content]];
        [scanner scanDouble:&fontSize];

        self.fontSize = fontSize;
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot extract font size");
    }

    // Inscription.
    //
    XMLElement *inscriptionXML = [plaqueXML elementByPath:@"inscription"];
    self.inscription = [inscriptionXML content];

    return self;
}

- (XMLElement *)xml
{
    XMLElement *plaqueXML = [XMLElement elementWithName:@"plaque"];

    XMLElement *plaqueTokenXML = [XMLElement elementWithName:@"plaque_token"];
    [plaqueTokenXML setContent:[self.plaqueToken UUIDString]];

    XMLElement *creationStampXML = [XMLElement elementWithName:@"creation_stamp"];
    NSTimeInterval since1970 = [self.creationStamp timeIntervalSince1970];
    NSString *unixCreationStamp = [NSString stringWithFormat:@"%.0f", since1970];
    [creationStampXML setContent:unixCreationStamp];

    XMLElement *coordinateXML = [XMLElement elementWithName:@"coordinate2d"];
    NSString *coordinate2d = [NSString stringWithFormat:@"%f;%f",
                              self.coordinate.latitude,
                              self.coordinate.longitude];
    [coordinateXML setContent:coordinate2d];

    XMLElement *altitudeXML = [XMLElement elementWithName:@"altitude"];
    [altitudeXML setContent:[NSString stringWithFormat:@".2%f", self.altitude]];

    XMLElement *directionXML = [XMLElement elementWithName:@"direction"];
    if (self.directed == NO)
        [directionXML setContent:@"null"];
    else
        [directionXML setContent:[NSString stringWithFormat:@"%.0f", self.direction]];

    XMLElement *tiltXML = [XMLElement elementWithName:@"tilt"];
    if (self.tilted == NO)
        [tiltXML setContent:@"null"];
    else
        [tiltXML setContent:[NSString stringWithFormat:@"%.0f", self.tilt]];

    XMLElement *sizeXML = [XMLElement elementWithName:@"size"];
    NSString *size = [NSString stringWithFormat:@"%.1f;%.1f",
                      self.width,
                      self.height];
    [sizeXML setContent:size];

    XMLElement *colorsXML = [XMLElement elementWithName:@"colors"];
    [colorsXML setContent:[NSString stringWithFormat:@"%d;%d",
                           (unsigned int)[self.backgroundColor argb],
                           (unsigned int)[self.foregroundColor argb]]];

    XMLElement *fontSizeXML = [XMLElement elementWithName:@"font_size"];
    [fontSizeXML setContent:[NSString stringWithFormat:@"%.2f", self.fontSize]];

    XMLElement *inscriptionXML = [XMLElement elementWithName:@"inscription"];
    [inscriptionXML setContent:self.inscription];

    [plaqueXML addElement:plaqueTokenXML];
    [plaqueXML addElement:creationStampXML];
    [plaqueXML addElement:altitudeXML];
    [plaqueXML addElement:directionXML];
    [plaqueXML addElement:tiltXML];
    [plaqueXML addElement:sizeXML];
    [plaqueXML addElement:colorsXML];
    [plaqueXML addElement:fontSizeXML];
    [plaqueXML addElement:inscriptionXML];
    
    return plaqueXML;
}

- (id)clone
{
    Plaque *clonedPlaque = [[Plaque alloc] initForClone];
    if (self == nil)
        return nil;

    clonedPlaque.plaqueToken        = (self.plaqueToken == nil) ? nil : [self.plaqueToken copy];
    clonedPlaque.profileToken       = (self.profileToken == nil) ? nil : [self.profileToken copy];
    clonedPlaque.plaqueRevision     = self.plaqueRevision;
    clonedPlaque.creationStamp      = [self.creationStamp copy];
    clonedPlaque.location           = [self.location copy];
    clonedPlaque.directed           = self.directed;
    clonedPlaque.direction          = self.direction;
    clonedPlaque.tilted             = self.tilted;
    clonedPlaque.tilt               = self.tilt;
    clonedPlaque.size               = self.size;
    clonedPlaque.backgroundColor    = [self.backgroundColor copy];
    clonedPlaque.foregroundColor    = [self.foregroundColor copy];
    clonedPlaque.fontSize           = self.fontSize;
    clonedPlaque.inscription        = [self.inscription copy];

    clonedPlaque.cloneChain = self;
    self.cloneChain = clonedPlaque;

    return clonedPlaque;
}

- (id)copy
{
    Plaque *copy = [[Plaque alloc] init];
    if (copy == nil)
        return nil;

    copy.plaqueToken        = self.plaqueToken;
    copy.profileToken       = self.profileToken;
    copy.plaqueRevision     = self.plaqueRevision;
    copy.location           = [self.location copy];
    copy.directed           = self.directed;
    copy.direction          = self.direction;
    copy.tilted             = self.tilted;
    copy.tilt               = self.tilt;
    copy.size               = self.size;
    copy.backgroundColor    = self.backgroundColor;
    copy.foregroundColor    = self.foregroundColor;
    copy.fontSize           = self.fontSize;
    copy.inscription        = [self.inscription copy];

    return copy;
}

- (void)saveToDatabase
{
    SQLiteDatabase *database = [Database mainDatabase];

    NSString *query = [NSString stringWithFormat:@"INSERT INTO plaques (plaque_token, profile_token, revision, creation_stamp, dimension, latitude, longitude, altitude, direction, tilt, width, height, background_color, foreground_color, font_size, inscription) VALUES ('%@', '%@', %d, %ld, %d, %f, %f, %f, %f, %f, %f, %f, %d, %d, %f, '%@')",
                       [self.plaqueToken UUIDString],
                       [self.profileToken UUIDString],
                       self.plaqueRevision,
                       lround([self.creationStamp timeIntervalSince1970]),
                       PlaqueDimension3D,
                       self.location.coordinate.latitude,
                       self.location.coordinate.longitude,
                       self.location.altitude,
                       self.direction,
                       self.tilt,
                       self.size.width,
                       self.size.height,
                       (unsigned int)[self.backgroundColor argb],
                       (unsigned int)[self.foregroundColor argb],
                       self.fontSize,
                       self.inscription];

    self.rowId = [database executeINSERT:query ignoreConstraints:YES];

    if (self.directed == NO)
    {
        query = [NSString stringWithFormat:@"UPDATE plaques SET direction = NULL WHERE rowid = %llu",
                 self.rowId];
        [database executeUPDATE:query ignoreConstraints:YES];
    }

    if (self.tilted == NO)
    {
        query = [NSString stringWithFormat:@"UPDATE plaques SET tilt = NULL WHERE rowid = %llu",
                 self.rowId];
        [database executeUPDATE:query ignoreConstraints:YES];
    }

    if (self.rowId != 0)
    {
        // Should be set to 'yes' only if record been successfully saved in local database.
        // Otherwise setter methods of properties would cause writing to database.
        //
        storedInDatabase = YES;
    }

#ifdef VERBOSE_PLAQUES_DB_INSERT
    NSLog(@"Saved plaque: %llu %@", self.rowId, self.inscription);
#endif
}

#pragma mark - Properties

- (void)setProfileToken:(NSUUID *)profileToken
{
    NSUUID *previousProfileToken = _profileToken;
    if ((previousProfileToken == nil) || ([previousProfileToken isEqual:profileToken] == NO))
    {
        _profileToken = profileToken;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET profile_token = '%@' WHERE rowid = %llu",
                               [profileToken UUIDString],
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }
    }
}

- (void)setPlaqueRevision:(int)plaqueRevision
{
    if (plaqueRevision != _plaqueRevision)
    {
        _plaqueRevision = plaqueRevision;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET revision = %d WHERE rowid = %llu",
                               plaqueRevision,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D currentCoordinate = self.coordinate;
    if ((coordinate.latitude != currentCoordinate.latitude) || (coordinate.longitude != currentCoordinate.longitude))
    {
        self.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                      altitude:self.altitude
                                            horizontalAccuracy:0
                                              verticalAccuracy:0
                                                        course:self.location.course
                                                         speed:0.0f
                                                     timestamp:[NSDate date]];

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET latitude = %f, longitude = %f WHERE rowid = %llu",
                               coordinate.latitude,
                               coordinate.longitude,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeLocation:self];
    }
}

- (CLLocationDistance)altitude
{
    return self.location.altitude;
}

- (void)setAltitude:(CLLocationDistance)altitude
{
    if (altitude != self.altitude)
    {
        self.location = [[CLLocation alloc] initWithCoordinate:self.coordinate
                                                      altitude:altitude
                                            horizontalAccuracy:0
                                              verticalAccuracy:0
                                                        course:self.location.course
                                                         speed:0.0f
                                                     timestamp:[NSDate date]];

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET altitude = %f WHERE rowid = %llu",
                               altitude,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeLocation:self];
    }
}

- (void)setDirected:(Boolean)directed
{
    if (directed != _directed)
    {
        _directed = directed;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query;
            if (directed == NO) {
                query = [NSString stringWithFormat:@"UPDATE plaques SET direction = NULL WHERE rowid = %llu",
                         self.rowId];
            } else {
                query = [NSString stringWithFormat:@"UPDATE plaques SET direction = %f WHERE rowid = %llu",
                         self.direction,
                         self.rowId];
            }

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeOrientation:self];
    }
}

- (void)setDirection:(CLLocationDirection)direction
{
    if (direction != _direction)
    {
        _direction = direction;

        _directed = YES;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET direction = %f WHERE rowid = %llu",
                               direction,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeOrientation:self];
    }
}

- (void)setTilted:(Boolean)tilted
{
    if (tilted != _tilted)
    {
        _tilted = tilted;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query;
            if (tilted == NO) {
                query = [NSString stringWithFormat:@"UPDATE plaques SET tilt = NULL WHERE rowid = %llu",
                         self.rowId];
            } else {
                query = [NSString stringWithFormat:@"UPDATE plaques SET tilt = %f WHERE rowid = %llu",
                         self.tilt,
                         self.rowId];
            }

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeOrientation:self];
    }
}

- (void)setTilt:(CGFloat)tilt
{
    if (tilt != _tilt)
    {
        _tilt = tilt;

        _tilted = YES;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET tilt = %f WHERE rowid = %llu",
                               tilt,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeOrientation:self];
    }
}

- (void)setWidth:(CGFloat)width
{
    if (width != _width)
    {
        _width = width;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET width = %f WHERE rowid = %llu",
                               width,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidResize:self];
    }
}

- (void)setHeight:(CGFloat)height
{
    if (height != _height)
    {
        _height = height;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET height = %f WHERE rowid = %llu",
                               height,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidResize:self];
    }
}

- (CGSize)size
{
    return CGSizeMake(self.width, self.height);
}

- (void)setSize:(CGSize)size
{
    [self setWidth:size.width];
    [self setHeight:size.height];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    UInt32 currentColor  = (_backgroundColor == nil) ? 0 : [_backgroundColor argb];
    UInt32 newColor      = [backgroundColor argb];

    if (newColor != currentColor)
    {
        _backgroundColor = backgroundColor;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET background_color = %u WHERE rowid = %llu",
                               (unsigned int)newColor,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }
    }

    [[Plaques sharedPlaques] notifyPlaqueDidChangeColor:self];
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    UInt32 currentColor  = (_foregroundColor == nil) ? 0 : [_foregroundColor argb];
    UInt32 newColor      = [foregroundColor argb];

    if (newColor != currentColor)
    {
        _foregroundColor = foregroundColor;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET foreground_color = %u WHERE rowid = %llu",
                               (unsigned int)newColor,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }
    }

    [[Plaques sharedPlaques] notifyPlaqueDidChangeColor:self];
}

- (void)setFontSize:(CGFloat)fontSize
{
    if (fontSize != _fontSize)
    {
        _fontSize = fontSize;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET font_size = %f WHERE rowid = %llu",
                               fontSize,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeFont:self];
    }
}

- (void)setInscription:(NSString *)inscription
{
    if ([inscription isEqualToString:_inscription] == NO)
    {
        _inscription = inscription;

        if (storedInDatabase == YES)
        {
            SQLiteDatabase *database = [Database mainDatabase];

            NSString *query = [NSString stringWithFormat:@"UPDATE plaques SET inscription = '%@' WHERE rowid = %llu",
                               inscription,
                               self.rowId];

            [database executeUPDATE:query ignoreConstraints:YES];
        }

        [[Plaques sharedPlaques] notifyPlaqueDidChangeInscription:self];
    }
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    if ((self.cloneChain != nil) && (storedInDatabase == NO))
        [self.cloneChain setImage:image];
}

#pragma mark - Cloud

- (BOOL)uploadToCloudIfNecessary
{
    BOOL uploadNecessary = NO;

    if (self.plaqueToken == nil)
    {
        Paquet *uploadPaquet = self.uploadPaquet;
        if (uploadPaquet != nil)
        {
            [uploadPaquet setSenderDelegate:nil];
            [uploadPaquet setCancelWhenPossible:YES];
        }

        // New plaque.
        //
        if ([self.inscription length] > 1)
        {
            Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPostNewPlaque];
            self.uploadPaquet = paquet;

            [paquet setSenderDelegate:self];

            [paquet putDouble:self.coordinate.latitude];
            [paquet putDouble:self.coordinate.longitude];
            [paquet putFloat:self.altitude];
            [paquet putBoolean:self.directed];
            [paquet putFloat:self.direction];
            [paquet putBoolean:self.tilted];
            [paquet putFloat:self.tilt];
            [paquet putFloat:self.size.width];
            [paquet putFloat:self.size.height];
            [paquet putColor:[self.backgroundColor CGColor]];
            [paquet putColor:[self.foregroundColor CGColor]];
            [paquet putFloat:self.fontSize];
            [paquet putString:self.inscription];

            [paquet send];

#ifdef VERBOSE_PLAQUE_UPLOAD
            NSLog(@"Plaque create request sent");
#endif
        }

        uploadNecessary = YES;
    }
    else
    {
        // Look if this plaque is already downloaded and its original exists already in plaque cache.
        //
        if (self.cloneChain == nil)
        {
            // Search for original.
            //
            Plaque *cloneChain = [[Plaques sharedPlaques] plaqueByToken:self.plaqueToken];

            // If original was already downloaded then chain this plaque and original with each other.
            //
            if (cloneChain != nil)
            {
                self.cloneChain = cloneChain;
                cloneChain.cloneChain = self;
            }
        }

        // Modifications can be sent to cloud only if the original plaque already exists in plaque cache.
        //
        if (self.cloneChain != nil)
        {
            Plaque *original = self.cloneChain;

            if ((self.coordinate.latitude != original.coordinate.latitude) ||
                (self.coordinate.longitude != original.coordinate.longitude) ||
                (nearbyintf(self.altitude * 100) != nearbyintf(original.altitude * 100)))
            {
                Paquet *locationPaquet = self.locationPaquet;
                if (locationPaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque location change request");
#endif
                    [locationPaquet setSenderDelegate:nil];
                    [locationPaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedLocation];
                self.locationPaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putDouble:self.coordinate.latitude];
                [paquet putDouble:self.coordinate.longitude];
                [paquet putFloat:self.altitude];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change coordinate request: %f->%f %f->%f %f->%f",
                      original.coordinate.latitude,
                      self.coordinate.latitude,
                      original.coordinate.longitude,
                      self.coordinate.longitude,
                      original.altitude,
                      self.altitude);
#endif

                [paquet send];

                uploadNecessary = YES;
            }

            if ((self.directed != original.directed) ||
                (nearbyintf(self.direction) != nearbyintf(original.direction)) ||
                (self.tilted != original.tilted) ||
                (nearbyintf(self.tilt) != nearbyintf(original.tilt)))
            {
                Paquet *orientationPaquet = self.orientationPaquet;
                if (orientationPaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque orientation change request");
#endif
                    [orientationPaquet setSenderDelegate:nil];
                    [orientationPaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedOrientation];
                self.orientationPaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putBoolean:self.directed];
                [paquet putFloat:self.direction];
                [paquet putBoolean:self.tilted];
                [paquet putFloat:self.tilt];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change orientation request: directed=%d->%d, direction=%f->%f tilted=%d->%d tilt=%f->%f",
                    original.directed,
                    self.directed,
                    original.direction,
                    self.direction,
                    original.tilted,
                    self.tilted,
                    original.tilt,
                    self.tilt);
#endif

                [paquet send];

                uploadNecessary = YES;
            }

            if ((nearbyintf(self.width * 100.0f) != nearbyintf(original.width * 100.0f)) ||
                (nearbyintf(self.height * 100.0f) != nearbyintf(original.height * 100.0f)))
            {
                Paquet *sizePaquet = self.sizePaquet;
                if (sizePaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque size change request");
#endif
                    [sizePaquet setSenderDelegate:nil];
                    [sizePaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedSize];
                self.sizePaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putFloat:self.size.width];
                [paquet putFloat:self.size.height];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change size request: width=%f->%f height=%f->%f",
                      original.width,
                      self.width,
                      original.height,
                      self.height);
#endif

                [paquet send];

                uploadNecessary = YES;
            }

            if (([self.backgroundColor argb] != [original.backgroundColor argb]) ||
                ([self.foregroundColor argb] != [original.foregroundColor argb]))
            {
                Paquet *colorPaquet = self.colorPaquet;
                if (colorPaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque color change request");
#endif
                    [colorPaquet setSenderDelegate:nil];
                    [colorPaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedColors];
                self.colorPaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putColor:[self.backgroundColor CGColor]];
                [paquet putColor:[self.foregroundColor CGColor]];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change color request: background=0x%08X->0x%08X forground=0x%08X->0x%08X",
                      (unsigned int)[original.backgroundColor argb],
                      (unsigned int)[self.backgroundColor argb],
                      (unsigned int)[original.foregroundColor argb],
                      (unsigned int)[self.foregroundColor argb]);
#endif

                [paquet send];

                uploadNecessary = YES;
            }

            if (nearbyintf(self.fontSize * 100) != nearbyintf(original.fontSize * 100))
            {
                Paquet *fontPaquet = self.fontPaquet;
                if (fontPaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque font change request");
#endif
                    [fontPaquet setSenderDelegate:nil];
                    [fontPaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedFont];
                self.fontPaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putFloat:self.fontSize];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change font: %f->%f",
                      original.fontSize,
                      self.fontSize);
#endif

                [paquet send];
                
                uploadNecessary = YES;
            }

            if ([self.inscription isEqualToString:original.inscription] == NO)
            {
                Paquet *inscriptionPaquet = self.inscriptionPaquet;
                if (inscriptionPaquet != nil)
                {
#ifdef VERBOSE_PLAQUE_CHANGE
                    NSLog(@"Cancel previous plaque inscription change request");
#endif
                    [inscriptionPaquet setSenderDelegate:nil];
                    [inscriptionPaquet setCancelWhenPossible:YES];
                }

                Paquet *paquet = [[Paquet alloc] initWithCommand:API_PaquetPlaqueModifiedInscription];
                self.inscriptionPaquet = paquet;

                [paquet setSenderDelegate:self];

                [paquet putToken:original.plaqueToken];
                [paquet putString:self.inscription];

#ifdef VERBOSE_PLAQUE_CHANGE
                NSLog(@"Plaque change inscription request: <%@>",
                      self.inscription);
#endif

                [paquet send];

                uploadNecessary = YES;
            }
        }
    }

    return uploadNecessary;
}

#pragma mark - Paquet delegate

- (void)paquetComplete:(Paquet *)paquet
{
    switch (paquet.commandCode)
    {
        case API_PaquetPostNewPlaque:
        {
            UInt32 status = [paquet getUInt32];
            NSUUID *plaqueToken = [paquet getToken];

#ifdef VERBOSE_PLAQUE_UPLOAD
            if (status == API_PaquetCreatePlaqueSucceeded) {
                NSLog(@"Plaque created with token %@",
                      [plaqueToken UUIDString]);
            } else {
                NSLog(@"Plaque creation failed");
            }
#endif

            if (status == API_PaquetCreatePlaqueSucceeded)
                [self setPlaqueToken:plaqueToken];

            [[Plaques sharedPlaques] downloadPlaque:plaqueToken];

            [[StatusBar sharedStatusBar] postMessage:
             NSLocalizedString(@"STATUS_BAR_NEW_PLAQUE_SYNCRONIZED", nil)];

            break;
        }

        case API_PaquetPlaqueModifiedLocation:
        case API_PaquetPlaqueModifiedOrientation:
        case API_PaquetPlaqueModifiedSize:
        case API_PaquetPlaqueModifiedColors:
        case API_PaquetPlaqueModifiedFont:
        case API_PaquetPlaqueModifiedInscription:
            //[[Plaques sharedPlaques] downloadPlaque:self.cloneChain.plaqueToken];

            [[StatusBar sharedStatusBar] postMessage:
             NSLocalizedString(@"STATUS_BAR_PLAQUE_CHANGES_SYNCRONIZED", nil)];
            break;

        default:
            break;
    }
}

#pragma mark - Visual layer

- (CALayer *)layerWithFrameToFit:(CGRect)frame
{
    CGSize plaqueSize = self.size;
    CGFloat xScaleFactor = CGRectGetWidth(frame) / plaqueSize.width;
    CGFloat yScaleFactor = CGRectGetHeight(frame) / plaqueSize.height;
    CGFloat scaleFactor = MIN(xScaleFactor, yScaleFactor);
    CGSize plaqueSizeInBounds = CGSizeMake(plaqueSize.width * scaleFactor,
                                           plaqueSize.height * scaleFactor);
    CGRect layerFrame = CGRectMake(CGRectGetMinX(frame) + (CGRectGetWidth(frame) - plaqueSizeInBounds.width) / 2,
                                   CGRectGetMinY(frame) + (CGRectGetHeight(frame) - plaqueSizeInBounds.height) / 2,
                                   plaqueSizeInBounds.width,
                                   plaqueSizeInBounds.height);

    CALayer *plaqueLayer = [CALayer layer];
    [plaqueLayer setFrame:layerFrame];
    if (CGColorEqualToColor([self.backgroundColor CGColor], [[UIColor clearColor] CGColor]) == NO)
    {
        [plaqueLayer setBackgroundColor:[self.backgroundColor CGColor]];
        [plaqueLayer setBorderColor:[[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor]];
        [plaqueLayer setBorderWidth:PLAQUE_BORDER_WIDTH];
        [plaqueLayer setCornerRadius:PLAQUE_CORNER_RADIUS];
    }

    return plaqueLayer;
}

- (CALayer *)inscriptionLayerForLayer:(CALayer *)plaqueLayer
{
    CGRect plaqueFrame = plaqueLayer.bounds;

    CALayer *inscriptionLayer;

    if (self.image == nil)
    {
        NSString *fontFamily = @"HelveticaNeue";
        CGFloat fontSize = [self fontSize];
        NSString *inscription = [self inscription];

        CGSize maxTextSize = CGSizeMake(CGRectGetWidth(plaqueFrame) * 0.95f,
                                        CGRectGetHeight(plaqueFrame) * 0.95f);

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSTextAlignmentCenter];

        NSDictionary *attributes = @{ NSFontAttributeName:[UIFont fontWithName:fontFamily size:fontSize],
                                      NSParagraphStyleAttributeName:paragraphStyle };


        CGRect textFrame;
        textFrame = [inscription boundingRectWithSize:maxTextSize
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];

        textFrame = CGRectOffset(textFrame,
                                 (CGRectGetWidth(plaqueFrame) - CGRectGetWidth(textFrame)) / 2,
                                 (CGRectGetHeight(plaqueFrame) - CGRectGetHeight(textFrame)) / 2);

        CATextLayer *textLayer = [CATextLayer layer];
        [textLayer setForegroundColor:[self.foregroundColor CGColor]];
        [textLayer setAlignmentMode:kCAAlignmentCenter];
        [textLayer setWrapped:YES];
        [textLayer setString:inscription];
        [textLayer setFrame:textFrame];
        [textLayer setFont:(CFTypeRef)fontFamily];
        [textLayer setFontSize:fontSize];

        inscriptionLayer = textLayer;
    }
    else
    {
        CGRect imageFrame = CGRectInset(plaqueFrame, 4.0f, 4.0f);
        CALayer *imageLayer = [CALayer layer];
        [imageLayer setContents:(id)[self.image CGImage]];
        [imageLayer setFrame:imageFrame];

        inscriptionLayer = imageLayer;
    }

    [self resizeInscriptionLayer:inscriptionLayer
                        forLayer:plaqueLayer];

    [plaqueLayer addSublayer:inscriptionLayer];

    return inscriptionLayer;
}

- (void)resizeInscriptionLayer:(CALayer *)inscriptionLayer
                      forLayer:(CALayer *)plaqueLayer
{
    CGRect plaqueFrame = plaqueLayer.bounds;

    if (self.image == nil)
    {
        NSString *fontFamily = @"HelveticaNeue";
        CGFloat fontSize = CGRectGetHeight(plaqueFrame) * [self fontSize];
        NSString *inscription = [self inscription];

        CGSize maxTextSize = CGSizeMake(CGRectGetWidth(plaqueFrame) * 0.95f,
                                        CGRectGetHeight(plaqueFrame) * 0.95f);

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSTextAlignmentCenter];

        NSDictionary *attributes = @{ NSFontAttributeName:[UIFont fontWithName:fontFamily size:fontSize],
                                      NSParagraphStyleAttributeName:paragraphStyle };


        CGRect textFrame;
        textFrame = [inscription boundingRectWithSize:maxTextSize
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];

        textFrame = CGRectOffset(textFrame,
                                 (CGRectGetWidth(plaqueFrame) - CGRectGetWidth(textFrame)) / 2,
                                 (CGRectGetHeight(plaqueFrame) - CGRectGetHeight(textFrame)) / 2);

        CATextLayer *textLayer = (CATextLayer *)inscriptionLayer;
        [textLayer setFrame:textFrame];
        [textLayer setFont:(CFTypeRef)fontFamily];
        [textLayer setFontSize:fontSize];
    }
    else
    {
        CGRect imageFrame = CGRectInset(plaqueFrame, 4.0f, 4.0f);
        CALayer *imageLayer = (CALayer *)inscriptionLayer;
        [imageLayer setFrame:imageFrame];
    }
}

@end
