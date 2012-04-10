//
//  CompositeView.m
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

#import "CompositeViewStorage.h"
#import "CompositeObjectTextView.h"
#import "CompositeObjectView.h"
#import "CompositeViewObject.h"
#import "CompositeObject.h"
#import "CompositeView.h"

NSString *CompositeObjectReferencePboardType = @"CompositeObjectReferencePboard";

@interface CompositeView (CompositeViewInternal)

- (NSPoint)originForViewAtIndex:(unsigned)index;
- (void)recalculateViewSize;
- (void)updateViewSize;

- (void)performAddObject:(CompositeObject *)object atIndex:(unsigned)index;
- (void)performMoveObjectsFromIndex:(unsigned)index byDelta:(float)delta;
- (void)performRemoveObjectAtIndex:(unsigned)index;

@end

@implementation CompositeView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame: frame];
    
    _backgroundColor = [[NSColor whiteColor] copy];
    _activeColor = [[NSColor redColor] copy];
    _doneColor = [[NSColor yellowColor] copy];
    _doneActiveColor = [[NSColor lightGrayColor] copy];
    _toDoColor = [[NSColor blueColor] copy];
    
    _autosortsCompletedItems = NO;
    _defaultFont = [[NSFont systemFontOfSize: 11.0] retain];
    _insertionIndex = -1;
    _isEditable = YES;
    _lineView = nil;
    _rowHeight = kCompositeViewStandardRowHeight;
    _selectItem = YES;
    _selectedItem = -1;
    _storage = nil;
    _viewObjects = [[NSMutableArray alloc] init];
    
    [self registerForDraggedTypes: [NSArray arrayWithObjects: CompositeObjectReferencePboardType, NSStringPboardType, NSFilenamesPboardType, NSRTFPboardType, nil]];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_backgroundColor release];
    [_activeColor release];
    [_doneColor release];
    [_doneActiveColor release];
    [_toDoColor release];
    
    [_defaultFont release];
    [_viewObjects release];
    
    [super dealloc];
}

- (void)viewDidMoveToSuperview
{ 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViewSize) name:NSViewFrameDidChangeNotification object:[self superview]];
}

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark -
#pragma mark Accessors

- (CompositeViewStorage *)storage
{
    return _storage;
}

- (void)setStorage:(CompositeViewStorage *)aStorage
{
    // remove old source
    if (_storage != nil) {
        [_storage removeObserver:self forKeyPath:@"items"];
        _storage = nil;
    }
    
    // change
    _storage = aStorage;
    
    // setup new source
    if (_storage != nil)
        [_storage addObserver:self forKeyPath:@"items" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    // update views
    [self observeValueForKeyPath:@"items" ofObject:_storage change:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: NSKeyValueChangeSetting], NSKeyValueChangeKindKey, nil] context:nil];
    
    // select the last one
    [self setSelectedItem: 0];
}

- (NSUndoManager *)undoManager
{
    return [_storage undoManager];
}

- (NSScrollView *)enclosingView
{
    return (NSScrollView *)[[self superview] superview];
}

#pragma mark -

