//
//  UNQBaseObject.m
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "UNQBaseObject.h"

@implementation UNQBaseObject

- (id)initWithDataBase:(UNQDataBase * __nonnull)lite {
    if (self = [super init]) {
        self.lite = lite;
    }
    return self;
}

- (void)_associateObject:(id)obj toValue:(unqlite_value *)pVal {
    if ([obj isKindOfClass:NSString.class]) {
        const char *zString = [obj UTF8String];
        unqlite_value_string(pVal, zString, (int)strlen(zString));
    }else if ([obj isKindOfClass:NSArray.class]) {
        for (id item in obj) {
            unqlite_value *pValue = [self valueWithObject:item];
            [_lite handleStatus:unqlite_array_add_elem(pVal, NULL, pValue)];
            [self releaseValue:pValue];
        }
    }else if ([obj isKindOfClass:NSDictionary.class]) {
        for (NSString *key in obj) {
            id sValue = [obj objectForKey:key];
            unqlite_value *pkey = [self valueWithObject:key];
            unqlite_value *pValue = [self valueWithObject:sValue];
            
            [_lite handleStatus:unqlite_array_add_elem(pVal, pkey, pValue)];
            [self releaseValue:pValue];
        }
    }else if ([obj isKindOfClass:NSNumber.class]) {
        if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            unqlite_value_bool(pVal, [obj boolValue]);
        }else if (strcmp([obj objCType], @encode(NSInteger)) == 0) {
            unqlite_value_int64(pVal, [obj integerValue]);
        }else{
            unqlite_value_double(pVal, [obj doubleValue]);
        }
    }else{
        unqlite_value_null(pVal);
    }
}

- (unqlite_value *)valueWithObject:(id)obj {
    unqlite_value *pval;
    if ([obj isKindOfClass:NSArray.class] || [obj isKindOfClass:NSDictionary.class]) {
        pval = [self newArray];
    }else{
        pval = [self newScalar];
    }
    [self _associateObject:obj toValue:pval];
    return pval;
}

- (unqlite_value *)newScalar {
    [NSException raise:@"Abstract method should never be called directly." format:@""];
    return NULL;
}
- (unqlite_value *)newArray {
    [NSException raise:@"Abstract method should never be called directly." format:@""];
    return NULL;
}
- (BOOL)releaseValue:(unqlite_value *)pval {
    [NSException raise:@"Abstract method should never be called directly." format:@""];
    return false;
}

@end

static int unq_extract_walk(unqlite_value *pkey, unqlite_value *pvalue, void *context) {
    id userData = (__bridge id)(context);
    if ([userData isKindOfClass:NSMutableDictionary.class]) {
        NSString *key = unq_base_object_extract(pkey);
        id value = unq_base_object_extract(pvalue);
        [userData setObject:value forKey:key];
    }else if ([userData isKindOfClass:NSMutableArray.class]) {
        id value = unq_base_object_extract(pvalue);
        [userData addObject:value];
    }
    return 0;
}
id unq_base_object_extract( unqlite_value * __nonnull  pval) {
    id ret;
    if (unqlite_value_is_bool(pval)) {
        ret = [NSNumber numberWithBool:unqlite_value_to_bool(pval)];
    }else if (unqlite_value_is_float(pval)) {
        ret = [NSNumber numberWithDouble:unqlite_value_to_double(pval)];
    }else if (unqlite_value_is_int(pval)) {
        ret = [NSNumber numberWithInteger:unqlite_value_to_int64(pval)];
    }else if (unqlite_value_is_string(pval)) {
        int pLen;
        ret = [[NSString alloc] initWithBytes:unqlite_value_to_string(pval, &pLen) length:pLen encoding:NSUTF8StringEncoding];
    }else if (unqlite_value_is_json_object(pval)) {
        ret = [NSMutableDictionary new];
        unqlite_array_walk(pval, unq_extract_walk, (__bridge void *)(ret));
    }else if (unqlite_value_is_json_array(pval)) {
        ret = [NSMutableArray new];
        unqlite_array_walk(pval, unq_extract_walk, (__bridge void *)(ret));
    }else {
        ret = nil;
    }
    
    return ret;
}
