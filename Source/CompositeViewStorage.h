//
//  CompositeViewStorage.h
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "ChangeReport.h"

@class CompositeObject;

@interface CompositeViewStorage : NSObject <ChangeReport>
{
    SEL             _changeReportAction;
    id              _changeReportObject;
    NSMutableArray  *_items;
    NSUndoManager   *_undoManager;
}

// Content
- (NSMutableArray *)items;
- (void)setItems:(NSArray *)items;
- (void)addItems:(NSArray *)items;

- (NSFileWrapper *)fileWrapperWithItems;
- (void)setItemsWithFileWrapper:(NSFileWrapper *)wrapper;

// Conversion Methodes
+ (NSFileWrapper *)fileWrapperForItems:(NSArray *)items;
+ (NSArray *)itemsWithFileWrapper:(NSFileWrapper *)wrapper;

// Undo Support
- (NSUndoManager *)undoManager;

// Adding Items
- (void)addEmptyItem;
- (void)addEmptyItemAtIndex:(int)index;

- (void)addItemWithContent:(NSData *)data;
- (void)addItemWithContent:(NSData *)data atIndex:(int)index;

- (void)addItem:(CompositeObject *)object atIndex:(int)index;

// Changing Items
- (void)replaceItemAtIndex:(int)index withContent:(NSData *)data;
- (void)moveItemAtIndex:(int)oldIndex toIndex:(int)newIndex;

// Removing Items
- (void)removeEmptyItems;

- (void)removeItem:(CompositeObject *)object;
- (void)removeItemAtIndex:(int)index;

@end
