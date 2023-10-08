//
//  MHSourceCodeTextView+Autocomplete.m
//  MadHat
//
//  Created by Dan Romik on 7/30/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSourceCodeTextView+Autocomplete.h"
#import "MHParser+SpecialSymbols.h"
#import "MHPackageManager.h"

#import <AppKit/AppKit.h>


@implementation MHSourceCodeTextView (Autocomplete)

- (MHSourceCodeAutocompleteSuggestionsView *)autocompleteSuggestionsView
{
    // lazily create the autocomplete suggestions view
    if (!_autocompleteSuggestionsView) {
        _autocompleteSuggestionsView = [[MHSourceCodeAutocompleteSuggestionsView alloc] initWithFrame:NSZeroRect];
        _autocompleteSuggestionsView.autocompleteSuggestionsDelegate = self;
        _autocompleteSuggestionsView.suggestionsFont = self.currentFont;
    }
    return _autocompleteSuggestionsView;
}

- (void)calculateAndPresentAutocompleteSuggestionsAtCurrentInsertionPoint
{
    MHSourceCodeTextStorage *sourceCode = self.textStorage;
    NSString *code = sourceCode.string;
    NSRange selectedRange = self.selectedRange;
    
    char *bytes = (char *)sourceCode.codeSemanticsData.bytes;
    char currentByte = bytes[selectedRange.location-1];
    char currentByteForegroundColorCode = currentByte & (kMHParserSyntaxColoringBitMask
    -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode);
    bool charUnresolvedCommand = (currentByteForegroundColorCode == kMHParserSyntaxColoringUnresolvedCommandName);
    if (charUnresolvedCommand) {
        NSInteger charIndex = selectedRange.location-1;
        while (charIndex >= 0 &&
               (bytes[charIndex] & (kMHParserSyntaxColoringBitMask -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode)) == kMHParserSyntaxColoringUnresolvedCommandName) {
            charIndex--;
        }
        NSRange unresolvedCommandRange = NSMakeRange(charIndex+2, selectedRange.location-charIndex-2);
        
        static const NSUInteger minimalLengthOfPrefixToTriggerAutocompleteSuggestions = 1;
        
        if (unresolvedCommandRange.length >= minimalLengthOfPrefixToTriggerAutocompleteSuggestions) {
            NSString *unresolvedCommandString = [code substringWithRange:NSMakeRange(charIndex+2, selectedRange.location-1-charIndex-1)];
            
            NSArray <NSString *> *autocompleteSuggestions =
            [[MHPackageManager sharedPackageManager]
             autocompleteSuggestionsForCommandPrefix:unresolvedCommandString
             includeConfigurationCommands:_notebookConfigurationCommandsEnabled];

            if (autocompleteSuggestions)
                [self presentAutocompleteSuggestions:autocompleteSuggestions
                 rangeOfSubstringToAutocomplete:NSMakeRange(charIndex+1, selectedRange.location-charIndex-1)];
        }
    }
}

- (void)presentAutocompleteSuggestions:(NSArray <NSString *> *)suggestions rangeOfSubstringToAutocomplete:(NSRange)range
{
    [self dismissAutocompleteSuggestions];  // dismiss any existing suggestions
    
    _rangeOfAutocompletionSubstring = range;
    NSLayoutManager *layoutManager = self.layoutManager;
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:nil];
    MHSourceCodeAutocompleteSuggestionsView *autocompleteSuggestionsView = self.autocompleteSuggestionsView;
    NSRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    autocompleteSuggestionsView.suggestions = suggestions;
//    [autocompleteSuggestionsView sizeToFit];
    NSRect myBounds = self.bounds;
    NSRect autocompleteSuggestionsViewFrame = autocompleteSuggestionsView.frame;
    autocompleteSuggestionsViewFrame.origin.x = glyphRect.origin.x;
    autocompleteSuggestionsViewFrame.origin.y = glyphRect.origin.y + glyphRect.size.height;
    
    if (autocompleteSuggestionsViewFrame.origin.x + autocompleteSuggestionsViewFrame.size.width > myBounds.size.width) {
        // push the suggestions view to the left to keep its content inside the superview
        autocompleteSuggestionsViewFrame.origin.x = myBounds.size.width - autocompleteSuggestionsViewFrame.size.width - 4.0;
    }

    if (autocompleteSuggestionsViewFrame.origin.y + autocompleteSuggestionsViewFrame.size.height > myBounds.size.height) {
        // push the suggestions view up to keep its content inside the superview
        autocompleteSuggestionsViewFrame.origin.y = glyphRect.origin.y - autocompleteSuggestionsViewFrame.size.height - 4.0;
    }


        
    autocompleteSuggestionsView.frame = autocompleteSuggestionsViewFrame;
    [self addSubview:autocompleteSuggestionsView];
}

- (void)dismissAutocompleteSuggestions
{
    [_autocompleteSuggestionsView removeFromSuperview];
    _autocompleteSuggestionsView.suggestions = [NSArray array];
}

- (bool)autocompleteSuggestionsViewPresented
{
    return (_autocompleteSuggestionsView.superview != nil);
}

- (void)selectedSuggestion:(NSString *)suggestion
{
    NSString *suggestionWithCommandSymbol = [NSString stringWithFormat:@"%C%@", kMHParserCharStartCommand, suggestion];
    if ([self shouldChangeTextInRange:_rangeOfAutocompletionSubstring replacementString:suggestionWithCommandSymbol]) {
        [self.textStorage replaceCharactersInRange:_rangeOfAutocompletionSubstring withString:suggestionWithCommandSymbol];
        [self didChangeText];
        self.selectedRange = NSMakeRange(_rangeOfAutocompletionSubstring.location+suggestionWithCommandSymbol.length, 0);
    }
    [self dismissAutocompleteSuggestions];
    [self.window makeFirstResponder:self];
}

@end
