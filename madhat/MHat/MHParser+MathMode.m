//
//  MHParser+MathMode.m
//  MadHat
//
//  Created by Dan Romik on 1/5/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHParser+MathMode.h"
#import "MHParser+TextMode.h"
#import "MHInlineMathContainer.h"
#import "MHMathAtom.h"
//#import "MHWhitespace.h"
#import "MHScriptedExpression.h"
#import "MHFraction.h"
#import "MHBracket.h"
#import "MHPlaceholderCommand.h"
#import "MHAttributesCommand.h"

#import <AppKit/AppKit.h>


#define MakeExpressionAndMarkSyntaxColoringForCurrentWord(varName) ({ \
    varName = [_packageManager expressionForMathKeyword:currentWord]; \
    if (!varName) {\
        varName = [MHMathAtom mathAtomWithString:currentWord typographyClass:currentWordTypographyClass]; \
        if (currentWordIsDifferential) { \
            codeColoringBuffer[endOfSemanticUnitIndex-1] |= kMHParserSyntaxColoringMathKeyword; \
            codeColoringBuffer[endOfSemanticUnitIndex] |= kMHParserSyntaxColoringMathKeyword; \
        } \
    } \
    else { \
        NSUInteger anIndex; \
        for (anIndex=beginningOfSemanticUnitIndex; anIndex <= endOfSemanticUnitIndex; anIndex++) {       \
            codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringMathKeyword;    \
        } \
    } \
})

#define UnicharIsNumeral(myUnichar) (myUnichar >= '0' && myUnichar <= '9')

// FIXME: a major todo item is to refactor the code in a way that eliminates all cast operations, they are bad practice and represent assumptions about the way objects behave that aren't guaranteed by the interface

@implementation MHParser (MathMode)

