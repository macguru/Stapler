//
//  CompositeObjectView.h
//  Ulysses
//
//  Created by Max on 21.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

@class CompositeViewObject;

@interface CompositeObjectView : NSControl
{
    IBOutlet CompositeViewObject *object;
    id _target;
}

@end
