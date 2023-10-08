//
//  MHParser.m
//  MadHat
//
//  Created by Dan Romik on 1/5/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHParser.h"
#import "MHParser+TextMode.h"
#import "MHParser+MathMode.h"
#import "MHTextParagraph.h"
#import "MHMathParagraph.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeEditorThemeManager.h"




const unichar kMHParserMathShiftFirstChar      = 'M';
const unichar kMHParserMathShiftSecondChar     = 0x0302;
NSString * const kMHParserMathShiftControlString = @"M\u0302\u27EA\u27EB";
NSString * const kMHParserMathParagraphControlString = @"M\u0302:";
NSString * const kMHParserMathParagraphShortcutString = @"M\u0302: ";
#define kMHParserMathParagraphControlStringLength   3

const unichar kMHParserTextShiftFirstChar      = 'T';
const unichar kMHParserTextShiftSecondChar     = 0x0302;
NSString * const kMHParserTextShiftControlString = @"T\u0302\u27EA\u27EB";

const unichar kMHParserCharCommentMarker       = 0xFF05;  // '％' (U+FFE5, full width percent sign)

const unichar kMHParserCharSpace               = ' ';
const unichar kMHParserCharTab                 = '\t';
const unichar kMHParserCharNewline             = '\n';

// DEPENDENCY ALERT: if these two definitions are changed, the string constants kMHParserMathShiftControlString and kMHParserTextShiftControlString defined above also need to be changed
const unichar kMHParserCharOpenBlock           = 0x27EA;    // '⟪'
const unichar kMHParserCharCloseBlock          = 0x27EB;    // '⟫'

const unichar kMHParserCharOpenCodeQuoteBlock  = 0x3010;    // '【'
const unichar kMHParserCharCloseCodeQuoteBlock = 0x3011;    // '】'
const unichar kMHParserCharOpenMathModeCodeQuoteBlock  = 0x3016;    // '〖'
const unichar kMHParserCharCloseMathModeCodeQuoteBlock = 0x3017;    // '〗'
const unichar kMHParserCharOpenCodeAnnotationBlock  = 0x2053;    // '⁓' (Unicode swung dash)
const unichar kMHParserCharCloseCodeAnnotationBlock = 0x2053;    // '⁓' (Unicode swung dash)
const unichar kMHParserCharCodeQuoteParagraphPrefix = '+';

const unichar kMHParserCharSubscript           = '_';
const unichar kMHParserCharSuperscript         = '^';
const unichar kMHParserCharStartCommand        = 0x2318;    // '⌘' (command symbol)
const unichar kMHParserCharQuickCloseCommand   = 0xFF0E;  // '．' (full width full stop, U+FF0E)
const unichar kMHParserCharFraction            = '/';
const unichar kMHParserCharListDelimiter       = 0xFF1B;    // '；' (full width semicolon)
const unichar kMHParserCharSecondaryListDelimiter = 0xFF03;    // '＃' (full width pound sign)
const unichar kMHParserCharDerivative          = '\'';

const unichar kMHParserCharPrimeSymbol         = 0x2032; //'′';

const unichar kMHParserCharASCIIApostrophe     = '\'';
const unichar kMHParserCharTextApostrophe     = 0x2019; // '’' symbol (unicode "right single quotation mark"). Though some people claim U+02BC is a more correct character to use for apostrophes (but I tried it and it causes strange kerning behavior)
const unichar kMHParserCharASCIIAccentGrave  = '`'; //
const unichar kMHParserCharOpeningSingleQuote  = 0x2018; // '‘' symbol (unicode "left single quotation mark").

const unichar kMHParserCharHyphen              = '-';
const unichar kMHParserCharEnDash              = 0x2013;       // an en dash

const unichar kMHParserCharASCIIQuote          = '"';          // unicode U+0022 symbol - standard double quote character on most keyboards
const unichar kMHParserCharLeftDoubleQuote     = 0x201C;       // left double quote ('“') symbol
const unichar kMHParserCharRightDoubleQuote    = 0x201D;       // left double quote ('”') symbol

const unichar kMHParserCharEmDash              = 0x2014;       // an em dash
const unichar kMHParserCharMinusSign           = 0x2212;       // a minus sign
const unichar kMHParserCharPlusSign            = '+';          // a plus sign
const unichar kMHParserCharPlusMinusSign       = 0x00B1;       // '±' (plus-minus sign)
const unichar kMHParserCharMinusPlusSign       = 0x2213;       // '∓' (minus-plus sign)