- (MHHorizontalLayoutContainer *)parseMathModeCodeInRange:(NSRange)charRange
                               actuallyScannedRange:(NSRange *)scannedRangePointer
                                      rootContainer:(nullable MHHorizontalLayoutContainer *)rootContainer
{
        
    NSUInteger index;
    NSUInteger maxIndex = charRange.location + charRange.length;
    NSUInteger beginningOfSemanticUnitIndex = 0;
    NSUInteger endOfSemanticUnitIndex = 0;

    NSMutableArray <MHExpression *> *attachedContentExpressions = [[NSMutableArray alloc] initWithCapacity:0];

    char *codeColoringBuffer = [_characterTypeBytesMutableBuffer mutableBytes];
    
    
    NSUInteger numberOfDerivativeSymbols = 0;   // for use when we encounter a sequence of derivative/prime symbols
    
    MHHorizontalLayoutContainer *compiledMathExpression = (rootContainer != nil ? rootContainer : [MHInlineMathContainer expression]);

    MHHorizontalLayoutContainer *currentContainer = compiledMathExpression;
    MHParserState currentState = MHParserStateGeneric;
    MHParserCharType currentCharType;
    MHParserMathCharSubtype currentCharSubtype;
    MHBracketType bracketType = kMHParserBracketCharLeftParenthesis;   // FIXME: pointless initialization to eliminate an incorrect compiler warning, is there a better way to handle this?
    NSMutableString *currentWord;
    MHTypographyClass currentWordTypographyClass = MHTypographyClassText; // initializing so the compiler won't complain (this value is never used)
    bool scannedDecimalPointWhenScanningNumber = false;
    bool currentWordIsDifferential = false;
    NSMutableString *currentCommand;
    unichar currentChar = 0;
    MHListDelimiterType currentDelimiterType = MHListDelimiterTypePrimary;
    
    for (index = charRange.location /* + (paragraphMode ? 1 : 0)*/ ; index <= maxIndex; index++) {  // In paragraph mode, skip the control character kMHParserCharStartMathParagraph      // FIXME: the logic isn't quite correct here, fix this
        
        currentCharSubtype = MHParserCharVarText; // assign some value so the compiler won't complain it may not be initialized when used later...
        // Classify the character so we can decide what to do
        if (index == maxIndex)
            currentCharType = MHParserCharEndOfCode;
        else {
            currentChar = [_codeString characterAtIndex:index];
            
            // Mark the character as scanned in math mode:
            codeColoringBuffer[index] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
            
            // Code to process comments in the source code
            if (currentState != MHParserStateScanningCommand && currentChar == kMHParserCharCommentMarker) {
                // A comment - ignore everything from here to the end of the current line, but mark characters as a comment
                codeColoringBuffer[index] |= kMHParserSyntaxColoringComment;
                index++;
                while (index < maxIndex && [_codeString characterAtIndex:index] != kMHParserCharNewline) {
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringComment | kMHParserSyntaxColoringMathMode;
                    index++;
                }
                if (index < maxIndex) {
                    // mark the newline character that terminates the comment field
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringComment | kMHParserSyntaxColoringMathMode;
                }
                if (index == maxIndex) {
                    index--;    // This makes sure we enter the loop one last time to process the end of code token
                }
                continue;   // go to the next loop iteration
            }
            
            // We now classify the character into various categories, while also applying some simple but useful substitution rules
            
            if (currentChar == kMHParserCharHyphen && currentState != MHParserStateScanningCommand) {
                // Substitutions involving hyphens
                if (index < maxIndex - 1 && [_codeString characterAtIndex:index+1] == kMHParserCharPlusSign) {
                    // a plus sign following a hyphen is substituted by a minus-plus sign
                    currentChar = kMHParserCharMinusPlusSign;
                    currentCharType = MHParserCharText;
                    currentCharSubtype = MHParserCharBinaryOperator;
                    codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                    index++;
                }
                else {  // a hyphen without a following plus sign gets turned into a minus sign
                    currentChar = kMHParserCharMinusSign;
                    currentCharType = MHParserCharText;
                    currentCharSubtype = MHParserCharBinaryOperator; // FIXME: a minus sign can also be a unary prefix operator, is there a way to decide?
                }
            }
            else if (currentChar == kMHParserCharPlusSign && index < maxIndex - 1 && currentState != MHParserStateScanningCommand
                     && [_codeString characterAtIndex:index+1] == kMHParserCharHyphen) {
                // a plus sign followed by a hyphen is substituted by a plus-minus sign
                currentChar = kMHParserCharPlusMinusSign;
                currentCharType = MHParserCharText;
                currentCharSubtype = MHParserCharBinaryOperator;
                codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                index++;
            }
            else if (currentChar == kMHParserCharLessThanSign && index < maxIndex-1 && currentState != MHParserStateScanningCommand
                     && [_codeString characterAtIndex:index+1] == kMHParserCharEqualSign) {
                // substitute a less-than-or-equal sign for a pair "<="
                currentChar = kMHParserCharLessThanOrEqualSign;
                currentCharType = MHParserCharText;
                currentCharSubtype = MHParserCharBinaryRelation;
                codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                index++;
            }
            else if (currentChar == kMHParserCharGreaterThanSign && index < maxIndex-1 && currentState != MHParserStateScanningCommand
                     && [_codeString characterAtIndex:index+1] == kMHParserCharEqualSign) {
                // substitute a greater-than-or-equal sign for a pair ">="
                currentChar = kMHParserCharGreaterThanOrEqualSign;
                currentCharType = MHParserCharText;
                currentCharSubtype = MHParserCharBinaryRelation;
                codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                index++;
            }
            // Substitute a times sign for an asterisk, center dot sign for two asterisks, and a math asterisk operator for three asterisks
            else if (currentChar == kMHParserCharAsterisk && currentState != MHParserStateScanningCommand) {
                if (index < maxIndex-1) {
                    unichar nextChar = [_codeString characterAtIndex:index+1];
                    currentCharType = MHParserCharText;
                    currentCharSubtype = MHParserCharBinaryOperator;
                    if (nextChar == kMHParserCharAsterisk) {
                        if (index<maxIndex-2 && [_codeString characterAtIndex:index+2]==kMHParserCharAsterisk) {
                            // three successive asterisks - skip the next two code characters (marking them as scanned) and substitute a centered asterisk operator
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode;
                            codeColoringBuffer[index+2] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode;
                            index += 2;
                            currentChar = kMHParserCharAsteriskOperator;
                        }
                        else {
                            // two successive asterisks - skip the next code character (marking it as scanned) and substitute a center dot
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode;
                            index++;
                            currentChar = kMHParserCharCenterDot;
                        }
                    }
                    else {  // for a single asterisk symbol, substitute a multiplication (times) symbol
                        currentChar = kMHParserCharMultiplicationSymbol;
                    }
                }
                else {  // for a single asterisk symbol, substitute a multiplication (times) symbol
                    currentCharType = MHParserCharText;
                    currentChar = kMHParserCharMultiplicationSymbol;
                }
            }
//  a different substitution scheme for asterisks I decided not to use:
//            // Substitute times signs for asterisks, unless scanning a command
//            else if (currentChar == kMHParserCharAsterisk && index < count && currentState != MHParserStateScanningCommand) {
//                currentChar = kMHParserCharMultiplicationSymbol;
//                currentCharType = MHParserCharText;
//                currentCharSubtype = MHParserCharBinaryOperator;
//            }
            else if (currentChar == kMHParserCharFraction && index < maxIndex-1 && currentState != MHParserStateScanningCommand) {
                // The fraction command is '//', so we need to peek ahead and see if the next character is also a slash
                unichar nextChar = [_codeString characterAtIndex:index+1];
                if (nextChar == kMHParserCharFraction) {    // it's a double slash shortbut - mark the character as a fraction, scanned in math mode, and skip ahead
                    currentCharType = MHParserCharFraction;
                    codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                    index++;        // skip the next character
                }
                else if (nextChar == kMHParserCharEqualSign) {
                    // substitute a not-equal sign for a '/=' pair
                    currentChar = kMHParserCharNotEqualSign;
                    currentCharType = MHParserCharText;
                    currentCharSubtype = MHParserCharBinaryRelation;
                    codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                    index++;
                }
                else {
                    currentCharType = MHParserCharText;
                    currentCharSubtype  = MHParserCharBinaryOperator;
                }
            }
            else if (currentChar == kMHParserCharPeriod && currentState != MHParserStateScanningCommand) {
                if (index == maxIndex - 1) {
                    // a period as the last character - mark it as punctuation
                    currentCharSubtype = MHParserCharPunctuation;
                    currentCharType = MHParserCharText;
                }
                else {
                    currentCharType = MHParserCharText;
                    unichar nextChar = [_codeString characterAtIndex:index+1];
                    unichar characterAfterNext = (index == maxIndex - 2 ? 0x00 : [_codeString characterAtIndex:index+2]);
                    if (nextChar == kMHParserCharPeriod && characterAfterNext == kMHParserCharPeriod) {
                        // three successive periods get turned into an ellipsis character  // FIXME: add this in text mode as well?
                        currentChar = kMHParserCharEllipsis;
                        currentCharSubtype = MHParserCharPunctuation;
                        codeColoringBuffer[index+1] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                        codeColoringBuffer[index+2] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                        index += 2;
                    }
                    else {
                        // Just a regular period rather than an ellipsis substitution
                        // In this case we classify the period as either a decimal point or punctuation depending on the context
                        if (currentState == MHParserStateScanningWord
                            && currentWordTypographyClass == MHTypographyClassNumber
                            && !scannedDecimalPointWhenScanningNumber
                            && UnicharIsNumeral(nextChar)) {
                            // we are scanning a number but haven't yet encountered a decimal point, and the next character is a numeral, so classify the period as a decimal point and remember that we scanned it
                            currentCharSubtype = MHParserCharNumeralOrDecimalPoint;
                            scannedDecimalPointWhenScanningNumber = true;
                        }
                        else {
                            // not the decimal point scenario - classify the period as punctuation
                            currentCharSubtype = MHParserCharPunctuation;
                        }
                    }
                }
            }
            else if (currentChar == kMHParserCharSpace || currentChar == kMHParserCharNewline || currentChar == kMHParserCharTab) {
                // FIXME: newline is temporarily classified as space
                currentCharType = MHParserCharSpace;
            }
            else if (currentChar == kMHParserCharOpenBlock)
                currentCharType = MHParserCharOpenBlock;
            else if (currentChar == kMHParserCharCloseBlock)
                currentCharType = MHParserCharCloseBlock;
            else if (currentChar == kMHParserCharSubscript)
                currentCharType = MHParserCharSubscript;
            else if (currentChar == kMHParserCharSuperscript)
                currentCharType = MHParserCharSuperscript;
            else if (currentChar == kMHParserCharStartCommand)
                currentCharType = MHParserCharStartCommand;
            else if (currentChar == kMHParserCharListDelimiter) {
                currentCharType = MHParserCharListDelimiter;
                currentDelimiterType = MHListDelimiterTypePrimary;
            }
            else if (currentChar == kMHParserCharSecondaryListDelimiter) {
                currentCharType = MHParserCharListDelimiter;
                currentDelimiterType = MHListDelimiterTypeSecondary;
            }
            else if (currentChar == kMHParserCharDerivative) {
                // We encountered a derivative (prime) symbol, this is handled in a special way to get the correct typography
                
                // count the number of prime symbols
                numberOfDerivativeSymbols = 1;
                NSUInteger derivativeScanningIndex = index+1;
                while (derivativeScanningIndex < maxIndex && [_codeString characterAtIndex:derivativeScanningIndex] == kMHParserCharDerivative) {
                    // mark the character as scanned in math mode
                    codeColoringBuffer[derivativeScanningIndex] |= (char)(kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode);
                    
                    // advance the counters
                    derivativeScanningIndex++;
                    numberOfDerivativeSymbols++;
                }
                index = derivativeScanningIndex-1;    // in the next main loop iteration, start from the character that follows the primes
                
                currentCharType = MHParserCharDerivative;
            }
            else if (currentChar == kMHParserTextShiftFirstChar
                     && index < maxIndex-1
                     && [_codeString characterAtIndex:index+1] == kMHParserTextShiftSecondChar) {
                // A text shift pair of characters
                currentCharType = MHParserCharModeSwitch;
                codeColoringBuffer[index] |= kMHParserSyntaxColoringModeSwitch;
                codeColoringBuffer[index+1] |=
                kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode | kMHParserSyntaxColoringModeSwitch;
                index++;
            }
            else if (currentChar == kMHParserCharAttributesSymbol) {
                if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock)
                    currentCharType = MHParserCharAttributes;
                else
                    currentCharType = MHParserCharIgnore;
            }
            else if (currentChar == kMHParserCharAssignment)
                currentCharType = MHParserCharAssignment;
            else if (currentChar == kMHParserCharOpenCodeAnnotationBlock) {
                currentCharType = MHParserCharOpenCodeAnnotationBlock;
            }
            else {
                currentCharType = MHParserCharText;
                // In math parsing mode we categorize text characters into several subtypes:
                NSString *currentCharString = [NSString stringWithFormat:@"%C", currentChar];
                if ([kMHParserCharsBinaryOperator containsString:currentCharString])
                    currentCharSubtype = MHParserCharBinaryOperator;
                else if ([kMHParserCharsBinaryRelation containsString:currentCharString])
                    currentCharSubtype = MHParserCharBinaryRelation;
                else if ([kMHParserCharsUnaryPrefixOperator containsString:currentCharString])
                    currentCharSubtype = MHParserCharUnaryPrefixOperator;   // FIXME: this will never be executed
                else if ([kMHParserCharsUnaryPostfixOperator containsString:currentCharString])
                    currentCharSubtype = MHParserCharUnaryPostfixOperator;
                else if (UnicharIsNumeral(currentChar))
                    currentCharSubtype = MHParserCharNumeralOrDecimalPoint;
                else if ([kMHParserCharsLeftBracket containsString:currentCharString]) {
                    currentCharSubtype = MHParserCharLeftBracket;
                    if (currentChar == kMHParserBracketCharLeftParenthesis)
                        bracketType = MHBracketTypeParenthesis;
                    else if (currentChar == kMHParserBracketCharLeftSquareBrace)
                        bracketType = MHBracketTypeSquareBrace;
                    else if (currentChar == kMHParserBracketCharLeftCurlyBrace)
                        bracketType = MHBracketTypeCurlyBrace;
                }
                else if ([kMHParserCharsRightBracket containsString:currentCharString]) {
                    currentCharSubtype = MHParserCharRightBracket;
                    if (currentChar == kMHParserBracketCharRightParenthesis)
                        bracketType = MHBracketTypeParenthesis;
                    else if (currentChar == kMHParserBracketCharRightSquareBrace)
                        bracketType = MHBracketTypeSquareBrace;
                    else if (currentChar == kMHParserBracketCharRightCurlyBrace)
                        bracketType = MHBracketTypeCurlyBrace;
                }
                else if ([kMHParserCharsDirectionallyAmbiguousBracket containsString:currentCharString]) {
                    currentCharSubtype = MHParserCharDirectionallyAbmbiguousBracket;
                    if (currentChar == kMHParserBracketCharAbsoluteValue) {
                        // Two successive absolute value symbols get treated like a norm (double vertical bar) character
                        if (index < maxIndex - 1 && [_codeString characterAtIndex:index+1] == kMHParserBracketCharAbsoluteValue) {
                            bracketType = MHBracketTypeDoubleVerticalBar;
                            index++;
                            codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode;
                        }
                        else    // no substitution
                            bracketType = MHBracketTypeVerticalBar;
                    }
                    else if (currentChar == kMHParserBracketCharNorm)   // the usual unicode double vertical bar also maps to a norm bracket
                        bracketType = MHBracketTypeDoubleVerticalBar;
                }
                else if ([kMHParserCharsPunctuation containsString:currentCharString])
                    currentCharSubtype = MHParserCharPunctuation;
                else
                    currentCharSubtype = MHParserCharVarText;   // redundant since I already initialized to that value earlier, but this is clearer
            }
        }
        
        switch (currentState) {
#pragma mark - MHParserStateScanningWord
            case MHParserStateScanningWord:
                switch (currentCharType) {
                    case MHParserCharSpace: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        
//                        [currentContainer addSubexpression:[MHWhitespace spaceWithType:MHHorizontalSpaceLogical]];    // disabling this since I implemented implicit multiplication in math formulas in the MHMathFormulaParser class. Probably this can safely be deleted
                        
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharText:
                        switch (currentCharSubtype) {
                            case MHParserCharUnaryPrefixOperator: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *unaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassUnaryPrefixOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, unaryOperatorText);
                                [currentContainer addSubexpression:unaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharUnaryPostfixOperator: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *unaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassUnaryPostfixOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, unaryOperatorText);
                                [currentContainer addSubexpression:unaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharBinaryOperator: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *binaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassBinaryOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, binaryOperatorText);
                                [currentContainer addSubexpression:binaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharBinaryRelation: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *binaryRelationText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassBinaryRelation];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, binaryRelationText);
                                [currentContainer addSubexpression:binaryRelationText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharNumeralOrDecimalPoint:
                                if (currentWordTypographyClass == MHTypographyClassNumber) {
                                    [currentWord appendFormat:@"%C", currentChar];
                                    currentWordIsDifferential = false;
                                    currentState = MHParserStateScanningWord;
                                }
                                else if (currentWordTypographyClass == MHTypographyClassRomanMathVariable
                                         || currentWordTypographyClass == MHTypographyClassItalicMathVariable) {
                                    endOfSemanticUnitIndex = index - 1;
                                    MHExpression *mathAtom;
                                    MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                    MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                    [currentContainer addSubexpression:mathAtom];
                                    
//                                    [currentContainer addSubexpression:[MHWhitespace spaceWithType:MHHorizontalSpaceLogical]];  // disabling this since I implemented implicit multiplication in math formulas in the MHMathFormulaParser class. Probably this can safely be deleted
                                    
                                    currentWord = [NSMutableString stringWithCapacity:0];
                                    [currentWord appendFormat:@"%C", currentChar];
                                    currentWordTypographyClass = MHTypographyClassNumber;
                                    scannedDecimalPointWhenScanningNumber = false;
                                    currentWordIsDifferential = false;
                                    currentState = MHParserStateScanningWord;
                                    beginningOfSemanticUnitIndex = index;
                                }
                                break;
                            case MHParserCharLeftBracket: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]];
//                                bracketText.typographyClass = MHTypographyClassLeftBracket;

                                // ***commenting out to experiment with adjustable height symbols***
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
//                                                           typographyClass:MHTypographyClassLeftBracket];
//                                [currentContainer addSubexpression:bracketText];
                                
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketLeftOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                                [currentContainer addSubexpression:bracketSymbol];

                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharRightBracket: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]];
