//
//  UNQKeyValueCursor.m
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import "UNQKeyValueCursor.h"

static int cursor_callback(const void *pData, unsigned int iDataLen, void *pUserData);

@implementation UNQKeyValueCursor

- (nullable id)initWithKVStore:(nonnull id<UnQLiteKVStore>)store {
    if (self = [super init]) {
        self.lite = (UNQDataBase *)store;
        
        if ([self.lite handleStatus:unqlite_kv_cursor_init(_lite.context, &_cursor)]) {
            return self;
        }
    }
    return nil;
}

- (void)dealloc {
    if (_cursor) {
        [self.lite handleStatus:unqlite_kv_cursor_release(_lite.context, _cursor)];
    }
}

- (NSString * __nonnull)_key {
    NSMutableData *kdata = [NSMutableData new];
    unqlite_kv_cursor_key_callback(_cursor, cursor_callback, (__bridge void *)(kdata));
    return [[NSString alloc] initWithData:kdata encoding:NSUTF8StringEncoding];
}
- (NSData* __nonnull)_value {
    NSMutableData *kData = [NSMutableData new];
    unqlite_kv_cursor_data_callback(_cursor, cursor_callback, (__bridge void *)(kData));
    return [NSData dataWithData:kData];
}


// Change current location. If success, return self, otherwise nil.
- (nullable id<UnQLiteKVCursor>)seek:(NSString * __nullable)key {
    __block id<UnQLiteKVCursor> cursor;
    [_lite synchronize:^{
        cursor = [_lite handleStatus:unqlite_kv_cursor_seek(_cursor, [key UTF8String], -1, UNQLITE_CURSOR_MATCH_EXACT)] ? self : nil;
    }];
    return cursor;
}
- (nullable id<UnQLiteKVCursor>)first {
    __block id<UnQLiteKVCursor> cursor;
    [_lite synchronize:^{
        cursor = [_lite handleStatus:unqlite_kv_cursor_first_entry(_cursor)] && unqlite_kv_cursor_valid_entry(_cursor) ? self : nil;
    }];
    return cursor;
}
- (nullable id<UnQLiteKVCursor>)last {
    __block id<UnQLiteKVCursor> cursor;
    [_lite synchronize:^{
        cursor = [_lite handleStatus:unqlite_kv_cursor_last_entry(_cursor)] && unqlite_kv_cursor_valid_entry(_cursor) ? self : nil;
    }];
    return cursor;
}
- (nullable id<UnQLiteKVCursor>)next {
    __block id<UnQLiteKVCursor> cursor;
    [_lite synchronize:^{
        cursor = [_lite handleStatus:unqlite_kv_cursor_next_entry(_cursor)] && unqlite_kv_cursor_valid_entry(_cursor) ? self : nil;
    }];
    return cursor;
}
- (nullable id<UnQLiteKVCursor>)previous {
    __block id<UnQLiteKVCursor> cursor;
    [_lite synchronize:^{
        cursor = [_lite handleStatus:unqlite_kv_cursor_prev_entry(_cursor)] && unqlite_kv_cursor_valid_entry(_cursor) ? self : nil;
    }];
    return cursor;
}

- (BOOL)drop {
    __block BOOL success;
    [_lite synchronize:^{
        success = [_lite handleStatus:unqlite_kv_cursor_delete_entry(_cursor)];
    }];
    return success;
}

- (NSString * __nonnull)key {
    __block NSString *key;
    [_lite synchronize:^{
        NSMutableData *kdata = [NSMutableData new];
        unqlite_kv_cursor_key_callback(_cursor, cursor_callback, (__bridge void *)(kdata));
        key = [[NSString alloc] initWithData:kdata encoding:NSUTF8StringEncoding];
    }];
    return key;
}
- (NSData* __nonnull)value {
    __block NSData *value;
    [_lite synchronize:^{
        NSMutableData *kData = [NSMutableData new];
        unqlite_kv_cursor_data_callback(_cursor, cursor_callback, (__bridge void *)(kData));
        value = [NSData dataWithData:kData];
    }];
    return value;
}

@end

static int cursor_callback(const void *pData, unsigned int iDataLen, void *pUserData) {
    NSMutableData *data = (__bridge NSMutableData *)(pUserData);
    [data appendBytes:pData length:iDataLen];
    return UNQLITE_OK;
}