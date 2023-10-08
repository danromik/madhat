//
//  MHTypingStyle.m
//  MadHat
//
//  Created by Dan Romik on 1/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTypingStyle.h"
#import "MHMathFontManager.h"


#define MHTypingStyleTextUnderliningMask    NSCompressedFontMask
#define MHTypingStyleTextStrikethroughMask    NSPosterFontMask
#define MHTypingStyleTextHighlightingMask   NSFixedPitchFontMask


@interface MHTypingStyle ()
{
    CGFloat _baseFontSize;

    NSFontTraitMask _fontTraitMask;     // this encodes the bold, italic, underlining, strikethrough, and highlighting traits in a single bitmask (underlining, strikethrough and highlighting are stored in some of the unused fields, see the definitions of MHTypingStyleTextUnderliningMask, MHTypingStyleTextStrikethroughMask and MHTypingStyleTextHighlightingMask above)
    
    MHTextSubstitutionType _textSubstitutionType;
    
    NSColor *_textForegroundColor;
    NSColor * _Nullable _textHighlightColor;
    
    NSString *_textFontNameForPublishingMode;
    NSString *_textFontNameForEditingMode;
    NSString *_mathFontName;
    
    MHMathFontVariant _mathFontVariant;
    
    MHMathFontSystem *_mathFontSystem;
}

@property (readonly) NSFontTraitMask fontTraitMask;  // this encodes the bold, italic, underlining, strikethrough, and highlighting traits in a single bitmask

@end

@implementation MHTypingStyle


#pragma mark - Initialization

+ (instancetype)defaultStyle
{
    return [[[self class] alloc] initWithTextType:MHTypingStyleNormal];
}

+ (instancetype)defaultStyleForTextType:(MHTypingStyleTextType)textType
{
    return [[[self class] alloc] initWithTextType:textType];
}

- (instancetype)init
{
    return [self initWithTextType:MHTypingStyleNormal];
}

- (instancetype)initWithTextType:(MHTypingStyleTextType)textType
{
    if (self = [super init]) {
        // Set default values depending on the text type
        
        // Potentially useful reference:
        // https://tex.stackexchange.com/questions/203577/font-sizes-for-different-header-levels
        
        switch (textType) {
            case MHTypingStyleNormal:
                self.textForegroundColor = [NSColor blackColor];
                self.baseFontSize = 16.0;
                break;
            case MHTypingStyleHeader:
                self.textForegroundColor = [NSColor blackColor];
                self.baseFontSize = 24.0;
                self.textBold = true;
                break;
            case MHTypingStyleSubheader:
                self.textForegroundColor = [NSColor blackColor];
                self.baseFontSize = 18.0;
                self.textBold = true;
                break;
            case MHTypingStyleSubsubheader:
                self.textForegroundColor = [NSColor blackColor];
                self.baseFontSize = 16.0;
                self.textBold = true;
                break;
            case MHTypingStyleParagraphHeader:
                self.textForegroundColor = [NSColor blackColor];
                self.baseFontSize = 16.0;
                self.textBold = true;
                break;
            case MHTypingStyleSuperheader:
                self.textForegroundColor = [NSColor colorWithRed:0.75 green:0.0 blue:0.0 alpha:1.0];     // FIXME: temporary, just for testing
                self.baseFontSize = 32.0;
                self.textBold = true;
                break;
            case MHTypingStyleTextHyperlink:
                self.textForegroundColor = [NSColor colorWithRed:0.07 green:0.0 blue:0.7 alpha:1.0];
                self.baseFontSize = 16.0;
                self.textBold = true;
                break;
            case MHTypingStyleURLHyperlink:
                self.textForegroundColor = [NSColor colorWithRed:0.07 green:0.0 blue:0.7 alpha:1.0];
                self.baseFontSize = 16.0;
                self.textBold = true;
                break;
            case MHTypingStyleIntralink:
                self.textForegroundColor = [NSColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
                self.baseFontSize = 16.0;
                self.textBold = true;
                break;
        }
        
        // These values are the same for the different text types
        self.textHighlightColor = [NSColor colorWithRed:1.0 green:0.9 blue:0.57 alpha:1.0]; // FIXME: temporary, improve
        [self setTextFontName:@"Latin Modern Roman" forPresentationMode:MHExpressionPresentationModePublishing];
        [self setTextFontName:@"Latin Modern Roman" forPresentationMode:MHExpressionPresentationModeEditing];
        self.mathFontName = @"Latin Modern Math";
    }
    return self;
}



#pragma mark - Colors

- (NSColor *)textForegroundColor
{
    return (_textForegroundColor ? _textForegroundColor : [NSColor clearColor]);
}

- (void)setTextForegroundColor:(NSColor *)textForegroundColor
{
    _textForegroundColor = textForegroundColor;
}

- (NSColor * _Nullable)textHighlightColor
{
    return _textHighlightColor;
}

- (void)setTextHighlightColor:(NSColor *)textHighlightColor
{
    _textHighlightColor = textHighlightColor;
}


#pragma mark - Fonts

- (NSString *)textFontNameForPresentationMode:(MHExpressionPresentationMode)mode
{
    switch (mode) {
        case MHExpressionPresentationModePublishing:
            return _textFontNameForPublishingMode;
        case MHExpressionPresentationModeEditing:
            return _textFontNameForEditingMode;
    }
}

- (void)setTextFontName:(NSString *)fontName forPresentationMode:(MHExpressionPresentationMode)mode
{
    // test if the font exists
    if (![[NSFontManager sharedFontManager] fontWithFamily:fontName traits:0 weight:5 size:12.0]) {
//        NSLog(@"font %@ doesn't exist", fontName);
        return;
    }

    switch (mode) {
        case MHExpressionPresentationModePublishing:
            _textFontNameForPublishingMode = fontName;
            break;
        case MHExpressionPresentationModeEditing:
            _textFontNameForEditingMode = fontName;
            break;
    }
}

- (NSFont *)textFontForPresentationMode:(MHExpressionPresentationMode)mode nestingLevel:(NSUInteger)nestingLevel
{
    NSString *fontName = [self textFontNameForPresentationMode:mode];
    CGFloat fontSize = [self fontSizeForNestingLevel:nestingLevel];
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
    NSFont *fontWithTraits = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:_fontTraitMask & 0xff]; // AND'ing with a bitmask to zero out the bits in the upper bytes, which we're using to encode text highlighting, strikethrough and underlining
    return fontWithTraits;
}