//                                bracketText.typographyClass = MHTypographyClassRightBracket;

                                // ***commenting out to experiment with adjustable height symbols***
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
//                                                           typographyClass:MHTypographyClassRightBracket];
//                                [currentContainer addSubexpression:bracketText];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketRightOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                                [currentContainer addSubexpression:bracketSymbol];

                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharDirectionallyAbmbiguousBracket: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketDynamicallyDeterminedOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                                [currentContainer addSubexpression:bracketSymbol];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharPunctuation: {
                                endOfSemanticUnitIndex = index - 1;
                                MHExpression *mathAtom;
                                MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                [currentContainer addSubexpression:mathAtom];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *punctuationText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
                                                               typographyClass:MHTypographyClassPunctuation];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, punctuationText);
                                [currentContainer addSubexpression:punctuationText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharVarText:
                                if (currentWordTypographyClass == MHTypographyClassNumber) {
                                    endOfSemanticUnitIndex = index - 1;
                                    MHExpression *mathAtom;
                                    MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                                    MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                                    [currentContainer addSubexpression:mathAtom];
                                    
//                                    [currentContainer addSubexpression:[MHWhitespace spaceWithType:MHHorizontalSpaceLogical]];  // disabling this since I implemented implicit multiplication in math formulas in the MHMathFormulaParser class. Probably this can safely be deleted
                                    
                                    beginningOfSemanticUnitIndex = index;
                                    endOfSemanticUnitIndex = index;
                                    currentWord = [NSMutableString stringWithCapacity:0];
                                    [currentWord appendFormat:@"%C", currentChar];
                                    currentWordTypographyClass = MHTypographyClassItalicMathVariable;
                                    currentWordIsDifferential = false;
                                    currentState = MHParserStateScanningWord;
                                    beginningOfSemanticUnitIndex = index;
                                }
                                else if (currentWordTypographyClass == MHTypographyClassItalicMathVariable
                                         || currentWordTypographyClass == MHTypographyClassRomanMathVariable) {
                                    [currentWord appendFormat:@"%C", currentChar];
                                    currentState = MHParserStateScanningWord;
                                    if (currentWord.length == 2 && [currentWord characterAtIndex:0] == 'd') {
                                        // This is a differential so should be typeset in italic
                                        currentWordTypographyClass = MHTypographyClassItalicMathVariable;
                                        currentWordIsDifferential = true;
                                    }
                                    else {
                                        // Otherwise, a multi-letter word like "sin", "cos", "det" etc, is set in the roman math font
                                        currentWordTypographyClass = MHTypographyClassRomanMathVariable;
                                        currentWordIsDifferential = false;
                                    }
                                }
                                break;
                        }
                        break;
                    case MHParserCharOpenBlock: {       // lightly modified from text parsing code to specify typography class of added word
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);

                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        [currentContainer addSubexpression:newBlock];   // ***need to mark this as a semantic unit eventually***
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharCloseBlock: {        // lightly modified from text parsing code to specify typography class of added word
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];

                        MHExpression *currentContainerParent = currentContainer.parent;
                        if (currentContainerParent) {
                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
                                NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
                                bool resolved;
                                MHExpression *resolvedCommand =
                                [_packageManager expressionForCommandString:commandString
                                                            commandArgument:justClosedContainer
                                         allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                                       resolvedSuccessfully:&resolved];
                                if (resolved) {
                                    // Go back and change the syntax coloring info to mark the command as resolved
                                    NSRange commandRange = currentContainerParent.codeRange;
                                    NSUInteger anIndex;
                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                                    }
                                    resolvedCommand.codeRange = commandRange;
                                }
                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];

