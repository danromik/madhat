//
//  MHSourceCodeTextStorage.h
//  MadHat
//
//  Created by Dan Romik on 1/25/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//
//  This class implements the text storage for the MHSourceCodeTextView class. It adds the following capabilities to an
//  ordinary NSTextStorage object:
//
//  - support for keeping track of code paragraph boundaries
//  - support for maintaining code semantics data (used for syntax coloring, autocomplete etc) alongside the code attributed text
//  - support for breaking up code editing actions into a succession of "small edit operations" in which text is either inserted or deleted (instead of both insertions and deletions being allowed to occur simultaneously) and in which the text which is inserted or deleted either consists of a single newline character, or is a string that does not contain a newline character
//  - calling a delegate object to inform it whenever a block of small edits begins and ends and after each small edit operations

#import <Cocoa/Cocoa.h>
#import "MHExpression.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MHSourceCodeString <NSObject>

@property (readonly) NSString *string;
@property (readonly) NSMutableData *codeSemanticsData;
@property (readonly) NSMutableArray <NSValue *> *codeParagraphRanges;

// the decomposesEditsIntoSmallOperations property: defaults to YES. Thist means that when the string property is manipulated, the text storage decomposes it into discrete insertion/deletion operations in which the string being inserted or deleted either does not contain any newline characters, or consists of a single newline character
// when decomposesEditsIntoSmallOperations is set to NO, changes to the code are processed atomically without breaking them up into small edits. In that case the smallEditsDelegate object is not called.
@property BOOL decomposesEditsIntoSmallOperations;

- (nullable MHExpression *)expressionMappedAtOrProximateToCodeIndex:(NSUInteger)codeIndex;
- (void)setExpression:(MHExpression *)expression forCodeRange:(NSRange)range;


// scans the receiver for the specified bracket character from the given location. The direction of scanning is backwards if the bracket is an opening bracket, or forward if the bracket is a closing bracket
// We only scan the current code paragraph, and if the bracket character is not found, the return range will have NSNotFound as its location field
// Currently the only allowed values for the bracket character are kMHParserCharOpenBlock and kMHParserCharCloseBlock
- (NSRange)rangeOfBracketChar:(unichar)bracketChar startScanningFromLocation:(NSUInteger)location;

@end

@protocol MHSourceCodeTextStorageSmallEditsDelegate;


@interface MHSourceCodeTextStorage : NSTextStorage <MHSourceCodeString>

// NSTextStorage has a delegate property conforming to the NSTextStorage protocol. Those methods didn't meet the particular needs we have, so the current class adds a separate delegate property, smallEditsDelegate, that conforms to a custom protocol, MHSourceCodeTextStorageSmallEditsDelegate
@property (weak) id <MHSourceCodeTextStorageSmallEditsDelegate> smallEditsDelegate;

@end

@protocol MHSourceCodeTextStorageSmallEditsDelegate <NSObject>

- (void)beginSmallEditsBlock:(MHSourceCodeTextStorage *)sourceCodeTextStorage
totalLengthOfStringBeingDeleted:(NSUInteger)deletedLength
totalLengthOfStringBeingInserted:(NSUInteger)insertedLength;

- (void)endSmallEditsBlock:(MHSourceCodeTextStorage *)sourceCodeTextStorage;

- (void)sourceCodeTextStorage:(MHSourceCodeTextStorage *)sourceCodeTextStorage
performedSmallEditReplacingCharactersInRange:(NSRange)range
          stringBeingReplaced:(NSString *)stringBeingReplaced
            replacementString:(NSString *)replacementString;
@end

NS_ASSUME_NONNULL_END
