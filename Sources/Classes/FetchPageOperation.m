//
//  FetchPageOperation.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 26/7/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "FetchPageOperation.h"

@implementation FetchPageOperation

@synthesize tableName;
@synthesize pageSize;
@synthesize pageIndex;
@synthesize errorCode;
@synthesize startIndex;
@synthesize stopIndex;
@synthesize connection;
@synthesize totalRows;
@synthesize page;

+ fetchPageFromConnection:(ThriftConnection *)conn
				 withName:(NSString *)tableName 
				  atIndex:(int)pageIndex 
				  andSize:(int)pageSize
{
	FetchPageOperation * fpOp = [[FetchPageOperation alloc] init];
	[fpOp setTableName:tableName];
	[fpOp setPageIndex:pageIndex];
	[fpOp setPageSize:pageSize];
	[fpOp setConnection:conn];
	return fpOp;
}

- (void) main
{
	NSLog(@"Fetching keys for table \"%s\"\n", [[self tableName] UTF8String]);
	[self setTotalRows:0];

	DataRow * keys = row_new([tableName UTF8String]);
	int rc = get_keys([connection thriftClient], keys, [tableName UTF8String]);
	[self setErrorCode:rc];
	if ( rc != T_OK) {
		NSLog(@"Failed to fetch keys with code %d, %s\n", rc,
			  [[ThriftConnection errorFromCode:rc] UTF8String]);
		free(keys);
		return;
	}
	
	if (keys->cellsCount <= 0) {
		NSLog(@"Zero keys returned.\n");
		free(keys);
		return;
	}
	
	[self setTotalRows:keys->cellsCount];
	
	NSLog(@"Calculating page indexes\n");
	//calculate start key index.
	startIndex = 0;
	if (pageIndex > 1) {
		startIndex = (pageIndex - 1) * pageSize;
	}
	
	//calculate stop key index
	stopIndex = startIndex + pageSize - 1;
	if (stopIndex > keys->cellsCount-1) {
		stopIndex = keys->cellsCount-1;
	}
	
	//set start key
	DataCell * startCell = row_cell_at_index(keys, startIndex);
	char * startRow = (char*)malloc(sizeof(char) * startCell->cellValueSize + 1);
	strncpy(startRow, startCell->cellValue, startCell->cellValueSize + 1);
	NSLog(@"Start row key: %s\n", startRow);
	
	//set stop key
	DataCell * stopCell = row_cell_at_index(keys, stopIndex);
	char * stopRow = (char*)malloc(sizeof(char) * stopCell->cellValueSize + 1);
	strncpy(stopRow, stopCell->cellValue, stopCell->cellValueSize + 1);
	NSLog(@"End row key: %s\n", stopRow);
	
	if ( !page )
		page = page_new();
	else
		page_clear(page);


	rc = get_page([connection thriftClient], page, [tableName UTF8String], startRow, stopRow);
	[self setErrorCode:rc];
	if ( rc != T_OK) {
		[self setErrorCode:rc];
		NSLog(@"Failed to fetch page content with code %d, %s\n", rc,
			  [[ThriftConnection errorFromCode:rc] UTF8String]);
		free(keys);
		return;
	}
	
	free(keys);
	NSLog(@"Successfully received page with %d row(s) of %d requested.\n",
		  page->rowsCount,
		  pageSize);
}

@end