//                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent);   // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                            withExpression:resolvedCommand]; // ***need to mark this as a semantic unit eventually***
                                
                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
                                
                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
                                if (resolvedCommandAttachments) {
                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
                                }
                                
                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal) {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                                withExpression:resolvedCommand];

                                    // If the command is an attributes command, add the attributes dictionary to the container
                                    if ([resolvedCommand isKindOfClass:[MHAttributesCommand class]]) {
                                        currentContainer.attributes = [(MHAttributesCommand *)resolvedCommand attributesDictionary];
                                        
                                        // also reset the code coloring info to an attributes symbol
                                        // FIXME: bad design to do it after already setting it to a command symbol, improve
                                        codeColoringBuffer[currentContainerParent.codeRange.location] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[currentContainerParent.codeRange.location] |= kMHParserSyntaxColoringAttributesSymbol;
                                    }
                                }
                                else {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    
                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];

                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
                                    // FIXME: this works but seems confusing and illogical - improve
                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
                                    // future once I have a better understanding of what attached content can be used for.
                                    if (!resolvedCommandAttachments) {
                                        [attachedContentExpressions addObject:resolvedCommand];
                                    }
                                }
                                
                            }
                            else if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]
                                     || [currentContainerParent isKindOfClass:[MHFraction class]]) {
//                                     || [currentContainerParent conformsToProtocol:@protocol(MHCommand)]) {
                                // FIXME: the test for "[currentContainer conformsToProtocol:@protocol(MHCommand)]" does nothing and can be safely removed, no?
                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                            else {
                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                NSLog(@"currentcontainer=%@, lastexpression=%@",[currentContainer class], [currentContainer.lastExpression class]);
                            }
                        }
                        else {
                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
                            index--;
                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
                        }
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharSubscript: {       // lightly modified from text parsing code to specify typography class of added word
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:mathAtom
                                                                    subscript:[MHHorizontalLayoutContainer expression]
                                                                    superscript:[MHHorizontalLayoutContainer expression]];
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExpression.subscript); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, seems to work but it's bad coding practice
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharSuperscript: {     // lightly modified from text parsing code to specify typography class of added word
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:mathAtom
                                                                    subscript:[MHHorizontalLayoutContainer expression]
                                                                    superscript:[MHHorizontalLayoutContainer expression]];
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExpression.superscript); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, seems to work but it's bad coding practice
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharDerivative: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        NSString *derivativesString = [@"" stringByPaddingToLength:numberOfDerivativeSymbols
                                                                        withString:[NSString stringWithFormat:@"%C", kMHParserCharPrimeSymbol]
                                                                   startingAtIndex:0];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        
                        // FIXME: in the next line, using the punctuation typography class is conceptually incorrect, doing it temporarily since that gives the best kerning result, but a more robust and conceptually appropriate solution should be implemented
                        MHMathAtom *derivativesAtom = [MHMathAtom mathAtomWithString:derivativesString
                                                                 typographyClass:MHTypographyClassPunctuation];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, derivativesAtom);
                        
                        // disabling an older method of adding the derivative(s) symbol as a superscript
                        // this was conceptually more elegant and would potentially be useful if I wanted
                        // to add features for parsing the expression and understanding that it represents
                        // a derivative symbolically, but it didn't typeset correctly
