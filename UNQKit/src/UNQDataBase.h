//
//  UNQDataBase.h
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnQLiteTool.h"
#import "unqlite.h"

@interface UNQDataBase: NSObject<UnQLite, UnQLiteKVStore>

@property (nonatomic, nonnull) unqlite *context;

@property (nonatomic, strong, nonnull) dispatch_queue_t queue;

@property (nonatomic, copy, nullable) void (^exceptionHandler)(NSException * __nonnull);

@property (nonatomic, strong, nonnull) NSMutableDictionary *configure;

@property (nonatomic, strong, nonnull) NSMapTable *collectionTable;

- (BOOL)handleStatus:(int)status;

- (void)synchronize:(nonnull dispatch_block_t)block;


@end
