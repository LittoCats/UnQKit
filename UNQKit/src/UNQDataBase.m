//
//  UNQDataBase.m
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "UNQDataBase.h"
#import "UNQKeyValueCursor.h"
#import "UNQCollection.h"

static NSString * status_description(int status) {
    switch (status) {
        case UNQLITE_NOTFOUND:          return @"Key not found";
        case UNQLITE_NOMEM:             return @"Out of memory";
        case UNQLITE_ABORT:             return @"Executed command request an operation abort";
        case UNQLITE_IOERR:             return @"IO error";
        case UNQLITE_CORRUPT:           return @"Corrupt database";
        case UNQLITE_LOCKED:            return @"Locked database";
        case UNQLITE_BUSY:              return @"Database is locked by another thread/process";
        case UNQLITE_DONE:              return @"Error: UNQLITE_DONE";
        case UNQLITE_NOTIMPLEMENTED:    return @"Not implemented";
        case UNQLITE_READ_ONLY:         return @"Database is in read-only mode";
            
        default: return [NSString stringWithFormat:@"Unknown exception"];
    }
}

static int unq_kv_fetch_callback(const void *pData, unsigned int iDataLen, void *pUserData){
    NSMutableData *buffer = (__bridge NSMutableData *)(pUserData);
    if (pData) [buffer appendBytes:pData length:iDataLen];
    
    return UNQLITE_OK;
}

@implementation UNQDataBase

// MARK: lift circle
- (id)initWithFile:(NSString *)file options:(UnQLiteOpenOption)options exceptionHandler:(void (^)(NSException *))handler {
    if (self = [super init]) {
        self.exceptionHandler = handler;
        
        if ([self handleStatus:unqlite_open(&_context, [file UTF8String], options)]){
            self.queue = dispatch_queue_create([[NSString stringWithFormat:@"org.littocats.unq.queue_%p", self] cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
            
            dispatch_queue_set_specific(self.queue, &_queue, (__bridge void *)(self), NULL);
            
            self.collectionTable = [NSMapTable strongToWeakObjectsMapTable];
            return self;
        }
    }
    return nil;
}

- (void)synchronize:(dispatch_block_t)block {
    if (self == dispatch_get_specific(&_queue)) {
        block();
    }else{
        dispatch_sync(self.queue, block);
    }
}

- (void)dealloc {
    if (!_context) {
        return;
    }
    
    int status = unqlite_close(_context);
    [self handleStatus:status];
    while (status == UNQLITE_BUSY) {
        [NSThread sleepForTimeInterval:20];
        status = unqlite_close(_context);
    }
}

// MARK: getter
- (NSDictionary *)getConfigure {
    return @{};
}

// MARK: store context
- (id<UnQLiteKVStore>)kvStore {
    return self;
}

/**
 Auto create if not exist
 */
- (id<UnQLiteCollection>)collectionWithName:(NSString *)name {
    __block UNQCollection *collection;
    [self synchronize:^{
        if (!(collection = [_collectionTable objectForKey:name])) {
            collection = [[UNQCollection alloc] initWithDataBase:self name:name];
            [_collectionTable setObject:collection forKey:name];
        }
    }];
    return collection;
}

// MARK: exception
- (BOOL)handleStatus:(int)status {
    if (status == UNQLITE_OK) {
        return true;
    }
    
    char *_dbError;
    int _dbErrorLength;
    unqlite_config(_context, UNQLITE_CONFIG_ERR_LOG, &_dbError, &_dbErrorLength);
    if (!_dbErrorLength) {
        unqlite_config(_context, UNQLITE_CONFIG_JX9_ERR_LOG, &_dbError, &_dbErrorLength);
    }

    NSException *exception = [[NSException alloc] initWithName:UnQLiteExceptionName
                                                        reason:status_description(status)
                                                      userInfo:@{@"statusCode": @(status),
                                                                 NSLocalizedDescriptionKey: [[NSString alloc] initWithBytes:_dbError length:_dbErrorLength encoding:NSUTF8StringEncoding]}];
    self.exceptionHandler(exception);
    return false;
}

// MARK: UnQLiteKVStore Protocol
- (BOOL)storeData:(NSData *)data forKey:(NSString *)key {
    __block int status;
    const char *pKey = key.UTF8String;
    [self synchronize:^{
        status = unqlite_kv_store(_context, pKey, (int)strlen(pKey), data.bytes, (int)data.length);
    }];
    
    return [self handleStatus:status];
}

- (BOOL)appendData:(NSData *)data forKey:(NSString *)key {
    __block int status;
    const char *pKey = key.UTF8String;
    [self synchronize:^{
        status = unqlite_kv_append(_context, pKey, (int)strlen(pKey), data.bytes, (int)data.length);
    }];
    
    return [self handleStatus:status];
}

- (BOOL)dropDataForKey:(NSString *)key {
    __block int status;
    const char *pKey = key.UTF8String;
    [self synchronize:^{
        status = unqlite_kv_delete(_context, pKey, (int)strlen(pKey));
    }];
    
    return [self handleStatus:status];
}

- (NSData *)dataForKey:(NSString *)key {
    NSMutableData *data = [[NSMutableData alloc] init];
    const char *pKey = key.UTF8String;
    __block int status;
    [self synchronize:^{
        status = unqlite_kv_fetch_callback(_context, pKey, (int)strlen(pKey), unq_kv_fetch_callback, (__bridge void *)(data));
    }];
    
    return [self handleStatus:status] ? [[NSData alloc] initWithData:data] : nil;
}

- (nonnull id<UnQLiteKVCursor>)cursor {
    __block UNQKeyValueCursor *cursor;
    [self synchronize:^{
        cursor = [[UNQKeyValueCursor alloc] initWithKVStore:self];
    }];
    return cursor;
}
@end

id<UnQLite> openUnQLite(NSString *nameOrDBFilePath, UnQLiteOpenOption option, void (^exceptionHandler)(NSException *)) {
    static dispatch_once_t onceToken;
    static NSMapTable *dbTable;
    dispatch_once(&onceToken, ^{
        dbTable = [NSMapTable strongToWeakObjectsMapTable];
    });
    UNQDataBase *base;
    @synchronized(dbTable) {
        if (!(base = [dbTable objectForKey:nameOrDBFilePath])) {
            base = [[UNQDataBase alloc] initWithFile:nameOrDBFilePath options:option exceptionHandler:exceptionHandler];
            [dbTable setObject:base forKey:nameOrDBFilePath];
        }
    }
    return base;
}