//                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
//                                                                    scriptedExpressionWithBody:mathAtom
//                                                                    subscript:[MHHorizontalLayoutContainer expression]
//                                                                    superscript:derivativesAtom];
//                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        
                        // instead, I'm just adding the math atom and then the derivatives atom to the current container. This typesets correctly but may be hard to make sense of from the point of view of parsing -- consider improving at some point
                        [currentContainer addSubexpression:mathAtom];
                        [currentContainer addSubexpression:derivativesAtom];
                        
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharFraction: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        MHHorizontalLayoutContainer *fractionDenominator = [MHHorizontalLayoutContainer expression];
                        MHFraction *fraction = [MHFraction fractionWithNumerator:mathAtom
                                                                                           denominator:fractionDenominator];
                        [currentContainer addSubexpression:fraction]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = fractionDenominator;
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharStartCommand:
                    case MHParserCharAttributes: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        currentCommand = [NSMutableString stringWithCapacity:0];

                        // If the character is an attributes symbol, treat it like we're starting a commmand and append the attributes character to the name
                        // FIXME: this way of implementing the attributes feature is not very good design as it mixes it with another language feature in a way that's difficult to understand - improve
                        if (currentCharType == MHParserCharAttributes)
                            [currentCommand appendString:kMHParserCharAttributesString];

                        currentState = MHParserStateScanningCommand;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        beginningOfSemanticUnitIndex = index;
                    }
                        break;
                    case MHParserCharListDelimiter: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        [currentContainer addListDelimiterWithType:currentDelimiterType]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringListDelimiter;
                    }
                        break;
                    case MHParserCharAssignment: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        MHExpression *assignmentExpression = [MHTextAtom textAtomWithString:kMHParserCharAssignmentString];
                        [currentContainer addSubexpression:assignmentExpression]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringAssignment;
                    }
                        break;
                    case MHParserCharEndOfCode: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                    }
                        break;
                        
                    case MHParserCharModeSwitch: {
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];
                        if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock) {
                            NSRange textScannedRange;
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock
                                                            | kMHParserSyntaxColoringMathMode;
                            MHExpression *textExpression = [self parseTextModeCodeInRange:NSMakeRange(index+2, maxIndex - index - 2)
                                                                     actuallyScannedRange:&textScannedRange
                                                            rootContainer:nil];
                            [currentContainer addSubexpression:textExpression]; // ***need to mark this as a semantic unit eventually***
                            
                            index = textScannedRange.location + textScannedRange.length + 1;

                            // upon exiting the text parser, usually there will be a block close character. If so, mark it appropriately and skip to the next
                            if (index < maxIndex) {
                                unichar textModeExitChar = [_codeString characterAtIndex:index];
                                if (textModeExitChar == kMHParserCharCloseBlock) {
                                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock
                                                                    | kMHParserSyntaxColoringMathMode;
                                }
                            }
                        }
                        else {
                            // If the text shift control string is not followed by an open block character, we ignore it, and mark the two characters as not scanned as a subtle cue to the user
                            codeColoringBuffer[index] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                            codeColoringBuffer[index-1] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                        }
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharOpenCodeAnnotationBlock: {
                        // A code annotation block
                        endOfSemanticUnitIndex = index - 1;
                        MHExpression *mathAtom;
                        MakeExpressionAndMarkSyntaxColoringForCurrentWord(mathAtom);
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        [currentContainer addSubexpression:mathAtom];

                        // We will search for a string with the close annotation character
                        NSString *closeCodeAnnotationBlockString = [NSString stringWithFormat:@"%C", kMHParserCharCloseCodeAnnotationBlock];

                        NSRange closeCodeAnnotationBlockRange = [_codeString rangeOfString:closeCodeAnnotationBlockString
                                                                              options:NSLiteralSearch
                                                                                range:NSMakeRange(index+1, maxIndex-index-1)];

                        // The code annotation block is everything between where we are now and this marker, or to the end of the allowed range if the marker is not found
                        bool closeMarkerFound = closeCodeAnnotationBlockRange.location != NSNotFound;
                        NSRange rangeOfCodeAnnotationBlock = NSMakeRange(index+1,
                                                                     (closeMarkerFound ? closeCodeAnnotationBlockRange.location-index-1 : maxIndex-index-1));
                        
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringCodeAnnotationBlock;
                        for (NSUInteger j = rangeOfCodeAnnotationBlock.location; j < rangeOfCodeAnnotationBlock.location+rangeOfCodeAnnotationBlock.length; j++) {
                            codeColoringBuffer[j] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode | kMHParserSyntaxColoringCodeAnnotationBlock;
                        }
                        if (closeMarkerFound) {
                            codeColoringBuffer[closeCodeAnnotationBlockRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode | kMHParserSyntaxColoringCodeAnnotationBlock;
                        }
                        index += rangeOfCodeAnnotationBlock.length+1;
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    default:
                        codeColoringBuffer[index] &= kMHParserSyntaxColoringNotScanned;  // forget the color code classification and that the character was scanned
                        break;
                }
                break;
#pragma mark - MHParserStateScanningCommand
            case MHParserStateScanningCommand:
                if (currentChar == kMHParserCharQuickCloseCommand) {
                    endOfSemanticUnitIndex = index;
                    bool resolved;
                    MHExpression *command =
                    [_packageManager expressionForCommandString:currentCommand
                                                commandArgument:nil
                             allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                           resolvedSuccessfully:&resolved];
                    if (resolved) {
                        // Go back and change the syntax coloring info to mark the command as unresolved
                        NSUInteger anIndex;
                        for (anIndex = index - currentCommand.length - 1; anIndex < index; anIndex++) {
                            codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                            codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                        }
                    }

                    MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, command);
                    
                    MHLayoutType commandLayoutPreference = command.layoutPreference;
                    NSArray <MHExpression *> *commandAttachments = command.attachedContent;
                    if (commandAttachments) {
                        [attachedContentExpressions addObjectsFromArray:commandAttachments];
                    }
                    
                    if (commandLayoutPreference == MHLayoutHorizontal) {
                        [currentContainer addSubexpression:command];
                    }
                    else {  // vertical layout - add as attached content unless the command has its own attached content in which case that content is added to the global attached content and the command itself is discarded
                        if (!commandAttachments) {
                            [attachedContentExpressions addObject:command];
                        }
                    }
                    
                    currentState = MHParserStateGeneric;
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                }
                else switch (currentCharType) {
//                    case MHParserCharSpace:
//                        break;
//                    case MHParserCharText:
//                        break;
                    case MHParserCharOpenBlock: {   // code copied from MHTextParser to add alternate mode functionality
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        MHPlaceholderCommand *command = (MHPlaceholderCommand *)[MHPlaceholderCommand commandNamed:currentCommand
                                                                                                    withParameters:nil
                                                                                                          argument:newBlock];
                        command.codeRange = NSMakeRange(beginningOfSemanticUnitIndex, index-beginningOfSemanticUnitIndex);    // mark the code range for later use in the MHParserMarkSemanticUnit macro and for syntax coloring
                        [currentContainer addSubexpression:command]; // FIXME: need to mark this as a semantic unit
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                    }
                        break;
//                    case MHParserCharCloseBlock:
//                        break;
//                    case MHParserCharSubscript:
//                        break;
//                    case MHParserCharSuperscript:
//                        break;
//                    case MHParserCharFraction:
//                        break;
//                    case MHParserCharStartCommand:
//                        break;
//                    case MHParserCharModeSwitch:
//                    break;
                    case MHParserCharEndOfCode:
                        // reached end of code - no character to add to the command name
                        break;
                    default:
                        [currentCommand appendFormat:@"%C", currentChar];
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        break;
                }
                break;
