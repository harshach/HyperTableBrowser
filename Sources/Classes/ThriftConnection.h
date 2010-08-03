//
//  ThriftConnection.h
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 12/8/09.
//  Copyright 2009 AwesomeStanly Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ThriftConnectionInfo.h>
#include <HyperThriftWrapper.h>
#include <HyperThriftHql.h>

@interface ThriftConnection : NSObject {
	ThriftConnectionInfo * connInfo;
	HTHRIFT thriftClient;
	HTHRIFT_HQL hqlClient;
	NSMutableArray * tables;
	NSLock * connectionLock;
}

@property (retain) NSLock * connectionLock;
@property (retain) NSMutableArray * tables;
@property (retain) ThriftConnectionInfo * connInfo;
@property (assign) HTHRIFT thriftClient;
@property (assign) HTHRIFT_HQL hqlClient;

- (BOOL)isConnected;
+ (NSString *)errorFromCode:(int)code;

@end
