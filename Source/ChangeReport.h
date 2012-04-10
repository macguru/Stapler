/*
 *  ChangeReport.h
 *  Ulysses
 *
 *  Created by Max on 04.12.05.
 *  Copyright 2002-2006 The Blue Technologies Group. All rights reserved.
 *
 */

@protocol ChangeReport

- (void)reportChangesToObject:(id)object withSelector:(SEL)action;

@end