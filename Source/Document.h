//
//  Document.h
//  Stapler
//
//  Created by Max on 22.02.06.
//  Copyright The Blue Technologies Group 2006 . All rights reserved.
//

@class CompositeView, CompositeViewStorage;

@interface Document : NSDocument
{
    IBOutlet CompositeView  *mainView;
    IBOutlet NSWindow       *preferencesWindow;
    
    NSMutableDictionary     *_preferences;
    CompositeViewStorage    *_storage;
    NSToolbar               *_toolbar;
    NSMutableDictionary     *_toolbarItems;
}

// Preferences
- (NSDictionary *)preferences;

- (void)openPreferences;
- (IBAction)changePreferenceFont:(id)sender;

// Items
- (IBAction)addItem:(id)sender;
- (IBAction)removeItem:(id)sender;

- (void)addItemWithFile:(NSString *)path;

- (IBAction)collapseItem:(id)sender;
- (IBAction)moveItem:(id)sender;

@end
