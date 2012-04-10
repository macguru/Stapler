//
//  CompositeView.h
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

@class CompositeObject, CompositeViewObject, CompositeViewStorage;

@interface CompositeView : NSView
{
    NSColor                 *_activeColor;
    BOOL                    _autosortsCompletedItems;
    NSColor                 *_backgroundColor;
    NSFont                  *_defaultFont;
    NSColor                 *_doneActiveColor;
    NSColor                 *_doneColor;
    int                     _insertionIndex;
    BOOL                    _isEditable;
    NSClipView              *_lineView;
    float                   _rowHeight;
    BOOL                    _selectItem;
    int                     _selectedItem;
    CompositeViewStorage    *_storage;
    NSColor                 *_toDoColor;
    NSMutableArray          *_viewObjects;
}

// Accessors
- (CompositeViewStorage *)storage;
- (void)setStorage:(CompositeViewStorage *)aStorage;

- (NSUndoManager *)undoManager;
- (NSScrollView *)enclosingView;

- (NSColor *)activeColor;
- (void)setActiveColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)doneActiveColor;
- (void)setDoneActiveColor:(NSColor *)color;
- (NSColor *)doneColor;
- (void)setDoneColor:(NSColor *)color;
- (NSColor *)toDoColor;
- (void)setToDoColor:(NSColor *)color;

- (NSFont *)defaultFont;
- (void)setDefaultFont:(NSFont *)newFont;

- (float)rowHeight;
- (void)setRowHeight:(float)newHeight;

- (BOOL)isEditable;
- (void)setIsEditable:(BOOL)flag;

// Autosorting
- (BOOL)autosortsCompletedItems;
- (void)setAutosortsCompletedItems:(BOOL)flag;

- (void)autosortItem:(CompositeViewObject *)object;

// Printing
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError;

// Common Methodes
- (void)addEmptyItem;
- (void)removeSelectedItem;

- (void)collapseAll:(BOOL)closed;
- (void)beginDragForObject:(CompositeViewObject *)draggedObject withEvent:(NSEvent *)event;

// Selection
- (int)selectedItem;
- (CompositeViewObject *)selectedViewItem;
- (void)setSelectedViewItemDidChange:(CompositeViewObject *)object;

- (void)setSelectedItem:(int)index;
- (void)setSelectedItem:(int)index direction:(NSSelectionDirection)direction;

- (void)selectItem:(CompositeViewObject *)object direction:(NSSelectionDirection)direction;

- (void)changeSelectionFromItem:(CompositeViewObject *)object inDirection:(NSSelectionDirection)direction;

@end
