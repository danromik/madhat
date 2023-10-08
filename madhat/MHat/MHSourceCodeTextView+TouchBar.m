//
//  MHSourceCodeTextView+TouchBar.m
//  MadHat
//
//  Created by Dan Romik on 7/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSourceCodeTextView+TouchBar.h"
#import "MHParser.h"

#import <AppKit/AppKit.h>


// Touch bar items:

static NSString *kMHTouchBarTextShiftButton    = @"com.numath.textshift";
static NSString *kMHTouchBarCodeQuoteBlockButton = @"com.numath.codequoteblock";
static NSString *kMHTouchBarMathModeCodeQuoteBlockButton = @"com.numath.mathcodequoteblock";
static NSString *kMHTouchBarCodeAnnotationBlockButton = @"com.numath.annotationblock";

NSString * const kMHTouchBarTextShiftLabel = @"T\u0302";


@implementation MHSourceCodeTextView (TouchBar)

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *touchBar = [[NSTouchBar alloc] init];
    touchBar.delegate = self;
    touchBar.defaultItemIdentifiers = @[
        kMHTouchBarTextShiftButton,
        kMHTouchBarCodeQuoteBlockButton,
        kMHTouchBarMathModeCodeQuoteBlockButton,
        kMHTouchBarCodeAnnotationBlockButton
    ];
    return touchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSCustomTouchBarItem *item;
    if ([identifier isEqualToString:kMHTouchBarTextShiftButton]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *myButton = [NSButton buttonWithTitle:kMHTouchBarTextShiftLabel target:self action:@selector(textShiftButtonTapped:)];
        item.view = myButton;
    }
    else if ([identifier isEqualToString:kMHTouchBarCodeQuoteBlockButton]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *myButton = [NSButton buttonWithTitle:@"【】" target:self action:@selector(codeQuoteBlockButtonTapped:)];
        item.view = myButton;
    }
    else if ([identifier isEqualToString:kMHTouchBarMathModeCodeQuoteBlockButton]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *myButton = [NSButton buttonWithTitle:@"〖〗" target:self action:@selector(mathModeCodeQuoteBlockButtonTapped:)];
        item.view = myButton;
    }
    else if ([identifier isEqualToString:kMHTouchBarCodeAnnotationBlockButton]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *myButton = [NSButton buttonWithTitle:@"~annotation~" target:self action:@selector(codeAnnotationBlockButtonTapped:)];
        item.view = myButton;
    }
    else
        return nil;
    return item;
}






- (void)textShiftButtonTapped:(id)sender
{
    NSRange insertionRange = [[[self selectedRanges] objectAtIndex:0] rangeValue];
    
    NSString *replacementString = kMHParserTextShiftControlString;
    
    if ([self shouldChangeTextInRange:insertionRange replacementString:replacementString]) {
        [self.textStorage replaceCharactersInRange:insertionRange withString:replacementString];

        // Move to the cursor to the left so it's positioned inside the math block
        NSRange selection = self.selectedRange;
        selection.location -= 1;
        self.selectedRange = selection;

        [self didChangeText];
    }
}


#pragma mark - Code quote and annotation blocks touch bar shortcuts

// FIXME: three almost identical methods - need to refactor to a single method

- (void)codeQuoteBlockButtonTapped:(id)sender
{
    NSRange insertionRange = [[[self selectedRanges] objectAtIndex:0] rangeValue];
    NSString *replacementString = @"【】";
    
    if ([self shouldChangeTextInRange:insertionRange replacementString:replacementString]) {
        [self.textStorage replaceCharactersInRange:insertionRange withString:replacementString];

        // Move to the cursor to the left so it's positioned inside the math block
        NSRange selection = self.selectedRange;
        selection.location -= 1;
        self.selectedRange = selection;

        [self didChangeText];
    }
}

// FIXME: violates DRY -- improve/refactor
- (void)mathModeCodeQuoteBlockButtonTapped:(id)sender
{
    NSRange insertionRange = [[[self selectedRanges] objectAtIndex:0] rangeValue];
    NSString *replacementString = @"〖〗";
    
    if ([self shouldChangeTextInRange:insertionRange replacementString:replacementString]) {
        [self.textStorage replaceCharactersInRange:insertionRange withString:replacementString];

        // Move to the cursor to the left so it's positioned inside the math block
        NSRange selection = self.selectedRange;
        selection.location -= 1;
        self.selectedRange = selection;

        [self didChangeText];
    }
}

// FIXME: violates DRY -- improve/refactor
- (void)codeAnnotationBlockButtonTapped:(id)sender
{
    NSRange insertionRange = [[[self selectedRanges] objectAtIndex:0] rangeValue];
    NSString *replacementString = @"⁓⁓";
    
    if ([self shouldChangeTextInRange:insertionRange replacementString:replacementString]) {
        [self.textStorage replaceCharactersInRange:insertionRange withString:replacementString];

        // Move to the cursor to the left so it's positioned inside the math block
        NSRange selection = self.selectedRange;
        selection.location -= 1;
        self.selectedRange = selection;

        [self didChangeText];
    }
}



@end
