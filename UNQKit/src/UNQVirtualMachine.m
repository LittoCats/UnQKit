//
//  UNQVirtualMachine.m
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "UNQVirtualMachine.h"
#import "UNQContext.h"

static int vm_function_bridge(unqlite_context *pCtx,int argc,unqlite_value **argv);

@implementation UNQVirtualMachine

- (id)initWithDataBase:(UNQDataBase * __nonnull)lite {
    if (self = [super initWithDataBase:lite]) {
        self.ffTable = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void)dealloc {
    for (NSString *variable in [_ffTable dictionaryRepresentation]) {
        [self removeFuncForVariable:variable];
    }
    
    if (_vm) {
        [self.lite handleStatus:unqlite_vm_release(_vm)];
    }
}

// MARK: override

- (unqlite_value * __nonnull)newArray {
    return unqlite_vm_new_array(_vm);
}

- (unqlite_value * __nonnull)newScalar {
    return unqlite_vm_new_scalar(_vm);
}

- (BOOL)releaseValue:(unqlite_value * __nonnull)pval {
    return [self.lite handleStatus:unqlite_value_release(pval)];
}

// MARK: task

- (BOOL)compileScript:(NSString * __nonnull)script {
    BOOL success = [self.lite handleStatus:unqlite_compile(self.lite.context, [script UTF8String], -1, &_vm)];
    if (success) {
        [self setFunction:^int(UNQContext *context, int argc, unqlite_value **argv) {
            NSMutableString *logStr = [NSMutableString new];
            for (int i = 0; i < argc; i++) {
                [logStr appendFormat:@"%@",unq_base_object_extract(argv[i])];
            }
            NSLog(@"%@", logStr);
            return UNQLITE_OK;
        } forVariable:@"print"];
    }

    return success;
}

- (BOOL)excute {
    return [self.lite handleStatus:unqlite_vm_exec(_vm)];
}

- (BOOL)reset {
    return [self.lite handleStatus:unqlite_vm_reset(_vm)];
}

- (BOOL)setObject:(id __nullable)value forVariable:(NSString * __nonnull)variable {
    unqlite_value *pval = [self valueWithObject:value];
    BOOL ret = [self.lite handleStatus:unqlite_vm_config(_vm, UNQLITE_VM_CONFIG_CREATE_VAR, [variable UTF8String], pval)];
    [self releaseValue:pval];
    return ret;
}

- (BOOL)setFunction:(int (^)(UNQContext *context, int argc, unqlite_value **argv))func forVariable:(NSString * __nonnull)variable {
    if ([self.lite handleStatus: unqlite_create_function(_vm, [variable UTF8String], vm_function_bridge, (__bridge void *)(self))]) {
        [_ffTable setObject:func forKey:variable];
        return true;
    }
    return false;
}

- (BOOL)removeFuncForVariable:(NSString * __nullable)variable {
    [_ffTable removeObjectForKey:variable];
    return [self.lite handleStatus:unqlite_delete_function(_vm, [variable UTF8String])];
}

- (id __nullable)extractVariable:(NSString * __nonnull)name {
    unqlite_value *pval = unqlite_vm_extract_variable(_vm, [name UTF8String]);
    if (!pval) {
        return nil;
    }
    id obj = unq_base_object_extract(pval);
    [self releaseValue:pval];
    return obj;
}

@end

static int vm_function_bridge(unqlite_context *pCtx,int argc,unqlite_value **argv) {
    UNQVirtualMachine *vm = (__bridge UNQVirtualMachine *)(unqlite_context_user_data(pCtx));
    UNQContext *context = [[UNQContext alloc] initWithDataBase:vm.lite context:pCtx];
    NSString *variable = [NSString stringWithUTF8String:unqlite_function_name(pCtx)];
    int (^func)(UNQContext *context, int argc, unqlite_value **argv) = [vm.ffTable objectForKey:variable];
    return func(context, argc, argv);
}