- (NSColor *)backgroundColor
{
    return _backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)color
{
    [_backgroundColor release];
    _backgroundColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

- (NSColor *)activeColor
{
    return _activeColor;
}

- (void)setActiveColor:(NSColor *)color
{
    [_activeColor release];
    _activeColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

- (NSColor *)doneColor
{
    return _doneColor;
}

- (void)setDoneColor:(NSColor *)color
{
    [_doneColor release];
    _doneColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

- (NSColor *)doneActiveColor
{
    return _doneActiveColor;
}

- (void)setDoneActiveColor:(NSColor *)color
{
    [_doneActiveColor release];
    _doneActiveColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

- (NSColor *)toDoColor
{
    return _toDoColor;
}

- (void)setToDoColor:(NSColor *)color
{
    [_toDoColor release];
    _toDoColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

- (NSFont *)defaultFont
{
    return _defaultFont;
}

- (void)setDefaultFont:(NSFont *)newFont
{
    [_defaultFont release];
    _defaultFont = [newFont retain];
}

- (float)rowHeight
{
    return _rowHeight;
}

- (void)setRowHeight:(float)newHeight
{
    _rowHeight = newHeight;
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setIsEditable:(BOOL)flag
{
    _isEditable = flag;
}

#pragma mark -
#pragma mark Autosorting

- (BOOL)autosortsCompletedItems
{
    return _autosortsCompletedItems;
}

- (void)setAutosortsCompletedItems:(BOOL)flag
{
    _autosortsCompletedItems = flag;
}

- (void)autosortItem:(CompositeViewObject *)object
{
    if (![object wasCompleted] || ![self autosortsCompletedItems])
        return;
    
    [_storage moveItemAtIndex:[[_storage items] indexOfObject: [object sourceObject]] toIndex:[[_storage items] count]];
}

#pragma mark -
#pragma mark Common Methodes

- (void)addEmptyItem
{
    if ([self isEditable])
        [_storage addEmptyItem];
}

- (void)removeSelectedItem
{
    if ([self isEditable] && [self selectedItem] != -1)
        [_storage removeItemAtIndex: [self selectedItem]];
}

#pragma mark -

- (void)collapseAll:(BOOL)closed
{
    unsigned i;
    
    for (i=0; i<[_viewObjects count]; i++)
     {
        [[_viewObjects objectAtIndex: i] setCollapsed: closed];
     }
    
    [self setNeedsDisplayInRect: [self visibleRect]];
}

#pragma mark -

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
    NSMutableParagraphStyle *style, *styleStart;
    NSPrintOperation *operation;
    NSTextStorage *textStorage;
    NSDictionary *attributes;
    NSTextView *textView;
    NSArray *items;
    NSRect frame;
    unsigned i;
    
    // Generate view
    textView = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 50, 50)];
    textStorage = [textView textStorage];
    operation = [NSPrintOperation printOperationWithView: textView];
    
    [textView release];
    
    // Adjust frame
    frame = [textView frame];
    frame.size.width = [[operation printInfo] paperSize].width - [[operation printInfo] leftMargin] - [[operation printInfo] rightMargin];
    [textView setFrameSize: frame.size];
    
    // Setup content
    attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont fontWithName:@"Apple Symbols" size: 16], NSFontAttributeName, nil];
    items = [_storage items];
    
    styleStart = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [styleStart setFirstLineHeadIndent: 0];
    [styleStart setHeadIndent: 24.0];
    
    style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setFirstLineHeadIndent: 24.0];
    [style setHeadIndent: 24.0];
    
    // Generate content
    for (i=0; i<[items count]; i++) {
        CompositeObject *object;
        unichar character;
        
        object = [items objectAtIndex: i];
        character = ([object wasCompleted]) ? 0x2612 : 0x2610;
        
        [textStorage replaceCharactersInRange:NSMakeRange([textStorage length], 0) withString:[NSString stringWithCharacters:&character length:1]];
        [textStorage replaceCharactersInRange:NSMakeRange([textStorage length], 0) withString:@"  "];
        [textStorage setAttributes:attributes range:NSMakeRange([textStorage length]-3, 3)];
        
        [textStorage replaceCharactersInRange:NSMakeRange([textStorage length], 0) withAttributedString:(NSAttributedString *)[object contentTextStorage]];
        [textStorage addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange([textStorage length]-[[object contentTextStorage] length], [[object contentTextStorage] length])];
        [textStorage addAttribute:NSParagraphStyleAttributeName value:styleStart range:NSMakeRange([textStorage length]-[[object contentTextStorage] length]-3, 3)];
        
        [textStorage replaceCharactersInRange:NSMakeRange([textStorage length], 0) withString:@"\n"];
        [textStorage addAttributes:attributes range:NSMakeRange([textStorage length]-1, 1)];
    }
    
    [textView sizeToFit];
    
    return operation;
}

#pragma mark -
#pragma mark Dragging

