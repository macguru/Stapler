//
//  CompositeObjectTextView.m
//  Ulysses
//
//  Created by Max on 21.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeViewObject.h"
#import "CompositeObjectTextView.h"
#import "CompositeView.h"

@implementation CompositeObjectTextView

#pragma mark -
#pragma mark Accessors

- (CompositeViewObject *)owner
{
    return owner;
}

- (void)setOwner:(CompositeViewObject *)newOwner
{
    owner = newOwner;
}

- (BOOL)resignFirstResponder
{
    BOOL result;
    
    [self setSelectedRange: NSMakeRange(0, 0)];
    result = [super resignFirstResponder];
    [[owner containingView] setNeedsDisplay: YES];
    
    return result;
}

- (BOOL)becomeFirstResponder
{
    BOOL result;
    
    result = [super becomeFirstResponder];
    [[owner containingView] setNeedsDisplay: YES];
    [[owner containingView] setSelectedViewItemDidChange: owner];
    
    return result;
}

#pragma mark -
#pragma mark Custom events

- (void)keyDown:(NSEvent *)theEvent
{
    switch ([theEvent keyCode])
     {
        case 123:
        case 126:
            if (NSEqualRanges([self selectedRange], NSMakeRange(0, 0))) {
                [[owner containingView] changeSelectionFromItem:owner inDirection:NSSelectingPrevious];
                return;
            }
            if ([owner collapsed]) {
                [[owner containingView] changeSelectionFromItem:owner inDirection:NSSelectingPrevious];
                return;
            }
            break;
        case 124:
        case 125:
            if (NSEqualRanges([self selectedRange], NSMakeRange([[self string] length], 0))) {
                [[owner containingView] changeSelectionFromItem:owner inDirection:NSSelectingNext];
                return;
            }
            if ([owner collapsed]) {
                [[owner containingView] changeSelectionFromItem:owner inDirection:NSSelectingNext];
                return;
            }
            break;
        case 36:
            if ([theEvent modifierFlags] & NSControlKeyMask) {
                [owner toggleCollapsed: self];
                return;
            }
     }
    
    [super keyDown: theEvent];
}

#pragma mark -
#pragma mark Dragging expansion update

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSDragOperation operation;
    
    operation = [super draggingEntered: sender];
    wasCollapsed = [owner collapsed];
    
    if (operation != NSDragOperationNone && wasCollapsed)
        [owner startUncollapse];
    
    return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    [super draggingExited: sender];
    
    if ([owner collapsed])
        [owner abortUncollapse];
    
    if (![owner collapsed] && wasCollapsed)
        [owner setCollapsed: YES];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [super concludeDragOperation: sender];
    
    [[self window] makeFirstResponder: self];
}

#pragma mark -
#pragma mark Custom dragging of Attachments

- (BOOL)dragSelectionWithEvent:(NSEvent *)event offset:(NSSize)mouseOffset slideBack:(BOOL)slideBack
{
    NSTextAttachment *att;
    
    att = [[[self textStorage] attributesAtIndex:[self selectedRange].location effectiveRange:nil] objectForKey: NSAttachmentAttributeName];
    
    if ([self selectedRange].length == 1 && att != nil)
     {
        NSString *type;
        NSPoint location;
        
        location = [self convertPoint:[event locationInWindow] fromView:nil];
        type = [[[att fileWrapper] preferredFilename] pathExtension];
        
        [self dragPromisedFilesOfTypes:[NSArray arrayWithObject: type] fromRect:NSMakeRect(location.x - 17, location.y + 17, 0, 0) source:self slideBack:slideBack event:event];
        return YES;
     }
    
    return [super dragSelectionWithEvent:event offset:mouseOffset slideBack:slideBack];
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    NSTextAttachment *att;
    NSString *path;
    
    att = [[[self textStorage] attributesAtIndex:[self selectedRange].location effectiveRange:nil] objectForKey: NSAttachmentAttributeName];
    path = [[dropDestination path] stringByAppendingPathComponent: [[att fileWrapper] preferredFilename]];
    
    [[att fileWrapper] writeToFile:path atomically:YES updateFilenames:NO];
    
    return [NSArray arrayWithObject: [path lastPathComponent]];
}


@end
