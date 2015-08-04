//
//  UNQVirtualMachine.h
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "UNQBaseObject.h"

@class UNQContext;

@interface UNQVirtualMachine : UNQBaseObject

@property (nonatomic, nullable) unqlite_vm *vm;
@property (nonatomic, nonnull) NSMapTable *ffTable;

- (BOOL)compileScript:(NSString * __nonnull)script;
- (BOOL)reset;
- (BOOL)excute;

- (BOOL)setObject:(id __nullable)value forVariable:(NSString * __nonnull)variable;
- (id __nullable)extractVariable:(NSString * __nonnull)variable;
- (BOOL)setFunction:(int (^ __nonnull)(UNQContext * __nullable context, int argc, unqlite_value __nullable ** __nullable argv))func  forVariable:(NSString * __nonnull)variable;
- (BOOL)removeFuncForVariable:(NSString * __nullable)variable;

@end
