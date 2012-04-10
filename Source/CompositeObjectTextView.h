//
//  CompositeObjectTextView.h
//  Ulysses
//
//  Created by Max on 21.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

@class CompositeViewObject;

@interface CompositeObjectTextView : NSTextView
{
    IBOutlet CompositeViewObject *owner;
    BOOL wasCollapsed;
}

- (CompositeViewObject *)owner;
- (void)setOwner:(CompositeViewObject *)newOwner;

@end
