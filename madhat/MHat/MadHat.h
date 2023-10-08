//
//  MadHat.h
//  MadHat
//
//  Created by Dan Romik on 10/25/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifndef MadHat_h
#define MadHat_h




// Basic data structures and classifications of the MadHat framework

typedef struct {
    double width;
    double height;
    double depth;
} MHDimensions;

typedef enum {
    MHExpressionPresentationModeEditing = 0,
    MHExpressionPresentationModePublishing = 1,
} MHExpressionPresentationMode;

typedef enum {
    MHTypographyClassText = 0,                    // The default class for ordinary text parsed in text mode
    MHTypographyClassNumber = 1,                  // Numbers
    MHTypographyClassUnaryPrefixOperator = 2,     // Prefix operators such as "+" and "-" appearing at the beginning of a formula
    MHTypographyClassUnaryPostfixOperator = 3,    // Postfix operators such as "!"
    MHTypographyClassBinaryOperator = 4,          // Any binary operator (ordinary arithmetic operations +, -, *, /, etc.)
    MHTypographyClassBinaryRelation = 5,          // Binary relations: "=", "<", ">", etc
    MHTypographyClassRomanMathVariable = 6,         // Used for multi-letter text symbols in a math formula (e.g.: cos, det, lim), and Greek letters
    MHTypographyClassItalicMathVariable = 7,          // Used for single-letter, latin alphabet symbols in a math formula (e.g.: x, y, f)
    MHTypographyClassLeftBracket = 8,             // All left brackets
    MHTypographyClassRightBracket = 9,            // All right brackets
    MHTypographyClassPunctuation = 10,            // Punctuation symbols
    MHTypographyClassCompoundExpression = 11,      // Expressions built up from other expressions, e.g., fractions, sub/superscripted expressions, radical symbols, matrices etc.
    MHTypographyNumberOfClasses = 12,    // the numerical value of this keyword is the number of actual typography classes
    //
    //  the typography classes above this line participate in kerning. The next few classes are ones for which kerning is not applied
    //
    MHTypographyClassWhiteSpace = 998,  // for spaces, newlines etc. Kern is not inserted for expression pairs where one of the expressions has this class
    MHTypographyClassUnknown = 999,     // for expressions where the typography class still hasn't been (or can't be) determined
    MHTypographyClassNone = 1000        // for empty expressions
} MHTypographyClass;


typedef enum {
    MHMathFontVariantDefault = 0,   // the default behavior is italic for single-letter symbols, roman for multi-letter symbols
    MHMathFontVariantRoman,
    MHMathFontVariantItalic,
    MHMathFontVariantBold,
    MHMathFontVariantBlackboard,
    MHMathFontVariantFraktur,
    MHMathFontVariantCalligraphy,
    MHMathFontVariantMonospace,
    MHMathFontVariantSansSerif,
} MHMathFontVariant;

typedef enum {
    MHTextSubstitutionNone = 0,
    MHTextSubstitutionLowercase = 1,
    MHTextSubstitutionUppercase = 2,
    MHTextSubstitutionRedacted = 3,
    MHTextSubstitutionObfuscated = 4,
} MHTextSubstitutionType;


typedef enum {
    MHMathParagraphTabStop,
    MHMathParagraphDiscretionaryLineBreaking,
    MHMathParagraphNoAlignmentRole
} MHMathParagraphAlignmentRole;



// the paragraph type affects the spacing inserted before and after the paragraph by the MHVerticalLayoutContainer class
typedef enum {
    MHParagraphNone = 0,
    MHParagraphNormal = 1,      // default type     // FIXME: maybe have separate types for text and math paragraphs, or even additional subtypes to encode whether a math paragraph should be considered a part of the text paragraph above and/or below it
    MHParagraphHeader = 2,
    MHParagraphSubheader = 3,
    MHParagraphSubsubheader = 4,
    MHParagraphParagraphHeader = 5,
    MHParagraphSuperheader = 6,
    MHParagraphListItem = 7,
    MHParagraphBeginBox = 8,
    MHParagraphEndBox = 9,
    MHParagraphQuotedCodeParagraph = 10,
    // above this point in the typedef are the effective paragraph types that are used by the MHVerticalLayoutContainer
    // paragraph kerning algorithm (see the macros MHParagraphEffectiveParagraphTypeFromAbove and
    // MHParagraphEffectiveParagraphTypeFromBelow in that class file)
    //
    // (note: if we add more effective paragraph types, make sure to keep the MHNumberOfEffectiveParagraphTypes constant
    // defined below in sync with the number of effective types)
    //
    // below this point in the typedef are paragraph types that are never returned by the effectiveTypeFromAbove
    // and effectiveTypeFromBelow
    MHParagraphBoxDivider = 11,
    MHParagraphSuppressParagraphIndentBitMask = 32,   // used as a bit mask to signal that the paragraph indentation should be suppressed
    MHParagraphForceNewParagraphBitMask = 64,   // used as a bit mask to signal that the paragraph should be treated as a new paragraph (as opposed to a continuation of the preceding paragraph, which is the default behavior for a text paragraph following a math paragraph) and that the paragraph indentation should be added.
    MHParagraphIsMathParagraphBitMask = 128,   // used as a bit mask to signal that the paragraph is a math paragraph. This is used by the paragraph kerning algorithm
} MHParagraphType;