- (void)beginDragForObject:(CompositeViewObject *)draggedObject withEvent:(NSEvent *)event
{
    NSImage *image, *temp_img;
    NSPasteboard *pboard;
    unsigned index;
    NSRect rect;
    
    pboard = [NSPasteboard generalPasteboard];
    index = [_viewObjects indexOfObject: draggedObject];
    
    // Preparing Pasteboard
    [pboard declareTypes:[NSArray arrayWithObject: CompositeObjectReferencePboardType] owner:self];
    [pboard setPropertyList:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt: index], @"index", [NSNumber numberWithInt: (int)draggedObject], @"object", nil] forType:CompositeObjectReferencePboardType];
    
    // Creating Image
    image = [[NSImage alloc] initWithSize: [draggedObject frame].size];
    rect = NSMakeRect(0, 0, [image size].width, [image size].height);
    
    // Drawing temporary Image
    temp_img = [[NSImage alloc] initWithSize: [image size]];
    
    [temp_img lockFocus];
    
    [_backgroundColor set];
    [NSBezierPath fillRect: rect];
    
    [(NSPDFImageRep *)[NSPDFImageRep imageRepWithData: [[draggedObject view] dataWithPDFInsideRect: rect]] drawAtPoint: NSZeroPoint];
    
    [temp_img unlockFocus];
    
    // Drawing Image
    [image lockFocus];
    
    [temp_img dissolveToPoint:NSZeroPoint fraction:0.8];
    
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect: rect];
    
    [image unlockFocus];
    
    // Creationg Drag Operation
    [self dragImage:image at:[self originForViewAtIndex:index+1] offset:NSMakeSize(0, 0) event:event pasteboard:pboard source:self slideBack:YES];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return [self draggingUpdated: sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    // Check wether we're dragging an item
    if ([[sender draggingPasteboard] dataForType: CompositeObjectReferencePboardType])
     {
        NSPoint location;
        unsigned i;
        
        location = [self convertPoint:[sender draggingLocation] fromView:nil];
        _insertionIndex = 0;
        
        for (i=0; i<[_viewObjects count]; i++)
         {
            NSRect frame;
            
            frame = [[_viewObjects objectAtIndex: i] frame];
            
            if (location.y < frame.origin.y + frame.size.height / 2)
                break;
            
            _insertionIndex++;
         }
        
        [self setNeedsDisplay: YES];
        
        if ([sender draggingSource] == self)
            return NSDragOperationMove;
        else
            return NSDragOperationCopy;
     }
    
    // Otherwise prepare to add item
    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    _insertionIndex = -1;
    [self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    // Check wether we're dragging an item
    if ([[sender draggingPasteboard] dataForType: CompositeObjectReferencePboardType])
     {
        if ([sender draggingSource] == self)
         {
            unsigned index;
            
            index = [[[[sender draggingPasteboard] propertyListForType: CompositeObjectReferencePboardType] objectForKey: @"index"] intValue];
            
            if (index != [self selectedItem] || [[self selectedViewItem] collapsed])
                _selectItem = NO;
            [_storage moveItemAtIndex:index toIndex:_insertionIndex];
            _selectItem = YES;
         }
        else
         {
            CompositeViewObject *viewObject;
            CompositeObject *object, *new;
            
            viewObject = (CompositeViewObject *)[[[[sender draggingPasteboard] propertyListForType: CompositeObjectReferencePboardType] objectForKey: @"object"] intValue];
            object = [viewObject sourceObject];
            
            new = [CompositeObject objectWithContent: [object content]];
            [new setCollapsed: [object collapsed]];
            [_storage addItem:new atIndex:_insertionIndex];
         }
     }
    // Otherwise add new item
    else
     {
        NSAttributedString *string;
        NSArray *types;
        
        types = [[sender draggingPasteboard] types];
        string = nil;
        
        if ([types containsObject: NSRTFPboardType]) {
            string = [[[NSAttributedString alloc] initWithRTF:[[sender draggingPasteboard] dataForType: NSRTFPboardType] documentAttributes:nil] autorelease];
        }
        else if ([types containsObject: NSFilenamesPboardType]) {
            unichar character;
            NSArray *files;
            
            files = [[sender draggingPasteboard] propertyListForType: NSFilenamesPboardType];
            character = NSAttachmentCharacter;
            
            for (unsigned i=0; i<[files count]; i++) {
                
                if (!(string = [[NSAttributedString alloc] initWithPath:[files objectAtIndex: i] documentAttributes:nil])) {
                    character = NSAttachmentCharacter;
                    
					NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithCharacters:&character length:1]];
                    [mutableString addAttribute:NSAttachmentAttributeName value:[[[NSTextAttachment alloc] initWithFileWrapper: [[[NSFileWrapper alloc] initWithPath: [files objectAtIndex: i]] autorelease]] autorelease] range:NSMakeRange(0,1)];
					string = mutableString;
                }
                
                [_storage addItemWithContent: [string RTFDFromRange:NSMakeRange(0, [string length]) documentAttributes:nil]];
            }
            
            string = nil;
        }
        else if ([types containsObject: NSStringPboardType]) {
            string = [[[NSAttributedString alloc] initWithString:[[sender draggingPasteboard] stringForType: NSStringPboardType] attributes:[NSDictionary dictionaryWithObject:[self defaultFont] forKey:NSFontAttributeName]] autorelease];
        }
        
        if (string)
            [_storage addItemWithContent: [string RTFDFromRange:NSMakeRange(0, [string length]) documentAttributes:nil]];
     }
    
    _insertionIndex = -1;
    [self setNeedsDisplay: YES];
    
    return YES;
}