- (NSString *)mathFontName
{
    return _mathFontName;
}

- (void)setMathFontName:(NSString *)mathFontName
{
//    MHMathFontSystem *newMathFontSystem = [[MHMathFontSystem alloc] initWithFontFamilyName:mathFontName];
    MHMathFontSystem *newMathFontSystem = [[MHMathFontManager defaultManager] mathFontWithName:mathFontName];
    if (newMathFontSystem) {
        _mathFontName = mathFontName;
        _mathFontSystem = newMathFontSystem;
    }
    else {
//        NSLog(@"math font %@ doesn't exist", mathFontName);
    }
}

- (MHMathFontSystem *)mathFontSystem
{
    return _mathFontSystem;
}

//- (void)setMathFontSystem:(MHMathFontSystem * _Nonnull)mathFontSystem
//{
//    _mathFontSystem = mathFontSystem;
//}

- (NSFont *)mathFontForNestingLevel:(NSUInteger)nestingLevel traits:(MHMathFontTraits)traits
{
    return [_mathFontSystem fontWithPointSize:[self fontSizeForNestingLevel:nestingLevel] traits:traits];
}

- (CGFloat)baseFontSize
{
    return _baseFontSize;
}

- (void)setBaseFontSize:(CGFloat)baseFontSize
{
    _baseFontSize = baseFontSize;
}

- (CGFloat)fontSizeForNestingLevel:(NSUInteger)nestingLevel
{
    return floorf(fmax(6.0,_baseFontSize * MHMathTypesettingDefaultNestingLevelRescalingFactors[nestingLevel]));
}

- (MHMathFontVariant)mathFontVariant
{
    return _mathFontVariant;
}

- (void)setMathFontVariant:(MHMathFontVariant)mathFontVariant
{
    _mathFontVariant = mathFontVariant;
}


#pragma mark - Font weight and style

- (NSFontTraitMask)fontTraitMask
{
    return _fontTraitMask;
}

- (bool)textBold
{
    return ((_fontTraitMask & NSBoldFontMask) != 0);
}

- (void)setTextBold:(bool)textBold
{
    if (textBold)
        _fontTraitMask |= NSBoldFontMask;
    else
        _fontTraitMask &= ~NSBoldFontMask;
}

