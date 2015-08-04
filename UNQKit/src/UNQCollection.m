//
//  UNQCollection.m
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import "UNQCollection.h"
#import "UNQVirtualMachine.h"
#import "unqlite.h"
#import "UNQDocument.h"
#import "UNQContext.h"

#define DOCUMENTWITHID(document, documentId) if (!(document = [self.documentTable objectForKey:documentId])) {\
    document = [[UNQDocument alloc] initWithCollection:self documentId:documentId];\
    [self.documentTable setObject:document forKey:documentId];\
}

@implementation UNQCollection

- (nonnull id)initWithDataBase:(UNQDataBase * __nonnull)lite name:(NSString * __nonnull)name {
    if (self = [super init]) {
        self.lite = lite;
        self.name = name;
        self.documentTable = [NSMapTable strongToWeakObjectsMapTable];
        [self excuteScript:@"if (!db_exists($collection)) { db_create($collection); }" withArgs:nil];
    }
    return self;
}

- (UNQVirtualMachine *)excuteScript:(NSString *)script withArgs:(NSDictionary *)args {
    UNQVirtualMachine *vm = [[UNQVirtualMachine alloc] initWithDataBase:_lite];
    if ([vm compileScript:script]) {
        [vm setObject:_name forVariable:@"collection"];
        for (NSString *key in args) {
            [vm setObject:[args objectForKey:key] forVariable:key];
        }
        [vm excute];
    }
    return vm;
}

- (id)objectByExcuteScript:(NSString *)script withArgs:(NSDictionary *)args {
    UNQVirtualMachine *vm = [self excuteScript:script withArgs:args];
    return [vm extractVariable:@"ret"];
}


// MARK: UnQCollection protocol
- (__nullable id<UnQLiteDocument>)documentWithDictionary:(nonnull NSDictionary *)dicData {
    __block id documentId;
    [self.lite synchronize:^{
        documentId = [self objectByExcuteScript:@"db_store($collection, $new_value); $ret=$new_value.__id; db_commit();"
                                       withArgs:@{@"new_value":dicData}];
    }];
    return [self documentWithId:documentId];
}

- (__nullable id<UnQLiteDocument>)documentWithId:(nonnull id)docId {
    __block id<UnQLiteDocument> ret;
    [self.lite synchronize:^{
        if (!(ret = [_documentTable objectForKey:docId])) {
            if ([self objectByExcuteScript:@"$ret = db_fetch_by_id($collection, $document_id).__id == $document_id;"
                                  withArgs:@{@"document_id": docId}]) {
                ret = [[UNQDocument alloc] initWithCollection:self documentId: docId];
                [_documentTable setObject:ret forKey:docId];
            }
        }
    }];
    return ret;
}

- (NSArray * __nonnull)allDocuments {
    __block NSMutableArray *documents = [NSMutableArray new];
    [self.lite synchronize:^{
       id documentIds = [self objectByExcuteScript:@"$array=db_fetch_all($collection); $ret = []; foreach ($array as $doc){array_push($ret, $doc.__id);}"
                                          withArgs:nil];
        if ([documentIds isKindOfClass:NSArray.class]) {
            for (id documentId in documentIds) {
                UNQDocument *document;
                DOCUMENTWITHID(document, documentId);
                [documents addObject:document];
            }
        }
    }];
    return [NSArray arrayWithArray:documents];
}

// If filter is nil, return allDocuments.
- (NSArray * __nonnull)documentsWithFilter:(BOOL (^ __nullable)(id<UnQLiteDocument> __nonnull))filter {
    __block NSMutableArray *documents = [NSMutableArray new];
    NSString *script = @"$array=db_fetch_all($collection, filter); $ret = []; foreach ($array as $doc){array_push($ret, $doc.__id);}";
    [self.lite synchronize:^{
        UNQVirtualMachine *vm = [[UNQVirtualMachine alloc] initWithDataBase:self.lite];
        if ([vm compileScript:script]) {
            [vm setObject:_name forVariable:@"collection"];
            [vm setFunction:^int(UNQContext *context, int argc, unqlite_value **argv) {
                assert(argc == 1);
                unqlite_value *docVal = argv[0];
                unqlite_value *idVal = unqlite_array_fetch(docVal, "__id", 4);
                id documentId = unq_base_object_extract(idVal);
                UNQDocument *documment = [[UNQDocument alloc] initWithCollection:self documentId:documentId];
                [context pushResult:[NSNumber numberWithBool:filter(documment)]];
                return UNQLITE_OK;
            } forVariable:@"filter"];
        }
        [vm excute];
        id documentIds = [vm extractVariable:@"ret"];
        if ([documentIds isKindOfClass:NSArray.class]) {
            for (id documentId in documentIds) {
                UNQDocument *document;
                DOCUMENTWITHID(document, documentId);
                [documents addObject:document];
            }
        }
    }];
    
    return [NSArray arrayWithArray:documents];
}
@end
