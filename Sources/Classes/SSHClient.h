//
//  SSHClient.h
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 15/8/2010.
//  Copyright 2010 Stanislav Yudin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SSHClient : NSObject {	
	NSTask * ssh;
	NSLock * sshLock;
	NSMutableArray * arguments;
	NSPipe * stdoutPipe;
	NSPipe * stderrPipe;
	NSString * targetIpAddress;
	
	NSString * output;
	NSString * err;
}

@property (nonatomic, retain) NSString * output;
@property (nonatomic, retain) NSString * error;

@property (nonatomic, readonly, retain) NSLock * sshLock;
@property (nonatomic, readonly, retain) NSString * targetIpAddress;

- (id) initClientTo:(NSString *)address onPort:(int)port asUser:(NSString *)user withKey:(NSString *)privateKeyPath;

- (int)runCommand:(NSString*)command;

@end