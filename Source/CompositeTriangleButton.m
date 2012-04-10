//
//  CompositeTriangleButton.m
//  Ulysses
//
//  Created by Max on 22.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeTriangleButton.h"
#import "CompositeObjectTextView.h"
#import "CompositeViewObject.h"
#import "CompositeView.h"

@implementation CompositeTriangleButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    
    [self setBezelStyle: NSDisclosureBezelStyle];
    blinks = NO;
    
    return self;
}

- (void)startBlinking
{
    blinks = YES;
    
    drawTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(blink:) userInfo:nil repeats:YES];
    [drawTimer fire];
}

- (void)blink:(NSTimer *)timer
{
    [self display];
    blinks = !blinks;
}

- (void)stopBlinking
{
    blinks = NO;
    [self display];
    
    if (drawTimer) {
        [drawTimer invalidate];
        drawTimer = nil;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!([theEvent modifierFlags] & NSCommandKeyMask))
     {
        event = theEvent;
        [super mouseDown: theEvent];
        event = nil;
     }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([theEvent modifierFlags] & NSCommandKeyMask)
        [[self superview] mouseDragged: theEvent];
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
    if ([event modifierFlags] & NSAlternateKeyMask)
     {
        [[(CompositeViewObject *)theTarget containingView] collapseAll: ![(CompositeViewObject *)theTarget collapsed]];
        [[(CompositeViewObject *)theTarget containingView] display]; // hacky, sorry
        return YES;
     }
    else
     {
        return [super sendAction:nil to:nil];
     }
}
/*
- (void)drawRect:(NSRect)rect
{
    NSString *name;
    
    name = @"Arrow";
    name = [name stringByAppendingString: ([self state]) ? @"Open" : @"Closed"];
    name = [name stringByAppendingString: ([[self cell] isHighlighted]) ? @"On" : @"Off"];
    
    [[NSImage imageNamed: name] compositeToPoint:NSMakePoint(1 + ![self state], 10 - [self state]) operation:NSCompositeSourceOver];
    
    
    if (blinks) {
        [[[[(CompositeViewObject *)[self target] textView] backgroundColor] colorWithAlphaComponent: 0.3] set];
        [NSBezierPath fillRect: rect];
    }
}*/

@end
