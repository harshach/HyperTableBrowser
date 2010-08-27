//
//  SSHClient.m
//  Ore Foundry
//
//  Created by Stanislav Yudin on 15/8/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "SSHClient.h"

@implementation SSHClient

@synthesize sshLock;
@synthesize targetIpAddress;

- (void) dealloc
{
	[sshLock release];
	[targetIpAddress release];
	[arguments release];
	[stdoutPipe release];
	[stderrPipe release];
	
	if (sshOutput) {
		[sshOutput release];
	}
	
	if (sshError) {
		[sshError release];
	}
	
	NSLog(@"Deallocating ssh client.");
	[super dealloc];
}

- (id) initClientTo:(NSString *)address 
			 onPort:(int)port 
			 asUser:(NSString *)user 
			withKey:(NSString *)privateKeyPath
{
	/*
	 self.ssh_cmd = ['ssh',
	 '-i', self.privkey_path,
	 '-p 22',
	 '-oStrictHostKeyChecking=no',
	 '-oBatchMode=yes', 
	 '-oLogLevel=ERROR',
	 '-oServerAliveInterval=15',
	 '-oPreferredAuthentications=publickey',
	 '-oUserKnownHostsFile=/dev/null',
	 host_login]
	 */
	
	if (self = [super init]) {
		
		//setup ssh arguments
		arguments = [[NSMutableArray alloc] init];
		
		//private key path
		[arguments addObject:@"-i"];
		[arguments addObject:[privateKeyPath stringByExpandingTildeInPath]];
		
		//port
		[arguments addObject:@"-p"];
		[arguments addObject:[NSString stringWithFormat:@"%d", port]];
		
		//options
		[arguments addObject:@"-oStrictHostKeyChecking=no"];
		[arguments addObject:@"-oBatchMode=yes"];
		[arguments addObject:@"-oLogLevel=ERROR"];
		[arguments addObject:@"-oServerAliveInterval=15"];
		[arguments addObject:@"-oPreferredAuthentications=publickey"];
		[arguments addObject:@"-oUserKnownHostsFile=/dev/null"];
		
		//login & host
		NSString * hostArgument = [NSString stringWithFormat:@"%s@%s", 
								   [user UTF8String],
								   [address UTF8String]];
		[arguments addObject:hostArgument];
		
		//save target address
		targetIpAddress = address;
		[targetIpAddress retain];
		
		//create lock
		sshLock = [[NSLock alloc] init];
	}
	return self;
}

- (id) initClientTo:(NSString *)address 
			 onPort:(int)port 
			 asUser:(NSString *)user
{
	return [self initClientTo:address 
					   onPort:port 
					   asUser:user 
					  withKey:[[NSString stringWithString:@"~/.ssh/id_dsa"] stringByExpandingTildeInPath]];
}

- (int)lastExitCode
{
	if (ssh) {
		return [ssh terminationStatus];
	}
	NSLog(@"/usr/bin/ssh was not executed. No terminationStatus available.");
	return 0;
}

- (int)runCommand:(NSString*)command
{
	NSLog(@"SSH running command \"%s\"", [command UTF8String]);
	ssh = [[NSTask alloc] init];
	//path to actual ssh
	[ssh setLaunchPath:@"/usr/bin/ssh"];
	
	//set arguments
	NSMutableArray * args = [NSMutableArray arrayWithArray:arguments];
	[args addObject:command];
	[ssh setArguments:args];
	
	if (stdoutPipe) {
		[stdoutPipe release];
		stdoutPipe = nil;
	}
	stdoutPipe = [[NSPipe alloc] init];
	if (stderrPipe) {
		[stderrPipe release];
		stderrPipe = nil;
	}
	stderrPipe = [[NSPipe alloc] init];
	if (sshOutput) {
		[sshOutput release];
		sshOutput = nil;
	}
	if (sshError) {
		[sshError release];
		sshError = nil;
	}
	
	[ssh setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[ssh setStandardError:stderrPipe];
	[ssh setStandardOutput:stdoutPipe];
	
	int rc = 0;
	[ssh launch];
	
	//wait for ssh with timeout
	int secondsToWait = 2;
	int totalWaited = 0;
	while (YES) {
		if ([ssh isRunning]) {
			sleep(secondsToWait);
			totalWaited += secondsToWait;
			
			if (totalWaited >= 14) {
				NSLog(@"Error: ssh command timed out!");
				
				[ssh terminate];
				[ssh release];
				return 254;
			}
		}
		else
			break;
		
	}
	
	[ssh waitUntilExit];
	
	if ([ssh terminationReason] != NSTaskTerminationReasonExit) {
		NSLog(@"Error: ssh child failed with uncaught signal");
		rc = 255;
	}
	else {
		rc = [ssh terminationStatus];
		if (rc) {
			NSLog(@"Error: ssh child process failed with code %d", rc);
		}
	}
	[ssh release];
	
	return rc;
}


- (NSString *) output
{
	if (!sshOutput) {
		NSLog(@"Reading ssh output");
		NSData *theOutput = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
		sshOutput = [[NSString alloc] initWithData:theOutput encoding:NSUTF8StringEncoding];
		[sshOutput retain];
		[stdoutPipe release];
		stdoutPipe = nil;
	}
	return sshOutput;
}

- (NSString *) error
{
	if (!sshError) {
		NSLog(@"Reading ssh error");
		NSData *theOutput = [[stderrPipe fileHandleForReading] readDataToEndOfFile];
		sshError = [[NSString alloc] initWithData:theOutput encoding:NSUTF8StringEncoding];
		[sshError retain];
		[stderrPipe release];
		stderrPipe = nil;
	}
	return sshError;
}

@end