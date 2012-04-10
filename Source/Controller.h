//
//  Controller.h
//  Stapler
//
//  Created by Max on 22.02.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

@interface Controller : NSObject
{
}

- (IBAction)addItem:(id)sender;
- (IBAction)collapseItem:(id)sender;
- (IBAction)moveItem:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)printDocument:(id)sender;
- (IBAction)removeItem:(id)sender;

@end
