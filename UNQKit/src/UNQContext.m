//
//  UNQContext.m
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import "UNQContext.h"

@implementation UNQContext

- (id)initWithDataBase:(UNQDataBase * __nonnull)lite context:(unqlite_context * __nonnull)context {
    if (self = [super initWithDataBase:lite]) {
        self.context = context;
    }
    return self;
}

- (unqlite_value * __nonnull)newArray {
    return unqlite_context_new_array(_context);
}

- (unqlite_value * __nonnull)newScalar {
    return unqlite_context_new_scalar(_context);
}

- (BOOL)releaseValue:(unqlite_value * __nonnull)pval {
    unqlite_context_release_value(_context, pval);
    return true;
}

- (void)pushResult:(nullable id)ret {
    unqlite_value *value = [self valueWithObject:ret];
    [self.lite handleStatus:unqlite_result_value(_context, value)];
    [self releaseValue:value];
}

@end
