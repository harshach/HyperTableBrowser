//
//  HqlController.h
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 12/16/09.
//  Copyright 2009 AwesomeStanly Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Utility.h>
#import <PageSource.h>
#import <HqlQueryOperation.h>

@interface HqlController : HyperTableBrokersCntrl {
	NSTextView * hqlQuery;
	NSButton * goButton;
	
	//source for hql page
	PageSource * pageSource;
	
	//view used to display source
	NSTableView * pageView;
}

@property (nonatomic, retain) IBOutlet NSTextView * hqlQuery;
@property (nonatomic, retain) IBOutlet NSButton * goButton;
@property (nonatomic, retain) IBOutlet PageSource * pageSource;
@property (nonatomic, retain) IBOutlet NSTableView * pageView;

- (IBAction)go:(id)sender;
- (IBAction)done:(id)sender;

- (void)runQuery:(NSString *)query withConnection:(id)connection;

@end
