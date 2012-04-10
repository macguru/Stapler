//
//  CompositeController.m
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeViewStorage.h"
#import "CompositeObject.h"
#import "CompositeView.h"

@interface CompositeViewStorage (CompositeViewStorageInternal)

- (void)customUndoAddItem:(CompositeObject *)object atIndex:(int)index;
- (void)customUndoRemoveItemAtIndex:(int)index;

@end

@implementation CompositeViewStorage

- (id)init
{
    self = [super init];
    
    [NSBundle loadNibNamed:@"CompositeView" owner:self];
    
    _changeReportAction = nil;
    _changeReportObject = nil;
    _items = [[NSMutableArray alloc] init];
    _undoManager = [[NSUndoManager alloc] init];
    
    [self addEmptyItem];
    [_undoManager removeAllActions];
    
    return self;
}

- (void)dealloc
{
    [_items release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSUndoManager *)undoManager
{
    return _undoManager;
}

#pragma mark -

- (NSMutableArray *)items
{
    return _items;
}

- (void)setItems:(NSArray *)items
{
    [_items setArray: items];
    
    for (unsigned i=0; i<[items count]; i++)
        [[items objectAtIndex: i] reportChangesToObject:self withSelector:@selector(sendChangeReport)];
}

- (void)addItems:(NSArray *)items
{
    [self willChangeValueForKey: @"items"];
    [_items addObjectsFromArray: items];
    [self didChangeValueForKey: @"items"];
    
    for (unsigned i=0; i<[items count]; i++)
        [[items objectAtIndex: i] reportChangesToObject:self withSelector:@selector(sendChangeReport)];
}

#pragma mark -

- (NSFileWrapper *)fileWrapperWithItems
{
    return [CompositeViewStorage fileWrapperForItems: [self items]];
}

- (void)setItemsWithFileWrapper:(NSFileWrapper *)wrapper
{
    [self setItems: [CompositeViewStorage itemsWithFileWrapper: wrapper]];
}

#pragma mark -
#pragma mark Conversion Methodes

+ (NSFileWrapper *)fileWrapperForItems:(NSArray *)items
{
    NSMutableDictionary *docs, *dict;
    unsigned i;
    
    docs = [NSMutableDictionary dictionary];
    dict = [NSMutableDictionary dictionary];
    
    for (i=0; i<[items count]; i++)
     {
        CompositeObject *object;
        
        object = [items objectAtIndex: i];
        
        [docs setObject:[[[NSFileWrapper alloc] initWithSerializedRepresentation: [object content]] autorelease] forKey:[NSString stringWithFormat: @"%d.rtfd", i]];
        [dict setObject:[object attributesAsPropertyList] forKey:[NSString stringWithFormat: @"%d.rtfd", i]];
     }
    
    [docs setObject:[[[NSFileWrapper alloc] initRegularFileWithContents: [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil]] autorelease] forKey:@"Info.plist"];

    return [[NSFileWrapper alloc] initDirectoryWithFileWrappers:docs];
}

+ (NSArray *)itemsWithFileWrapper:(NSFileWrapper *)wrapper
{
    NSDictionary *wrappers, *dict;
    NSMutableArray *items;
    NSArray *keys;
    unsigned i;
    
    items = [NSMutableArray array];
    wrappers = [wrapper fileWrappers];
    keys = [[wrappers allKeys] sortedArrayUsingSelector: @selector(localizedCompare:)];
    
    dict = [NSPropertyListSerialization propertyListFromData:[[wrappers objectForKey: @"Info.plist"] regularFileContents] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    
    for (i=0; i<[keys count]; i++)
     {
        NSFileWrapper *object;
        
        object = [wrappers objectForKey: [keys objectAtIndex: i]];
        
        if ([[[object preferredFilename] pathExtension] isEqual: @"rtfd"])
         {
            [items addObject: [CompositeObject objectWithContent: [object serializedRepresentation]]];
            [[items lastObject] setAttributesWithPropertyList: [dict objectForKey: [object preferredFilename]]];
         }
     }
    
    return items;
}

#pragma mark -
#pragma mark Actions

- (void)addEmptyItem
{
    [self addEmptyItemAtIndex: [[self items] count]];
}

- (void)addEmptyItemAtIndex:(int)index
{
    [self addItemWithContent:nil atIndex:index];
}

- (void)addItemWithContent:(NSData *)data
{
    [self addItemWithContent:data atIndex:[[self items] count]];
}

- (void)addItemWithContent:(NSData *)data atIndex:(int)index
{
    [self addItem:[CompositeObject objectWithContent: data] atIndex:index];
}

- (void)addItem:(CompositeObject *)object atIndex:(int)index
{
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
    
    [[_undoManager prepareWithInvocationTarget: self] customUndoRemoveItemAtIndex: index];
    [_undoManager setActionName: NSLocalizedStringFromTable(@"Add Item", @"CompositeView", nil)];
    
    [_items insertObject:object atIndex:index];
    [object reportChangesToObject:self withSelector:@selector(sendChangeReport)];
    
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
}

- (void)customUndoAddItem:(CompositeObject *)object atIndex:(int)index
{
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
    
    [[_undoManager prepareWithInvocationTarget: self] removeItemAtIndex: index];
    [_undoManager setActionName: NSLocalizedStringFromTable(@"Delete Item", @"CompositeView", nil)];
    
    [_items insertObject:object atIndex:index];
    [object reportChangesToObject:self withSelector:@selector(sendChangeReport)];
    
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
}

#pragma mark -

- (void)replaceItemAtIndex:(int)index withContent:(NSData *)data
{
    CompositeObject *object;
    
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
    
    object = [_items objectAtIndex: index];
    
    [[_undoManager prepareWithInvocationTarget: self] replaceItemAtIndex:index withContent: [object content]];
    [object setContent: data];
    
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
}

- (void)moveItemAtIndex:(int)oldIndex toIndex:(int)newIndex
{
    CompositeObject *object;
    
    object = [[_items objectAtIndex: oldIndex] retain];
    
    [[_undoManager prepareWithInvocationTarget: self] moveItemAtIndex:newIndex toIndex:oldIndex];
    [_undoManager setActionName: NSLocalizedStringFromTable(@"Move Item", @"CompositeView", nil)];
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: oldIndex] forKey:@"items"];
    [_items removeObjectAtIndex: oldIndex];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: oldIndex] forKey:@"items"];
    
    newIndex -= (newIndex > oldIndex);
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: newIndex] forKey:@"items"];
    [_items insertObject:object atIndex:newIndex];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex: newIndex] forKey:@"items"];
    
    [object release];
}

