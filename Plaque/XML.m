//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "XML.h"

@implementation NSString(XML)

- (NSString *)xml
{
    NSString *string = self;

    string = [string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    string = [string stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    string = [string stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    string = [string stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];

    return string;
}

- (NSString *)MD5
{
    // Create pointer to the string as UTF8.
    //
    const char *input = [self UTF8String];

    // Create byte array of unsigned characters.
    //
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

    // Create 16 byte MD5 hash value, store in buffer.
    //
    CC_MD5(input, (CC_LONG)strlen(input), md5Buffer);

    // Convert MD5 value in the buffer to NSString of hex values.
    //
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02X", md5Buffer[i]];

    return output;
}

@end

@interface XMLDocument () <NSXMLParserDelegate>

@property (nonatomic, strong, readwrite) NSString  *target;
@property (nonatomic, strong, readwrite) NSString  *documentVersion;

@end

@interface XMLElement ()

@property (nonatomic, strong, readwrite) NSMutableArray  *elements;
@property (nonatomic, assign)            Boolean         parsed;

- (NSData *)data;

@end

@implementation XMLDocument
{
    NSXMLParser *xmlParser;
}

@synthesize target = _target;
@synthesize documentVersion = _documentVersion;
@synthesize forest = _forest;

+ (XMLDocument *)documentWithTarget:(NSString *)target
                        version:(NSString *)documentVersion
{
    XMLDocument *document = [[XMLDocument alloc] initWithTarget:target
                                                        version:documentVersion];
    return document;
}

+ (XMLDocument *)documentFromData:(NSData *)data
{
    XMLDocument *document = [[XMLDocument alloc] initWithData:data];
    return document;
}

- (id)initWithTarget:(NSString *)target
             version:(NSString *)documentVersion
{
    self = [super init];
    if (self == nil)
        return nil;

    self.target = target;
    self.documentVersion = documentVersion;

    return self;
}

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self == nil)
        return nil;

    xmlParser = [[NSXMLParser alloc] initWithData:data];
    [xmlParser setDelegate:self];
    [xmlParser parse];

    return self;
}

- (NSData *)xmlData
{
    NSMutableData *data = [NSMutableData data];
    NSData *forest = [self.forest data];
    if (forest == nil)
        return nil;

    NSString *root = [NSString stringWithFormat:@"<?%@ version=\"%@\"?>",
                      self.target,
                      self.documentVersion];

    @try
    {
        [data appendData:[root dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:forest];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Error in xmlData");
        @throw exception;
    }

    return data;
}

- (NSString *)string
{
    NSData *data;

    @try
    {
        data = [self xmlData];
    }
    @catch (NSException *exception)
    {
        return nil;
    }

    return [NSString stringWithUTF8String:data.bytes];
}

#pragma mark - XML parser

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    parser = nil;
}

- (void)parser:(NSXMLParser *)parser
foundProcessingInstructionWithTarget:(NSString *)target
          data:(NSString *)data
{
    self.target = target;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributes
{
    XMLElement *element;
    if (self.forest == nil) {
        element = [XMLElement elementWithName:elementName];
        if (element != nil) {
            [self setForest:element];
        }
    } else {
        element = [XMLElement elementWithName:elementName];
        if (element != nil) {
            XMLElement *parent = [self lastParsingElement];
            if (parent != nil)
                [parent addElement:element];
        }
    }

    [element setAttributes:(NSMutableDictionary *)attributes];
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
{
    XMLElement *lastElement = [self lastParsingElement];
    if (lastElement != nil)
        [lastElement setParsed:YES];
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    XMLElement *lastElement = [self lastParsingElement];
    if (lastElement != nil)
        [lastElement setContent:string];
}

- (XMLElement *)lastParsingElement
{
    XMLElement *elementUnderCursor = self.forest;

    while (elementUnderCursor != nil)
    {
        @try
        {
            if (elementUnderCursor.parsed == YES)
                return nil;

            if ([elementUnderCursor.elements count] == 0)
                return elementUnderCursor;

            XMLElement *childElement = (XMLElement *)[elementUnderCursor.elements lastObject];

            if (childElement.parsed == YES)
                return elementUnderCursor;
            
            elementUnderCursor = childElement;
        }
        @catch (NSException *exception)
        {
            return nil;
        }
    }

    return elementUnderCursor;
}

@end

@implementation XMLElement

+ (XMLElement *)elementWithName:(NSString *)name
{
    XMLElement *element = [[XMLElement alloc] initWithName:name];

    return element;
}

+ (XMLElement *)elementWithName:(NSString *)name
                           tree:(NSMutableArray *)tree
{
    XMLElement *element = [[XMLElement alloc] initWithName:name];

    element.elements = tree;

    return element;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self == nil)
        return nil;

    self.name = name;
    self.elements = [NSMutableArray array];
    self.attributes = [NSMutableDictionary dictionary];

    return self;
}

- (NSData *)data
{
    NSString *attributesString = @"";
    for (NSString *attribute in self.attributes)
    {
        attributesString = [attributesString stringByAppendingFormat:@" %@=\"%@\"",
                            attribute,
                            [[self.attributes objectForKey:attribute] xml]];
    }

    if (self.content != nil)
    {
        NSString *string = [NSString stringWithFormat:@"\n<%@%@>%@</%@>",
                            self.name,
                            attributesString,
                            [self.content xml],
                            self.name];

        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

        return data;
    }
    else if ([self.elements count] == 0)
    {
        NSString *string = [NSString stringWithFormat:@"\n<%@%@ />",
                            self.name,
                            attributesString];


        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

        return data;
    }
    else
    {
        NSMutableData *data = [NSMutableData data];

        NSString *prefix = [NSString stringWithFormat:@"\n<%@%@>",
                            self.name,
                            attributesString];
        NSString *suffix = [NSString stringWithFormat:@"\n</%@>",
                            self.name];

        [data appendData:[prefix dataUsingEncoding:NSUTF8StringEncoding]];

        for (XMLElement *element in self.elements)
            [data appendData:[element data]];

        [data appendData:[suffix dataUsingEncoding:NSUTF8StringEncoding]];

        return data;
    }
}

#pragma mark - API

- (void)setAttribute:(NSString *)attributeName
             toValue:(NSString *)value
{
    [self.attributes setObject:value
                        forKey:attributeName];
}

- (NSString *)attribute:(NSString *)attributeName
{
    return [self.attributes objectForKey:attributeName];
}

- (void)addElement:(XMLElement *)element
{
    [self.elements addObject:element];
}

- (XMLElement *)elementByPath:(NSString *)path
{
    NSArray *parts = [path componentsSeparatedByString:@"/"];

    XMLElement *elementUnderCursor = self;
    for (NSString *part in parts)
    {
        Boolean found = NO;
        NSMutableArray *elements = [elementUnderCursor elements];
        for (XMLElement *element in elements)
        {
            if ([element.name isEqualToString:part] == YES) {
                found = YES;
                elementUnderCursor = element;
                break;
            }
        }

        if (found == NO)
            return nil;
    }

    return elementUnderCursor;
}

@end
