//
//  MHSourceCodeTextView+Autocomplete.h
//  MadHat
//
//  Created by Dan Romik on 7/30/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHSourceCodeTextView.h"
#import "MHSourceCodeAutocompleteSuggestionsView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHSourceCodeTextView (Autocomplete) <MHSourceCodeAutocompleteSuggestionsViewDelegate>

@property (readonly) MHSourceCodeAutocompleteSuggestionsView *autocompleteSuggestionsView;

- (bool)autocompleteSuggestionsViewPresented;

- (void)calculateAndPresentAutocompleteSuggestionsAtCurrentInsertionPoint;

@end

NS_ASSUME_NONNULL_END
