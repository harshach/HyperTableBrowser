//
//  HyperTableOperationController.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 4/8/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "HyperTableOperationController.h"


@implementation HyperTableOperationController

@synthesize serverSelector;
@synthesize statusField;
@synthesize indicator;

- (void)dealloc
{
	[serverSelector release];
	[statusField release];
	[indicator release];
	[super dealloc];
}

- (IBAction)updateConnections:(id)sender
{
	[self setMessage:@"Updating connections..."];
	[self indicateBusy];
	
	//populate selector
	[serverSelector removeAllItems];
	id brokersList = [HyperTable allHypertables];
	BOOL didReconnect = NO;
	for (id hypertable in brokersList) {
		if ( ![hypertable isConnected]) {
			didReconnect = YES;
			[hypertable reconnect:^ {
				NSLog(@"Automatic reconnect: Operation complete.\n");
				[self indicateDone];
				
				if ( ![hypertable isConnected] ) {
					[self setMessage:@"Failed to reconnect to HyperTable thrift broker."];
					NSString * reason = [NSString stringWithFormat:@"Please make sure that Thrift API service is running on %@",
										 [hypertable valueForKey:@"name"]];
					[[NSApp delegate] showErrorDialog:1 
											  message:reason 
										   withReason:nil];		
				}
				else {
					[self setMessage:@"Connected to HyperTable broker successfuly."];
					
					[serverSelector addItemWithTitle:[hypertable ipAddress]];
					[self setMessage:[NSString stringWithFormat:@"%d server(s) available", 
									  [[serverSelector itemArray] count]] ];
				}
			}];
		}
		else {
			//already connected
			[serverSelector addItemWithTitle:[hypertable ipAddress]];
		}		
	}
	//is operation was started, do not indicate end
	if (!didReconnect) {
		[self setMessage:[NSString stringWithFormat:@"%d server(s) available", 
						  [[serverSelector itemArray] count]] ];
		[self indicateDone];
	}
}

- (id) getSelectedConnection {
	if (![[serverSelector itemArray] count] < 0) {
		[self setMessage:@"There are no connected servers. You need to establish connection before executing HQL."];
		return nil;
	}
	
	for (HyperTable * hypertable in [HyperTable allHypertables]) {
		if ([[hypertable ipAddress] isEqual: [[serverSelector selectedItem] title]]) {
			return hypertable;
		}
	}
	
	NSLog(@"No connected Hypertable brokers available!");
	return nil;
}

- (void)setMessage:(NSString*)message {
	NSLog(@"%s\n", [message UTF8String]);
	[statusField setTitleWithMnemonic:message];
}

- (void)indicateBusy {
	[indicator setHidden:NO];
	[indicator startAnimation:self];
}

- (void)indicateDone {
	[indicator stopAnimation:self];
	[indicator setHidden:YES];
}

@end
