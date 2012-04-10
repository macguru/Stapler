//
//  BTArchiving.h
//  BlueApplication
//
//  Created by Max on 11.12.05.
//  Copyright 2002-2006 The Blue Technologies Group. All rights reserved.
//

// use methodes to archive not XML/plist-compatible objects to NSData and back, using NS(Un)Archiver / NSKeyed(Un)Archiver

@interface NSDictionary (BTArchiving)

// Public methodes
- (NSDictionary *)archive;
- (NSDictionary *)unarchive;

- (NSDictionary *)keyedArchive;
- (NSDictionary *)keyedUnarchive;

- (NSMutableDictionary *)mutableUnarchive;
- (NSMutableDictionary *)mutableKeyedUnarchive;

// Half-private methodes
- (NSDictionary *)archiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;
- (NSDictionary *)unarchiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;

- (NSDictionary *)archive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;

@end

@interface NSArray (BTArchiving)

// Public methodes
- (NSArray *)archive;
- (NSArray *)unarchive;

- (NSArray *)keyedArchive;
- (NSArray *)keyedUnarchive;

- (NSMutableArray *)mutableUnarchive;
- (NSMutableArray *)mutableKeyedUnarchive;

// Half-private methodes
- (NSArray *)archiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;
- (NSArray *)unarchiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;

- (NSArray *)archive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;

@end