#pragma mark - MHParserStateScanningQuickExpression
            case MHParserStateScanningQuickExpression:
                if (currentCharType == MHParserCharOpenBlock || currentCharType == MHParserCharEndOfCode) {
                    currentState = MHParserStateGeneric;
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                }
                else {
                    MHTypographyClass typographyClass;
                    switch(currentCharSubtype) {
                        case MHParserCharUnaryPrefixOperator:
                            typographyClass = MHTypographyClassUnaryPrefixOperator;
                            break;
                        case MHParserCharUnaryPostfixOperator:
                            typographyClass = MHTypographyClassUnaryPostfixOperator;
                            break;
                        case MHParserCharBinaryOperator:
                            typographyClass = MHTypographyClassBinaryOperator;
                            break;
                        case MHParserCharBinaryRelation:
                            typographyClass = MHTypographyClassBinaryRelation;
                            break;
                        case MHParserCharNumeralOrDecimalPoint:
                            typographyClass = MHTypographyClassNumber;
                            break;
                        case MHParserCharLeftBracket:
                            typographyClass = MHTypographyClassLeftBracket;
                            break;
                        case MHParserCharRightBracket:
                            typographyClass = MHTypographyClassRightBracket;
                            break;
                        case MHParserCharDirectionallyAbmbiguousBracket:
                            typographyClass = MHTypographyClassUnknown;
                            break;
                        case MHParserCharPunctuation:
                            typographyClass = MHTypographyClassPunctuation;
                            break;
                        case MHParserCharVarText:
                            typographyClass = MHTypographyClassItalicMathVariable;
                            break;
                    }
                    MHExpression *mathAtom = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C",currentChar] typographyClass:typographyClass];
                    
                    MHExpression *currentContainerParent = currentContainer.parent;
                    if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
                        MHScriptedExpression *scriptedExp = (MHScriptedExpression *)currentContainerParent;
                        bool isSubscript = [currentContainer isEqualTo:scriptedExp.subscript];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        if (isSubscript) {
                            scriptedExp.subscript = mathAtom;
                        }
                        else {
                            scriptedExp.superscript = mathAtom;
                        }
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExp.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                    }
                    else if ([currentContainerParent isKindOfClass:[MHFraction class]]) {
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, mathAtom);
                        MHFraction *fraction = ((MHFraction *)(currentContainer.parent));
                        fraction.denominator = mathAtom;
                        currentContainer = (MHHorizontalLayoutContainer *)(fraction.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                        NSLog(@"currentcontainer=%@, lastexpression=%@",[currentContainer class], [currentContainer.lastExpression class]);
                    }
                    else
                        NSLog(@"error: expecting currentNode parent to be a MHScriptedExpression or a MHFraction. parent=%@",currentContainerParent);
                    currentState = MHParserStateGeneric;
                }
                break;
#pragma mark - MHParserStateGeneric
                //
                //  I revised this section to adapt it from the text parsing code I started with
                //
            case MHParserStateGeneric:
                switch (currentCharType) {
                    case MHParserCharSpace:
                        
//                        [currentContainer addSubexpression:[MHWhitespace spaceWithType:MHHorizontalSpaceLogical]];  // disabling this since I implemented implicit multiplication in math formulas in the MHMathFormulaParser class. Probably this can safely be deleted
                        
                        currentState = MHParserStateGeneric;
                        break;
                    case MHParserCharText:      // this is modified from the text parsing code
                        switch (currentCharSubtype) {
                            case MHParserCharUnaryPrefixOperator: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *unaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassUnaryPrefixOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, unaryOperatorText);
                                [currentContainer addSubexpression:unaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharUnaryPostfixOperator: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *unaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassUnaryPostfixOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, unaryOperatorText);
                                [currentContainer addSubexpression:unaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharBinaryOperator: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *binaryOperatorText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassBinaryOperator];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, binaryOperatorText);
                                [currentContainer addSubexpression:binaryOperatorText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharBinaryRelation: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *binaryRelationText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar] typographyClass:MHTypographyClassBinaryRelation];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, binaryRelationText);
                                [currentContainer addSubexpression:binaryRelationText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharNumeralOrDecimalPoint:
                                currentWord = [NSMutableString stringWithCapacity:0];
                                [currentWord appendFormat:@"%C", currentChar];
                                currentWordTypographyClass = MHTypographyClassNumber;
                                scannedDecimalPointWhenScanningNumber = false;
                                currentWordIsDifferential = false;
                                currentState = MHParserStateScanningWord;
                                beginningOfSemanticUnitIndex = index;
                                break;
                            case MHParserCharLeftBracket: {
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]];
//                                bracketText.typographyClass = MHTypographyClassLeftBracket;
                                
                                // ***commenting out to experiment with adjustable height symbols***
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
//                                                           typographyClass:MHTypographyClassLeftBracket];
//                                [currentContainer addSubexpression:bracketText];
                                
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketLeftOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                               [currentContainer addSubexpression:bracketSymbol];
                                
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharRightBracket: {
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]];
//                                bracketText.typographyClass = MHTypographyClassRightBracket;

                                // ***commenting out to experiment with adjustable height symbols***
