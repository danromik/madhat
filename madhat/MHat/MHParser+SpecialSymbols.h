//
//  MHParser+SpecialSymbols.h
//  MadHat
//
//  Created by Dan Romik on 2/8/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#ifndef MHParser_SpecialSymbols_h
#define MHParser_SpecialSymbols_h



#define kMHParserSyntaxColoringText         ((char)0)
#define kMHParserSyntaxColoringAssignment  ((char)1)
#define kMHParserSyntaxColoringCommandName  ((char)2)
#define kMHParserSyntaxColoringBlock        ((char)3)
#define kMHParserSyntaxColoringListDelimiter ((char)4)
#define kMHParserSyntaxColoringModeSwitch   ((char)5)
#define kMHParserSyntaxColoringComment      ((char)6)
#define kMHParserSyntaxColoringQuotedCodeBlock      ((char)7)
#define kMHParserSyntaxColoringUnresolvedCommandName  ((char)8)
#define kMHParserSyntaxColoringMathKeyword  ((char)9)
#define kMHParserSyntaxColoringCodeAnnotationBlock      ((char)10)
#define kMHParserSyntaxColoringAttributesSymbol      ((char)11)
#define kMHParserSyntaxColoringNumberOfColorClasses     12   // ***make sure to keep this in sync with the definitions above

// The two upper bits of each character type byte give additional information about whether we're in math mode and whether the character
// was scanned, according to the following bit mask:
#define kMHParserSyntaxColoringCharacterScanned     0x40
#define kMHParserSyntaxColoringMathMode             0x80

#define kMHParserSyntaxColoringBitMask              0xff    // used when we want to switch off specific bits by bitwise AND'ing.

#define kMHParserSyntaxColoringForgetClassification 0xf0    // bitwise AND with this mask to discard color class information
#define kMHParserSyntaxColoringNotScanned           (0xff-kMHParserSyntaxColoringCharacterScanned)    // bitwise AND with this mask to mark the character as not scanned (while preserving information about math mode)




extern const unichar kMHParserMathShiftFirstChar;
extern const unichar kMHParserMathShiftSecondChar;
extern NSString * const kMHParserMathShiftControlString;
extern NSString * const kMHParserMathParagraphControlString;
extern NSString * const kMHParserMathParagraphShortcutString;    // this is the string the text view will insert when the '$' keyboard shortcut is used

extern const unichar kMHParserTextShiftFirstChar;
extern const unichar kMHParserTextShiftSecondChar;
extern NSString * const kMHParserTextShiftControlString;

extern const unichar kMHParserCharCommentMarker;

extern const unichar kMHParserCharSpace;
extern const unichar kMHParserCharTab;
extern const unichar kMHParserCharNewline;
extern const unichar kMHParserCharOpenBlock;
extern const unichar kMHParserCharCloseBlock;
extern const unichar kMHParserCharSubscript;
extern const unichar kMHParserCharSuperscript;
extern const unichar kMHParserCharStartCommand;
extern const unichar kMHParserCharQuickCloseCommand;
extern const unichar kMHParserCharFraction;
extern const unichar kMHParserCharListDelimiter;
extern const unichar kMHParserCharSecondaryListDelimiter;
extern const unichar kMHParserCharDerivative;

extern const unichar kMHParserCharOpenCodeQuoteBlock;
extern const unichar kMHParserCharCloseCodeQuoteBlock;
extern const unichar kMHParserCharOpenMathModeCodeQuoteBlock;
extern const unichar kMHParserCharCloseMathModeCodeQuoteBlock;
extern const unichar kMHParserCharOpenCodeAnnotationBlock;
extern const unichar kMHParserCharCloseCodeAnnotationBlock;
extern const unichar kMHParserCharCodeQuoteParagraphPrefix;

extern const unichar kMHParserCharPrimeSymbol;  // symbol for the parser to use for prime notation

extern const unichar kMHParserCharASCIIApostrophe;
extern const unichar kMHParserCharTextApostrophe;
extern const unichar kMHParserCharASCIIAccentGrave;
extern const unichar kMHParserCharOpeningSingleQuote;


extern const unichar kMHParserCharHyphen;
extern const unichar kMHParserCharEnDash;
extern const unichar kMHParserCharEmDash;

extern const unichar kMHParserCharASCIIQuote;
extern const unichar kMHParserCharLeftDoubleQuote;
extern const unichar kMHParserCharRightDoubleQuote;


extern const unichar kMHParserCharMinusSign;
extern const unichar kMHParserCharPlusSign;
extern const unichar kMHParserCharPlusMinusSign;
extern const unichar kMHParserCharMinusPlusSign;


extern const unichar kMHParserCharLessThanSign;
extern const unichar kMHParserCharGreaterThanSign;
extern const unichar kMHParserCharEqualSign;
extern const unichar kMHParserCharLessThanOrEqualSign;
extern const unichar kMHParserCharGreaterThanOrEqualSign;
extern const unichar kMHParserCharNotEqualSign;


extern const unichar kMHParserCharAsterisk;
extern const unichar kMHParserCharAsteriskOperator;
extern const unichar kMHParserCharMultiplicationSymbol;
extern const unichar kMHParserCharCenterDot;

extern const unichar kMHParserCharPeriod;
extern const unichar kMHParserCharEllipsis;

// Starting a list item at the beginning of a text paragraph
extern const unichar kMHParserCharUnnumberedListItemFirstChar;
extern const unichar kMHParserCharUnnumberedListItemSecondChar;
extern const unichar kMHParserCharNumberedListItemFirstChar;
extern const unichar kMHParserCharNumberedListItemSecondChar;
extern const unichar kMHParserCharNumberedListItemThirdChar;
extern const unichar kMHParserCharCheckboxListItemFirstChar;
extern const unichar kMHParserCharCheckboxListItemSecondChar;
extern const unichar kMHParserCharCheckboxListItemThirdChar;


//extern const unichar kMHParserCharStartMathParagraph;

extern NSString * const kMHParserCharsUnaryPrefixOperator;
extern NSString * const kMHParserCharsUnaryPostfixOperator;
extern NSString * const kMHParserCharsBinaryOperator;
extern NSString * const kMHParserCharsBinaryRelation;
extern NSString * const kMHParserCharsNumeral;
extern NSString * const kMHParserCharsLeftBracket;
extern NSString * const kMHParserCharsRightBracket;
extern NSString * const kMHParserCharsDirectionallyAmbiguousBracket;
extern NSString * const kMHParserCharsPunctuation;

extern const unichar kMHParserBracketCharLeftParenthesis;
extern const unichar kMHParserBracketCharLeftSquareBrace;
extern const unichar kMHParserBracketCharLeftCurlyBrace;

extern const unichar kMHParserBracketCharRightParenthesis;
extern const unichar kMHParserBracketCharRightSquareBrace;
extern const unichar kMHParserBracketCharRightCurlyBrace;

extern const unichar kMHParserBracketCharAbsoluteValue;
extern const unichar kMHParserBracketCharNorm;


// Attributes dictionaries
extern const unichar kMHParserCharAttributesSymbol;
extern NSString * const kMHParserCharAttributesString;
extern const unichar kMHParserCharAssignment;
extern NSString * const kMHParserCharAssignmentString;



#endif /* MHParser_SpecialSymbols_h */
