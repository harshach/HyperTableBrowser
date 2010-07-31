//
//  HqlQueryOperation.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 26/7/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "HqlQueryOperation.h"

@implementation HqlQueryOperation

@synthesize connection;
@synthesize errorCode;
@synthesize page;
@synthesize query;

+ queryHql:(NSString *)query withConnection:(ThriftConnection *)con
{
	HqlQueryOperation * hqlOp = [[HqlQueryOperation alloc] init];
	[hqlOp setConnection:con];
	[hqlOp setQuery:query];
	return hqlOp;
}

- (void) dealloc
{
	[connection release];
	[query release];
	if (page) {
		page_clear(page);
		free(page);
		page = nil;
	}
	[super dealloc];
}

- (void)main
{
	NSLog(@"Executing HQL: %s\n", [query UTF8String]);
	
	if (page) {
		page_clear(page);
		free(page);
	}
	page = page_new();
	int rc = hql_query([connection hqlClient], page, [query UTF8String]);
	[self setErrorCode:rc];
}
@end
