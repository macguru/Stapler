//
//  Document.m
//  Stapler
//
//  Created by Max on 22.02.06.
//  Copyright The Blue Technologies Group 2006 . All rights reserved.
//

#import "Document.h"

#import "BTArchiving.h"
#import "CompositeObject.h"
#import "CompositeView.h"
#import "CompositeViewObject.h"
#import "CompositeViewStorage.h"

NSString *ToolbarItemAddIdentifier          = @"add";
NSString *ToolbarItemAttachmentIdentifier   = @"attachment";
NSString *ToolbarItemRemoveIdentifier       = @"remove";
NSString *ToolbarItemSaveIdentifier         = @"save";

NSString *DocumentPreferencesFilename       = @"Preferences.plist";
NSString *DocumentPreferencesDefaultKey     = @"Preferences";

NSString *PreferencesKeyDefaultFont         = @"defaultFont";
NSString *PreferencesKeyBackgroundColor     = @"backgroundColor";
NSString *PreferencesKeyToDoColor           = @"toDoColor";
NSString *PreferencesKeyDoneColor           = @"doneColor";
NSString *PreferencesKeyActiveColor         = @"activeColor";
NSString *PreferencesKeyDoneActiveColor     = @"doneActiveColor";
NSString *PreferencesKeyNewItemPosition     = @"newItemPosition";
NSString *PreferencesKeyMoveDoneItems       = @"moveDoneItems";

@interface Document (DocumentInternal) <NSToolbarDelegate>

- (int)indexForNewItem;

@end

@implementation Document

- (id)init
{
    self = [super init];
    
    _storage = [[CompositeViewStorage alloc] init];
    
    _preferences = [[NSMutableDictionary alloc] init];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: DocumentPreferencesDefaultKey]) {
        [_preferences setDictionary: [[[NSUserDefaults standardUserDefaults] objectForKey: DocumentPreferencesDefaultKey] keyedUnarchive]];
    } else {
        [_preferences setObject:[NSFont systemFontOfSize: 11.0] forKey:PreferencesKeyDefaultFont];
        [_preferences setObject:[NSColor whiteColor] forKey:PreferencesKeyBackgroundColor];
        [_preferences setObject:[NSColor colorWithDeviceRed:203.0/255 green:163.0/255 blue:164.0/255 alpha:1.0] forKey:PreferencesKeyToDoColor];
        [_preferences setObject:[NSColor colorWithDeviceWhite:0.91 alpha:1.0] forKey:PreferencesKeyDoneColor];
        [_preferences setObject:[NSColor colorWithDeviceRed:183.0/255 green:212.0/255 blue:246.0/255 alpha:1.0] forKey:PreferencesKeyActiveColor];
    }
    
    return self;
}

