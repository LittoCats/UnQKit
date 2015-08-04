//
//  UNQCollection.h
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnQLiteTool.h"

@class UNQVirtualMachine;
@class UNQDataBase;

@interface UNQCollection : NSObject <UnQLiteCollection>

@property (nonnull, nonatomic, strong) UNQDataBase *lite;
@property (nonatomic, nonnull, copy) NSString *name;

@property (nonnull, nonatomic, strong) NSMapTable *documentTable;

- (nonnull id)initWithDataBase:(UNQDataBase * __nonnull)lite name:(NSString * __nonnull)name;

- (UNQVirtualMachine * __nonnull)excuteScript:(NSString * __nonnull)script withArgs:(NSDictionary * __nullable)args;

- (nullable id)objectByExcuteScript:(NSString *__nonnull)script withArgs:(NSDictionary *__nullable)args;

@end
