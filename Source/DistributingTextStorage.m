//
//  DistributingTextStorage.m
//  Ulysses
//
//  Created by Max on 02.01.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

#import "DistributingTextStorage.h"
#import "DistributedTextStorage.h"

@interface DistributingTextStorage (DistributingTextStorageInternal)

- (void)sendChangeReport;

@end

@implementation DistributingTextStorage

- (id)init
{
    self = [super init];
    
    _distributedTextStorages = [[NSMutableArray alloc] init];
    _tStorage = [[NSTextStorage allocWithZone: [self zone]] init];
    _undoManager = [[NSUndoManager alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_distributedTextStorages release];
    [_undoManager release];
    [_tStorage release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSUndoManager *)undoManager
{
    return _undoManager;
}

#pragma mark -
#pragma mark TextStorage Distribution

- (void)addDistributedTextStorage:(NSTextStorage *)aTextStorage
{
    if ([_distributedTextStorages indexOfObjectIdenticalTo: aTextStorage] == NSNotFound)
        [_distributedTextStorages addObject: aTextStorage];
}

- (void)removeDistributedTextStorage:(NSTextStorage *)aTextStorage
{
    [_distributedTextStorages removeObject: aTextStorage];
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
    int lengthChange;
    
    [self willEditCharactersInRange: range];
    [_tStorage replaceCharactersInRange:range withString:str];
    [self didEditCharactersInRange: NSMakeRange(range.location, [str length])];
    
    lengthChange = [str length] - range.length;
    
    [self distributedEdited:NSTextStorageEditedCharacters range:range changeInLength:lengthChange];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [_tStorage setAttributes:attrs range:range];
    [self distributedEdited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

#pragma mark -
#pragma mark NSTextStorage Additions

- (void)beginEditing
{
    unsigned i;
    
    [_tStorage beginEditing];
    
    for (i=0; i<[_distributedTextStorages count]; i++)
        [[_distributedTextStorages objectAtIndex: i] beginDistributedEditing];
}

- (void)endEditing
{
    unsigned i;
    
    [_tStorage endEditing];
    
    for (i=0; i<[_distributedTextStorages count]; i++)
        [[_distributedTextStorages objectAtIndex: i] endDistributedEditing];
}

- (void)edited:(unsigned)editedMask range:(NSRange)range changeInLength:(int)delta
{
    [self distributedEdited:editedMask range:range changeInLength:delta];
}

- (void)distributedEdited:(unsigned)editedMask range:(NSRange)range changeInLength:(int)delta
{
    unsigned i;
    
    for (i=0; i<[_distributedTextStorages count]; i++)
        [[_distributedTextStorages objectAtIndex: i] edited:editedMask range:range changeInLength:delta];
    
    [self sendChangeReport];
}

- (void)willEditCharactersInRange:(NSRange)range
{
    if ([[self delegate] respondsToSelector: @selector(textStorage:willEditCharactersInRange:)])
        [(id)[self delegate] textStorage:self willEditCharactersInRange:range];
}

- (void)didEditCharactersInRange:(NSRange)range
{
    if ([[self delegate] respondsToSelector: @selector(textStorage:didEditCharactersInRange:)])
        [(id)[self delegate] textStorage:self didEditCharactersInRange:range];
}

#pragma mark -
#pragma mark ChangeReport Protocol Implementation

- (void)reportChangesToObject:(id)object withSelector:(SEL)action
{
    _changeReportAction = action;
    _changeReportObject = object;
}

- (void)sendChangeReport
{
    if (!_changeReportAction || !_changeReportObject) return;    
    [_changeReportObject performSelector:_changeReportAction withObject:self];
}

#pragma mark -
#pragma mark Others

- (BOOL)isEqual:(id)other
{
    return (self == other);
}

@end
