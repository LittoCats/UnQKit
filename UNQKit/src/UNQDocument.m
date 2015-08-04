//
//  UNQDocuments.m
//  UNQKit
//
//  Created by 程巍巍 on 8/4/15.
//  Copyright © 2015 Littocats. All rights reserved.
//

#import "UNQDocument.h"
#import "UNQDataBase.h"

#define ISDROPPED if (_isDropped) {\
    [self lite].exceptionHandler([[NSException alloc] initWithName:UnQLiteExceptionName\
                                                            reason:@"Document has been dropped."\
                                                        userInfo:@{@"UnQLite": [[self lite] configure],\
                                                                   @"UnQLiteCollection": [self.collection name]}]);\
    return;\
}

@interface UNQDocument ()

@property (nonatomic, nonnull, strong) UNQCollection *collection;

@property (nonatomic, nonnull, strong) id documentId;

@property (nonatomic, nonnull, readonly) UNQDataBase *lite;

@property (nonatomic) BOOL isDropped;

@end

@implementation UNQDocument

- (nonnull id)initWithCollection:(UNQCollection * __nonnull)collection documentId:(nonnull id)documentId {
    if (self = [super init]) {
        self.collection = collection;
        self.documentId = documentId;
    }
    return self;
}

- (UNQDataBase *)lite {
    return self.collection.lite;
}

// MARK: UnQLiteDocument

- (NSDictionary *)dictionaryRepresentation {
    __block id ret;
    [[self lite] synchronize:^{
        ISDROPPED
        ret = [self.collection objectByExcuteScript:@"$ret=db_fetch_by_id($collection,$document_id);" withArgs:nil];
    }];
    [ret removeObjectForKey:@"__id"];
    return ret;
}

- (BOOL)setObject:(nonnull id)object forKeyPath:(NSArray * __nonnull)keyPath {
    __block id ret;
    NSMutableString *path = [NSMutableString new];
    for (id key in keyPath) {
        if ([key isKindOfClass:NSString.class]) {
            [path appendFormat:@"['%@']", key];
        }else if ([key isKindOfClass:NSNumber.class]) {
            [path appendFormat:@"[%li]", (long)[key integerValue]];
        }
    }
    NSString *script = [NSString stringWithFormat:@"$doc = db_fetch_by_id($collection,$document_id);$doc%@ = $new_value;$ret=db_commit()",path];
    [[self lite] synchronize:^{
        ISDROPPED
        ret = [self.collection objectByExcuteScript:script withArgs:@{@"new_value": object,
                                                                      @"document_id": _documentId}];
    }];
    return [ret boolValue];
}

- (id)objectForKeyPath:(NSArray * __nonnull)keyPath {
    __block id ret;
    NSMutableString *path = [NSMutableString new];
    for (id key in keyPath) {
        if ([key isKindOfClass:NSString.class]) {
            [path appendFormat:@"['%@']", key];
        }else if ([key isKindOfClass:NSNumber.class]) {
            [path appendFormat:@"[%li]", (long)[key integerValue]];
        }
    }
    NSString *script = [NSString stringWithFormat:@"$ret = db_fetch_by_id($collection,$document_id)%@;",path];
    [[self lite] synchronize:^{
        ISDROPPED
        ret = [self.collection objectByExcuteScript:script withArgs:@{@"document_id": _documentId}];
    }];
    return ret;
}

- (BOOL)drop {
    __block id ret;
    [self.lite synchronize:^{
        ret = [self.collection objectByExcuteScript:@"$ret=db_drop_record($collection, $document_id);"
                                           withArgs:@{@"document_id": _documentId}];
        if ([ret boolValue]) {
            [self.collection.documentTable removeObjectForKey:_documentId];
        }
    }];
    return [ret boolValue];
}
@end
