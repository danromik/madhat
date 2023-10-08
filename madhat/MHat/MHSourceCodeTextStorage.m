//
//  MHSourceCodeTextStorage.m
//  MadHat
//
//  Created by Dan Romik on 1/25/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHSourceCodeTextStorage.h"
#import "MHParser+SpecialSymbols.h"


@interface MHSourceCodeTextStorage ()
{
    NSMutableAttributedString *_backingStore;
    NSMutableData *_codeSemanticsData;
    NSMutableArray <MHExpression *> *_codeToCompiledExpressions;
    NSMutableArray <NSValue *> *_codeParagraphRanges;
    BOOL _decomposesEditsIntoSmallOperations;
}
@end

@implementation MHSourceCodeTextStorage

- (instancetype)init
{
    if (self = [super init]) {
        _backingStore = [[NSMutableAttributedString alloc] init];
        _codeSemanticsData = [[NSMutableData alloc] init];
        _codeToCompiledExpressions = [[NSMutableArray alloc] init];
        _codeParagraphRanges = [[NSMutableArray alloc] initWithCapacity:0];
        _decomposesEditsIntoSmallOperations = YES;
    }
    return self;
}

- (BOOL)decomposesEditsIntoSmallOperations
{
    return _decomposesEditsIntoSmallOperations;
}

- (void)setDecomposesEditsIntoSmallOperations:(BOOL)decomposesEditsIntoSmallOperations
{
    _decomposesEditsIntoSmallOperations = decomposesEditsIntoSmallOperations;
}



#pragma mark - NSTextStorage methods that we are required to implement

