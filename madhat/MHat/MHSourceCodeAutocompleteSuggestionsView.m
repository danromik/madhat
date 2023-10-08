//
//  MHSourceCodeAutocompleteSuggestionsView.m
//  MadHat
//
//  Created by Dan Romik on 7/30/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSourceCodeAutocompleteSuggestionsView.h"
#import "MHParser+SpecialSymbols.h"

@interface MHSourceCodeAutocompleteSuggestionsView ()
{
    NSArray <NSString *> *_suggestions;
    NSFont *_suggestionsFont;
    NSDictionary *_suggestionAttributeDict;
}

@end

@implementation MHSourceCodeAutocompleteSuggestionsView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        NSTableColumn *suggestionColumn = [[NSTableColumn alloc] initWithIdentifier:@"autocomplete suggestion"];
        [self addTableColumn:suggestionColumn];
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = [NSColor colorWithWhite:0.8 alpha:1.0];      // FIXME: temporary
        [self reloadData];
    }
    return self;
}

- (NSArray <NSString *> *)suggestions
{
    return _suggestions;
}

- (void)setSuggestions:(NSArray<NSString *> *)suggestions
{
    _suggestions = suggestions;
    
    [self reloadData];
    
    NSTableColumn *suggestionsColumn = [[self tableColumns] objectAtIndex:0];
    NSRect rect = NSMakeRect(0,0, INFINITY, self.rowHeight);
    CGFloat maxSize = 0;
    NSUInteger numberOfRows = _suggestions.count;
    for (NSInteger rowIndex = 0; rowIndex < numberOfRows; rowIndex++) {
        NSCell *cell = [self preparedCellAtColumn:0 row:rowIndex];
        NSSize size = [cell cellSizeForBounds:rect];
        maxSize = MAX(maxSize, size.width);
    }
    suggestionsColumn.width = maxSize + 2.0;   // add a bit of padding, otherwise sometimes cell text is truncated
    
    if (_suggestions.count > 0) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self selectRowIndexes:indexSet byExtendingSelection:NO];
    }
}

- (NSFont *)suggestionsFont
{
    if (!_suggestionsFont) {
        self.suggestionsFont = [NSFont systemFontOfSize:14.0];
    }
    return _suggestionsFont;
}

- (void)setSuggestionsFont:(NSFont *)suggestionsFont
{
    _suggestionsFont = [[NSFontManager sharedFontManager] convertFont:suggestionsFont toHaveTrait:NSBoldFontMask];
    _suggestionAttributeDict = @{
        NSFontAttributeName : _suggestionsFont,
        NSForegroundColorAttributeName : [NSColor colorWithRed:0.25 green:0.0 blue:0.75 alpha:1.0]  // FIXME: temporary
    };
    [self reloadData];
}


#pragma mark - NSTableViewDelegate and NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _suggestions.count;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // The table has just one column
    NSString *suggestionString = [NSString stringWithFormat:@"%C%@", kMHParserCharStartCommand, _suggestions[rowIndex]];
    NSAttributedString *suggestionAttribString = [[NSAttributedString alloc] initWithString:suggestionString
                                                                                 attributes:_suggestionAttributeDict];
    return suggestionAttribString;
}


#pragma mark - Capturing key events

- (void)keyDown:(NSEvent *)event
{
    NSString *characters = event.characters;
    unichar theChar = [characters characterAtIndex:0];
    switch (theChar) {
        case '\r':
        case '\t': {
            NSInteger selectedRowIndex = self.selectedRow;
            if (selectedRowIndex == -1) {
                NSBeep();
            }
            else {
                NSString *theSuggestion = _suggestions[selectedRowIndex];
                [self.autocompleteSuggestionsDelegate selectedSuggestion:theSuggestion];
                
            }
            return;
        }
        case NSLeftArrowFunctionKey:
        case NSRightArrowFunctionKey:
        case NSDeleteCharacter: {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
                [self selectRowIndexes:indexSet byExtendingSelection:NO];
                [self.window makeFirstResponder:self.superview];
                return;
        }
            break;
        case NSUpArrowFunctionKey:
            if (self.selectedRow == 0) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:_suggestions.count-1];
                [self selectRowIndexes:indexSet byExtendingSelection:NO];
                return;
            }
            break;
        case NSDownArrowFunctionKey:
            if (self.selectedRow == _suggestions.count-1) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
                [self selectRowIndexes:indexSet byExtendingSelection:NO];
                return;
            }
            break;
        case 0x1B:  // the escape key
            [self.window makeFirstResponder:self.superview];
            [self.autocompleteSuggestionsDelegate dismissAutocompleteSuggestions];
            return;
            break;
    }
    [super keyDown:event];
}

@end
