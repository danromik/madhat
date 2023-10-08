//
//  MHSourceCodeAutocompleteSuggestionsView.h
//  MadHat
//
//  Created by Dan Romik on 7/30/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MHSourceCodeAutocompleteSuggestionsViewDelegate;

@interface MHSourceCodeAutocompleteSuggestionsView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>


@property id <MHSourceCodeAutocompleteSuggestionsViewDelegate>autocompleteSuggestionsDelegate;
@property NSFont *suggestionsFont;
@property NSArray <NSString *> *suggestions;

@end


@protocol MHSourceCodeAutocompleteSuggestionsViewDelegate <NSObject>

- (void)selectedSuggestion:(NSString *)suggestion;
- (void)dismissAutocompleteSuggestions;

@end

NS_ASSUME_NONNULL_END