// Important macros relating to the paragraph type enum
// FIXME: check very carefully if these definitions are correct
#define MHNumberOfEffectiveParagraphTypes  11

#define MHParagraphDoNotSuppressParagraphIndentBitMask (~MHParagraphSuppressParagraphIndentBitMask)
#define MHParagraphDoNotForceNewParagraphBitMask (~MHParagraphForceNewParagraphBitMask)
#define MHParagraphIsNotMathParagraphBitMask (~MHParagraphIsMathParagraphBitMask)

#define MHParagraphTypeIgnoringBitMask(parType) (parType & (MHParagraphDoNotSuppressParagraphIndentBitMask & MHParagraphDoNotForceNewParagraphBitMask & MHParagraphIsNotMathParagraphBitMask))

#define MHParagraphEffectiveParagraphTypeFromAbove(parType) \
  (MHParagraphTypeIgnoringBitMask(parType) == MHParagraphBoxDivider ? MHParagraphEndBox : MHParagraphTypeIgnoringBitMask(parType))

#define MHParagraphEffectiveParagraphTypeFromBelow(parType) \
  (MHParagraphTypeIgnoringBitMask(parType) == MHParagraphBoxDivider ? MHParagraphBeginBox : MHParagraphTypeIgnoringBitMask(parType))

#define MHParagraphTypeIndentShouldBeSuppressed(parType) ((parType & MHParagraphSuppressParagraphIndentBitMask) != 0)

#define MHParagraphTypeNewParagraphShouldBeForced(parType) ((parType & MHParagraphForceNewParagraphBitMask) != 0)

#define MHParagraphTypeIsMathParagraph(parType) ((parType & MHParagraphIsMathParagraphBitMask) != 0)


typedef CGFloat MHParagraphKerningMatrix[MHNumberOfEffectiveParagraphTypes][MHNumberOfEffectiveParagraphTypes];
typedef CGFloat *MHParagraphKerningMatrixCastAsPointer; // objective-c doesn't like passing arrays as method arguments and returning them from method calls, so we sometimes need to cast variables of type MHParagraphKerningMatrix as pointers

typedef enum {
    MHParagraphBoxTypeNoBox,
    MHParagraphBoxTypeBoxHeader,
    MHParagraphBoxTypeBoxBody,
    MHParagraphBoxTypeBoxFooter,
    MHParagraphBoxTypeBoxDivider
} MHParagraphBoxType;

typedef struct {
    CGFloat minX, maxX, minY, maxY;
} MHGraphicsRectangle;



// Types of list delimiters

typedef enum {
    MHListDelimiterTypePrimary,
    MHListDelimiterTypeSecondary
} MHListDelimiterType;



// Types of expression layout behaviors
typedef enum {
    MHLayoutHorizontal,
    MHLayoutVertical
} MHLayoutType;




// Notifications - FIXME: is this a good place to put these declarations?
extern NSString * _Nonnull const kMHInteractiveEventOutlinerNodeToggledNotification;    // the object sent with the notification is the paragraph containing the outliner item (which conforms to the MHOutlinerItemParagraph protocol)


// FIXME: these notifications are currently only sent by the MHVideo class when a video starts and stops playing. Extend this to other types of animations
extern NSString * _Nonnull const kMHInteractiveEventAnimationStartedNotification;   // the notification object is the MHExpression instance that's starting an animation, and is assumed to conform to the MHAnimatableExpression protocol
extern NSString * _Nonnull const kMHInteractiveEventAnimationEndedNotification;     // the notification object is the MHExpression instance that finished animating, and is assumed to conform to the MHAnimatableExpression protocol

extern NSString * _Nonnull const kMHNotebookPageShowTransientStatusMessageNotification;
extern NSString * _Nonnull const kMHNotebookPageShowTransientStatusMessageMessageKey;

// *** Temporarily putting some types here - FIXME: should move them to one of the class files later ***
typedef enum {
    MHBracketLeftOrientation = 0,
    MHBracketRightOrientation = 1,
    MHBracketDynamicallyDeterminedOrientation = 2,
    MHBracketMiddleOrientation = 3
} MHBracketOrientation;

