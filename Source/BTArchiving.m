//
//  BTArchiving.m
//  BlueApplication
//
//  Created by Max on 11.12.05.
//  Copyright 2002-2006 The Blue Technologies Group. All rights reserved.
//

#import "BTArchiving.h"

@interface NSObject (BTArchiving)

- (id)_archiveSelf:(BOOL)isDict unarchive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed;

@end

@implementation NSObject (BTArchiving)

- (id)_archiveSelf:(BOOL)isDict unarchive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    NSMutableDictionary *dict;
    NSArray *values, *keys;
    NSMutableArray *array;
    unsigned i;
    
    if (isDict) {
        dict = [NSMutableDictionary dictionary];
        values = [(NSDictionary *)self allValues];
        keys = [(NSDictionary *)self allKeys];
    } else {
        array = [NSMutableArray array];
        values = (NSArray *)self;
        dictsMutable = arraysMutable; // Subdicts should be immutable, too
    }
    
    for (i=0; i<[values count]; i++)
     {
        id object, value;
        NSString *key;
        
        if (isDict) {
            object = [values objectAtIndex: i];
            key = [keys objectAtIndex: i];
        } else {
            object = [(NSArray *)self objectAtIndex: i];
        }
        
        if ([object isKindOfClass: [NSArray class]] || [object isKindOfClass: [NSDictionary class]])
         {
            value = [object archive:unarchive withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
         }
        else 
         {
            if (unarchive)
             {
                if ([object isKindOfClass: [NSData class]]) {
                    if (keyed)
                        value = [NSKeyedUnarchiver unarchiveObjectWithData: object];
                    else
                        value = [NSUnarchiver unarchiveObjectWithData: object];
                } else
                    value = nil;
             }
            else
             {
                if (!([object isKindOfClass: [NSString class]] || [object isKindOfClass: [NSNumber class]] || [object isKindOfClass: [NSDate class]] || [object isKindOfClass: [NSData class]])) {
                    if (keyed)
                        value = [NSKeyedArchiver archivedDataWithRootObject: object];
                    else
                        value = [NSArchiver archivedDataWithRootObject: object];
                } else
                    value = nil;
             }
            
            if (!value)
                value = object;
         }
        
        if (isDict)
            [dict setObject:value forKey:key];
        else
            [array addObject: value];
     }
    
    if (isDict)
     {
        if (dictsMutable)
            return dict;
        else
            return [NSDictionary dictionaryWithDictionary: dict];
     }
    else
     {
        if (arraysMutable)
            return array;
        else
            return [NSArray arrayWithArray: array];
     }
}

@end

@implementation NSDictionary (BTArchiving)

- (NSDictionary *)archive
{
    return [self archiveWithDictionariesMutable:NO arraysMutable:NO keyed:NO];
}

- (NSDictionary *)keyedArchive
{
    return [self archiveWithDictionariesMutable:NO arraysMutable:NO keyed:YES];
}

- (NSDictionary *)unarchive
{
    return [self unarchiveWithDictionariesMutable:NO arraysMutable:NO keyed:NO];
}

- (NSDictionary *)keyedUnarchive
{
    return [self unarchiveWithDictionariesMutable:NO arraysMutable:NO keyed:YES];
}

- (NSMutableDictionary *)mutableUnarchive
{
    return (NSMutableDictionary *)[self unarchiveWithDictionariesMutable:YES arraysMutable:YES keyed:NO];
}

- (NSMutableDictionary *)mutableKeyedUnarchive
{
    return (NSMutableDictionary *)[self unarchiveWithDictionariesMutable:YES arraysMutable:YES keyed:YES];
}

- (NSDictionary *)archiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self archive:NO withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

- (NSDictionary *)unarchiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self archive:YES withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

- (NSDictionary *)archive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self _archiveSelf:YES unarchive:unarchive withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

@end

@implementation NSArray (BTArchiving)

- (NSArray *)archive
{
    return [self archiveWithDictionariesMutable:NO arraysMutable:NO keyed:NO];
}

- (NSArray *)keyedArchive
{
    return [self archiveWithDictionariesMutable:NO arraysMutable:NO keyed:YES];
}

- (NSArray *)unarchive
{
    return [self unarchiveWithDictionariesMutable:NO arraysMutable:NO keyed:NO];
}

- (NSArray *)keyedUnarchive
{
    return [self unarchiveWithDictionariesMutable:NO arraysMutable:NO keyed:YES];
}

- (NSMutableArray *)mutableUnarchive
{
    return (NSMutableArray *)[self unarchiveWithDictionariesMutable:YES arraysMutable:YES keyed:NO];
}

- (NSMutableArray *)mutableKeyedUnarchive
{
    return (NSMutableArray *)[self unarchiveWithDictionariesMutable:YES arraysMutable:YES keyed:YES];
}

- (NSArray *)archiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self archive:NO withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

- (NSArray *)unarchiveWithDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self archive:YES withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

- (NSArray *)archive:(BOOL)unarchive withDictionariesMutable:(BOOL)dictsMutable arraysMutable:(BOOL)arraysMutable keyed:(BOOL)keyed
{
    return [self _archiveSelf:NO unarchive:unarchive withDictionariesMutable:dictsMutable arraysMutable:arraysMutable keyed:keyed];
}

@end