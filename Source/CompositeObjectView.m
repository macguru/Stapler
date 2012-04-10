//
//  CompositeObjectView.m
//  Ulysses
//
//  Created by Max on 21.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeObjectView.h"
#import "CompositeViewObject.h"
#import "CompositeView.h"

@implementation CompositeObjectView

- (void)mouseDown:(NSEvent *)theEvent
{
    [[object containingView] selectItem:object direction:NSDirectSelection];
    
    if ([theEvent clickCount] == 2)
     {
        [object setCollapsed: YES];
     }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([theEvent modifierFlags] & NSCommandKeyMask)
     {
        [[object containingView] beginDragForObject:object withEvent:theEvent];
     }
}

- (id)target
{
    return _target;
}

- (void)setTarget:(id)anObject
{
    _target = anObject;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
    NSColor *backgroundColor, *borderColor;
    CompositeView *view;
    NSSize size;
    
    view = [object containingView];
    
    backgroundColor = [view backgroundColor];
    if ([view selectedViewItem] == object) {
        if ([object wasCompleted])
            borderColor = [view doneActiveColor];
        else
            borderColor = [view activeColor];
    } else {
        if ([object wasCompleted])
            borderColor = [view doneColor];
        else
            borderColor = [view toDoColor];
    }
    
    size = [self frame].size;
    
    [backgroundColor set];
    [NSBezierPath fillRect: NSMakeRect(0, 0, size.width, size.height)];
    
    if ([object collapsed] == NO)
     {
        [borderColor set];
        [NSBezierPath fillRect: NSMakeRect(0, 0, 27, size.height - 1)];
        [NSBezierPath fillRect: NSMakeRect(27, size.height - 22, size.width, 21)];
        
        [[borderColor blendedColorWithFraction:0.3 ofColor:[NSColor whiteColor]] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0, size.height - 0.5) toPoint:NSMakePoint(size.width, size.height - 0.5)];
     }
    else
     {
        [borderColor set];
        [NSBezierPath fillRect: NSMakeRect(0, 0, 27, size.height)];
     }
    
}

@end
