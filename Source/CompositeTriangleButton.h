//
//  CompositeTriangleButton.h
//  Ulysses
//
//  Created by Max on 22.11.04.
//  Copyright 2004 The Blue Technologies Group. All rights reserved.
//

@interface CompositeTriangleButton : NSButton
{
    NSTimer *drawTimer;
    NSEvent *event;
    BOOL blinks;
}

- (void)startBlinking;
- (void)stopBlinking;

@end
