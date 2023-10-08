//
//  MHParser.h
//  MadHat
//
//  Created by Dan Romik on 1/5/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHExpression.h"
#import "MHPackageManager.h"
#import "MHSourceCodeTextView.h"
#import "MHParagraph.h"
#import "MHParser+SpecialSymbols.h"
#import "MHVerticalLayoutContainer.h"


NS_ASSUME_NONNULL_BEGIN



#define MHParserMarkSemanticUnit(startIndex,endIndex,theExpression) { \
NSRange theRange = NSMakeRange(startIndex, endIndex - startIndex+1);   \
[_code setExpression:theExpression forCodeRange:theRange];   \
theExpression.codeRange = theRange;  \
}



typedef enum {
    MHParserStateScanningWord,
    MHParserStateScanningSpace,
    MHParserStateScanningCommand,
    MHParserStateScanningQuickExpression,
    MHParserStateGeneric,
    MHParserStateTest           // used for debugging/experimentation
} MHParserState;

typedef enum {
    MHParserCharSpace,
    MHParserCharNewline,
    MHParserCharText,           // in text parsing, everything that isn't classified as one of the other types is classified as MHParserCharText
    MHParserCharOpenBlock,
    MHParserCharCloseBlock,
    MHParserCharSubscript,
    MHParserCharSuperscript,
    MHParserCharFraction,
    MHParserCharStartCommand,
    MHParserCharModeSwitch,
    MHParserCharListDelimiter,
// FIXME: decide whether to include the next three character types - should they be in the typedef?
//    MHParserCharQuickCloseCommand,    // will only be tested for when scanning a command so I'm not including it in the typedef
//    MHParserCharNewline,              // I'm currently classifying such characters as MHParserCharSpace, so not including in typedef
    MHParserCharDerivative,    // this is treated as a substitution so not clear if it needs to be in the typedef
    MHParserCharOpenCodeQuoteBlock,
    MHParserCharOpenMathModeCodeQuoteBlock,
    MHParserCharOpenCodeAnnotationBlock,
    MHParserCharAttributes,
    MHParserCharAssignment,
    MHParserCharEndOfCode,
    MHParserCharIgnore,
    //
    MHParserCharTest            // used for debugging/experimentation
} MHParserCharType;

typedef enum {
    MHParserCharUnaryPrefixOperator,
    MHParserCharUnaryPostfixOperator,
    MHParserCharBinaryOperator,
    MHParserCharBinaryRelation,
    MHParserCharNumeralOrDecimalPoint,
    MHParserCharLeftBracket,
    MHParserCharRightBracket,
    MHParserCharDirectionallyAbmbiguousBracket,
    MHParserCharPunctuation,
    MHParserCharVarText,        // everything that isn't in one of the previous subcategories gets classified as MHParserCharVarText
} MHParserMathCharSubtype;


typedef enum {
    MHParserCodeFormattingText,
    MHParserCodeFormattingMathWithMathParagraphPrefix,
    MHParserCodeFormattingMathWithoutMathParagraphPrefix,
} MHParserCodeFormattingStyle;




@protocol MHParserDelegate;

@interface MHParser : NSObject <MHSourceCodeTextViewDelegate>
{
@private
    NSObject <MHSourceCodeString> *_code;
    NSString *_codeString;
    NSMutableData *_characterTypeBytesMutableBuffer;
    MHPackageManager *_packageManager;
    BOOL _notebookConfigurationCommandsEnabled;     // defaults to NO
}


@property (readonly) MHVerticalLayoutContainer *compiledExpression;
@property (readonly) NSData *characterTypeBytes;

@property BOOL notebookConfigurationCommandsEnabled; // defaults to NO, set to YES to enable notebook configuration commands

@property id <MHParserDelegate> delegate;


+ (NSAttributedString *)syntaxColoredCodeFromCode:(NSString *)sourceCode codeFormattingStyle:(MHParserCodeFormattingStyle)formattingStyle; // FIXME: implementation needs to be improved


@end



typedef enum {
    MHCompiledExpressionUpdateTypeCompilation,          // the entire document was recompiled
    MHCompiledExpressionUpdateTypeParagraphUpdate,      // an update to a single paragraph
    MHCompiledExpressionUpdateTypeParagraphDeletion,    // deleting a paragraph
    MHCompiledExpressionUpdateTypeParagraphSplit,       // splitting a paragarph into two paragraphs
    MHCompiledExpressionUpdateTypeParagraphMerge,       // merging two paragraphs into a single paragraph
    MHCompiledExpressionUpdateTypeParagraphInsertion,    // inserting a paragraph
} MHExpressionCompiledExpressionUpdateType;

@protocol MHParserDelegate

- (void)compiledExpressionChangedTo:(MHVerticalLayoutContainer *)newExpression
                         changeType:(MHExpressionCompiledExpressionUpdateType)changeType
             firstAffectedParagraph:(MHParagraph * _Nullable)firstParagraph
                     paragraphIndex:(NSUInteger)paragraphIndex
            secondAffectedParagraph:(MHParagraph * _Nullable)secondParagraph;

@end






NS_ASSUME_NONNULL_END
