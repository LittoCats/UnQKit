//
//  UNQKeyValueCursor.h
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UNQDataBase.h"
#import "UnQLiteTool.h"
#import "unqlite.h"

@interface UNQKeyValueCursor : NSObject<UnQLiteKVCursor>

@property (nonnull, nonatomic, strong) UNQDataBase *lite;

@property (nonatomic, nonnull) unqlite_kv_cursor *cursor;

- (nullable id)initWithKVStore:(nonnull id<UnQLiteKVStore>)store;

@end