const unichar kMHParserCharLessThanSign        = '<';
const unichar kMHParserCharGreaterThanSign     = '>';
const unichar kMHParserCharEqualSign           = '=';
const unichar kMHParserCharLessThanOrEqualSign = 0x2264;       // '≤' character
const unichar kMHParserCharGreaterThanOrEqualSign = 0x2265;    // '≥' character
const unichar kMHParserCharNotEqualSign        = 0x2260;       // '≠' character

const unichar kMHParserCharAsterisk            = '*';          // a standard ASCII asterisk
const unichar kMHParserCharAsteriskOperator    = 0x2217;       // the asterisk mathematical operator symbol
const unichar kMHParserCharMultiplicationSymbol = 0x00D7;      // the multiplication or "times" symbol
const unichar kMHParserCharCenterDot           = 0x22C5;       // a center dot (bullet) symbol '·'

const unichar kMHParserCharPeriod              = '.';
const unichar kMHParserCharEllipsis            = 0x2026;       // '…' ellipsis character


// Starting a list item at the beginning of a text paragraph:

// sequence of characters for an unnumbered list item
const unichar kMHParserCharUnnumberedListItemFirstChar   = '*';
const unichar kMHParserCharUnnumberedListItemSecondChar   = ' ';

// sequence of characters for a numbered list item
const unichar kMHParserCharNumberedListItemFirstChar   = '*';
const unichar kMHParserCharNumberedListItemSecondChar   = '.';
const unichar kMHParserCharNumberedListItemThirdChar   = ' ';

// sequence of characters for a checkbox list item
const unichar kMHParserCharCheckboxListItemFirstChar   = '*';
const unichar kMHParserCharCheckboxListItemSecondChar   = '?';
const unichar kMHParserCharCheckboxListItemThirdChar   = ' ';

NSString * const kMHParserCharsUnaryPrefixOperator   = @"-+±∓";
NSString * const kMHParserCharsUnaryPostfixOperator  = @"!";
NSString * const kMHParserCharsBinaryOperator        = @"-+*/−±∓";
NSString * const kMHParserCharsBinaryRelation        = @"=<>≤≥≠:";
NSString * const kMHParserCharsNumeral               = @"0123456789";
NSString * const kMHParserCharsLeftBracket           = @"([{";
NSString * const kMHParserCharsRightBracket          = @")]}";
NSString * const kMHParserCharsDirectionallyAmbiguousBracket = @"|‖";
NSString * const kMHParserCharsPunctuation           = @",;…";

const unichar kMHParserBracketCharLeftParenthesis   = '(';
const unichar kMHParserBracketCharLeftSquareBrace   = '[';
const unichar kMHParserBracketCharLeftCurlyBrace    = '{';

const unichar kMHParserBracketCharRightParenthesis   = ')';
const unichar kMHParserBracketCharRightSquareBrace   = ']';
const unichar kMHParserBracketCharRightCurlyBrace    = '}';

const unichar kMHParserBracketCharAbsoluteValue      = '|';
const unichar kMHParserBracketCharNorm               = 0x2016; // '‖' symbol


// Attribute dictionaries
const unichar kMHParserCharAttributesSymbol          = 0xFF20;  // '＠' (U+FF20, full width commercial at)
NSString * const kMHParserCharAttributesString       = @"＠";
const unichar kMHParserCharAssignment                = 0x2190;    // '←'
NSString * const kMHParserCharAssignmentString       = @"←";


// FIXME: todo: refactor the code in a way that eliminates all cast operations, they are bad practice and represent assumptions about the way objects behave that aren't guaranteed by the interface



@interface MHParser () {
    MHVerticalLayoutContainer *_compiledExpression;
}
@end

@implementation MHParser

- (instancetype)init
{
    if (self = [super init]) {
        _packageManager = [MHPackageManager sharedPackageManager];
        _notebookConfigurationCommandsEnabled = NO;
    }
    return self;
}

- (NSData *)characterTypeBytes
{
    return [NSData dataWithData:_characterTypeBytesMutableBuffer];  // return a non-mutable copy of the buffer
}

