//
//  UnQLiteTool.h
//  UNQKit
//
//  Created by 程巍巍 on 8/3/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, UnQLiteOpenOption) {
    /*
     * These bit values are intended for use in the 3rd parameter to the [unqlite_open()] interface
     * and in the 4th parameter to the xOpen method of the [unqlite_vfs] object.
     */
    UnQLiteOpenOptionReadonly            = 0x00000001,  /* Read only mode. Ok for [unqlite_open] */
    UnQLiteOpenOptionReadwrite           = 0x00000002,  /* Ok for [unqlite_open] */
    UnQLiteOpenOptionCreate              = 0x00000004,  /* Ok for [unqlite_open] */
    UnQLiteOpenOptionNomutex             = 0x00000020,  /* Ok for [unqlite_open] */
    UnQLiteOpenOptionOmitJournaling      = 0x00000040,  /* Omit journaling for this database. Ok for [unqlite_open] */
    UnQLiteOpenOptionInMemery            = 0x00000080,  /* An in memory database. Ok for [unqlite_open]*/
    UnQLiteOpenOptionMmap                = 0x00000100  /* Obtain a memory view of the whole file. Ok for [unqlite_open] */
};

#define UnQLiteExceptionName @"org.littocats.unq.exception"

@protocol UnQLite;
@protocol UnQLiteKVStore;
@protocol UnQLiteCollection;
@protocol UnQLiteKVCursor;
@protocol UnQLiteDocument;

/**
 打开数据库
 If nameOrDBFilePath is ":mem:" or NULL, then a private, in-memory database is created for the connection. The in-memory database will vanish when the database connection is closed. Future versions of UnQLite might make use of additional special filenames that begin with the ":" character. It is recommended that when a database filename actually does begin with a ":" character you should prefix the filename with a pathname such as "./" to avoid ambiguity.
 
 If not im-memory database and file for nameOrDBFilePath doesn't exist, automotica create file
 */
extern __nullable id<UnQLite> openUnQLite( NSString * __nonnull nameOrDBFilePath, UnQLiteOpenOption option, void (^ __nullable exceptionHandler)(NSException  * __nonnull ));

@protocol UnQLite <NSObject>

- (__nullable id<UnQLiteKVStore>)kvStore;

/**
 Auto create if not exist
 */
- (__nullable id<UnQLiteCollection>)collectionWithName:( NSString * __nonnull )name;

@property (nonatomic, readonly, nonnull) NSDictionary *configure;

@end

// MARK: Key/Value Store
@protocol UnQLiteKVStore <NSObject>

/**
 Write a new record into the database. If the record does not exists, it is created. Otherwise, it is replaced. That is, the new data overwrite the old data.
 If data is nill, db will delete current data for key.
 */
- (BOOL)storeData:(nonnull NSData *)data forKey:(nonnull NSString *)key;

/**
 Write a new record into the database. If the record does not exists, it is created. Otherwise, the new data chunk is appended to the end of the old chunk.
 */
- (BOOL)appendData:(nonnull NSData *)data forKey:(nonnull NSString *)key;
/**
 To remove a particular record from the database.
 */
- (BOOL)dropDataForKey:(nonnull NSString *)key;


/**
 If not exist, return nil.
 */
- (nullable NSData *)dataForKey:(nonnull NSString *)key;

/**
 return new cursor by every call. KVStore doesn't retain the return value, otherwise ,if you want to use the return value at other time, you should retain the return value by yourself.
 */
- (nonnull id<UnQLiteKVCursor>)cursor;

@end

// MARK: Key/Value Cursor
@protocol UnQLiteKVCursor <NSObject>

// Change current location. If success, return self, otherwise nil.
- (nullable id<UnQLiteKVCursor>)seek:(NSString * __nullable)key;
- (nullable id<UnQLiteKVCursor>)first;
- (nullable id<UnQLiteKVCursor>)last;
- (nullable id<UnQLiteKVCursor>)next;
- (nullable id<UnQLiteKVCursor>)previous;
- (BOOL)drop;

- (NSString * __nonnull)key;
- (NSData* __nonnull)value;
@end

// MARK: Document store

@protocol UnQLiteDocument <NSObject>

@property (nonatomic, nonnull, readonly) id documentId;
@property (nonatomic, nullable, readonly) NSDictionary *dictionaryRepresentation;

- (BOOL)drop;
/**
 Object must be NSString or NSNumber(bool/int/float and etc) or NSDictionary or NSArray, others will be instead by NSNull;
 KeyPath must be an array contains NSString or NSNumber, key that typed NSNumber will be instead by [NSNumber integerValue].
 */
- (BOOL)setObject:(nonnull id)object forKeyPath:(NSArray * __nonnull)keyPath;
- (nullable id)objectForKeyPath:(NSArray * __nonnull)keyPath;

@end

@protocol UnQLiteCollection <NSObject>

/**
 生成并存储 一个 document
 Object must be NSString or NSNumber(bool/int/float and etc) or NSDictionary or NSArray, others will be instead by NSNull;
 */
- (__nullable id<UnQLiteDocument>)documentWithDictionary:(nonnull NSDictionary *)dicData;

- (__nullable id<UnQLiteDocument>)documentWithId:(nonnull id)docId;

- (NSArray * __nonnull)allDocuments;

// If filter is nil, return allDocuments.
- (NSArray * __nonnull)documentsWithFilter:(BOOL (^ __nullable)(__nonnull id<UnQLiteDocument> document))filter;

@end