//                                MHMathAtom *bracketText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
//                                                           typographyClass:MHTypographyClassRightBracket];
//                                [currentContainer addSubexpression:bracketText];

                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketRightOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                                [currentContainer addSubexpression:bracketSymbol];

                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharDirectionallyAbmbiguousBracket: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHBracket *bracketSymbol = [MHBracket bracketWithType:bracketType
                                                                                              orientation:MHBracketDynamicallyDeterminedOrientation
                                                                                                  variant:MHBracketDynamicallyDeterminedSize];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, bracketSymbol);
                                [currentContainer addSubexpression:bracketSymbol];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharPunctuation: {
                                beginningOfSemanticUnitIndex = index;
                                endOfSemanticUnitIndex = index;
                                MHMathAtom *punctuationText = [MHMathAtom mathAtomWithString:[NSString stringWithFormat:@"%C", currentChar]
                                                               typographyClass:MHTypographyClassPunctuation];
                                MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, punctuationText);
                                [currentContainer addSubexpression:punctuationText];
                                currentState = MHParserStateGeneric;
                            }
                                break;
                            case MHParserCharVarText:
                                currentWord = [NSMutableString stringWithCapacity:0];
                                [currentWord appendFormat:@"%C", currentChar];
                                currentWordTypographyClass = MHTypographyClassItalicMathVariable;
                                currentWordIsDifferential = false;
                                currentState = MHParserStateScanningWord;
                                beginningOfSemanticUnitIndex = index;
                                break;
                        }
                        break;
                    case MHParserCharOpenBlock: {       // copied from text parsing - good? not sure but trying for now
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        [currentContainer addSubexpression:newBlock]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharCloseBlock: {
                        MHExpression *currentContainerParent = currentContainer.parent;
                        if (currentContainerParent) {      // copied from text parsing, still good I think
                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
                                NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
                                bool resolved;
                                MHExpression *resolvedCommand =
                                [_packageManager expressionForCommandString:commandString
                                                            commandArgument:justClosedContainer
                                         allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                                       resolvedSuccessfully:&resolved];
                                if (resolved) {
                                    // Go back and change the syntax coloring info to mark the command as resolved
                                    NSRange commandRange = currentContainerParent.codeRange;
                                    NSUInteger anIndex;
                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                                    }
                                    resolvedCommand.codeRange = commandRange;
                                }
                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];

//                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                            withExpression:resolvedCommand];
                                
                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
                                
                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
                                if (resolvedCommandAttachments) {
                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
                                }
                                
                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal) {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                                withExpression:resolvedCommand];

                                    // If the command is an attributes command, add the attributes dictionary to the container
                                    if ([resolvedCommand isKindOfClass:[MHAttributesCommand class]]) {
                                        currentContainer.attributes = [(MHAttributesCommand *)resolvedCommand attributesDictionary];
                                        
                                        // also reset the code coloring info to an attributes symbol
                                        // FIXME: bad design to do it after already setting it to a command symbol, improve
                                        codeColoringBuffer[currentContainerParent.codeRange.location] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[currentContainerParent.codeRange.location] |= kMHParserSyntaxColoringAttributesSymbol;
                                    }
                                }
                                else {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    
                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];

                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
                                    // FIXME: this works but seems confusing and illogical - improve
                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
                                    // future once I have a better understanding of what attached content can be used for.
                                    if (!resolvedCommandAttachments) {
                                        [attachedContentExpressions addObject:resolvedCommand];
                                    }
                                }
                                
                            }
                            else if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]
                                     || [currentContainerParent isKindOfClass:[MHFraction class]]) {
//                                     || [currentContainerParent conformsToProtocol:@protocol(MHCommand)]) {
                                // FIXME: the test for "[currentContainer conformsToProtocol:@protocol(MHCommand)]" does nothing and can be safely removed, no?
                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                            else {
                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                        }
                        else {
                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
                            index--;
                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop

                            
                            
//                            // the block close character is exiting math mode so is not classified as a math mode characetr
//                            codeColoringBuffer[index] &= kMHParserSyntaxColoringBitMask-kMHParserSyntaxColoringMathMode;
//
//                            codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
//                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
                        }
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharSubscript: {           // copied from text parsing, still good I think
                        // Check if the last expression added was already scripted
                        MHExpression *lastExpressionAdded = nil;
                        if (currentContainer.numberOfSubexpressions > 0)
                            lastExpressionAdded = [currentContainer lastExpression];
                        if (lastExpressionAdded && [lastExpressionAdded isKindOfClass:[MHScriptedExpression class]]) {
                            MHHorizontalLayoutContainer *subscript = [MHHorizontalLayoutContainer expression];
                            ((MHScriptedExpression *)lastExpressionAdded).subscript = subscript;
                            currentContainer = subscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                        else {
                            MHHorizontalLayoutContainer *subscript = [MHHorizontalLayoutContainer expression];
                            MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                        scriptedExpressionWithBody:
                                                                        (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression])
                                                                        subscript:subscript
                                                                        superscript:[MHHorizontalLayoutContainer expression]];
                            if (lastExpressionAdded)
                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                            withExpression:scriptedExpression];
                            else
                                [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                            currentContainer = subscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                    }
                        break;
                    case MHParserCharSuperscript: {         // copied from text parsing, still good I think
                        // Check if the last expression added was already scripted
                        MHExpression *lastExpressionAdded = nil;
                        if (currentContainer.numberOfSubexpressions > 0)
                            lastExpressionAdded = [currentContainer lastExpression];
                        if (lastExpressionAdded && [lastExpressionAdded isKindOfClass:[MHScriptedExpression class]]) {
                            MHHorizontalLayoutContainer *superscript = [MHHorizontalLayoutContainer expression];
                            ((MHScriptedExpression *)lastExpressionAdded).superscript = superscript;
                            currentContainer = superscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                        else {
                            MHHorizontalLayoutContainer *superscript = [MHHorizontalLayoutContainer expression];
                            MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                        scriptedExpressionWithBody:
                                                                        (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression])
                                                                        subscript:[MHHorizontalLayoutContainer expression]
                                                                        superscript:superscript];
                            if (lastExpressionAdded)
                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                            withExpression:scriptedExpression];
                            else
                                [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                            currentContainer = superscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                    }
                        break;
                    case MHParserCharDerivative: {
                        NSString *derivativesString = [@"" stringByPaddingToLength:numberOfDerivativeSymbols
                                                                        withString:[NSString stringWithFormat:@"%C", kMHParserCharPrimeSymbol]
                                                                   startingAtIndex:0];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;

                        // FIXME: in the next line, using the punctuation typography class is conceptually incorrect, doing it temporarily since that gives the best kerning result, but a more robust and conceptually appropriate solution should be implemented
                        MHMathAtom *derivativesAtom = [MHMathAtom mathAtomWithString:derivativesString
                                                                 typographyClass:MHTypographyClassPunctuation];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, derivativesAtom);
                        [currentContainer addSubexpression:derivativesAtom];
                        currentState = MHParserStateGeneric;
                        
                        
                        // disabling an older method of adding the derivative(s) symbol as a superscript
                        // this was conceptually more elegant and would potentially be useful if I wanted
                        // to add features for parsing the expression and understanding that it represents
                        // a derivative symbolically, but it didn't typeset correctly
                        
                        // Prepare the primes text expression to add as a superscript
//                        NSString *derivativesString = [@"" stringByPaddingToLength:numberOfDerivativeSymbols
//                                                                        withString:[NSString stringWithFormat:@"%C", kMHParserCharPrimeSymbol]
//                                                                   startingAtIndex:0];
//                        MHMathAtom *derivativesAtom = [MHMathAtom mathAtomWithString:derivativesString
//                                                                 typographyClass:MHTypographyClassItalicMathVariable];
//                        // Check if the last expression added was already scripted
//                        MHExpression *lastExpressionAdded = nil;
//                        if (currentContainer.numberOfSubexpressions > 0)
//                            lastExpressionAdded = [currentContainer lastExpression];
//                        if (lastExpressionAdded && [lastExpressionAdded isKindOfClass:[MHScriptedExpression class]]) {
//                            ((MHScriptedExpression *)lastExpressionAdded).superscript = derivativesAtom;
//                            currentState = MHParserStateGeneric;
//                        }
//                        else {
//                            MHScriptedExpression *scriptedExpression = [MHScriptedExpression
//                                                                        scriptedExpressionWithBody:
//                                                                        (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression])
//                                                                        subscript:[MHHorizontalLayoutContainer expression]
//                                                                        superscript:derivativesAtom];
//                            if (lastExpressionAdded)
//                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                            withExpression:scriptedExpression];
//                            else
//                                [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
//                            currentState = MHParserStateGeneric;
//                        }
                    }
                        break;
                    case MHParserCharFraction: {        // copied from text parsing, still good I think
                        MHExpression *lastExpressionAdded = nil;
                        if (currentContainer.numberOfSubexpressions > 0)
                            lastExpressionAdded = [currentContainer lastExpression];
                        MHExpression *numerator = (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression]);
                        MHHorizontalLayoutContainer *fractionDenominator = [MHHorizontalLayoutContainer expression];
                        MHFraction *fraction = [MHFraction fractionWithNumerator:numerator
                                                                                           denominator:fractionDenominator];
                        if (lastExpressionAdded)
                            [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                        withExpression:fraction];
                        else
                            [currentContainer addSubexpression:fraction]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = fractionDenominator;
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharStartCommand:
                    case MHParserCharAttributes:
                        currentCommand = [NSMutableString stringWithCapacity:0];
                        
                        // If the character is an attributes symbol, treat it like we're starting a commmand and append the attributes character to the name
                        // FIXME: this way of implementing the attributes feature is not very good design as it mixes it with another language feature in a way that's difficult to understand - improve
                        if (currentCharType == MHParserCharAttributes)
                            [currentCommand appendString:kMHParserCharAttributesString];

                        currentState = MHParserStateScanningCommand;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharListDelimiter:     // copied from text parsing, still good I think
                        [currentContainer addListDelimiterWithType:currentDelimiterType];
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringListDelimiter;
                        break;
                    case MHParserCharAssignment: {
                        MHExpression *assignmentExpression = [MHTextAtom textAtomWithString:kMHParserCharAssignmentString];
                        [currentContainer addSubexpression:assignmentExpression]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringAssignment;
                    }
                        break;
                    case MHParserCharEndOfCode:         // copied from text parsing, still good I think
                        break;
                        
                    case MHParserCharModeSwitch:
                        if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock) {
                            NSRange textScannedRange;
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock
                                                            | kMHParserSyntaxColoringMathMode;
                            MHExpression *textExpression = [self parseTextModeCodeInRange:NSMakeRange(index+2, maxIndex - index - 2)
                                                                     actuallyScannedRange:&textScannedRange
                                                            rootContainer:nil];
                            [currentContainer addSubexpression:textExpression]; // ***need to mark this as a semantic unit eventually***
                            
                            index = textScannedRange.location + textScannedRange.length + 1;

                            // upon exiting the text parser, usually there will be a block close character. If so, mark it appropriately and skip to the next
                            if (index < maxIndex) {
                                unichar textModeExitChar = [_codeString characterAtIndex:index];
                                if (textModeExitChar == kMHParserCharCloseBlock) {
                                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock
                                                                    | kMHParserSyntaxColoringMathMode;
                                }
                            }
                        }
                        else {
                            // If the text shift control string is not followed by an open block character, we ignore it, and mark the two characters as not scanned as a subtle cue to the user
                            codeColoringBuffer[index] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                            codeColoringBuffer[index-1] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                        }
                        currentState = MHParserStateGeneric;
                        break;
                    case MHParserCharOpenCodeAnnotationBlock: {
                        // A code annotation block
                        // We will search for a string with the close annotation character
                        NSString *closeCodeAnnotationBlockString = [NSString stringWithFormat:@"%C", kMHParserCharCloseCodeAnnotationBlock];

                        NSRange closeCodeAnnotationBlockRange = [_codeString rangeOfString:closeCodeAnnotationBlockString
                                                                              options:NSLiteralSearch
                                                                                range:NSMakeRange(index+1, maxIndex-index-1)];

                        // The code annotation block is everything between where we are now and this marker, or to the end of the allowed range if the marker is not found
                        bool closeMarkerFound = closeCodeAnnotationBlockRange.location != NSNotFound;
                        NSRange rangeOfCodeAnnotationBlock = NSMakeRange(index+1,
                                                                     (closeMarkerFound ? closeCodeAnnotationBlockRange.location-index-1 : maxIndex-index-1));
                        
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringCodeAnnotationBlock;
                        for (NSUInteger j = rangeOfCodeAnnotationBlock.location; j < rangeOfCodeAnnotationBlock.location+rangeOfCodeAnnotationBlock.length; j++) {
                            codeColoringBuffer[j] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode | kMHParserSyntaxColoringCodeAnnotationBlock;
                        }
                        if (closeMarkerFound) {
                            codeColoringBuffer[closeCodeAnnotationBlockRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringMathMode | kMHParserSyntaxColoringCodeAnnotationBlock;
                        }
                        index += rangeOfCodeAnnotationBlock.length+1;
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    default:
                        codeColoringBuffer[index] &= kMHParserSyntaxColoringNotScanned;  // forget the color code classification and that the character was scanned
                        break;
                }
                break;
            default:
                NSLog(@"this code should never run");
                break;
        }
    }
main_loop_exit:
    *scannedRangePointer = NSMakeRange(charRange.location, index - charRange.location);
    
    // Logic for handling attached content expressions that were added during parsing: currently they are added as attached content to
    // the compiledTextExpression variable. At the moment only MHParagraph expressions implement an attachedContent property
    // so I'm adding a check if compiledTextExpression is of that class. If it's a different class the attached content
    // will be discarded
    // FIXME: improve this logic
    if (attachedContentExpressions.count > 0 &&  [compiledMathExpression isKindOfClass:[MHParagraph class]]) {
        ((MHParagraph *)compiledMathExpression).attachedContent = attachedContentExpressions;

//        for (MHExpression *attachedExpression in attachedContentExpressions) {
//            attachedExpression.parent = compiledMathExpression;
//        }
    }
    
    return compiledMathExpression;
}


@end

