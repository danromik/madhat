//
//  MHHelpNotebookSearchField.h
//  MadHat
//
//  Created by Dan Romik on 8/9/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MHHelpNotebookSearchFieldDelegate
- (nullable NSArray <NSString *> *)searchResultsForSearchString:(NSString *)searchString;
- (void)searchResultSelected:(NSString *)searchResult;
@end


@interface MHHelpNotebookSearchField : NSSearchField <NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property NSArray <NSString *> *searchResults;
@property (weak) id <MHHelpNotebookSearchFieldDelegate> helpNotebookSearchFieldDelegate;

- (void)presentSearchResultsPopover;
- (void)dismissSearchResultsPopover;

@end



NS_ASSUME_NONNULL_END
