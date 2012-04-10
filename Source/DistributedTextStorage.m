//
//  DistributedTextStorage.m
//  Ulysses
//
//  Created by Max on 02.01.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

#import "DistributedTextStorage.h"
#import "DistributingTextStorage.h"

@implementation DistributedTextStorage

- (id)initWithTextStorage:(DistributingTextStorage *)textStorage
{
    self = [super init];
    
    _tStorage = nil;
    
    [self setParentTextStorage: textStorage];
    
    return self;
}

- (void)dealloc
{
    [self setParentTextStorage: nil];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSUndoManager *)undoManager
{
    return [_tStorage undoManager];
}

- (DistributingTextStorage *)parentTextStorage
{
    return _tStorage;
}

- (void)setParentTextStorage:(DistributingTextStorage *)textStorage
{
    if (_tStorage)
        [_tStorage removeDistributedTextStorage: self];
    
    _tStorage = textStorage;
    
    if (_tStorage)
        [_tStorage addDistributedTextStorage: self];
}

#pragma mark -
#pragma mark NSTextStorage Getters

- (NSString *)string
{
    return [_tStorage string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)location effectiveRange:(NSRangePointer)range
{
    return [_tStorage attributesAtIndex:location effectiveRange:range];
}

#pragma mark -
#pragma mark NSTextStorage Setters

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    [_tStorage replaceCharactersInRange:range withString:str];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [_tStorage setAttributes:attrs range:range];
}

#pragma mark -
#pragma mark NSTextStorage Editing

- (void)beginEditing
{
    [_tStorage beginEditing];
}

- (void)endEditing
{
    [_tStorage endEditing];
}

- (void)beginDistributedEditing
{
    [super beginEditing];
}

- (void)endDistributedEditing
{
    [super endEditing];
}

#pragma mark -
#pragma mark ChangeReport Protocol Implementation

- (void)reportChangesToObject:(id)object withSelector:(SEL)action
{
    [_tStorage reportChangesToObject:object withSelector:action];
}

#pragma mark -
#pragma mark Others

- (BOOL)isEqual:(id)other
{
    return (self == other);
}

@end