- (bool)textItalic
{
    return ((_fontTraitMask & NSItalicFontMask) != 0);
}

- (void)setTextItalic:(bool)textItalic
{
    if (textItalic)
        _fontTraitMask |= NSItalicFontMask;
    else
        _fontTraitMask &= ~NSItalicFontMask;
}

- (bool)textUnderlining
{
    return ((_fontTraitMask & MHTypingStyleTextUnderliningMask) != 0);
}

- (void)setTextUnderlining:(bool)textUnderlining
{
    if (textUnderlining)
        _fontTraitMask |= MHTypingStyleTextUnderliningMask;
    else
        _fontTraitMask &= ~MHTypingStyleTextUnderliningMask;
}

- (bool)textStrikethrough
{
    return ((_fontTraitMask & MHTypingStyleTextStrikethroughMask) != 0);
}

- (void)setTextStrikethrough:(bool)textStrikethrough
{
    if (textStrikethrough)
        _fontTraitMask |= MHTypingStyleTextStrikethroughMask;
    else
        _fontTraitMask &= ~MHTypingStyleTextStrikethroughMask;
}

- (bool)textHighlighting
{
    return ((_fontTraitMask & MHTypingStyleTextHighlightingMask) != 0);
}

- (void)setTextHighlighting:(bool)textHighlighting
{
    if (textHighlighting)
        _fontTraitMask |= MHTypingStyleTextHighlightingMask;
    else
        _fontTraitMask &= ~MHTypingStyleTextHighlightingMask;
}

- (MHTextSubstitutionType)textSubstitutionType
{
    return _textSubstitutionType;
}

- (void)setTextSubstitutionType:(MHTextSubstitutionType)textSubstitutionType
{
    _textSubstitutionType = textSubstitutionType;
}


# pragma mark - Comparing two typing styles

- (BOOL)isEqual:(id)object
{
    if (![object isMemberOfClass:[self class]])
        return NO;

    MHTypingStyle *otherTypingStyle = object;

    NSColor *otherTypingStyleHighlightColor;

    return ([otherTypingStyle.textForegroundColor isEqual:_textForegroundColor]
            && ([(otherTypingStyleHighlightColor = otherTypingStyle.textHighlightColor) isEqual:_textHighlightColor]
                || (!otherTypingStyleHighlightColor && !_textHighlightColor))
            && [[otherTypingStyle textFontNameForPresentationMode:MHExpressionPresentationModeEditing]
            isEqualToString:_textFontNameForEditingMode]
            && [[otherTypingStyle textFontNameForPresentationMode:MHExpressionPresentationModePublishing]
            isEqualToString:_textFontNameForPublishingMode]
            && [otherTypingStyle.mathFontName isEqualToString:_mathFontName]
            && otherTypingStyle.baseFontSize == _baseFontSize
            && otherTypingStyle.fontTraitMask == _fontTraitMask);
}




# pragma mark - NSCopying protocol

- (instancetype)copyWithZone:(NSZone *)zone
{
    // FIXME: at some point maybe optimize this for speed
    MHTypingStyle *newStyle = [[[self class] alloc] init];
    newStyle.baseFontSize = self.baseFontSize;
    newStyle.textForegroundColor = self.textForegroundColor;
    newStyle.textHighlightColor = self.textHighlightColor;

    // FIXME: these four commands can be replaced by a single command to set the font trait mask (need to make the trait mask a settable property)
    newStyle.textItalic = self.textItalic;
    newStyle.textBold = self.textBold;
    newStyle.textUnderlining = self.textUnderlining;
    newStyle.textStrikethrough = self.textStrikethrough;
    newStyle.textHighlighting = self.textHighlighting;

    newStyle.mathFontVariant = self.mathFontVariant;
    newStyle.textSubstitutionType = self.textSubstitutionType;
    [newStyle setTextFontName:[self textFontNameForPresentationMode:MHExpressionPresentationModeEditing]
          forPresentationMode:MHExpressionPresentationModeEditing];
    [newStyle setTextFontName:[self textFontNameForPresentationMode:MHExpressionPresentationModePublishing]
          forPresentationMode:MHExpressionPresentationModePublishing];

    return newStyle;
}

//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %f %d"
//            ,_textForegroundColor,_textHighlightColor, _textFontNameForEditingMode, _textFontNameForPublishingMode,
//            _mathFontName, _baseFontSize, _fontTraitMask];
//}



@end
