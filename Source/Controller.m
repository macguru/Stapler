//
//  Controller.m
//  Stapler
//
//  Created by Max on 22.02.06.
//  Copyright 2006 The Blue Technologies Group. All rights reserved.
//

#import "Controller.h"

#import "Document.h"

@implementation Controller

#pragma mark -
#pragma mark Items

- (IBAction)addItem:(id)sender
{
    [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] addItem: sender];
}

- (IBAction)collapseItem:(id)sender
{
    [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] collapseItem: sender];
}

- (IBAction)moveItem:(id)sender
{
    [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] moveItem: sender];
}

- (IBAction)removeItem:(id)sender
{
    [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] removeItem: sender];
}

#pragma mark -
#pragma mark General Actions

- (IBAction)openPreferences:(id)sender
{
    [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] openPreferences];
}

- (IBAction)printDocument:(id)sender
{
    [[[NSDocumentController sharedDocumentController] currentDocument] printDocument: sender];
}

#pragma mark -
#pragma mark Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(addItem:) || [menuItem action] == @selector(removeItem:))
        return ([[NSDocumentController sharedDocumentController] currentDocument] != nil);
    
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    unsigned i;
    
    for (i=0; i<[filenames count]; i++)
     {
        if ([[[filenames objectAtIndex: i] pathExtension] isEqual: @"stpl"]) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath: [filenames objectAtIndex: i]] display:YES error:nil];
        } else {
            if (![[NSDocumentController sharedDocumentController] currentDocument])
                [[NSDocumentController sharedDocumentController] newDocument: nil];
            
            [(Document *)[[NSDocumentController sharedDocumentController] currentDocument] addItemWithFile: [filenames objectAtIndex: i]];
        }
     }
}

@end
