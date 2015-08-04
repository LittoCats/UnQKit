//
//  UNQDocuments.h
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnQLiteTool.h"
#import "UNQCollection.h"

@interface UNQDocument : NSObject<UnQLiteDocument>

- (nonnull id)initWithCollection:(UNQCollection * __nonnull)collection documentId:(nonnull id)documentId;

// MARK: UnQLiteDocument
@property (nonatomic, nonnull, readonly) id documentId;
@property (nonatomic, nullable, readonly) NSDictionary *dictionaryRepresentation;

- (BOOL)drop;
- (BOOL)setObject:(nonnull id)object forKeyPath:(NSArray * __nonnull)keyPath;
- (nullable id)objectForKeyPath:(NSArray * __nonnull)keyPath;


@end
