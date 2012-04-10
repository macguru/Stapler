//
//  CompositeObject.h
//  Ulysses
//
//  Created by Max on 04.11.05.
//  Copyright 2002-2006 The Blue Technologies Group. All rights reserved.
//

#import "ChangeReport.h"

@class DistributingTextStorage;

@interface CompositeObject : NSObject <ChangeReport>
{
    SEL                     _changeReportAction;
    id                      _changeReportObject;
    BOOL                    _collapsed;
    NSDate                  *_completionDate;
    DistributingTextStorage *_contentStorage;
    NSDate                  *_creationDate;
}

// Initializer
- (id)initWithContent:(NSData *)data;
+ (CompositeObject *)objectWithContent:(NSData *)data;

// Properties
- (BOOL)collapsed;
- (void)setCollapsed:(BOOL)flag;

- (BOOL)wasCompleted;
- (void)setWasCompleted:(BOOL)flag;

- (NSDate *)completionDate;
- (void)setCompletionDate:(NSDate *)newDate;

- (NSData *)content;
- (void)setContent:(NSData *)data;

- (NSDate *)creationDate;
- (void)setCreationDate:(NSDate *)newDate;

- (NSString *)stringContent;
- (DistributingTextStorage *)contentTextStorage;

- (NSDictionary *)attributesAsPropertyList;
- (void)setAttributesWithPropertyList:(NSDictionary *)dictionary;

@end
