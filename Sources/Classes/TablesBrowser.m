//
//  TablesBrowser.m
//  HyperTableBrowser
//
//  Created by Stanislav Yudin on 9/8/2010.
//  Copyright 2010 AwesomeStanly Lab. All rights reserved.
//

#import "TablesBrowser.h"
#import "DeleteRowOperation.h"
#import "HyperTable.h"

@implementation TablesBrowser

@synthesize pageSource;
@synthesize tablesList;

@synthesize newTablePnl;
@synthesize insertNewRowPnl;

@synthesize newTableController;
@synthesize newRowController;

@synthesize newTableBtn;
@synthesize dropTableBtn;
@synthesize refreshBtn;
@synthesize newRowBtn;
@synthesize dropRowBtn;

@synthesize toolBar;

@synthesize allowNewTable;
@synthesize allowDropTable;
@synthesize allowRefresh;
@synthesize allowInsertRow;
@synthesize allowDeleteRow;

#pragma mark Initialization

- (void) dealloc
{
	[pageSource release];
	[newTablePnl release];
	[newTableController release];
	[insertNewRowPnl release];
	[newRowController release];
	[refreshBtn release];
	[newTableBtn release];
	[dropTableBtn release];
	[newRowBtn release];
	[dropRowBtn release];
	[toolBar release];
	
	[super dealloc];
}

#pragma mark Toolbar Controller callbacks

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    if ([toolbarItem isEqual:newTableBtn]) {
		return [[self selectedBroker] isConnected];
    } else if ( [toolbarItem isEqual:dropTableBtn]) {
		return [tablesList selectedRowInColumn:0] >= 0;
    } else if ( [toolbarItem isEqual:refreshBtn]) {
		return [[self selectedBroker] isConnected];
	} else if ( [toolbarItem isEqual:newRowBtn]) {
		return [tablesList selectedRowInColumn:0] >= 0;
	} else if ( [toolbarItem isEqual:dropRowBtn]) {
		return ([pageSource selectedRowKeyValue] != nil) && ([[pageSource selectedRowKeyValue] length] > 0);
	}
	
	return YES;
}

- (IBAction)newTable:(id)sender
{
	[NSApp beginSheet:[[[NSApp delegate] tablesBrowser] newTablePnl] 
	   modalForWindow:[[[NSApp delegate] tablesBrowser] window]
        modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)dropTable:(id)sender
{
	id connection = [self selectedBroker];
	if (!connection) {
		[[NSApp delegate] showErrorDialog:-1 message:@"Cannot drop table. Server is NOT connected."];
		return;
	}
	
	[self indicateBusy];
	int rc = drop_table([connection thriftClient], [[[tablesList selectedCellInColumn:0] stringValue] UTF8String]);
	
	if (rc != T_OK) {
		[[NSApp delegate] showErrorDialog:-1 message:[NSString stringWithFormat:@"Failed to drop table \"%s\". %s",
													  [[[tablesList selectedCellInColumn:0] stringValue]  UTF8String],
													  [[HyperTable errorFromCode:rc] UTF8String]]];
		[self indicateDone];
	}
	else {
		NSString * msg = [NSString stringWithFormat:@"Table \"%s\" was dropped.",
						  [[[tablesList selectedCellInColumn:0] stringValue]  UTF8String]];
		
		//refresh tables on connection
		FetchTablesOperation * fetchTablesOp = [FetchTablesOperation fetchTablesFromConnection:connection];
		[fetchTablesOp setCompletionBlock: ^ {
			[tablesList reloadColumn:0];
			[[NSApp delegate] showErrorDialog:-1 message:msg];
		}];
		
		//start fetching tables
		[[[NSApp delegate] operations] addOperation: fetchTablesOp];
		[fetchTablesOp release];
	}
}

- (IBAction)refreshTables:(id)sender
{
	id hypertable = [self selectedBroker];
	if (hypertable)  {
		NSLog(@"Refreshing tables...");
		[hypertable refresh:^ {
			[tablesList loadColumnZero];
			[hypertable release];
		}];
	}
}

- (IBAction)insertNewRow:(id)sender
{
	id broker = [self selectedBroker];
	[[self newRowController] setConnection:broker];
	[NSApp beginSheet:[self insertNewRowPnl] modalForWindow:[self window]
        modalDelegate:self didEndSelector:nil contextInfo:nil];
	[broker release];
}

- (IBAction)deleteSelectedRow:(id)sender
{
	NSString * selectedRowKeyValue = [[self pageSource] selectedRowKeyValue];
	if (!selectedRowKeyValue || [selectedRowKeyValue length] <= 0 ) {
		NSLog(@"No row selected for delete");
		return;
	}
	
	NSString * selectedTable = [[self tablesList] selectedTable];
	if (!selectedTable) {
		NSLog(@"No table is selected to insert row");
		return;
	}
	
	NSLog([NSString stringWithFormat:@"Deleteing row with key \"%s\" from table \"%s\".", 
		   [[self selectedRowKeyValue] UTF8String],
		   [selectedTable UTF8String]]);
	
	id connection = [self selectedBroker];
	if (!connection) {
		[[NSApp delegate] showErrorDialog:-1 message:@"Cannot delete selected row. Server is NOT connected."];
		return;
	}
	
	//drop row
	DataPage * currentPage = [[self pageSource] page];
	int selectedRowIndex = [[self pageSource] selectedRowIndex];
	DataRow * selectedRow = page_row_at_index(currentPage, selectedRowIndex);
	DeleteRowOperation * delOp = [DeleteRowOperation deleteRow:selectedRow
													   inTable:selectedTable
												withConnection:connection];
	
	[[[NSApp delegate] operations] addOperation:delOp];
	[selectedRowKeyValue release];
	[delOp release];
	[connection release];
}

#pragma mark Servers List (NSBrowser) delegate callbacks

- (BOOL)browser:(NSBrowser *)browser shouldEditItem:(id)item
{ 
	//edit not supported yet
	return NO; 
}

- (BOOL)browser:(NSBrowser *)sender isColumnValid:(NSInteger)column
{
	return [[[self selectedBroker] tables] count] > 0;
}

//yes means non-expandable
- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item 
{
	if ([item class] == [HyperTable class]) {
		return NO;
	}
	return YES;
}

- (id)rootItemForBrowser:(NSBrowser *)browser
{
	return [self selectedBroker];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
	if ([item class] == [HyperTable class])
		return [item valueForKey:@"name"];
	else {
		return item;
	}

}
- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
	if ([item class] == [HyperTable class])
	{
		id table = [[[self selectedBroker] tables] objectAtIndex:index];
		return table;
	}
	return nil;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
	if ([item class] == [HyperTable class]) {
		return [[[self selectedBroker] tables] count];
	}
	return 0;
}

- (IBAction)tableSelectionChanged:(id)sender
{
	[pageSource showFirstPageFor:[[tablesList selectedCellInColumn:0] stringValue]
				  fromConnection:[self selectedBroker]];
}

@end
