//
//  MHHelpNotebookSearchField.m
//  MadHat
//
//  Created by Dan Romik on 8/9/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHHelpNotebookSearchField.h"

@interface MHHelpNotebookSearchField ()
{
    NSArray <NSString *> *_searchResults;
    NSTableView *_searchResultsView;
}

@end

@implementation MHHelpNotebookSearchField

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        self.delegate = self;
        self.target = self;
        self.action = @selector(performSearch:);
    }
    return self;
}

- (NSArray <NSString *> *)searchResults
{
    return _searchResults;
}

- (void)setSearchResults:(NSArray<NSString *> *)searchResults
{
    _searchResults = searchResults;
    NSTableColumn *searchResultsColumn;
    if (!_searchResultsView) {
        // lazily create the search results view
        _searchResultsView = [[NSTableView alloc] initWithFrame:NSZeroRect];
        _searchResultsView.backgroundColor = [NSColor whiteColor];
        searchResultsColumn = [[NSTableColumn alloc] initWithIdentifier:@"search results"];
        searchResultsColumn.editable = NO;
        [_searchResultsView addTableColumn:searchResultsColumn];
        _searchResultsView.dataSource = self;
        _searchResultsView.wantsLayer = YES;
        _searchResultsView.layer.borderWidth = 1.0;
        _searchResultsView.layer.borderColor = [[NSColor blackColor] CGColor];
        _searchResultsView.target = self;
        _searchResultsView.doubleAction = @selector(searchResultCellDoubleClicked:);
    }
    else {
        searchResultsColumn = [[_searchResultsView tableColumns] objectAtIndex:0];
    }
    
    // resize the search results view to fit the contents
    NSRect rect = NSMakeRect(0,0, INFINITY, _searchResultsView.rowHeight);
    CGFloat maxSize = 0;
    NSUInteger numberOfRows = _searchResults.count;
    for (NSInteger rowIndex = 0; rowIndex < numberOfRows; rowIndex++) {
        NSCell *cell = [_searchResultsView preparedCellAtColumn:0 row:rowIndex];
        NSSize size = [cell cellSizeForBounds:rect];
        maxSize = MAX(maxSize, size.width);
    }
    maxSize = MAX(maxSize + 20.0, self.bounds.size.width);
    searchResultsColumn.width = maxSize;

    [_searchResultsView reloadData];
    [_searchResultsView deselectAll:nil];
}

- (void)presentSearchResultsPopover
{
    NSRect searchResultsViewFrame = _searchResultsView.frame;
    NSRect myBounds = self.bounds;
    NSRect myFrameInWindowCoordinates = [self convertRect:myBounds toView:self.window.contentView];
    
    NSWindow *myWindow = self.window;
    NSRect windowFrame = myWindow.frame;
    NSRect childWindowFrame = {
        .origin.x = windowFrame.origin.x + myFrameInWindowCoordinates.origin.x,
        .origin.y = windowFrame.origin.y + myFrameInWindowCoordinates.origin.y - searchResultsViewFrame.size.height - 2.0,
        .size.width = searchResultsViewFrame.size.width,
        .size.height = searchResultsViewFrame.size.height,
    };
    NSWindow *childWindow = [[NSWindow alloc] initWithContentRect:childWindowFrame
                                                        styleMask:NSWindowStyleMaskBorderless
                                                          backing:NSBackingStoreBuffered
                                                            defer:YES];
    [childWindow.contentView addSubview:_searchResultsView];
    
    childWindow.backgroundColor = [NSColor clearColor];
    childWindow.contentView.wantsLayer = YES;
    childWindow.contentView.layer.backgroundColor = [NSColor clearColor].CGColor;

    [myWindow addChildWindow:childWindow ordered:NSWindowAbove];

}

- (void)dismissSearchResultsPopover
{
    if (_searchResultsView) {
        NSWindow *parentWindow = _searchResultsView.window.parentWindow;
        [parentWindow removeChildWindow:_searchResultsView.window];
//        [parentWindow display];
        [_searchResultsView removeFromSuperview];
    }
}


#pragma mark - NSSearchFieldDelegate methods

- (void)performSearch:(NSSearchField *)sender
{
    NSString *searchString = [sender.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    static const NSUInteger kSearchStringMinimalLength = 2;
    if (searchString.length >= kSearchStringMinimalLength) {
        self.searchResults = [self.helpNotebookSearchFieldDelegate searchResultsForSearchString:searchString];
        [self presentSearchResultsPopover];
    }
}

- (void)searchFieldDidStartSearching:(NSSearchField *)sender
{
//    NSLog(@"searchFieldDidStartSearching %@", sender.stringValue);
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender
{
//    NSLog(@"searchFieldDidEndSearching %@", sender.stringValue);
    [self dismissSearchResultsPopover];
}



#pragma mark - NSTableViewDelegate and NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _searchResults.count+1;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // The table has just one column
    if (rowIndex == 0) {
        NSUInteger numberOfResults = _searchResults.count;
        NSString *headerString;
        if (numberOfResults == 0) {
            headerString = NSLocalizedString(@"No results found", @"");
        }
        else {
            headerString = [NSString stringWithFormat:NSLocalizedString(@"%lu page%@ found", @""), _searchResults.count,
                            (numberOfResults == 1 ? @"" : @"s")];
        }
        NSDictionary *attributes = @{
            NSFontAttributeName : [NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightRegular],
            NSForegroundColorAttributeName : [NSColor grayColor]
        };
        return [[NSAttributedString alloc] initWithString:headerString attributes:attributes];
    }
    return _searchResults[rowIndex-1];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (void)searchResultCellDoubleClicked:(NSTableView *)tableView
{
    NSInteger rowIndex = tableView.clickedRow;
    [self searchResultCellSelected:rowIndex];
}

- (void)searchResultCellSelected:(NSInteger)rowIndex
{
    if (rowIndex >= 0) {
        NSString *selectedSearchResult = _searchResults[rowIndex-1];
        [self.helpNotebookSearchFieldDelegate searchResultSelected:selectedSearchResult];
        [self dismissSearchResultsPopover];
        [self.window makeFirstResponder:self];
    }
}


#pragma mark - Key events

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if(commandSelector == @selector(moveUp:)) {
        if (_searchResultsView.superview) {
            NSInteger selectedSearchResultIndex = _searchResultsView.selectedRow;
            if (selectedSearchResultIndex >= 1) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:selectedSearchResultIndex > 1 ? selectedSearchResultIndex-1 : _searchResults.count];
                [_searchResultsView selectRowIndexes:indexSet byExtendingSelection:NO];
            }
        }
        return YES;
    }
    if(commandSelector == @selector(moveDown:)) {
        if (_searchResultsView.superview) {
            NSInteger selectedSearchResultIndex = _searchResultsView.selectedRow;
            if (selectedSearchResultIndex >= 1) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:selectedSearchResultIndex+1 <= _searchResults.count ? selectedSearchResultIndex+1 : 1];
                [_searchResultsView selectRowIndexes:indexSet byExtendingSelection:NO];
            }
            else if (_searchResults.count >= 0) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
                [_searchResultsView selectRowIndexes:indexSet byExtendingSelection:NO];
            }
        }
        return YES;
    }
    if(commandSelector == @selector(insertNewline:)) {
        NSInteger selectedRowIndex = _searchResultsView.selectedRow;
        [self searchResultCellSelected:selectedRowIndex];
        return YES;
    }
    return NO;    // Default handling of the command
}


@end
