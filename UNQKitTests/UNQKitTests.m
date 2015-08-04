//
//  UNQKitTests.m
//  UNQKitTests
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UnQLiteTool.h"
#import "UNQVirtualMachine.h"
#import "UNQCollection.h"
#import "UNQContext.h"
#import "UNQDocument.h"

@interface UNQKitTests : XCTestCase

@end

@implementation UNQKitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}
- (void)testExample {
    // This is an example of a functional test case.
    
}

- (void)testVM {
    id<UnQLite> lite = openUnQLite([NSTemporaryDirectory() stringByAppendingPathComponent:@"TestDB"], UnQLiteOpenOptionReadwrite | UnQLiteOpenOptionCreate, ^(NSException *exception) {
        NSLog(@"%@\n%@", [exception name], [exception userInfo]);
    });
    
    UNQVirtualMachine *vm = [[UNQVirtualMachine alloc] initWithDataBase:lite];
    
    [vm compileScript:@" if (!db_exists($collection)) { db_create($collection); }\n $ret = db_exists($collection) ? $var : '';\n $ret={name:'Littocats', mail: 'littocats@gmail.com', book:{name: 'Left'}}; db_store($collection,$ret); $ret=$ret.__id"];
    [vm setObject:@"test_collection" forVariable:@"collection"];
    [vm setObject:@"users" forVariable:@"var"];
    [vm excute];
    id ret = [vm extractVariable:@"ret"];
    
    NSLog(@"%@", ret);
}

- (void)testJX9 {
    id<UnQLite> lite = openUnQLite([NSTemporaryDirectory() stringByAppendingPathComponent:@"TestDB"], UnQLiteOpenOptionReadwrite | UnQLiteOpenOptionCreate, ^(NSException *exception) {
        NSLog(@"%@\n%@", [exception name], [exception userInfo]);
    });
    
    UNQVirtualMachine *vm = [[UNQVirtualMachine alloc] initWithDataBase:lite];
    
    NSString *script = @"$ret=[];array_push($ret, 'dog','cat');$ret = testFunc(1234)";
    [vm compileScript:script];
    [vm setFunction:^int(UNQContext *context, int argc, unqlite_value **argv) {
        [context pushResult:@(12348)];
        return 0;
    } forVariable:@"testFunc"];
    [vm excute];
    id ret = [vm extractVariable:@"ret"];
    XCTAssert([ret integerValue] == 12348);
}

- (void)testDocument {
    id<UnQLite> lite = openUnQLite([NSTemporaryDirectory() stringByAppendingPathComponent:@"TestDB"], UnQLiteOpenOptionReadwrite | UnQLiteOpenOptionCreate, ^(NSException *exception) {
        NSLog(@"%@\n%@\n%@", [exception name], [exception reason], [exception userInfo]);
    });
    
    UNQCollection *collection = [lite collectionWithName:@"test_collection"];
    XCTAssert(collection);
    NSArray *documents = [collection documentsWithFilter:^BOOL(id<UnQLiteDocument>  __nonnull document) {
        if ([[document documentId] integerValue] == 13) {
            NSLog(@"____%@", [document documentId]);
        }
        return [[document documentId] integerValue] < 20;
    }];
    for (UNQDocument *document in documents) {
        NSLog(@"%@", [document documentId]);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