typedef enum {
    MHBracketTypeParenthesis = 0,
    MHBracketTypeSquareBrace = 1,
    MHBracketTypeFloor = 2,
    MHBracketTypeCeiling = 3,
    MHBracketTypeVerticalBar = 4,
    MHBracketTypeDoubleVerticalBar = 5,
    MHBracketTypeCurlyBrace = 6,
    MHBracketTypeAngleBrace = 7,
    MHBracketTypeInvisible = 8,
    MHBracketTypeMatchOpposingBracket = 9999
} MHBracketType;
#define kMHBracketNumberOfVisibleBracketTypes     MHBracketTypeInvisible


typedef enum {
    // Braces
    MHHorizontalExtensibleSymbolOverbrace = 0,           // top curly brace
    MHHorizontalExtensibleSymbolUnderbrace = 1,          // bottom curly brace
    MHHorizontalExtensibleSymbolOverbracket = 2,         // top square bracket
    MHHorizontalExtensibleSymbolUnderbracket = 3,        // bottom square bracket
    MHHorizontalExtensibleSymbolOverparenthesis = 4,     // top parenthesis
    MHHorizontalExtensibleSymbolUnderparenthesis = 5,    // bottom parenthesis
    MHHorizontalExtensibleSymbolOvertortoise = 6,        // top tortoise shell bracket
    MHHorizontalExtensibleSymbolUndertortoise = 7,       // bottom tortoise shell bracket
    // Arrows and equal signs
    MHHorizontalExtensibleSymbolEqualSign = 8,          // extensible equal sign
    MHHorizontalExtensibleSymbolRightArrow = 9,          // extensible right arrow
    MHHorizontalExtensibleSymbolDoubleRightArrow = 10,    // extensible double right arrow
    MHHorizontalExtensibleSymbolLeftArrow = 11,         // extensible left arrow
    MHHorizontalExtensibleSymbolDoubleLeftArrow = 12,    // extensible double right arrow
    MHHorizontalExtensibleSymbolLeftRightArrow = 13,    // extensible left-right arrow
    MHHorizontalExtensibleSymbolDoubleLeftRightArrow = 14,    // extensible double left-right arrow
    //
    MHHorizontalExtensibleSymbolNone = 15,
} MHHorizontalExtensibleSymbolType;
#define kMHHorizontalExtensibleSymbolNumberOfSymbolTypes     MHHorizontalExtensibleSymbolNone

typedef enum {
    MHHorizontalExtensibleSymbolPositioningTop,     // the extensible symbol is positioned above an expression being annotated (used for overbraces, overbrackets etc)
    MHHorizontalExtensibleSymbolPositioningBottom,  // the extensible symbol is positioned below an expression being annotated (used for underbraces, underbrackets etc)
    MHHorizontalExtensibleSymbolPositioningMiddle,  // the extensible symbol is positioned between two expressions (used for extensible arrows and equal signs)
} MHHorizontalExtensibleSymbolPositioning;


// Animations
//#define kMHDefaultAnimationDuration                     0.22
#define kMHDefaultOutlinerFadeAnimationDuration         0.22
#define kMHDefaultCoupledScrollingAnimationDuration     0.22
#define kMHDefaultNodePositionAnimationDuration         0.22
#define kMHDefaultSlideTransitionAnimationDuration      0.6
#define kMHDefaultPropertyChangeAnimationDuration       0.6
#define kMHDefaultPropertyChangeAnimationUpdateInterval 0.01


typedef enum {
    MHCommandNormal,
    MHCommandMathKeyword
} MHCommandType;



// Page sizes
// ************************************************************
// Letter page size: 8.5x11 inches at 72 points per inch
#define MHPageSizeLetterWidth       612.0
#define MHPageSizeLetterHeight      792.0

// A4 page size: 8.3x11.7 inches at 72 points per inch
#define MHPageSizeA4Width           597.6
#define MHPageSizeA4Height          842.4

#define MHPageSizeDefaultWidth      MHPageSizeLetterWidth
#define MHPageSizeDefaultHeight     MHPageSizeLetterHeight
// ************************************************************


#define MHPageSizeMinimumWidth        300.0
#define MHPageSizeMaximumWidth        2000.0

#define MHPageSizeMinimumHeight       300.0
#define MHPageSizeMaximumHeight       2000.0




extern const NSInteger kViewMenuItemTag;
extern const NSInteger kShowHideAssetLibraryMenuItemTag;
extern const NSInteger kExportToPDFMenuItemTag;
extern const NSInteger kPrintMenuItemTag;
extern const NSInteger kNavigationPreviousPageMenuItemTag;
extern const NSInteger kNavigationNextPageMenuItemTag;
extern const NSInteger kNavigationFirstPageInNotebookMenuItemTag;
extern const NSInteger kNavigationLastPageInNotebookMenuItemTag;
extern const NSInteger kNavigationGoToPageNumberMenuItemTag;
extern const NSInteger kToggleAutomaticQuoteSubstitutionMenuItemTag;
extern const NSInteger kToggleAutomaticDashSubstitutionMenuItemTag;





#endif /* MadHat_h */

