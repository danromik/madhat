//
//  MHSourceCodeTextView+UserEditingHandler.m
//  MadHat
//
//  Created by Dan Romik on 1/14/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHSourceCodeTextView+UserEditingHandler.h"
#import "MHSourceCodeTextView+Autocomplete.h"
#import "MHSourceCodeAutocompleteSuggestionsView.h"
#import "MHParser.h"

#import <AppKit/AppKit.h>

#define MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(rng)  { \
    _codeRangeBeingEditedInsideSmallEditsBlock = (_codeRangeBeingEditedInsideSmallEditsBlock.location == NSNotFound ? rng : NSUnionRange(_codeRangeBeingEditedInsideSmallEditsBlock, rng)); \
}


@implementation MHSourceCodeTextView (UserEditingHandler)




- (void)didChangeText
{
    [super didChangeText];
    [self applyParagraphRanges];
    [self applySyntaxColoringToRange:_codeRangeBeingEditedInsideSmallEditsBlock];
    
    // present autocomplete suggestions if appropriate
    if (_userEditIsSingleCharInsertion) {
        [self calculateAndPresentAutocompleteSuggestionsAtCurrentInsertionPoint];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSourceCodeTextViewSelectionCodeRecompiledNotification
                                                        object:self];
}


#pragma mark - MHSourceCodeTextStorageDelegate methods

- (void)beginSmallEditsBlock:(MHSourceCodeTextStorage *)sourceCodeTextStorage
   totalLengthOfStringBeingDeleted:(NSUInteger)deletedLength
  totalLengthOfStringBeingInserted:(NSUInteger)insertedLength;
{
    _codeRangeBeingEditedInsideSmallEditsBlock = NSMakeRange(NSNotFound, 0);
    _userEditIsSingleCharInsertion = (deletedLength == 0 && insertedLength >= 1);
}

- (void)endSmallEditsBlock:(MHSourceCodeTextStorage *)sourceCodeTextStorage
{
    // do we need this? currently no need to do anything, but since we have a method call for beginning a replacement block, seems like a potentially useful idea to have a matching call to close it in case some cleanup is needed of some data structures
}


