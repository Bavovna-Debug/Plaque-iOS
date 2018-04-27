//
//  Plaque'n'Play
//
//  Copyright © 2014-2018 Meine Werke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(XML)

- (NSString *)MD5;

@end

@class XMLElement;

@interface XMLDocument : NSObject

@property (nonatomic, strong, readonly)  NSString   *target;
@property (nonatomic, strong, readonly)  NSString   *documentVersion;

@property (nonatomic, strong, readwrite) XMLElement *forest;

+ (XMLDocument *)documentWithTarget:(NSString *)target
                            version:(NSString *)documentVersion;

+ (XMLDocument *)documentFromData:(NSData *)data;

- (NSData *)xmlData;

- (NSString *)string;

@end

@interface XMLElement : NSObject

@property (nonatomic, strong, readwrite) NSString               *name;
@property (nonatomic, strong, readwrite) NSMutableDictionary    *attributes;
@property (nonatomic, strong, readwrite) NSString               *content;
@property (nonatomic, strong, readonly)  NSMutableArray         *elements;

+ (XMLElement *)elementWithName:(NSString *)name;

+ (XMLElement *)elementWithName:(NSString *)name
                           tree:(NSMutableArray *)tree;

- (void)setAttribute:(NSString *)attributeName
             toValue:(NSString *)value;

- (NSString *)attribute:(NSString *)attributeName;

- (void)addElement:(XMLElement *)element;

- (XMLElement *)elementByPath:(NSString *)path;

@end
