//
//  MHTypesettingContextManager+TypingStyle.m
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHStyleIncludes.h"
#import "MHTypesettingContextManager+TypingStyle.h"


#import <AppKit/AppKit.h>


@implementation MHTypesettingContextManager (TypingStyle)

- (NSColor *)textForegroundColor {
    return _currentTypingStyle.textForegroundColor;
}
- (void)setTextForegroundColor:(NSColor *)color
{
    [self typingStyleWillChange];
    _currentTypingStyle.textForegroundColor = color;
}

- (NSColor *)textHighlightColor
{
    return _currentTypingStyle.textHighlightColor;
}

- (void)setTextHighlightColor:(NSColor *)highlightColor
{
    [self typingStyleWillChange];
    _currentTypingStyle.textHighlightColor = highlightColor;
}

- (bool)textItalic
{
    return _currentTypingStyle.textItalic;
}

- (void)setTextItalic:(bool)italic
{
    [self typingStyleWillChange];
    _currentTypingStyle.textItalic = italic;
}

- (bool)textBold
{
    return _currentTypingStyle.textBold;
}

- (void)setTextBold:(bool)bold
{
    [self typingStyleWillChange];
    _currentTypingStyle.textBold = bold;
}

- (bool)textUnderlining
{
    return _currentTypingStyle.textUnderlining;
}

- (void)setTextUnderlining:(bool)textUnderlining
{
    [self typingStyleWillChange];
    _currentTypingStyle.textUnderlining = textUnderlining;
}

- (bool)textStrikethrough
{
    return _currentTypingStyle.textStrikethrough;
}

- (void)setTextStrikethrough:(bool)textStrikethrough
{
    [self typingStyleWillChange];
    _currentTypingStyle.textStrikethrough = textStrikethrough;
}

- (bool)textHighlighting
{
    return _currentTypingStyle.textHighlighting;
}

- (void)setTextHighlighting:(bool)highlighting
{
    [self typingStyleWillChange];
    _currentTypingStyle.textHighlighting = highlighting;
}

- (MHTextSubstitutionType)textSubstitutionType
{
    return _currentTypingStyle.textSubstitutionType;
}

- (void)setTextSubstitutionType:(MHTextSubstitutionType)textSubstitutionType
{
    _currentTypingStyle.textSubstitutionType = textSubstitutionType;
}


- (MHMathFontSystem *)mathFontSystem
{
    return _currentTypingStyle.mathFontSystem;
}

- (NSString *)mathFontName
{
    return _currentTypingStyle.mathFontName;
}

- (void)setMathFontName:(NSString *)fontName
{
    [self typingStyleWillChange];
    _currentTypingStyle.mathFontName = fontName;
}

- (MHMathFontVariant)mathFontVariant
{
    return _currentTypingStyle.mathFontVariant;
}

- (void)setMathFontVariant:(MHMathFontVariant)mathFontVariant
{
    [self typingStyleWillChange];
    _currentTypingStyle.mathFontVariant = mathFontVariant;
}


- (NSString *)textFontNameForPresentationMode:(MHExpressionPresentationMode)mode
{
    return [_currentTypingStyle textFontNameForPresentationMode:mode];
}

- (void)setTextFontName:(NSString *)fontName forPresentationMode:(MHExpressionPresentationMode)mode
{
    [self typingStyleWillChange];
    [_currentTypingStyle setTextFontName:fontName forPresentationMode:mode];
}

- (NSFont *)textFontForPresentationMode:(MHExpressionPresentationMode)mode nestingLevel:(NSUInteger)nestingLevel
{
    return [_currentTypingStyle textFontForPresentationMode:mode nestingLevel:nestingLevel];
}

- (NSFont *)mathFontForNestingLevel:(NSUInteger)nestingLevel traits:(MHMathFontTraits)traits
{
    return [_currentTypingStyle mathFontForNestingLevel:nestingLevel traits:traits];
}

- (CGFloat)baseFontSize
{
    return _currentTypingStyle.baseFontSize;
}

- (CGFloat)fontSizeForNestingLevel:(NSUInteger)nestingLevel {
    return [_currentTypingStyle fontSizeForNestingLevel:nestingLevel];
}


- (void)setBaseFontSize:(CGFloat)newFontSize;
{
    [self typingStyleWillChange];
    _currentTypingStyle.baseFontSize = newFontSize;
}



- (void)typingStyleWillChange
{
    // In our implementation of a stack of typing styles with lazy copying, when the style is about to change is the time to actually copy the style
    if (lastDepthWhenTypingStylePushed < typingStylesStackDepthCounter) {
        MHTypingStyle *typingStyleCopy = [_currentTypingStyle copy];
        [typingStylesStack addObject:_currentTypingStyle];
        _currentTypingStyle = typingStyleCopy;
        [typingStyleChangeDepthIndicesStack addObject:[NSNumber numberWithShort:lastDepthWhenTypingStylePushed]];
        lastDepthWhenTypingStylePushed = typingStylesStackDepthCounter;
    }
}







@end