- (void)dealloc
{
    [mainView setStorage: nil];
    [mainView unbind: @"defaultFont"];
    [mainView unbind: @"backgroundColor"];
    [mainView unbind: @"toDoColor"];
    [mainView unbind: @"doneColor"];
    [mainView unbind: @"activeColor"];
    [mainView release];
    
    [_preferences release];
    [_storage release];
    [_toolbar release];
    [_toolbarItems release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark NSDocument Standards

- (NSString *)windowNibName
{
    return @"Document";
}

- (NSUndoManager *)undoManager
{
    return [_storage undoManager];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    NSToolbarItem *item;
    
    [super windowControllerDidLoadNib:aController];
    
    // Setup Toolbar
    _toolbar = [[NSToolbar alloc] initWithIdentifier: @"document"];
    _toolbarItems = [[NSMutableDictionary alloc] init];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier: ToolbarItemAddIdentifier];
    [item setLabel: NSLocalizedString(@"Add", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Add", nil)];
    [item setImage: [NSImage imageNamed: @"AddTool"]];
    [item setAction: @selector(addItem:)];
    [item setTarget: self];
    [_toolbarItems setObject:item forKey:ToolbarItemAddIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier: ToolbarItemRemoveIdentifier];
    [item setLabel: NSLocalizedString(@"Remove", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Remove", nil)];
    [item setImage: [NSImage imageNamed: @"RemoveTool"]];
    [item setAction: @selector(removeItem:)];
    [item setTarget: self];
    [_toolbarItems setObject:item forKey:ToolbarItemRemoveIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier: ToolbarItemAttachmentIdentifier];
    [item setLabel: NSLocalizedString(@"Attachment", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Attachment", nil)];
    [item setAction: @selector(openAttachment)];
    [item setTarget: self];
    [_toolbarItems setObject:item forKey:ToolbarItemAttachmentIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier: ToolbarItemSaveIdentifier];
    [item setLabel: NSLocalizedString(@"Save", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Save", nil)];
    [item setImage: [NSImage imageNamed: @"SaveTool"]];
    [item setAction: @selector(saveDocument:)];
    [item setTarget: self];
    [_toolbarItems setObject:item forKey:ToolbarItemSaveIdentifier];
    [item release];
    
    [_toolbar setDelegate: self];
    [_toolbar setAllowsUserCustomization: YES];
    [_toolbar setAutosavesConfiguration: YES];
    
    [[self windowForSheet] setToolbar: _toolbar];
    [[self windowForSheet] setFrameAutosaveName: @"document"];
    
    // Setup Preferences
    [mainView retain];
    [mainView bind:@"defaultFont" toObject:_preferences withKeyPath:PreferencesKeyDefaultFont options:nil];
    [mainView bind:@"backgroundColor" toObject:_preferences withKeyPath:PreferencesKeyBackgroundColor options:nil];
    [mainView bind:@"toDoColor" toObject:_preferences withKeyPath:PreferencesKeyToDoColor options:nil];
    [mainView bind:@"doneColor" toObject:_preferences withKeyPath:PreferencesKeyDoneColor options:nil];
    [mainView bind:@"activeColor" toObject:_preferences withKeyPath:PreferencesKeyActiveColor options:nil];
    [mainView bind:@"doneActiveColor" toObject:_preferences withKeyPath:PreferencesKeyDoneActiveColor options:nil];
    [mainView bind:@"autosortsCompletedItems" toObject:_preferences withKeyPath:PreferencesKeyMoveDoneItems options:nil];
    
    // Setup main view
    [mainView setStorage: _storage];
    [mainView setIsEditable: YES];
    
    // Setup change report
    [_storage reportChangesToObject:self withSelector:@selector(documentEdited)];
}

#pragma mark -
#pragma mark Persistence

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
    NSFileWrapper *theWrapper, *aWrapper;
    
    // Build wrapper
    theWrapper = [_storage fileWrapperWithItems];
    aWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: [NSPropertyListSerialization dataFromPropertyList:[_preferences keyedArchive] format:NSPropertyListXMLFormat_v1_0 errorDescription:nil]];
    [aWrapper setPreferredFilename: DocumentPreferencesFilename];
    [theWrapper addFileWrapper: aWrapper];
    [aWrapper release];
    
    // Save the preferences as default
    [[NSUserDefaults standardUserDefaults] setObject:[_preferences keyedArchive] forKey: DocumentPreferencesDefaultKey];
    
    // Done
    return theWrapper;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
    // First get preferences
    NSDictionary *prefs;
    prefs = [NSPropertyListSerialization propertyListFromData:[[[fileWrapper fileWrappers] objectForKey: DocumentPreferencesFilename] regularFileContents] mutabilityOption:kCFPropertyListMutableContainersAndLeaves format:nil errorDescription:nil];
    if (prefs)
        [_preferences setDictionary: [prefs keyedUnarchive]];
    
    // Then set contents
    [_storage setItemsWithFileWrapper: fileWrapper];
    
    return YES;
}

#pragma mark -
#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
    return [mainView printOperationWithSettings:printSettings error:outError];
}

#pragma mark -
#pragma mark Actions

- (void)openAttachment
{
    NSOpenPanel *openPanel;
    
    openPanel = [NSOpenPanel openPanel];
    if ([openPanel runModal] == NSOKButton)
        NSLog(@"open attachment");
}

- (void)openPreferences
{
    [preferencesWindow makeKeyAndOrderFront: self];
}

- (IBAction)changePreferenceFont:(id)sender
{
    NSFontManager *fontManager;
    
    fontManager = [NSFontManager sharedFontManager];
    
    [fontManager fontPanel: YES];
    [fontManager setSelectedFont:[_preferences objectForKey: PreferencesKeyDefaultFont] isMultiple:NO];
    [fontManager setDelegate: self];
    [fontManager setAction: @selector(selectFont:)];
    [[fontManager fontPanel: YES] makeKeyAndOrderFront: self];
}

- (IBAction)selectFont:(id)sender
{
    [_preferences setObject:[[NSFontManager sharedFontManager] convertFont: [_preferences objectForKey: PreferencesKeyDefaultFont]] forKey:PreferencesKeyDefaultFont];
}

- (void)documentEdited
{
    [self updateChangeCount: NSChangeDone];
}

- (BOOL)windowShouldClose:(id)sender
{
    [[NSFontManager sharedFontManager] setAction: @selector(changeFont:)];
    return YES;
}

#pragma mark -
#pragma mark Items

- (IBAction)addItem:(id)sender
{
    [_storage addEmptyItemAtIndex: [self indexForNewItem]];
}

- (void)addItemWithFile:(NSString *)path
{
    NSAttributedString *string;
    unichar character;
    
    if (!(string = [[NSAttributedString alloc] initWithPath:path documentAttributes:nil])) {
        character = NSAttachmentCharacter;
        NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithCharacters:&character length:1]];
        [mutableString addAttribute:NSAttachmentAttributeName value:[[[NSTextAttachment alloc] initWithFileWrapper: [[[NSFileWrapper alloc] initWithPath: path] autorelease]] autorelease] range:NSMakeRange(0,1)];
		string = mutableString;
    }
    
    [_storage addItemWithContent:[string RTFDFromRange:NSMakeRange(0, [string length]) documentAttributes:nil] atIndex:[self indexForNewItem]];
    [string release];
}

- (int)indexForNewItem
{
    switch ([[_preferences objectForKey: PreferencesKeyNewItemPosition] intValue]) {
        case 0:
            return 0;
        case 1:
            return fmaxf(0, [mainView selectedItem]);
        case 2:
            return [mainView selectedItem]+1;
        case 3:
            return [[_storage items] count];
    }
    
    return 0;
}

- (IBAction)removeItem:(id)sender
{
    [mainView removeSelectedItem];
}

#pragma mark -

- (IBAction)collapseItem:(id)sender
{
    switch ([sender tag]) {
        case 0: // Collapse
            [[mainView selectedViewItem] setCollapsed: YES];
            break;
        case 2: // Collapse All
            [mainView collapseAll: YES];
            break;
        case 1: // Uncollapse
            [[mainView selectedViewItem] setCollapsed: NO];
            break;
        case 3: // Uncollapse All
            [mainView collapseAll: NO];
            break;
        case 8: // Collapse Done
         {
             NSArray *items = [_storage items];
             for (unsigned i=0; i<[items count]; i++) {
                 if ([[items objectAtIndex: i] wasCompleted])
                     [[items objectAtIndex: i] setCollapsed: YES];
             }
         }
    }
}

- (IBAction)moveItem:(id)sender
{
    int index;
    
    index = [mainView selectedItem];
    
    switch ([sender tag]) {
        case 0: // Move Top
            [_storage moveItemAtIndex:index toIndex:0];
            break;
        case 1: // Move Up
            if (index > 0)
                [_storage moveItemAtIndex:index toIndex:index-1];
            break;
        case 2: // Move Down
            if (index < [[_storage items] count] - 1)
                [_storage moveItemAtIndex:index toIndex:index+2];
            break;
        case 3: // Move End
            [_storage moveItemAtIndex:index toIndex:[[_storage items] count]];
            break;
    }
}

#pragma mark -
#pragma mark Accessors

- (NSDictionary *)preferences
{
    return _preferences;
}

#pragma mark -
#pragma mark Toolbar

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [_toolbarItems objectForKey: itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects: ToolbarItemAddIdentifier, ToolbarItemRemoveIdentifier, NSToolbarSeparatorItemIdentifier, /*ToolbarItemAttachmentIdentifier,*/ NSToolbarShowFontsItemIdentifier, NSToolbarShowColorsItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, ToolbarItemSaveIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects: ToolbarItemAddIdentifier, ToolbarItemRemoveIdentifier, /*ToolbarItemAttachmentIdentifier,*/ NSToolbarSeparatorItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarShowColorsItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarPrintItemIdentifier, nil];
}

@end
