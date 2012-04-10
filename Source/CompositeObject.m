//
//  CompositeObject.m
//  Ulysses
//
//  Created by Max on 04.11.05.
//  Copyright 2002-2006 The Blue Technologies Group. All rights reserved.
//

#import "CompositeObject.h"

#import "DistributingTextStorage.h"

NSString *attributesKeyCollapsed        = @"collapsed";
NSString *attributesKeyCreationDate     = @"creationDate";
NSString *attributesKeyCompletionDate   = @"completionDate";

@interface CompositeObject (CompositeObjectInternal)

- (void)sendChangeReport;

@end

@implementation CompositeObject

- (void)dealloc
{
    [_completionDate release];
    [_contentStorage release];
    [_creationDate release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Initializer

- (id)init
{
    self = [super init];
    
    _collapsed = NO;
    _completionDate = nil;
    _contentStorage = [[DistributingTextStorage alloc] init];
    _creationDate = [[NSDate date] retain];
    
    return self;
}

- (id)initWithContent:(NSData *)data
{
    [self init];
    
    [self setContent: data];
    
    return self;
}

+ (CompositeObject *)objectWithContent:(NSData *)data
{
    return [[[self alloc] initWithContent: data] autorelease];
}

#pragma mark -
#pragma mark Accessors

- (BOOL)collapsed
{
    return _collapsed;
}

- (void)setCollapsed:(BOOL)flag
{
    _collapsed = flag;
}

- (BOOL)wasCompleted
{
    return ([self completionDate] != nil);
}

- (void)setWasCompleted:(BOOL)flag
{
    [self setCompletionDate: (flag) ? [NSDate date] : nil];
    [self sendChangeReport];
}

- (NSDate *)completionDate
{
    return _completionDate;
}

- (void)setCompletionDate:(NSDate *)newDate
{
    [_completionDate release];
    _completionDate = [newDate retain];
}

- (NSData *)content
{
    return [_contentStorage RTFDFromRange:NSMakeRange(0, [_contentStorage length]) documentAttributes:nil];
}

- (void)setContent:(NSData *)data
{
    if (data == nil)
        return;
    
    [_contentStorage setAttributedString: [[[NSAttributedString alloc] initWithRTFD:data documentAttributes:nil] autorelease]];
}

- (NSDate *)creationDate
{
    return _creationDate;
}

- (void)setCreationDate:(NSDate *)newDate
{
    [_creationDate release];
    _creationDate = [newDate retain];
}

- (NSString *)stringContent
{
    return [_contentStorage string];
}

- (DistributingTextStorage *)contentTextStorage
{
    return _contentStorage;
}

- (NSDictionary *)attributesAsPropertyList
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool: [self collapsed]], attributesKeyCollapsed,
        [self creationDate], attributesKeyCreationDate,
        [self completionDate], attributesKeyCompletionDate,
        nil];
}

- (void)setAttributesWithPropertyList:(NSDictionary *)dictionary
{
    [self setCollapsed: [[dictionary objectForKey: attributesKeyCollapsed] boolValue]];
    [self setCreationDate: [dictionary objectForKey: attributesKeyCreationDate]];
    [self setCompletionDate: [dictionary objectForKey: attributesKeyCompletionDate]];
}

#pragma mark -
#pragma mark ChangeReport Protocol Implementation

- (void)reportChangesToObject:(id)object withSelector:(SEL)action
{
    [_contentStorage reportChangesToObject:object withSelector:action];
    
    _changeReportAction = action;
    _changeReportObject = object;
}

- (void)sendChangeReport
{
    if (!_changeReportAction || !_changeReportObject) return;    
    [_changeReportObject performSelector:_changeReportAction withObject:self];
}

@end
