//
//  UNQBaseValue.h
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "unqlite.h"
#import "UNQDataBase.h"

FOUNDATION_EXTERN __nonnull id unq_base_object_extract( unqlite_value * __nonnull  pval);

@interface UNQBaseObject : NSObject

@property (nonatomic, strong, nonnull) UNQDataBase *lite ;

- (id __nonnull)initWithDataBase:(UNQDataBase * __nonnull)lite;

- (unqlite_value * __nonnull)valueWithObject:(id __nullable)obj;

// abstract method , subclass must implement mthods below
- (unqlite_value * __nonnull)newScalar;
- (unqlite_value * __nonnull)newArray;
- (BOOL)releaseValue:(unqlite_value * __nonnull)pval;

@end