#pragma mark -
#pragma mark Selection

- (int)selectedItem
{
    return _selectedItem;
}

- (CompositeViewObject *)selectedViewItem
{
    if (_selectedItem >= 0)
        return [_viewObjects objectAtIndex: _selectedItem];
    else
        return nil;
}

- (void)setSelectedItemDidChange:(int)index
{
    _selectedItem = index;
}

- (void)setSelectedViewItemDidChange:(CompositeViewObject *)object
{
    int index;
    
    index = [_viewObjects indexOfObject: object];
    if (index == NSNotFound)
        index = -1;
    
    [self setSelectedItemDidChange: index];
}

- (void)setSelectedItem:(int)index
{
    [self setSelectedItem:index direction:NSDirectSelection];
}

- (void)setSelectedItem:(int)index direction:(NSSelectionDirection)direction
{
    if (index < 0 || index >= [_viewObjects count]) {
        [self setSelectedItemDidChange: -1];
        return;
    }
    
    [self selectItem:[_viewObjects objectAtIndex: index] direction:direction];
}

- (void)selectItem:(CompositeViewObject *)object direction:(NSSelectionDirection)direction
{
    NSRange range;
    
    [self willChangeValueForKey: @"selection"];
    
    if ([self isEditable])
        [[self window] makeFirstResponder: [object textView]];
    [self setSelectedViewItemDidChange: object];
    
    switch (direction)
     {
        case NSDirectSelection:
            range = NSMakeRange([[object string] length], 0);
            if ([object collapsed])
                [object setCollapsed: NO];
                break;
        case NSSelectingNext:
            range = NSMakeRange(0, 0);
            break;
        case NSSelectingPrevious:
            range = NSMakeRange([[object string] length], 0);
            break;
        default:
            range = NSMakeRange(0, 0);
            break;
     }
    
    if ([object collapsed])
        range = NSMakeRange(0, 0);
    
    [[object textView] setSelectedRange: range];
    
    [self didChangeValueForKey: @"selection"];
}

- (void)changeSelectionFromItem:(CompositeViewObject *)object inDirection:(NSSelectionDirection)direction
{
    switch (direction)
     {
        case NSDirectSelection:
            [self selectItem:object direction:direction];
            break;
        case NSSelectingNext:
            if ([_viewObjects indexOfObject: object] < [_viewObjects count] - 1)
                [self selectItem:[_viewObjects objectAtIndex: [_viewObjects indexOfObject: object]+1] direction:direction];
            break;
        case NSSelectingPrevious:
            if ([_viewObjects indexOfObject: object] > 0)
                [self selectItem:[_viewObjects objectAtIndex: [_viewObjects indexOfObject: object]-1] direction:direction];
            break;
     }
}