- (NSString *)string
{
    return _backingStore.string;
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    return [_backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    NSUInteger strLength = str.length;
    id <MHSourceCodeTextStorageSmallEditsDelegate> smallEditsDelegate = self.smallEditsDelegate;

    if (!_decomposesEditsIntoSmallOperations) {
        [self atomicallyReplaceCharactersInRange:range withString:str notifySmallEditsDelegate:NO];
    }
    else {
        [smallEditsDelegate beginSmallEditsBlock:self
                                 totalLengthOfStringBeingDeleted:range.length
                                totalLengthOfStringBeingInserted:strLength];

        if (range.length > 0) {
            // deleting characters
            NSString *stringBeingDeleted = [self.string substringWithRange:range];
            NSArray <NSString *> *newlineSeparatedComponents = [stringBeingDeleted componentsSeparatedByString:@"\n"];
            NSUInteger numberOfComponents = newlineSeparatedComponents.count;
            NSRange rangeToDeleteAtomically;
            rangeToDeleteAtomically.location = range.location + range.length;
            for (NSInteger index = numberOfComponents - 1; index >= 0; index--) {
                // delete the component (if it is not empty)
                NSString *component = newlineSeparatedComponents[index];
                NSUInteger componentLength = component.length;
                if (componentLength > 0) {
                    rangeToDeleteAtomically.length = componentLength;
                    rangeToDeleteAtomically.location -= componentLength;
                    [self atomicallyReplaceCharactersInRange:rangeToDeleteAtomically
                                                  withString:@""
                          notifySmallEditsDelegate:YES];
                }

                // delete the newline preceding the component, unless we are in the first component, which was not preceded by a newline
                if (index > 0) {
                    rangeToDeleteAtomically.location--;
                    rangeToDeleteAtomically.length = 1;
                    [self atomicallyReplaceCharactersInRange:rangeToDeleteAtomically
                                                  withString:@""
                          notifySmallEditsDelegate:YES];
                }
            }
        }

        if (strLength > 0) {
            // inserting characters
            NSArray <NSString *> *newlineSeparatedComponents = [str componentsSeparatedByString:@"\n"];
            NSUInteger numberOfComponents = newlineSeparatedComponents.count;
            NSRange rangeToInsertAtomically;
            rangeToInsertAtomically.location = range.location;
            rangeToInsertAtomically.length = 0;
            for (NSInteger index = 0; index < numberOfComponents; index++) {
                // insert the component (if it is not empty)
                NSString *component = newlineSeparatedComponents[index];
                NSUInteger componentLength = component.length;
                if (componentLength > 0) {
                    [self atomicallyReplaceCharactersInRange:rangeToInsertAtomically
                                                  withString:component
                          notifySmallEditsDelegate:YES];
                    rangeToInsertAtomically.location += componentLength;
                }

                // insert the newline preceding the component, unless we are in the first component, which was not preceded by a newline
                if (index+1 < numberOfComponents) {
                    [self atomicallyReplaceCharactersInRange:rangeToInsertAtomically
                                                  withString:@"\n"
                          notifySmallEditsDelegate:YES];
                    rangeToInsertAtomically.location++;
                }
            }
        }
        
        [smallEditsDelegate endSmallEditsBlock:self];
    }
    
}

// this method gets sent text insertion/deletion operations which consist of either the ordinary text replacement operations that were sent to the replaceCharactersInRange:withString: method, or sub-operations of those operations (so-called "small edits") in which insertions are separated from deletions, and insertions and deletions of newline characters are done separately from insertions and deletions of all other content
- (void)atomicallyReplaceCharactersInRange:(NSRange)range withString:(NSString *)str
        notifySmallEditsDelegate:(BOOL)notifyDelegate
{
    NSString *stringBeingReplaced = [_backingStore.string substringWithRange:range];
    [_backingStore replaceCharactersInRange:range withString:str];
    
    NSUInteger strLength = str.length;

    // Update the code semantics and code-to-compiled-expression buffers so they stay consistent with the source code string
    char *newBytes = calloc(strLength, sizeof(char));
    [_codeSemanticsData replaceBytesInRange:range withBytes:newBytes length:strLength];
    free(newBytes);
    
    [_codeToCompiledExpressions removeObjectsInRange:range];
    NSUInteger index;
    MHExpression *dummyExpression = [MHExpression expression];  // FIXME: this seems pretty inefficient. Maybe insert an NSNull object?
    for (index = 0; index < strLength; index++) {
        [_codeToCompiledExpressions insertObject:dummyExpression atIndex:range.location];
    }

    [self edited:NSTextStorageEditedCharacters|NSTextStorageEditedAttributes range:range changeInLength:strLength - range.length];
    
    // notify the small edits delegate if appropriate
    if (notifyDelegate) {
        [self.smallEditsDelegate sourceCodeTextStorage:self
                           performedSmallEditReplacingCharactersInRange:range
                                             stringBeingReplaced:stringBeingReplaced
                                               replacementString:str];
    }
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range
{
    [_backingStore setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (NSMutableData *)codeSemanticsData
{
    return _codeSemanticsData;
}

- (NSMutableArray <NSValue *> *)codeParagraphRanges
{
    return _codeParagraphRanges;
}


- (void)setExpression:(MHExpression *)expression forCodeRange:(NSRange)range
{
    NSUInteger index;
    NSUInteger rangeLocationPlusLength = range.location + range.length;
    for (index = range.location; index < rangeLocationPlusLength; index++) {
        [_codeToCompiledExpressions replaceObjectAtIndex:index withObject:expression];
    }
}

- (MHExpression *)expressionMappedAtOrProximateToCodeIndex:(NSUInteger)codeIndex
{
    NSUInteger codeLength = self.length;
    if (codeIndex > codeLength)
        return nil;
        
    MHExpression *nextExpressionAfterCodeIndex = nil;
    NSInteger scanningIndex = codeIndex;
    while ((scanningIndex < codeLength) && (nextExpressionAfterCodeIndex.parent == nil)) {
        nextExpressionAfterCodeIndex = [_codeToCompiledExpressions objectAtIndex:scanningIndex];
        scanningIndex++;
    }
    if (nextExpressionAfterCodeIndex.parent)
        return nextExpressionAfterCodeIndex;

    
    MHExpression *previousExpressionBeforeCodeIndex = nil;
    scanningIndex = codeIndex-1;
    while ((previousExpressionBeforeCodeIndex.parent == nil) && (scanningIndex >= 0)) {
        previousExpressionBeforeCodeIndex = [_codeToCompiledExpressions objectAtIndex:scanningIndex];
        scanningIndex--;
    }
    if (previousExpressionBeforeCodeIndex.parent)
        return previousExpressionBeforeCodeIndex;

    return nil;
}



#pragma mark - Bracket matching

- (NSRange)rangeOfBracketChar:(unichar)bracketChar startScanningFromLocation:(NSUInteger)location
{
    // only the kMHParserCharOpenBlock and kMHParserCharCloseBlock bracket chars can be searched for in the current implementation
    if (bracketChar != kMHParserCharOpenBlock && bracketChar != kMHParserCharCloseBlock)
        return NSMakeRange(NSNotFound, 0);
    
    unichar matchingBracketChar = (bracketChar == kMHParserCharOpenBlock ? kMHParserCharCloseBlock : kMHParserCharOpenBlock);
        
    NSString *myString = self.string;
    NSUInteger myStringLength = myString.length;

    NSInteger indexIncrement = (bracketChar == kMHParserCharOpenBlock ? -1 : 1);
    NSInteger charIndex = location;
    NSUInteger consecutiveNewlineCounter = 0;
    NSUInteger bracketNestingCounter = 0;
    while (charIndex >= 0 && charIndex < myStringLength && consecutiveNewlineCounter < 2) {
        unichar currentChar = [myString characterAtIndex:charIndex];
        if (currentChar == bracketChar) {
            if (bracketNestingCounter == 0)
                return NSMakeRange(charIndex, 1);
            bracketNestingCounter--;
            consecutiveNewlineCounter = 0;
        }
        else if (currentChar == matchingBracketChar) {
            bracketNestingCounter++;
            consecutiveNewlineCounter = 0;
        }
        else if (currentChar == '\n')
            consecutiveNewlineCounter++;
        charIndex += indexIncrement;
    }
    return NSMakeRange(NSNotFound, 0);
}



@end
