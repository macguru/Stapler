//
//  DistributingTextStorage.h
//  Ulysses
//
//  Created by Max on 02.01.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

#import "ChangeReport.h"

@interface DistributingTextStorage : NSTextStorage <ChangeReport>
{
    SEL             _changeReportAction;
    id              _changeReportObject;
    NSMutableArray  *_distributedTextStorages;
    NSTextStorage   *_tStorage;
    NSUndoManager   *_undoManager;
}

// TextStorage Distribution
- (void)addDistributedTextStorage:(NSTextStorage *)aTextStorage;
- (void)removeDistributedTextStorage:(NSTextStorage *)aTextStorage;

// Undo Support
- (NSUndoManager *)undoManager;

// Editing
- (void)distributedEdited:(unsigned)editedMask range:(NSRange)range changeInLength:(int)delta;

- (void)willEditCharactersInRange:(NSRange)range;
- (void)didEditCharactersInRange:(NSRange)range;

@end

@interface NSObject (DistributingTextStorageDelegate)

- (void)textStorage:(DistributingTextStorage *)textStorage willEditCharactersInRange:(NSRange)range;
- (void)textStorage:(DistributingTextStorage *)textStorage didEditCharactersInRange:(NSRange)range;

@end