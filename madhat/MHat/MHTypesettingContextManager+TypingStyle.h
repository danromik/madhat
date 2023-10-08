//
//  MHTypesettingContextManager+TypingStyle.h
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHTypesettingContextManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTypesettingContextManager (TypingStyle)

@property NSColor *textForegroundColor;
@property (nullable) NSColor *textHighlightColor;      // a null value means a transparent background (no highlight)
@property bool textBold;
@property bool textItalic;
@property bool textHighlighting;
@property bool textUnderlining;
@property bool textStrikethrough;
@property MHTextSubstitutionType textSubstitutionType;

// FIXME: this isn't implemented yet, not sure if it's needed so commenting out for now
//@property (readonly) NSFontTraitMask fontTraitMask;     // this encodes the bold, italic (etc) traits in a single bitmask // FIXME: seems unimplemented

- (CGFloat)baseFontSize;
- (CGFloat)fontSizeForNestingLevel:(NSUInteger)nestingLevel;
- (void)setBaseFontSize:(CGFloat)newFontSize;

@property NSString *mathFontName;
@property (readonly) MHMathFontSystem *mathFontSystem;
@property MHMathFontVariant mathFontVariant;

- (NSString *)textFontNameForPresentationMode:(MHExpressionPresentationMode)mode;
- (void)setTextFontName:(NSString *)fontName forPresentationMode:(MHExpressionPresentationMode)mode;

- (NSFont *)textFontForPresentationMode:(MHExpressionPresentationMode)mode nestingLevel:(NSUInteger)nestingLevel;
- (NSFont *)mathFontForNestingLevel:(NSUInteger)nestingLevel traits:(MHMathFontTraits)traits;



- (void)typingStyleWillChange;  // FIXME: think whether I want to expose it - currently calling it in one place from the main class file









@end

NS_ASSUME_NONNULL_END
