//
//  MHMathFontSystem.h
//  MadHat
//
//  Created by Dan Romik on 11/24/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MadHat.h"

NS_ASSUME_NONNULL_BEGIN

#define kMHNumberOfNestingLevels    8   // nesting levels at or beyond this level will all be formatted with the same font size


#define kMHBracketNumberOfGlyphVariants   8
#define kMHHorizontalExtensibleSymbolNumberOfGlyphVariants   8
#define kMHRadicalNumberOfGlyphVariants   5



extern CGFloat MHMathTypesettingDefaultNestingLevelRescalingFactors[];



typedef enum {
    // These are the currently supported traits for a math font system:
    // FIXME: add other math font variants
    MHMathFontTraitRoman = 0,
    MHMathFontTraitBold = 1,
    MHMathFontTraitItalic = 2
} MHMathFontTraits;



@interface MHMathFontSystem : NSObject <NSCopying>


{
@private
    // glyph data for extensible brackets, arrows and radical signs - loaded lazily and cached, see the MHMathFontSystem+ExtensibleSymbols.m category file
    
    bool MHMathFontBracketDataPrepared;             // tells us if data for extensible vertical brackets has been loaded
    bool MHMathFontHorizontalExtensibleSymbolDataPrepared;   // tells us if data for extensible horizontal brackets and arrows has been loaded
    bool MHMathFontRadicalDataPrepared;             // tells us if data for extensible radical symbols has been loaded

    CGGlyph MHMathFontBracketGlyphs[kMHBracketNumberOfVisibleBracketTypes][2][kMHBracketNumberOfGlyphVariants];
    CGRect MHMathFontBracketGlyphBoundingBoxes[kMHBracketNumberOfVisibleBracketTypes][2][kMHBracketNumberOfGlyphVariants];
    int MHMathFontBracketGlyphAdvances[kMHBracketNumberOfVisibleBracketTypes][2][kMHBracketNumberOfGlyphVariants];

    CGGlyph MHMathFontHorizontalExtensibleSymbolGlyphs[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][kMHHorizontalExtensibleSymbolNumberOfGlyphVariants];
    CGRect MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][kMHHorizontalExtensibleSymbolNumberOfGlyphVariants];
    int MHMathFontHorizontalExtensibleSymbolGlyphAdvances[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][kMHHorizontalExtensibleSymbolNumberOfGlyphVariants];

    CGGlyph MHMathFontRadicalGlyphs[kMHBracketNumberOfGlyphVariants];
    CGRect MHMathFontRadicalGlyphBoundingBoxes[kMHRadicalNumberOfGlyphVariants];
    int MHMathFontRadicalGlyphAdvances[kMHRadicalNumberOfGlyphVariants];

    CGGlyph MHMathFontRadicalExtensibleMainPartGlyph;
    CGGlyph MHMathFontRadicalExtensibleExtensionPartGlyph;

    CGRect MHMathFontRadicalExtensibleMainPartBoundingBox;
    CGRect MHMathFontRadicalExtensibleExtensionPartBoundingBox;

    int MHMathFontRadicalExtensibleMainPartAdvance;
    int MHMathFontRadicalExtensibleExtensionPartAdvance;

    int MHMathFontUnitsPerEm;
}



// Serialization
- (NSString *)serializedStringRepresentation;
+ (instancetype)fontFamilyFromSerializedStringRepresentation:(NSString *)string;




@property (readonly) NSString *fontFamilyName;
@property short int mathAxisHeight;         // measured in thousandths of an em width
@property short int fractionLineThickness;  // measured in thousandths of an em width
@property (readonly) short int *mathKerningMatrix;  // a two-dimensional array of MHTypographyNumberOfClasses by MHTypographyNumberOfClasses values, measured in thousandths of an em width
@property (readonly) short int *nestingLevelMathTrackingFactors;   // an array of kMHNumberOfNestingLevels values, one for each possible nesting level, measured in one thousandths of a unit


// examples of valid family names: "Helvetica", "Times", "Palatino", "CMU Serif"
- (instancetype)initWithFontFamilyName:(NSString *)familyName;


- (NSFont *)fontWithPointSize:(CGFloat)pointSize traits:(MHMathFontTraits)traits;

- (short int)kernWidthForLeftTypographyClass:(MHTypographyClass)leftClass rightTypographyClass:(MHTypographyClass)rightClass; // measured in thousandths of an em width




@end

NS_ASSUME_NONNULL_END