- (MHExpression *)compiledExpressionForCodeParagraphOfIndex:(NSUInteger)index
{
    return [_compiledExpression expressionAtIndex:index];
}


- (void)parseCode:(NSObject <MHSourceCodeString> *)code
{
//    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//    NSLog(@"parsing code %@", code.string);
    
    _code = code;
    _codeString = code.string;
    _characterTypeBytesMutableBuffer = code.codeSemanticsData;
    
    NSMutableArray *paragraphRanges = code.codeParagraphRanges;
    [paragraphRanges removeAllObjects];     // FIXME: paragraphRanges should be initialized from the code's textStorage property
    
    _compiledExpression = [MHVerticalLayoutContainer expression];       // create a new root object to contain the compiled object tree
    
    NSUInteger index = 0;
    NSUInteger codeLength = _codeString.length;
    
    // Start by skipping any leading newline characters
    while (index < codeLength && [_codeString characterAtIndex:index] == '\n')
        index++;
    
    // The main loop to scan for content paragraphs and feed them into the appropriate single-mode parsers
    while (index < codeLength) {
        
        // FIXME: it would be more robust to let the text and math mode parser figure out where the paragraph break is rather than for the higher-level parsing method find the paragraph break
        NSRange paragraphBreak = [_codeString rangeOfString:@"\n\n"
                                             options:NSLiteralSearch
                                               range:NSMakeRange(index, codeLength-index)
                                              locale:nil];
        bool isLastParagraph = (paragraphBreak.location == NSNotFound);
        NSUInteger paragraphLength = (isLastParagraph ? codeLength-index - ([_codeString characterAtIndex:codeLength-1] == '\n' ? 1 : 0)
                                      : paragraphBreak.location - index);
        
        [paragraphRanges addObject:[NSValue valueWithRange:NSMakeRange(index, paragraphLength)]];
        
        NSRange scannedRange;
        [_compiledExpression addSubexpression:[self parseParagraphCodeInRange:NSMakeRange(index, paragraphLength)
                                                         actuallyScannedRange:&scannedRange]];
        
        index += paragraphLength;
        
        // For math paragraphs, we want to mark the newline immediately after the paragraph as a math mode character, to get the math mode background color to apply to the full paragraph including the entire width of the last line
        // FIXME: maybe not the most robust/future-proof solution, I'll probably have to adapt this later when adding other types of paragraphs
        if (paragraphLength >= 1 && index+1 < codeLength) {
            char *mutableBytes = _characterTypeBytesMutableBuffer.mutableBytes;
            if (mutableBytes[index-1] & kMHParserSyntaxColoringMathMode)
                mutableBytes[index] |= kMHParserSyntaxColoringMathMode;
        }
        
        index += 2;     // add 2 to skip also the double newline pattern that marks a paragraph break
        while (index < codeLength && [_codeString characterAtIndex:index] == '\n')
            index++;
    }
    
    _code = nil;
    _codeString = nil;
    _characterTypeBytesMutableBuffer = nil;
    
    [self.delegate compiledExpressionChangedTo:_compiledExpression
                                    changeType:MHCompiledExpressionUpdateTypeCompilation
                        firstAffectedParagraph:nil
                                paragraphIndex:0
                       secondAffectedParagraph:nil];
    
//    NSLog(@"parsing took %f seconds", CFAbsoluteTimeGetCurrent()-currentTime);
}

