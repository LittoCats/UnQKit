//
//  UNQContext.h
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UNQBaseObject.h"
#import "unqlite.h"

@interface UNQContext : UNQBaseObject

@property (nonnull, nonatomic) unqlite_context *context;

- (nonnull id)initWithDataBase:(UNQDataBase * __nonnull)lite context:(unqlite_context * __nonnull)context;

- (void)pushResult:(nullable id)ret;

@end