- (void)sourceCodeTextStorage:(nonnull MHSourceCodeTextStorage *)sourceCodeTextStorage
        performedSmallEditReplacingCharactersInRange:(NSRange)rangeOfCodeSubstringBeingDeleted
          stringBeingReplaced:(nonnull NSString *)codeSubstringBeingDeleted
            replacementString:(nonnull NSString *)codeStringBeingInserted
{
    // this method contains the main logic for parsing and acting on user edits to the code, which can consist of the following operations: a text insertion of a string not containing a newline character; a text insertion of a single newline character; a text deletion of a string not containing a newline character; or a text deletion of a newline character

    NSUInteger codeStringBeingInsertedLength = codeStringBeingInserted.length;

    // first, update the _codeRangeBeingEditedInsideSmallEditsBlock variable to take into account the edit, so that at the end of the replacement block, we'll know what range of characters in the code to apply syntax coloring to
    
    if (_codeRangeBeingEditedInsideSmallEditsBlock.location != NSNotFound) {
        if (rangeOfCodeSubstringBeingDeleted.length > 0) {
            // deleting characters
            if (rangeOfCodeSubstringBeingDeleted.location <= _codeRangeBeingEditedInsideSmallEditsBlock.location) {
                if (rangeOfCodeSubstringBeingDeleted.location + rangeOfCodeSubstringBeingDeleted.length <= _codeRangeBeingEditedInsideSmallEditsBlock.location) {
                    _codeRangeBeingEditedInsideSmallEditsBlock.location -= rangeOfCodeSubstringBeingDeleted.length;
                }
                else if (rangeOfCodeSubstringBeingDeleted.location + rangeOfCodeSubstringBeingDeleted.length >= _codeRangeBeingEditedInsideSmallEditsBlock.location + _codeRangeBeingEditedInsideSmallEditsBlock.length) {
                    _codeRangeBeingEditedInsideSmallEditsBlock = NSMakeRange(NSNotFound, 0);
                }
                else {
                    _codeRangeBeingEditedInsideSmallEditsBlock.length -= rangeOfCodeSubstringBeingDeleted.location + rangeOfCodeSubstringBeingDeleted.length - _codeRangeBeingEditedInsideSmallEditsBlock.location;
                    _codeRangeBeingEditedInsideSmallEditsBlock.location = rangeOfCodeSubstringBeingDeleted.location;
                }
            }
            else if (rangeOfCodeSubstringBeingDeleted.location < _codeRangeBeingEditedInsideSmallEditsBlock.location + _codeRangeBeingEditedInsideSmallEditsBlock.length) {
                if (rangeOfCodeSubstringBeingDeleted.location + rangeOfCodeSubstringBeingDeleted.length <= _codeRangeBeingEditedInsideSmallEditsBlock.location + _codeRangeBeingEditedInsideSmallEditsBlock.length) {
                    _codeRangeBeingEditedInsideSmallEditsBlock.length -= rangeOfCodeSubstringBeingDeleted.length;
                }
                else {
                    _codeRangeBeingEditedInsideSmallEditsBlock.length = rangeOfCodeSubstringBeingDeleted.location - _codeRangeBeingEditedInsideSmallEditsBlock.location;
                }
            }
        }
    }
    
    
    if (_codeRangeBeingEditedInsideSmallEditsBlock.location != NSNotFound) {
        if (codeStringBeingInsertedLength > 0) {
            // inserting characters
            if (rangeOfCodeSubstringBeingDeleted.location <= _codeRangeBeingEditedInsideSmallEditsBlock.location) {
                _codeRangeBeingEditedInsideSmallEditsBlock.location += codeStringBeingInsertedLength;
            }
            _codeRangeBeingEditedInsideSmallEditsBlock = NSUnionRange(_codeRangeBeingEditedInsideSmallEditsBlock, NSMakeRange(rangeOfCodeSubstringBeingDeleted.location, codeStringBeingInsertedLength));
        }
    }

    static NSRange zeroRange = { 0, 0 };
    
    // next, classify the edit operation as one of several kinds:
    // 1. adding a new character to an existing paragraph
    // 2. adding a new character at a place that creates a new paragraph following the last existing paragraph
    // 3. adding a new character at a place that creates a new paragraph preceding all existing paragraphs
    // 4. adding a new character at a place that creates a new paragraph in between two existing paragraphs
    // 5. adding a newline character that shifts some paragraphs down by one position
    // 6. adding a newline character that splits up a paragraph into two paragraph
    // 7. deleting a character from an existing paragraph
    // 8. deleting the only character in an existing paragraph
    // 9. deleting a newline in a way that shifts some paragraphs up by one position
    // 10. deleting a newline in a way that causes two existing paragraphs to merge
    // 11. replacing one character by another character
    // 12. another operation that adds or removes more than one character (requires special handling that I will add later)
        
    NSUInteger paragraphIndex;
    MHSourceCodeEditType editType;
    
    MHSourceCodeTextStorage *sourceCode = self.textStorage;
    NSString *code = sourceCode.string;
    NSUInteger codeLength = code.length;

    NSMutableArray <NSValue *> *codeParagraphRanges = sourceCode.codeParagraphRanges;
    
    NSUInteger numParagraphs = codeParagraphRanges.count;

    
    NSUInteger stringBeingReplacedLength = rangeOfCodeSubstringBeingDeleted.length;

    // Let's start by ruling out a type of edit operation that we don't know how to handle
    // FIXME: this is left over from an earlier version in which this was needed before I did some major refactoring, but I'm leaving it here just in case -- consider removing it in the future
    if ((codeStringBeingInsertedLength>0 && stringBeingReplacedLength > 0) ||
        (codeStringBeingInsertedLength > 1 && [codeStringBeingInserted rangeOfString:@"\n"].location != NSNotFound) ||
        (stringBeingReplacedLength > 1 && [codeSubstringBeingDeleted rangeOfString:@"\n"].location != NSNotFound)) {
        // this should never run, but if it does, this code will do the work of processing the edit correctly if inefficiently
        NSLog(@"unrecognized insertion/deletion type - currently handling this by recompiling the whole page");
        [self triggerCodeEditingDelegateUpdate];
        return;
    }
    
    // Now we are ready to start the classification into manageable operations. Let's consider first the case of inserting a character or string of (non-newline-containing) characters
    if (stringBeingReplacedLength == 0 && codeStringBeingInsertedLength >= 1) {
        
        // Is the string being inserted a newline?
        bool isNewline = [codeStringBeingInserted isEqualToString:@"\n"];    // if it's not a newline, that means it does not contain any newlines either since we filtered out that scenario before getting here (FIXME: that scenario needs to be handled separately)

        // Find whether the insertion string belongs to a paragraph
        NSRange editingParagraphRange = [self rangeOfParagraphContainingLocation:rangeOfCodeSubstringBeingDeleted.location
                                                               getParagraphIndex:&paragraphIndex];
        
        if (editingParagraphRange.location != NSNotFound) { // insertion string belongs to a paragraph
            unichar charBeforeInsertion = 0;
            if (isNewline && rangeOfCodeSubstringBeingDeleted.location==editingParagraphRange.location) {
#pragma mark - Newline insertion at beginning of paragraph
                // a newline character inserted at the beginning of a paragraph just shifts that paragraph and all subsequent ones by one position
                editType = MHSourceCodeEditNewlineAdditionShiftingParagraphs;
                
                // Update the paragraph ranges
                
                // Paragraphs starting from the one where the newline is inserted have their range locations shifted forward
                for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location++;
                    NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                // no need to call codeEditingDelegate method or update the _codeRangeBeingEditedInsideSmallEditsBlock range - this type of edit is cosmetic only and does not affect the semantic content of the code
            }
            else if (!isNewline ||
                ((rangeOfCodeSubstringBeingDeleted.location==0 || (charBeforeInsertion=[code characterAtIndex:rangeOfCodeSubstringBeingDeleted.location-1]) != '\n') &&
                (rangeOfCodeSubstringBeingDeleted.location==codeLength-1 || [code characterAtIndex:rangeOfCodeSubstringBeingDeleted.location+1] != '\n'))) {
#pragma mark - Non-newline-containing string insertion in middle of paragraph, or newline in middle of paragraph that doesn't split it
                // a non-newline-containing string inserted in the middle of the paragraph, or a newline character inserted in the middle of a paragraph that's not adjacent to an existing newline character, just extends that paragraph's length
                
                editType = MHSourceCodeEditCharsAdditionInExistingParagraph;
                
                // Update the paragraph ranges
                
                // The paragraph being edited grows its length
                NSRange paragraphNewRange = NSMakeRange(editingParagraphRange.location, editingParagraphRange.length+codeStringBeingInsertedLength);
                NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                [codeParagraphRanges replaceObjectAtIndex:paragraphIndex withObject:paragraphNewValue];
                
                // Subsequent paragraphs have their range locations shifted forward
                for (NSUInteger paraCopyingIndex = paragraphIndex+1; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location += codeStringBeingInsertedLength;
                    paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                          editType:editType
                                       firstAffectedParagraphRange:paragraphNewRange
                                       firstAffectedParagraphIndex:paragraphIndex
                                      secondAffectedParagraphRange:zeroRange
                                                 newParagraphRange:zeroRange];
                
                MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(paragraphNewRange);
            }
            else {
#pragma mark - Newline insertion in middle of paragraph that splits it into two
                // adding a newline character in the middle of a paragraph in a way that splits it into two paragraphs
                editType = MHSourceCodeEditNewlineAdditionSplittingParagraphs;
                
                // Update the paragraph ranges
                
                // Add the two new paragraphs resulting from the split
                bool wasAdjacentNewlineBeforeInsertion = (rangeOfCodeSubstringBeingDeleted.location>0 && charBeforeInsertion == '\n');
                
                NSRange firstParagraphRange = NSMakeRange(editingParagraphRange.location,
                                                          rangeOfCodeSubstringBeingDeleted.location-editingParagraphRange.location
                                                          - (wasAdjacentNewlineBeforeInsertion ? 1 : 0));
                NSValue *firstParagraphValue = [NSValue valueWithRange:firstParagraphRange];    // FIXME: check this
                [codeParagraphRanges replaceObjectAtIndex:paragraphIndex withObject:firstParagraphValue];

                NSRange secondParagraphRange = NSMakeRange(rangeOfCodeSubstringBeingDeleted.location
                                                           + (wasAdjacentNewlineBeforeInsertion ? 1 : 2),
                                                           editingParagraphRange.location + editingParagraphRange.length - rangeOfCodeSubstringBeingDeleted.location
                                                           - (wasAdjacentNewlineBeforeInsertion ? 0 : 1));
                NSValue *secondParagraphValue = [NSValue valueWithRange:secondParagraphRange];
                [codeParagraphRanges insertObject:secondParagraphValue atIndex:paragraphIndex+1];

                // Subsequent paragraphs have their range locations shifted forward
                for (NSUInteger paraCopyingIndex = paragraphIndex+2; paraCopyingIndex <= numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location++;
                    NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                          editType:editType
                                       firstAffectedParagraphRange:firstParagraphRange
                                       firstAffectedParagraphIndex:paragraphIndex
                                      secondAffectedParagraphRange:secondParagraphRange
                                                 newParagraphRange:zeroRange];

                MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(NSUnionRange(firstParagraphRange, secondParagraphRange));
            }
        }
        else {
            // The character was added in the space between paragraphs (or before the first paragraph, or after the last)
            
            // Separate this into two subcases according to whether the character is a newline
            
            if (!isNewline) {
                // A non-newline character
                // Now check whether it will have the effect of extending the preceding paragraph, extending the following paragraph,
                // merging the two paragraphs, or forming the beginning of a new paragraph
                
                NSRange precedingParagraphRange;
                if (paragraphIndex > 0)
                    precedingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex-1] rangeValue];

                NSRange followingParagraphRange;
                if (paragraphIndex < numParagraphs)
                   followingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex] rangeValue];
                
                bool extendingPrecedingParagraph = false;
                bool extendingFollowingParagraph = false;
                
                if (paragraphIndex > 0 &&
                    rangeOfCodeSubstringBeingDeleted.location <= precedingParagraphRange.location+precedingParagraphRange.length+1) {
                    extendingPrecedingParagraph = true;
                }
                
                if (paragraphIndex < numParagraphs &&
                    rangeOfCodeSubstringBeingDeleted.location + 1 == followingParagraphRange.location) {
                    extendingFollowingParagraph = true;
                }
                if (extendingPrecedingParagraph) {
                    if (extendingFollowingParagraph) {
#pragma mark - Non-newline-containing string insertion merging two paragraphs
                        // merging two paragraphs
                        editType = MHSourceCodeEditCharsAdditionMergingParagraphs;
                        
                        // Update the paragraph ranges
                        
                        // Merge the two paragraphs
                        NSRange firstParagraphRange = [codeParagraphRanges[paragraphIndex-1] rangeValue];
                        NSRange secondParagraphRange = [codeParagraphRanges[paragraphIndex] rangeValue];
                        
                        NSRange mergedParagraphRange = NSMakeRange(firstParagraphRange.location,
                                                                   firstParagraphRange.length+secondParagraphRange.length
                                                                   +2+codeStringBeingInsertedLength);
                        NSValue *paragraphNewValue = [NSValue valueWithRange:mergedParagraphRange];
                        [codeParagraphRanges replaceObjectAtIndex:paragraphIndex-1 withObject:paragraphNewValue];
                        [codeParagraphRanges removeObjectAtIndex:paragraphIndex];
                        
                        // Subsequent paragraphs have their range locations shifted forward
                        for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex+1 < numParagraphs; paraCopyingIndex++) {
                            NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                            paragraphNewRange.location += codeStringBeingInsertedLength;
                            paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                            [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                        }

                        [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                                  editType:editType
                                               firstAffectedParagraphRange:firstParagraphRange
                                               firstAffectedParagraphIndex:paragraphIndex-1
                                              secondAffectedParagraphRange:secondParagraphRange
                                                         newParagraphRange:mergedParagraphRange];

                        MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(mergedParagraphRange);
                    }
                    else {
#pragma mark - Non-newline-containing string insertion extending the preceding paragraph
                        // extending the preceding paragraph
                        editType = MHSourceCodeEditCharsAdditionInExistingParagraph;
                        
                        // Update the paragraph ranges
                        
                        // The paragraph being extended grows its length by either one or two characters depending on whether the new character was added after the newline character terminating the paragraph
                        NSRange extendingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex-1] rangeValue];
                        NSRange extendingParagraphNewRange = NSMakeRange(extendingParagraphRange.location,
                                                                         extendingParagraphRange.length
                                                                         + (rangeOfCodeSubstringBeingDeleted.location == precedingParagraphRange.location+precedingParagraphRange.length ? 0 : 1) + codeStringBeingInsertedLength);
                        
                        NSValue *paragraphNewValue = [NSValue valueWithRange:extendingParagraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paragraphIndex-1 withObject:paragraphNewValue];
                        
                        // Subsequent paragraphs have their range locations shifted forward
                        for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                            NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                            paragraphNewRange.location += codeStringBeingInsertedLength;
                            paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                            [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                        }
                        
                        [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                                  editType:editType
                                               firstAffectedParagraphRange:extendingParagraphNewRange
                                               firstAffectedParagraphIndex:paragraphIndex-1
                                              secondAffectedParagraphRange:zeroRange
                                                         newParagraphRange:zeroRange];
                        
                        MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(extendingParagraphNewRange);
                    }
                }
                else {
                    if (extendingFollowingParagraph) {
#pragma mark - Non-newline-containing string insertion extending the following paragraph
                        // extending the following paragraph
                        
                        editType = MHSourceCodeEditCharsAdditionInExistingParagraph;
                        
                        // Update the paragraph ranges
                        
                        // The paragraph being extended grows its length
                        NSRange extendingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex] rangeValue];
                        NSRange extendingParagraphNewRange = NSMakeRange(extendingParagraphRange.location-1,
                                                                         extendingParagraphRange.length + 1 + codeStringBeingInsertedLength);
                        NSValue *paragraphNewValue = [NSValue valueWithRange:extendingParagraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paragraphIndex withObject:paragraphNewValue];
                        
                        // Subsequent paragraphs have their range locations shifted forward
                        for (NSUInteger paraCopyingIndex = paragraphIndex+1; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                            NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                            paragraphNewRange.location += codeStringBeingInsertedLength;
                            paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                            [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                        }

                        [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                                  editType:editType
                                               firstAffectedParagraphRange:extendingParagraphNewRange
                                               firstAffectedParagraphIndex:paragraphIndex
                                              secondAffectedParagraphRange:zeroRange
                                                         newParagraphRange:zeroRange];

                        MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(extendingParagraphNewRange);
                    }
                    else {
#pragma mark - Non-newline-containing string insertion starting a new paragraph
                        // starting a new paragraph
                        
                        editType = MHSourceCodeEditCharsAdditionInNewParagraph;
                        
                        // Update the paragraph ranges
                        
                        // Add a new paragraph with the length of the insertion string
                        NSRange newParagraphRange = NSMakeRange(rangeOfCodeSubstringBeingDeleted.location, codeStringBeingInsertedLength);
                        [codeParagraphRanges insertObject:[NSValue valueWithRange:newParagraphRange] atIndex:paragraphIndex];
                        
                        // Subsequent paragraphs have their range locations shifted forward
                        for (NSUInteger paraCopyingIndex = paragraphIndex+1; paraCopyingIndex <= numParagraphs; paraCopyingIndex++) {
                            NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                            paragraphNewRange.location += codeStringBeingInsertedLength;
                            NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                            [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                        }

                        [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                                  editType:editType
                                               firstAffectedParagraphRange:newParagraphRange
                                               firstAffectedParagraphIndex:paragraphIndex
                                              secondAffectedParagraphRange:zeroRange
                                                         newParagraphRange:zeroRange];

                        MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(newParagraphRange);
                    }
                }
            }
            else {
#pragma mark - Newline insertion in white space between paragraph
                // adding a newline character in the white space between paragraphs
                editType = MHSourceCodeEditNewlineAdditionShiftingParagraphs;
                
                // Update the paragraph ranges
                
                // Subsequent paragraphs have their range locations shifted forward
                for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location++;
                    NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                // no need to call codeEditingDelegate method or update the _codeRangeBeingEditedInsideSmallEditsBlock range - this type of edit is cosmetic only and does not affect the semantic content of the code
            }
        }
    }
    else if (stringBeingReplacedLength >= 1 && codeStringBeingInsertedLength == 0) {
        
        // deleting a character
        
        // Find whether the position of the characters being deleted belongs to a paragraph
        NSRange editingParagraphRange = [self rangeOfParagraphContainingLocation:rangeOfCodeSubstringBeingDeleted.location
                                                               getParagraphIndex:&paragraphIndex];
        
        if (editingParagraphRange.location != NSNotFound) {
            // character belongs to a paragraph
            if (rangeOfCodeSubstringBeingDeleted.location == editingParagraphRange.location &&
                editingParagraphRange.length == stringBeingReplacedLength) {
                
#pragma mark - Deletion eliminates paragraph
                // deleting all characters in a paragraph, causing it to disappear
                editType = MHSourceCodeEditDeleteParagraph;
                
                // Update the paragraph ranges
                
                [codeParagraphRanges removeObjectAtIndex:paragraphIndex];
                
                // We skip the paragraphIndex paragraph. Subsequent paragraphs have their range locations shifted backwards
                for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex+1 < numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location -= stringBeingReplacedLength;
                    NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                          editType:editType
                                       firstAffectedParagraphRange:zeroRange
                                       firstAffectedParagraphIndex:paragraphIndex
                                      secondAffectedParagraphRange:zeroRange
                                                 newParagraphRange:zeroRange];

            }
            else {
                // deleting character in the middle (or possibly the end) of a paragraph
                if (rangeOfCodeSubstringBeingDeleted.location > 0 &&
                    [code characterAtIndex:rangeOfCodeSubstringBeingDeleted.location-1] == '\n' &&
                    rangeOfCodeSubstringBeingDeleted.location < codeLength &&
                    [code characterAtIndex:rangeOfCodeSubstringBeingDeleted.location] == '\n' &&
                    rangeOfCodeSubstringBeingDeleted.location+stringBeingReplacedLength < editingParagraphRange.location+editingParagraphRange.length
                    && rangeOfCodeSubstringBeingDeleted.location>editingParagraphRange.location+1
                    ) {

#pragma mark - Deletion splits up paragraph

                    // Deletion eliminates a line and splits up the paragraph into two paragraphs
                    editType = MHSourceCodeEditDeleteCharactersSplittingParagraphs;
                    
                    // Update the paragraph ranges

                    NSRange firstParagraphRange = NSMakeRange(editingParagraphRange.location,
                                                              rangeOfCodeSubstringBeingDeleted.location-editingParagraphRange.location-1);
                    NSValue *firstParagraphValue = [NSValue valueWithRange:firstParagraphRange];    // FIXME: check this
                    [codeParagraphRanges replaceObjectAtIndex:paragraphIndex withObject:firstParagraphValue];

                    NSRange secondParagraphRange = NSMakeRange(rangeOfCodeSubstringBeingDeleted.location + 1,
                                                               editingParagraphRange.location + editingParagraphRange.length
                                                               - rangeOfCodeSubstringBeingDeleted.location
                                                               - stringBeingReplacedLength - 1);
                    
                    NSValue *secondParagraphValue = [NSValue valueWithRange:secondParagraphRange];
                    [codeParagraphRanges insertObject:secondParagraphValue atIndex:paragraphIndex+1];

                    // Subsequent paragraphs have their range locations shifted backwards
                    for (NSUInteger paraCopyingIndex = paragraphIndex+2; paraCopyingIndex <= numParagraphs; paraCopyingIndex++) {
                        NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                        paragraphNewRange.location -= rangeOfCodeSubstringBeingDeleted.length;
                        NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                    }
                    
                    [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                              editType:editType
                                           firstAffectedParagraphRange:firstParagraphRange
                                           firstAffectedParagraphIndex:paragraphIndex
                                          secondAffectedParagraphRange:secondParagraphRange
                                                     newParagraphRange:zeroRange];

                    MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(NSUnionRange(firstParagraphRange, secondParagraphRange));
                }
                else {
#pragma mark - Deletion shortens paragraph
                    // Deletion just changes the length of the paragraph
                    editType = MHSourceCodeEditDeleteCharactersInParagraph;
                    
                    // Update the paragraph ranges
                    
                    NSRange newEditingParagraphRange;
                    if (rangeOfCodeSubstringBeingDeleted.location==editingParagraphRange.location) {
                        // the characters being deleted are at the beginning of the paragraph
                        
                        newEditingParagraphRange.location = editingParagraphRange.location;
                        newEditingParagraphRange.length = editingParagraphRange.length - stringBeingReplacedLength;
                        
                        if ([code characterAtIndex:newEditingParagraphRange.location] == '\n') {
                            // if the first character of the new paragraph is a newline, that means the paragraph actually starts after that newline character
                            newEditingParagraphRange.location++;
                            newEditingParagraphRange.length--;
                        }
                    }
                    else {
                        // the characters being deleted are at the middle or end of the paragraph, so only the length changes
                        newEditingParagraphRange.location = editingParagraphRange.location;
                        newEditingParagraphRange.length = editingParagraphRange.length - stringBeingReplacedLength;
                        
                        if ((editingParagraphRange.location + editingParagraphRange.length
                             == rangeOfCodeSubstringBeingDeleted.location + stringBeingReplacedLength)
                            && ([code characterAtIndex:rangeOfCodeSubstringBeingDeleted.location-1] == '\n')) {
                            // we are deleting characters at the end of the paragraph and there is still a trailing newline character
                            // which shouldn't be a part of the new paragraph, so shorten the new paragraph length by 1 to account for that
                            newEditingParagraphRange.length--;
                        };
                    }
                    
                    NSValue *paragraphNewValue = [NSValue valueWithRange:newEditingParagraphRange];
                    [codeParagraphRanges replaceObjectAtIndex:paragraphIndex withObject:paragraphNewValue];
                    
                    // Subsequent paragraphs have their range locations shifted backwards
                    for (NSUInteger paraCopyingIndex = paragraphIndex+1; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                        NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                        paragraphNewRange.location -= stringBeingReplacedLength;
                        paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                    }
                    
                    [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                              editType:editType
                                           firstAffectedParagraphRange:newEditingParagraphRange
                                           firstAffectedParagraphIndex:paragraphIndex
                                          secondAffectedParagraphRange:zeroRange
                                                     newParagraphRange:zeroRange];

                    MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(newEditingParagraphRange);
                }
            }
        }
        else {
            // deleting a newline character in the space between paragraphs
            
            NSRange precedingParagraphRange;
            if (paragraphIndex > 0)
                precedingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex-1] rangeValue];

            NSRange followingParagraphRange;
            if (paragraphIndex < numParagraphs)
               followingParagraphRange = [[codeParagraphRanges objectAtIndex:paragraphIndex] rangeValue];

            if (paragraphIndex > 0 && paragraphIndex < numParagraphs) {
                
                if (followingParagraphRange.location == precedingParagraphRange.location + precedingParagraphRange.length + 2) {
#pragma mark - Newline character deletion causes two paragraphs to merge
                    // deletion causes two paragraphs to merge
                    editType = MHSourceCodeEditDeleteLeadingToParagraphsMerging;
                    
                    // Update the paragraph ranges
                    
                    NSRange mergedParagraphRange = NSMakeRange(precedingParagraphRange.location,
                                                               precedingParagraphRange.length + followingParagraphRange.length + 1);
                    [codeParagraphRanges replaceObjectAtIndex:paragraphIndex-1 withObject:[NSValue valueWithRange:mergedParagraphRange]];
                    [codeParagraphRanges removeObjectAtIndex:paragraphIndex];
                    
                    // Subsequent paragraphs have their range locations shifted backwards
                    for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex+1 < numParagraphs; paraCopyingIndex++) {
                        NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                        paragraphNewRange.location--;
                        NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                    }
                    
                    [self.codeEditingDelegate codeDidChangeWithNewCode:sourceCode
                                                              editType:editType
                                           firstAffectedParagraphRange:precedingParagraphRange
                                           firstAffectedParagraphIndex:paragraphIndex-1
                                          secondAffectedParagraphRange:followingParagraphRange
                                                     newParagraphRange:zeroRange];

                    MHSourceCodeTextViewUpdateParagraphsWithSyntaxColoringRange(mergedParagraphRange);
                }
                else {
#pragma mark - Character deletion shifts paragraphs backwards
                    // deletion shifts the paragraphs below the deletion backwards
                    editType = MHSourceCodeEditDeleteShiftingParagraphs;
                    
                    // Update the paragraph ranges
                    
                    // Subsequent paragraphs have their range locations shifted backwards
                    for (NSUInteger paraCopyingIndex = paragraphIndex; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                        NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                        paragraphNewRange.location--;
                        NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                        [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                    }
                    
                    // no need to call codeEditingDelegate method or update the _codeRangeBeingEditedInsideSmallEditsBlock range - this type of edit is cosmetic only and does not affect the semantic content of the code
                }
            }
            else if (paragraphIndex == 0) {
#pragma mark - Character deletion shifts all paragraphs backwards

                // deleting before the first paragraph - all paragraphs will shift back
                editType = MHSourceCodeEditDeleteShiftingParagraphs;

                // Update the paragraph ranges
                
                for (NSUInteger paraCopyingIndex = 0; paraCopyingIndex < numParagraphs; paraCopyingIndex++) {
                    NSRange paragraphNewRange = [[codeParagraphRanges objectAtIndex:paraCopyingIndex] rangeValue];
                    paragraphNewRange.location--;
                    NSValue *paragraphNewValue = [NSValue valueWithRange:paragraphNewRange];
                    [codeParagraphRanges replaceObjectAtIndex:paraCopyingIndex withObject:paragraphNewValue];
                }

                // no need to call codeEditingDelegate method or update the _codeRangeBeingEditedInsideSmallEditsBlock range - this type of edit is cosmetic only and does not affect the semantic content of the code
            }
        }
    }
}

- (NSRange)rangeOfParagraphContainingLocation:(NSUInteger)location getParagraphIndex:(NSUInteger *)paragraphIndexPointer
{
    NSMutableArray <NSValue *> *codeParagraphRanges = self.textStorage.codeParagraphRanges;
    
    // FIXME: implementing a naive search algorithm. Binary search would be more efficient, potentially much more efficient for long documents
    NSUInteger index = 0;
    for (NSValue *paragraphRangeValue in codeParagraphRanges) {
        NSRange range = [paragraphRangeValue rangeValue];
        if (NSLocationInRange(location, range)) {
            *paragraphIndexPointer = index;
            return range;
        }
        if (range.location > location) {      // we passed the point where we might find a paragraph containing the given location
            *paragraphIndexPointer = index;
            return NSMakeRange(NSNotFound, 0);
        }
        index++;
    }
    *paragraphIndexPointer = index;
    return NSMakeRange(NSNotFound, 0);
}


@end