#pragma mark -

- (void)removeEmptyItems
{
    unsigned i;
    
    for (i=0; i<[_items count]; i++)
     {
        if ([[[_items objectAtIndex: i] string] length] == 0)
            [self removeItemAtIndex: i--];
     }
}

- (void)removeItem:(CompositeObject *)object
{
    [self removeItemAtIndex: [_items indexOfObject: object]];
}

- (void)removeItemAtIndex:(int)index
{
    CompositeObject *object;
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
    
    object = [_items objectAtIndex: index];
    
    [[_undoManager prepareWithInvocationTarget: self] customUndoAddItem:object atIndex:index];
    [_undoManager setActionName: NSLocalizedStringFromTable(@"Delete Item", @"CompositeView", nil)];
    
    [_items removeObjectAtIndex: index];
    
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
}

- (void)customUndoRemoveItemAtIndex:(int)index
{
    CompositeObject *object;
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
    
    object = [_items objectAtIndex: index];
    
    [[_undoManager prepareWithInvocationTarget: self] addItem:object atIndex:index];
    [_undoManager setActionName: NSLocalizedStringFromTable(@"Add Item", @"CompositeView", nil)];
    
    [_items removeObjectAtIndex: index];
    
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex: index] forKey:@"items"];
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

- (void)didChange:(NSKeyValueChange)changeKind valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
    [super didChange:changeKind valuesAtIndexes:indexes forKey:key];
    
    [self sendChangeReport];
}

@end
