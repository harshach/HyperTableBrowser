//
//  TableSchema.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 25/7/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "TableSchema.h"


@implementation TableSchema

+ (TableSchema *) tableSchemaWithDefaultContext
{
	return [NSEntityDescription insertNewObjectForEntityForName:@"TableSchema" inManagedObjectContext:[[NSApp delegate] managedObjectContext] ];
}

+ (NSEntityDescription *) entityDescription
{
	return [NSEntityDescription entityForName:@"TableSchema" inManagedObjectContext:[[NSApp delegate] managedObjectContext] ];
}

+ (NSArray *)listSchemes
{
	NSLog(@"Listing table schemes\n");
	NSFetchRequest * r = [[NSFetchRequest alloc] init];
	[r setEntity:[TableSchema entityDescription]];
	[r setIncludesPendingChanges:YES];
	NSError * err = nil;
	NSArray * schemesArray = [[[NSApp delegate] managedObjectContext] executeFetchRequest:r error:&err];
	if (err) {
		NSString * msg = @"listSchemes : Failed to get schemes from datastore";
		NSLog(@"Error: %s", [msg UTF8String]);
		[err release];
		[r release];
		return nil;
	}
	[err release];
	[r release];
	NSLog(@"There are %d schemes stored", [schemesArray count]);
	return schemesArray;
}

+ (TableSchema *)getSchemaByName:(NSString *)name
{
	NSArray * schemes = [TableSchema listSchemes];
	for (TableSchema * schema in schemes) {
		if ( [schema valueForKey:@"name"] == name) {
			return schema;
		}
	}
	return nil;
}

- (NSArray *) describeColumns
{
	return [NSArray array];
}

@end