#pragma mark -
#pragma mark Observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSKeyValueChange changeType;
    
    if (object == _storage)
        changeType = [[change objectForKey: NSKeyValueChangeKindKey] intValue];
    else
        changeType = NSKeyValueChangeSetting;
    
    switch (changeType)
     {
        case NSKeyValueChangeInsertion:
         {
             NSIndexSet *indexes;
             unsigned i, index;
             NSArray *objects;
             
             objects = [change objectForKey: NSKeyValueChangeNewKey];
             indexes = [change objectForKey: NSKeyValueChangeIndexesKey];
             index = [indexes firstIndex];
             
             for (i=0; i<[objects count]; i++) {
                 [self performAddObject:[objects objectAtIndex: i] atIndex:index];
                 index = [indexes indexGreaterThanIndex: index];
             }
             
             [self recalculateViewSize];
             [self setNeedsDisplay: YES];
             
             if ([_viewObjects count]) {
                 if (_selectItem)
                     [self selectItem:[_viewObjects objectAtIndex: [indexes lastIndex]] direction:NSDirectSelection];
                 [self scrollRectToVisible: [[_viewObjects objectAtIndex: [indexes lastIndex]] frame]];
             }
             break;
         }
        case NSKeyValueChangeSetting:
         {
             if (object == _storage) // All objects did change
              {
                 NSArray *objects;
                 unsigned i;
                 
                 objects = [_storage items];
                 
                 // remove all
                 while ([_viewObjects count])
                     [self performRemoveObjectAtIndex: 0];
                 // add all
                 for (i=0; i<[objects count]; i++)
                     [self performAddObject:[objects objectAtIndex: i] atIndex:i];
                 
                 [self recalculateViewSize];
                 [self setNeedsDisplay: YES];
              }
             else // One object did change frame
              {
                 NSRect oldFrame, newFrame;
                 float delta;
                 
                 oldFrame = [[change objectForKey: NSKeyValueChangeOldKey] rectValue];
                 newFrame = [[change objectForKey: NSKeyValueChangeNewKey] rectValue];
                 delta = newFrame.size.height - oldFrame.size.height;
                 
                 if (delta != 0)
                  {
                     [self recalculateViewSize];
                     [self performMoveObjectsFromIndex:[_viewObjects indexOfObject: object]+1 byDelta:delta];
                  }
              }
             
             [self setNeedsDisplay: YES];
             break;
         }
        case NSKeyValueChangeReplacement:
         {
             [self setNeedsDisplay: YES];
             break;
         }
        case NSKeyValueChangeRemoval:
         {
            NSIndexSet *indexes;
            unsigned index;
            
            indexes = [change objectForKey: NSKeyValueChangeIndexesKey];
            index = [indexes firstIndex];
            
            while (index < NSNotFound) {
                [self performRemoveObjectAtIndex:index];
                index = [indexes indexGreaterThanIndex: index];
            }
                
            [self recalculateViewSize];
            [self setNeedsDisplay: YES];
            break;
         }
        default:
            break;
     }
}

#pragma mark -
#pragma mark View Arrangement

- (NSPoint)originForViewAtIndex:(unsigned)index
{
    NSPoint point;
    unsigned i;
    
    point = NSMakePoint(0, 0);
    
    for (i=0; i<index; i++)
     {
        point.y += [[_viewObjects objectAtIndex: i] frame].size.height + 1;
     }
    
    return point;
}

- (void)recalculateViewSize
{
    NSRect frame;
    float height;
    
    height = [self originForViewAtIndex: [_viewObjects count]].y;    
    height = fmax(height, [[self superview] frame].size.height);
    
    frame = [self frame];
    frame.size.height = height - 1;
    frame.size.width = [[self superview] frame].size.width;
    
    [self setFrame: frame];
}

- (void)updateViewSize
{
    static BOOL recalc = NO;
    
    if (!recalc) {
        recalc = YES;
        [self recalculateViewSize];
        [self setNeedsDisplay: YES];
        recalc = NO;
    }
}

