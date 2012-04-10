//
//  CompositeViewObject.m
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeViewObject.h"

#import "CompositeObject.h"
#import "CompositeTriangleButton.h"
#import "CompositeView.h"
#import "DistributedTextStorage.h"

float kCompositeViewStandardRowHeight = 21;

@interface CompositeViewObject (CompositeObjectInternal)

- (void)frameChanged;

@end

@implementation CompositeViewObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self unbind:@"rowHeight"];
    
    [_sourceObject removeObserver:self forKeyPath:@"content"];
    [_sourceObject removeObserver:self forKeyPath:@"collapsed"];
    [_sourceObject release];
    
    [view release];
    [_textStorage setParentTextStorage: nil];
    [_textStorage release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Initializer

- (id)initWithSourceObject:(CompositeObject *)object
{
    self = [super init];
    
    _collapseTimer = nil;
    _rowHeight = kCompositeViewStandardRowHeight;
    _textStorage = [[DistributedTextStorage alloc] init];
    _sourceObject = [object retain];
    
    [self setCollapsed: [self collapsed]];
    
    [_textStorage setParentTextStorage: [_sourceObject contentTextStorage]];
    [_sourceObject addObserver:self forKeyPath:@"collapsed" options:0 context:nil];
    
    [NSBundle loadNibNamed:@"CompositeViewObject" owner:self];
    
    return self;
}

+ (CompositeViewObject *)objectWithSourceObject:(CompositeObject *)object
{
    return [[[self alloc] initWithSourceObject: object] autorelease];
}

#pragma mark -
#pragma mark Interface Setup

- (void)awakeFromNib
{
    [textView setDrawsBackground: NO];
    [textView setTextContainerInset: NSMakeSize(10, 10)];
    [_textStorage addLayoutManager: [textView layoutManager]];
    
    _frame = [view frame];
    _frame.origin = NSZeroPoint;
    [view setFrame: _frame];
    
    [textView setAllowsDocumentBackgroundColorChange: NO];
    [textView setImportsGraphics: YES];
    [textView setAllowsUndo: YES];
    [[textView layoutManager] setDefaultAttachmentScaling: NSScaleProportionally];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged) name:NSViewFrameDidChangeNotification object:textView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textEdited) name:NSTextDidChangeNotification object:textView];
}

#pragma mark -
#pragma mark Properties

- (NSString *)string
{
    return [textView string];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self willChangeValueForKey: keyPath];
    [self didChangeValueForKey: keyPath];
    
    [self setCollapsed: [self collapsed]];
}

- (BOOL)collapsed
{
    return [_sourceObject collapsed];
}

- (void)setCollapsed:(BOOL)flag
{
    if ([_sourceObject collapsed] != flag)
        [_sourceObject setCollapsed: flag];
    
    if (!flag)
     {
        [textView sizeToFit];
     }
    else
     {
        NSRect rect;
        
        rect = [view frame];
        rect.size.height = [self rowHeight];
        [self setFrame: rect];
        
        rect = [textView frame];
        rect.size.height = [self rowHeight]-2;
        rect.origin.y = 0;
        [textView setFrame: rect];
     }
    
    [[view superview] setNeedsDisplayInRect: [self frame]];
}

- (CompositeObject *)sourceObject
{
    return _sourceObject;
}

- (NSRect)frame
{
    return _frame;
}

- (void)setFrame:(NSRect)rect
{
    _frame = rect;
    [view setFrame: _frame];
}

- (float)rowHeight
{
    return _rowHeight;
}

- (void)setRowHeight:(float)newHeight
{
    _rowHeight = newHeight;
    
    NSRect frame;
    
    frame = [button frame];
    frame.origin.y = [self frame].size.height - _rowHeight + floor((_rowHeight - frame.size.height) / 2);
    [button setFrame: frame];
    
    [self frameChanged];
}

- (NSDate *)completionDate
{
    return [_sourceObject completionDate];
}

- (NSDate *)creationDate
{
    return [_sourceObject creationDate];
}

- (BOOL)wasCompleted
{
    return [_sourceObject wasCompleted];
}

- (void)setWasCompleted:(BOOL)flag
{
    [_sourceObject setWasCompleted: flag];
    [_containingView autosortItem: self];
    [view display];
}

#pragma mark -
#pragma mark Relationships

- (CompositeView *)containingView
{
    return _containingView;
}

- (void)setContainingView:(CompositeView *)aView
{
    if (_containingView) {
        [textView unbind:@"editable"];
        [self unbind:@"rowHeight"];
    }
    
    _containingView = aView;
    
    if (_containingView) {
        [textView bind:@"editable" toObject:_containingView withKeyPath:@"isEditable" options:nil];
        [self bind:@"rowHeight" toObject:_containingView withKeyPath:@"rowHeight" options:nil];
        
        [self setRowHeight: [_containingView rowHeight]];
        if (![[textView string] length] && [_containingView defaultFont])
            [textView setFont: [_containingView defaultFont]];
        
        [textView sizeToFit];
    }
}

#pragma mark -
#pragma mark Interface Actions

- (IBAction)toggleCollapsed:(id)sender
{
    [self setCollapsed: ![self collapsed]];
}

- (void)startUncollapse
{
    _collapseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(performUncollapse:) userInfo:nil repeats:NO];
    [[self button] startBlinking];
}

- (void)performUncollapse:(NSTimer *)timer
{
    [[self button] stopBlinking];
    _collapseTimer = nil;
    
    [self setCollapsed: NO];
}

- (void)abortUncollapse
{
    if (_collapseTimer != nil) {
        [_collapseTimer invalidate];
        _collapseTimer = nil;
    }
    
    [[self button] stopBlinking];
}

#pragma mark -
#pragma mark Interface Accessors

- (CompositeTriangleButton *)button
{
    return (CompositeTriangleButton *)button;
}

- (CompositeObjectTextView *)textView
{
    return (CompositeObjectTextView *)textView;
}

- (CompositeObjectView *)view
{
    return (CompositeObjectView *)view;
}

#pragma mark -
#pragma mark Notifications

- (void)frameChanged
{
    static BOOL corrected = NO;
    NSRect textRect, viewRect, infoRect;
    
    textRect = [textView frame];
    viewRect = [view frame];
    
    if (!corrected)
     {
        corrected = YES;
        
        textRect.size.width = viewRect.size.width - textRect.origin.x;
        
        if (![self collapsed]) {
            viewRect.size.height = fmax([self rowHeight], textRect.size.height + 27);
            
            textRect.origin.y = viewRect.size.height - textRect.size.height - 25;
            
            infoRect = [infoView frame];
            infoRect.origin.y = viewRect.size.height - infoRect.size.height - 4;
            [infoView setFrame: infoRect];
        } else {
            textRect.size.height = [self rowHeight]+7;
            textRect.origin.y = 0;
            viewRect.size.height = [self rowHeight];
        }
        
        [self setFrame: viewRect];
        [[textView textContainer] setContainerSize: NSMakeSize(textRect.size.width - [textView textContainerInset].width * 2, INT_MAX)];
        [textView setFrame: textRect];
        
        corrected = NO;
     }
}

- (void)textEdited
{
    if ([self collapsed])
        [self setCollapsed: NO];
}

#pragma mark -
#pragma mark Delegate Methodes

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView
{
    return [_containingView undoManager];
}

@end