- (MHParagraph *)parseParagraphCodeInRange:(NSRange)charRange
                      actuallyScannedRange:(NSRange *)scannedRangePointer
{
    [_characterTypeBytesMutableBuffer resetBytesInRange:charRange];
    
    bool isMathParagraph = charRange.length >= kMHParserMathParagraphControlStringLength &&
    ([_codeString rangeOfString:kMHParserMathParagraphControlString
                  options:NSLiteralSearch
                    range:NSMakeRange(charRange.location, kMHParserMathParagraphControlStringLength)].location != NSNotFound);
    
    if (isMathParagraph) {
        
        // Mark the paragraph control string as scanned in math mode
        char *buffer = _characterTypeBytesMutableBuffer.mutableBytes;
        buffer[charRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringModeSwitch | kMHParserSyntaxColoringMathMode;
        buffer[charRange.location+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringModeSwitch | kMHParserSyntaxColoringMathMode;
        buffer[charRange.location+2] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringModeSwitch | kMHParserSyntaxColoringMathMode;
        
        // Package the parsed expression in a math paragraph and add it to _compiledExpression
//        MHMathParagraph *mathParagraph = [MHMathParagraph expression];
        MHMathParagraph *mathParagraph = [MHMathParagraph expression];
        [self parseMathModeCodeInRange:NSMakeRange(charRange.location+kMHParserMathParagraphControlStringLength,
                                                   charRange.length-kMHParserMathParagraphControlStringLength)
                  actuallyScannedRange:scannedRangePointer
                         rootContainer:mathParagraph];
        return mathParagraph;
    }
    else {
        MHTextParagraph *textParagraph = [MHTextParagraph expression];
            [self parseTextModeCodeInRange:charRange
                  actuallyScannedRange:scannedRangePointer
                         rootContainer:textParagraph];
        return textParagraph;
    }
}




# pragma mark - MHSourceCodeTextViewDelegate protocol

- (void)codeDidChangeWithNewCode:(id <MHSourceCodeString>)code
                        editType:(MHSourceCodeEditType)editType
     firstAffectedParagraphRange:(NSRange)firstParagraphRange
     firstAffectedParagraphIndex:(NSUInteger)paragraphIndex
    secondAffectedParagraphRange:(NSRange)secondParagraphRange
               newParagraphRange:(NSRange)newParagraphRange
{
//    NSLog(@"edit type %d   firstrange: %lu %lu   paraindex: %lu     secondrange: %lu %lu", editType, firstParagraphRange.location, firstParagraphRange.length, paragraphIndex, secondParagraphRange.location, secondParagraphRange.length);
    
    // save the code and syntax coloring buffer temporarily for parsing    // FIXME: is this a good way?
    _code = code;
    _codeString = code.string;
    _characterTypeBytesMutableBuffer = code.codeSemanticsData;
    
    NSRange scannedRange;   // FIXME: is this good for anything? consider eliminating
    switch (editType) {
        case MHSourceCodeEditCharsAdditionInExistingParagraph:
        case MHSourceCodeEditDeleteCharactersInParagraph: {
            // get the old expression to be replaced and its parent container
            MHExpression *oldParagraphExpression = [self compiledExpressionForCodeParagraphOfIndex:paragraphIndex];
            MHVerticalLayoutContainer *container = (MHVerticalLayoutContainer *)(oldParagraphExpression.parent);   // FIXME: this is dangerous - too many assumptions that are not in the official interface about the way the expressions hierarchy is set up
            
            // Parse the paragraph and use it to replace the old one
            MHParagraph *paragraph = [self parseParagraphCodeInRange:firstParagraphRange actuallyScannedRange:&scannedRange];
        
            [container replaceParagraphAtIndex:paragraphIndex withParagraph:paragraph];
            
            [self.delegate compiledExpressionChangedTo:_compiledExpression
                                            changeType:MHCompiledExpressionUpdateTypeParagraphUpdate
                                firstAffectedParagraph:paragraph
                                        paragraphIndex:paragraphIndex secondAffectedParagraph:nil];
        }
            break;
        case MHSourceCodeEditDeleteParagraph: {
            // get the old expression to be replaced and its parent container
            MHExpression *oldParagraphExpression = [self compiledExpressionForCodeParagraphOfIndex:paragraphIndex];
            MHVerticalLayoutContainer *container = (MHVerticalLayoutContainer *)(oldParagraphExpression.parent);   // FIXME: this is dangerous - too many assumptions that are not in the official interface about the way the expressions hierarchy is set up
            
            [container removeParagraphAtIndex:paragraphIndex];
            
            [self.delegate compiledExpressionChangedTo:_compiledExpression
                                            changeType:MHCompiledExpressionUpdateTypeParagraphDeletion
                                firstAffectedParagraph:nil
                                        paragraphIndex:paragraphIndex
                               secondAffectedParagraph:nil];
        }
            break;
        case MHSourceCodeEditNewlineAdditionSplittingParagraphs:
        case MHSourceCodeEditDeleteCharactersSplittingParagraphs: {
            // get the old expression to be replaced and its parent container
            MHExpression *oldParagraphExpression = [self compiledExpressionForCodeParagraphOfIndex:paragraphIndex];
            MHVerticalLayoutContainer *container = (MHVerticalLayoutContainer *)(oldParagraphExpression.parent);   // FIXME: this is dangerous - too many assumptions that are not in the official interface about the way the expressions hierarchy is set up
            
            // Parse the first paragraph and use it to replace the old one
            MHParagraph *newFirstParagraph = [self parseParagraphCodeInRange:firstParagraphRange actuallyScannedRange:&scannedRange];

            [container replaceParagraphAtIndex:paragraphIndex withParagraph:newFirstParagraph];

            // Parse the second paragraph and insert it into the container
            MHParagraph *newSecondParagraph = [self parseParagraphCodeInRange:secondParagraphRange actuallyScannedRange:&scannedRange];

            [container insertParagraph:newSecondParagraph atIndex:paragraphIndex+1];
            
            [self.delegate compiledExpressionChangedTo:_compiledExpression
                                            changeType:MHCompiledExpressionUpdateTypeParagraphSplit
                                firstAffectedParagraph:newFirstParagraph
                                        paragraphIndex:paragraphIndex
                               secondAffectedParagraph:newSecondParagraph];
        }
            break;
        case MHSourceCodeEditCharsAdditionMergingParagraphs:
        case MHSourceCodeEditDeleteLeadingToParagraphsMerging: {
            // get the first of the old paragraphs to be merged and its parent container
            MHExpression *oldFirstParagraphExpression = [self compiledExpressionForCodeParagraphOfIndex:paragraphIndex];
            MHVerticalLayoutContainer *container = (MHVerticalLayoutContainer *)(oldFirstParagraphExpression.parent);   // FIXME: this is dangerous - too many assumptions that are not in the official interface about the way the expressions hierarchy is set up
            
            // Parse the merged paragraph and use it to replace the old one
            
            // FIXME: there is an inconsistency here. We use the firstParagraphRange and secondParagraphRange data to handle deletions, and use the newParagraph parameter (that isn't provided in the case of a deletion) to handle the second case of a paragraph-merge operation resulting from a string insertion. This discrepancy may be harmless but is still annoying and may cause unexpected problems later on - fix it at some point
            NSRange mergedParagraphRange;
            if (editType == MHSourceCodeEditCharsAdditionMergingParagraphs) {
                mergedParagraphRange = newParagraphRange;
//                NSMakeRange(firstParagraphRange.location,
//                                                   secondParagraphRange.location+secondParagraphRange.length-firstParagraphRange.location-1 + 2);
            }
            else {
                mergedParagraphRange = NSMakeRange(firstParagraphRange.location,
                                                   secondParagraphRange.location+secondParagraphRange.length-firstParagraphRange.location-1);

            }
            
            MHParagraph *newMergedParagraph = [self parseParagraphCodeInRange:mergedParagraphRange actuallyScannedRange:&scannedRange];

            [container replaceParagraphAtIndex:paragraphIndex withParagraph:newMergedParagraph];
            [container removeParagraphAtIndex:paragraphIndex+1];
            
            [self.delegate compiledExpressionChangedTo:_compiledExpression
                                            changeType:MHCompiledExpressionUpdateTypeParagraphMerge
                                firstAffectedParagraph:newMergedParagraph
                                        paragraphIndex:paragraphIndex
                               secondAffectedParagraph:nil];
        }
            break;
        case MHSourceCodeEditCharsAdditionInNewParagraph: {
            // get the root container
//            MHLinearContainer *container = _compiledExpression; // FIXME: making an assumption here... not so good
            MHVerticalLayoutContainer *container = (MHVerticalLayoutContainer *)_compiledExpression; // FIXME: making an assumption here... not so good

            // Parse the new paragraph
            MHParagraph *newParagraph = [self parseParagraphCodeInRange:firstParagraphRange actuallyScannedRange:&scannedRange];

            [container insertParagraph:newParagraph atIndex:paragraphIndex];

            [self.delegate compiledExpressionChangedTo:_compiledExpression
                                            changeType:MHCompiledExpressionUpdateTypeParagraphInsertion
                                firstAffectedParagraph:newParagraph
                                        paragraphIndex:paragraphIndex
                               secondAffectedParagraph:nil];
        }
            break;
        default:
            NSLog(@"add handling for this edit type");  // FIXME:
            break;
    }
    _code = nil;
    _codeString = nil;
    _characterTypeBytesMutableBuffer = nil;
}




+ (NSAttributedString *)syntaxColoredCodeFromCode:(NSString *)sourceCode codeFormattingStyle:(MHParserCodeFormattingStyle)formattingStyle
{
    static MHSourceCodeTextView *syntaxColoringSourceCodeEditingTextViewForTextMode;
    static MHSourceCodeTextView *syntaxColoringSourceCodeEditingTextViewForMathMode;
    static MHParser *syntaxColoringParser;
    
    // FIXME: generating syntax coloring code by compiling it inside a text view is very computationally inefficient. With a bit of work this can be rewritten to be much less resource-intensive
    
    // FIXME: this implementation makes assumptions on how the source code text view operates. Not good OO practice
    
    if (!syntaxColoringSourceCodeEditingTextViewForTextMode || !syntaxColoringParser) {
        syntaxColoringSourceCodeEditingTextViewForTextMode = [[MHSourceCodeTextView alloc] initWithFrame:NSZeroRect
                                                                                           textContainer:nil];

        MHSourceCodeEditorTheme *editorTheme = [[MHSourceCodeEditorThemeManager defaultManager] defaultThemeForQuotedCode];

        syntaxColoringSourceCodeEditingTextViewForTextMode.editorTheme = editorTheme;
        syntaxColoringSourceCodeEditingTextViewForTextMode.currentFont = [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                                                                         size:MHSourceCodeTextViewDefaultFontSize];
                
        syntaxColoringSourceCodeEditingTextViewForMathMode = [[MHSourceCodeTextView alloc] initWithFrame:NSZeroRect
                                                                                           textContainer:nil];
        syntaxColoringSourceCodeEditingTextViewForMathMode.editorTheme = editorTheme;

        syntaxColoringSourceCodeEditingTextViewForMathMode.currentFont = [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                                                                         size:MHSourceCodeTextViewDefaultFontSize];

        syntaxColoringParser = [[MHParser alloc] init];
        syntaxColoringSourceCodeEditingTextViewForTextMode.codeEditingDelegate = syntaxColoringParser;
        syntaxColoringSourceCodeEditingTextViewForMathMode.codeEditingDelegate = syntaxColoringParser;
    }
    
    bool inTextMode = (formattingStyle == MHParserCodeFormattingText);
    NSString *modeSpecificSourceCode = (inTextMode ? sourceCode :
                                        [NSString stringWithFormat:@"%@ %@", kMHParserMathParagraphControlString, sourceCode]);
    
    MHSourceCodeTextView *modeSpecificSourceCodeTextView = (inTextMode ?
                                                            syntaxColoringSourceCodeEditingTextViewForTextMode : syntaxColoringSourceCodeEditingTextViewForMathMode);
    
    modeSpecificSourceCodeTextView.string = modeSpecificSourceCode;
    [syntaxColoringParser parseCode:modeSpecificSourceCodeTextView.textStorage];
    [modeSpecificSourceCodeTextView applySyntaxColoringToRange:NSMakeRange(NSNotFound, 0)];
    
    NSAttributedString *syntaxColoredCode = [modeSpecificSourceCodeTextView.attributedString copy];
    
    NSMutableAttributedString *syntaxColoredCodeWithPrefixTrimmed =
    [(inTextMode || (formattingStyle == MHParserCodeFormattingMathWithMathParagraphPrefix) ? syntaxColoredCode :
    [syntaxColoredCode attributedSubstringFromRange:
     NSMakeRange(kMHParserMathParagraphControlStringLength+1, syntaxColoredCode.length - kMHParserMathParagraphControlStringLength-1)]) mutableCopy];
    
    // Remove the "⁓" annotation marks
    // FIXME: this is a bit of a hack, and also means the name of the method becomes a bit illogical. Consider improving
    [[syntaxColoredCodeWithPrefixTrimmed mutableString] replaceOccurrencesOfString:@"⁓"
                                                                        withString:@""
                                                                           options:0
                                                                             range:NSMakeRange(0, syntaxColoredCodeWithPrefixTrimmed.length)];
    
    return syntaxColoredCodeWithPrefixTrimmed;
}



@end