#pragma mark -

- (void)performAddObject:(CompositeObject *)object atIndex:(unsigned)index
{
    CompositeViewObject *viewObject;
    NSRect frame;
    
    // create view object
    viewObject = [CompositeViewObject objectWithSourceObject: object];
    [_viewObjects insertObject:viewObject atIndex:index];
    
    // adjust size
    frame = [viewObject frame];
    frame.size.width = [self frame].size.width;
    frame.origin = [self originForViewAtIndex: index];
    [viewObject setFrame: frame];
    
    // add view
    [viewObject setContainingView: self];
    [self addSubview: [viewObject view]];
    
    // adjust to match content
    [viewObject setCollapsed: [viewObject collapsed]];
    frame = [viewObject frame];
    
    // add observation
    [viewObject addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    // move others
    [self performMoveObjectsFromIndex:index+1 byDelta:frame.size.height+1];
}

- (void)performMoveObjectsFromIndex:(unsigned)index byDelta:(float)delta
{
    unsigned i;
    
    for (i=index; i<[_viewObjects count]; i++)
     {
        CompositeViewObject *viewObject;
        
        viewObject = [_viewObjects objectAtIndex: i];
        [viewObject setFrame: NSOffsetRect([viewObject frame], 0, delta)];
     }
}

- (void)performRemoveObjectAtIndex:(unsigned)index
{
    CompositeViewObject *viewObject;
    float height;
    
    // get objects
    viewObject = [_viewObjects objectAtIndex: index];
    height = [viewObject frame].size.height;
    
    // remove view and observation
    [viewObject setContainingView: nil];
    [[viewObject view] removeFromSuperview];
    [viewObject removeObserver:self forKeyPath:@"frame"];
    
    // delete view object
    [_viewObjects removeObjectAtIndex: index];
    
    // move others
    [self performMoveObjectsFromIndex:index byDelta: -height-1];
    
    // update selection
    [self setSelectedItem:(index < [_viewObjects count]) ? index : [_viewObjects count]-1 direction:NSSelectingNext];
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self window] makeFirstResponder: self];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
    float y, max;
    int z, count;
    
    [super drawRect: rect];
    
    // Get / Create utilities
    max = [self originForViewAtIndex: [_viewObjects count]].y;
    if (!_lineView) {
        _lineView = [[NSClipView alloc] initWithFrame: NSMakeRect(0, 0, 10, 2)];
        [_lineView setBackgroundColor: [NSColor blackColor]];
        [self addSubview: _lineView];
        [_lineView release];
    }
    if ([_lineView isHidden] == (_insertionIndex >= 0)) {
        [_lineView setHidden: !(_insertionIndex >= 0)];
        
        [_lineView retain];
        [_lineView removeFromSuperviewWithoutNeedingDisplay];
        [self addSubview: _lineView];
        [_lineView release];
    }
    
    // Draw Background
    if (NSMaxY(rect) < max)
     {
        [_backgroundColor set];
        [NSBezierPath fillRect: rect];
     }
    else
     {
        [_backgroundColor set];
        [NSBezierPath fillRect: NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, max - rect.origin.y)];
        
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect: NSMakeRect(rect.origin.x, max, rect.size.width, NSMaxY(rect) - max)];
     }
    
    // Determine some numbers
    count = [_viewObjects count];
    y = NSMinY(rect);
    z = 0 - (_insertionIndex == 0);
    
    while (z < count && y > [self originForViewAtIndex: ++z].y);
    
    // Draw divider lines
    while (z < count + (count > 0) && y <= NSMaxY(rect))
     {
        y = [self originForViewAtIndex: z++].y;
        
        if (_insertionIndex == z - 1)
         {
            [_lineView setFrame: NSMakeRect(NSMinX(rect), y-1, NSMaxX(rect), 2)];
         }
        else
         {
            [[_backgroundColor blendedColorWithFraction:0.44 ofColor:[NSColor blackColor]] set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rect), y-0.5) toPoint:NSMakePoint(NSMaxX(rect), y-0.5)];
         }
     }
}

@end
