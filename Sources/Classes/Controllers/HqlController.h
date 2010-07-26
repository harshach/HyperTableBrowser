//
//  HqlController.h
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 12/16/09.
//  Copyright 2009 AwesomeStanly Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#
#import <PageSource.h>
#import <ThriftConnection.h>
#import <HyperTableServer.h>
#import <HqlQueryOperation.h>

@interface HqlController : NSWindowController {
	NSTextView * hqlQuery;
	NSButton * goButton;
	NSProgressIndicator * indicator;
	NSTextField * statusField;
	
	NSPopUpButton * serverSelector;
	
	//source for hql page
	PageSource * pageSource;
	
	//view used to display source
	NSTableView * pageView;
}

@property (assign) IBOutlet NSTextView * hqlQuery;
@property (assign) IBOutlet NSButton * goButton;
@property (assign) IBOutlet NSPopUpButton * serverSelector;
@property (assign) IBOutlet PageSource * pageSource;
@property (assign) IBOutlet NSTableView * pageView;
@property (assign) IBOutlet NSProgressIndicator * indicator;
@property (assign) IBOutlet NSTextField * statusField;

- (IBAction)go:(id)sender;
- (IBAction)done:(id)sender;

//set available connections
- (IBAction)updateConnections:(id)sender;
//get connection selected by user in drop down 
- (id)getSelectedConnection;
//show status message on the bottom
- (void)setMessage:(NSString*)message;
//start operation indicator
- (void)indicateBusy;
//stop operation indicator
- (void)indicateDone;
//called when hql windows is about to close
- (void)windowWillClose:(NSNotification *)notification;
@end
