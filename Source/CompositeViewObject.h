//
//  CompositeViewObject.h
//  Ulysses
//
//  Created by Max on 18.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

extern float kCompositeViewStandardRowHeight;

@class CompositeObject, CompositeObjectTextView, CompositeObjectView, CompositeTriangleButton, CompositeView, DistributedTextStorage;

@interface CompositeViewObject : NSObject
{
    // Interface
    IBOutlet NSButton   *button;
    IBOutlet NSView     *infoView;
    IBOutlet NSTextView *textView;
    IBOutlet NSView     *view;
    
    // Properties
    NSTimer                 *_collapseTimer;
    CompositeView           *_containingView;
    NSRect                  _frame;
    int                     _rowHeight;
    CompositeObject         *_sourceObject;
    DistributedTextStorage  *_textStorage;
}

- (id)initWithSourceObject:(CompositeObject *)object;
+ (CompositeViewObject *)objectWithSourceObject:(CompositeObject *)object;

- (CompositeObject *)sourceObject;

// Properties
- (BOOL)collapsed;
- (void)setCollapsed:(BOOL)flag;

- (NSRect)frame;
- (void)setFrame:(NSRect)rect;

- (float)rowHeight;
- (void)setRowHeight:(float)newHeight;

- (NSDate *)completionDate;
- (NSDate *)creationDate;
- (BOOL)wasCompleted;
- (void)setWasCompleted:(BOOL)flag;

// Other Methods
- (NSString *)string;

// Relationships
- (CompositeView *)containingView;
- (void)setContainingView:(CompositeView *)aView;

// Interface Actions
- (IBAction)toggleCollapsed:(id)sender;
- (void)startUncollapse;
- (void)abortUncollapse;

// Interface Access
- (CompositeTriangleButton *)button;
- (CompositeObjectTextView *)textView;
- (CompositeObjectView *)view;

@end
