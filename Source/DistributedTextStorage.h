//
//  DistributedTextStorage.h
//  Ulysses
//
//  Created by Max on 02.01.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

#import "ChangeReport.h"

@class DistributingTextStorage;

@interface DistributedTextStorage : NSTextStorage <ChangeReport>
{
    DistributingTextStorage *_tStorage;
}

// Initialization
- (id)initWithTextStorage:(DistributingTextStorage *)textStorage;

// Accessors
- (DistributingTextStorage *)parentTextStorage;
- (void)setParentTextStorage:(DistributingTextStorage *)textStorage;

// Undo Support
- (NSUndoManager *)undoManager;

// Editing
- (void)beginEditing;
- (void)endEditing;
- (void)beginDistributedEditing;
- (void)endDistributedEditing;

@end
