//
//  MHTypingStyle.h
//  MadHat
//
//  Created by Dan Romik on 1/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHStyle.h"
#import "MHMathFontSystem.h"

typedef enum {
    MHTypingStyleNormal,
    MHTypingStyleHeader,
    MHTypingStyleSubheader,
    MHTypingStyleSubsubheader,
    MHTypingStyleParagraphHeader,
    MHTypingStyleSuperheader,
    MHTypingStyleTextHyperlink,
    MHTypingStyleURLHyperlink,
    MHTypingStyleIntralink,
} MHTypingStyleTextType;  // FIXME: should this be renamed to something like MHTypingStyleHeaderType? Is having such a typedef even a logical approach? See also the similar MHStyledTextType typedef in MHStyledTextWrapper

NS_ASSUME_NONNULL_BEGIN

@interface MHTypingStyle : MHStyle

+ (instancetype)defaultStyleForTextType:(MHTypingStyleTextType)textType;

// Text colors
@property NSColor *textForegroundColor;             // Defaults to black
@property NSColor * _Nullable textHighlightColor;  // Defaults to nil, which is equivalent to [NSColor clearColor]

// Style (bold, italic) for text mode
@property bool textBold;
@property bool textItalic;
@property bool textUnderlining;     // this is stored in one of the unused fields of the font trait mask
@property bool textHighlighting;    // this is stored in one of the unused fields of the font trait mask
@property bool textStrikethrough;
@property MHTextSubstitutionType textSubstitutionType;

// Font for text mode
- (NSString *)textFontNameForPresentationMode:(MHExpressionPresentationMode)mode;
- (void)setTextFontName:(NSString *)fontName forPresentationMode:(MHExpressionPresentationMode)mode;
- (NSFont *)textFontForPresentationMode:(MHExpressionPresentationMode)mode nestingLevel:(NSUInteger)nestingLevel;

// Math font
@property NSString *mathFontName;
@property (readonly) MHMathFontSystem *mathFontSystem;
- (NSFont *)mathFontForNestingLevel:(NSUInteger)nestingLevel traits:(MHMathFontTraits)traits;
@property MHMathFontVariant mathFontVariant;

// Font size
@property CGFloat baseFontSize;
- (CGFloat)fontSizeForNestingLevel:(NSUInteger)nestingLevel;




@end

NS_ASSUME_NONNULL_END
