//
//  ClusterManager.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 9/8/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "ClusterManager.h"


@implementation ClusterManager

@synthesize clustersController;
@synthesize membersController;

- (ClusterManager *) init
{
	if (self = [super init]){
		NSLog(@"Initializing cluster manager.");
		hypertableCache = [[NSMutableDictionary alloc] init];
		hadoopCache = [[NSMutableDictionary alloc] init];
		sshCache = [[NSMutableDictionary alloc] init];
		dataFileName =  @"Clusters.xml";
	}
	return self;
}

- (NSArray *)clusters
{
	NSLog(@"Reading clusters...");
	NSFetchRequest * r = [[NSFetchRequest alloc] init];
	[r setEntity:[NSEntityDescription entityForName:@"Cluster" 
							 inManagedObjectContext:[self managedObjectContext]]];
	[r setIncludesPendingChanges:YES];
	NSError * err = nil;
	NSArray * clustersArray = [[self managedObjectContext] executeFetchRequest:r error:&err];
	if (err) {
		NSLog(@"Error: Failed to get clusters from data file.");
		[err release];
		[r release];
		return nil;
	}
	[err release];
	[r release];
	return [clustersArray retain];
}

- (NSSet *)serversInCluster:(NSManagedObject *)cluster
{
	if (cluster) {
		NSLog(@"Reading members of %s...", [[cluster valueForKey:@"name"] UTF8String]);
		NSSet * members = [cluster mutableSetValueForKey:@"members"];
		NSLog(@"There are %d members in %s", [members count], [[cluster valueForKey:@"name"] UTF8String]);
		return members;
	}
	NSLog(@"Error: nil cluster specified for searching...");
	return nil;
}

- (HyperTable *)hypertableOnServer:(NSManagedObject *)server
{
	NSString * ipAddress = [server valueForKey:@"ipAddress"];
	HyperTable * ht = [hypertableCache objectForKey:ipAddress];
	if (ht) {
		return ht;
	}
	else {
		int thriftPort = [[server valueForKey:@"thriftPort"] intValue];
		ht = [HyperTable hypertableAt:ipAddress onPort:thriftPort];
		NSLog(@"Connecting to HyperTable Thrift broker at %s:%d...",
			  [ipAddress UTF8String], thriftPort);
		[hypertableCache setObject:ht forKey:ipAddress];
		return ht;
		
	}	
}

- (SSHClient *)remoteShellOnServer:(NSManagedObject *)server
{
	NSString * ipAddress = [server valueForKey:@"ipAddress"];
	SSHClient * ssh = [sshCache	objectForKey:ipAddress];
	if (ssh) {
		return ssh;
	}
	else {
		int sshPort = [[server valueForKey:@"sshPort"] intValue];
		NSString * sshUserName = [server valueForKey:@"sshUserName"];
		NSString * sshPrivateKeyPath = [server valueForKey:@"sshPrivateKeyPath"];
		
		NSLog(@"Connecting to remote shell at %s:%d...",
			  [ipAddress UTF8String], sshPort);
		ssh = [[SSHClient alloc] initClientTo:ipAddress 
									   onPort:sshPort 
									   asUser:sshUserName 
									  withKey:sshPrivateKeyPath];
		
		int rc = [ssh runCommand:@"lsb_release -a"];
		if (rc) {
			NSLog(@"Failed to open remote shell on server. Code %d", rc);
			NSLog(@"Error: %s", [[ssh error] UTF8String]);
			[ssh release];
			return nil;
		}
		NSLog(@"Connected to server:\n%s", [[ssh output] UTF8String]);
		[sshCache setObject:ssh forKey:ipAddress];
		return ssh;
	}
}

- (NSManagedObject *)serviceOnServer:(NSManagedObject *)server withName:(NSString *)name
{
	NSLog(@"Quering service %@ on server %@.", name, [server valueForKey:@"name"]);
	NSFetchRequest * r = [[NSFetchRequest alloc] init];
	[r setEntity:[NSEntityDescription entityForName:@"Service" 
							 inManagedObjectContext:[self managedObjectContext]]];
	[r setIncludesPendingChanges:YES];
	[r setPredicate:[NSPredicate predicateWithFormat:@"runsOnServer = %@ && name = %@", 
					 server, 
					 name] ];
	
	NSError * err = nil;
	NSArray * servicesArray = [[self managedObjectContext] executeFetchRequest:r error:&err];
	if (err) {
		NSLog(@"Error: Failed to get services on server %@.", [server valueForKey:@"name"]);
		[err release];
		[r release];
		return nil;
	}
	[err release];
	[r release];
	if (![servicesArray count]) {
		NSLog(@"No service \"%@\" found on server \"%@\"",
			  name, [server valueForKey:@"name"]);
		return nil;
	}
	else if ([servicesArray count] > 1) {
		NSLog(@"Multiple (%d) services with name \"%@\" found on server \"%@\"",
			  [servicesArray count], name, [server valueForKey:@"name"]);
	}
	return [servicesArray objectAtIndex:0];
}

- (NSArray *)servicesOnServer:(NSManagedObject *)server
{
	NSLog(@"Enumerating services on server %@.", [server valueForKey:@"name"]);
	NSFetchRequest * r = [[NSFetchRequest alloc] init];
	[r setEntity:[NSEntityDescription entityForName:@"Service" 
							 inManagedObjectContext:[self managedObjectContext]]];
	[r setIncludesPendingChanges:YES];
	[r setPredicate:[NSPredicate predicateWithFormat:@"runsOnServer == %@", server]];
	
	NSError * err = nil;
	NSArray * servicesArray = [[self managedObjectContext] executeFetchRequest:r error:&err];
	if (err) {
		NSLog(@"Error: Failed to get services on server %@.", [server valueForKey:@"name"]);
		[err release];
		[r release];
		return nil;
	}
	[err release];
	[r release];
	if (![servicesArray count]) {
		NSLog(@"No services found on server \"%@\"", [server valueForKey:@"name"]);
		return nil;
	}
	NSLog(@"%d services found.", [servicesArray count]);
	return [servicesArray retain];
}

- (void) dealloc
{
	[sshCache release];
	[hypertableCache release];
	[hadoopCache release];
	
	[clustersController release];
	[membersController release];
	
	[super dealloc];
}

- (NSArray *)allHypertableBrokers
{
	NSMutableArray * found = [[NSMutableArray alloc] init];
	for (id cluster in [self clusters]) {
		id server = [cluster valueForKey:@"hypertableThriftBroker"];
		HyperTable * hypertable = [self hypertableOnServer:server];
		[found addObject:hypertable];
	}
	return found;
}

@end
