//
//  MHMathFontSystem+ExtensibleSymbols.m
//  MadHat
//
//  Created by Dan Romik on 7/12/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHMathFontSystem+ExtensibleSymbols.h"

#import <AppKit/AppKit.h>


// Definitions for extensible brackets

NSString * const kMHMathFontSystemExtensibleBracketVariantGlyphNames[kMHBracketNumberOfVisibleBracketTypes][2][kMHBracketNumberOfGlyphVariants] = {
    {
        { @"parenleft", @"parenleft.v1", @"parenleft.v2", @"parenleft.v3", @"parenleft.v4", @"parenleft.v5", @"parenleft.v6", @"parenleft.v7" },   // left parenthesis
        { @"parenright", @"parenright.v1", @"parenright.v2", @"parenright.v3", @"parenright.v4", @"parenright.v5", @"parenright.v6", @"parenright.v7" },       // right parenthesis
    },
    {
        { @"bracketleft", @"bracketleft.v1", @"bracketleft.v2", @"bracketleft.v3", @"bracketleft.v4", @"bracketleft.v5", @"bracketleft.v6", @"bracketleft.v7" },     // left square bracket
        { @"bracketright", @"bracketright.v1", @"bracketright.v2", @"bracketright.v3", @"bracketright.v4", @"bracketright.v5", @"bracketright.v6", @"bracketright.v7" },   // right square bracket
    },
    {
        { @"uni230A", @"uni230A.v1", @"uni230A.v2", @"uni230A.v3", @"uni230A.v4", @"uni230A.v5", @"uni230A.v6", @"uni230A.v7" },    // left floor
        { @"uni230B", @"uni230B.v1", @"uni230B.v2", @"uni230B.v3", @"uni230B.v4", @"uni230B.v5", @"uni230B.v6", @"uni230B.v7" },    // right floor
    },
    {
        { @"uni2308", @"uni2308.v1", @"uni2308.v2", @"uni2308.v3", @"uni2308.v4", @"uni2308.v5", @"uni2308.v6", @"uni2308.v7" },    // left ceiling
        { @"uni2309", @"uni2309.v1", @"uni2309.v2", @"uni2309.v3", @"uni2309.v4", @"uni2309.v5", @"uni2309.v6", @"uni2309.v7" },    // right ceiling
    },
    {
        { @"bar", @"bar", @"bar", @"bar", @"bar", @"bar", @"bar", @"bar" },   // left vertical bar
        { @"bar", @"bar", @"bar", @"bar", @"bar", @"bar", @"bar", @"bar" },   // right vertical bar
    },
    {
        { @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar" },     // left double vertical bar
        { @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar", @"dblverticalbar" },     // right double vertical bar
    },
    {
        { @"braceleft", @"braceleft.v1", @"braceleft.v2", @"braceleft.v3", @"braceleft.v4", @"braceleft.v5", @"braceleft.v6", @"braceleft.v7" },                       // left curly brace
        { @"braceright", @"braceright.v1", @"braceright.v2", @"braceright.v3", @"braceright.v4", @"braceright.v5", @"braceright.v6", @"braceright.v7" },    // right curly brace
    },
    {
        { @"uni27E8", @"uni27E8.v1", @"uni27E8.v2", @"uni27E8.v3", @"uni27E8.v4", @"uni27E8.v5", @"uni27E8.v6", @"uni27E8.v7" }, // left angle brace
        { @"uni27E9", @"uni27E9.v1", @"uni27E9.v2", @"uni27E9.v3", @"uni27E9.v4", @"uni27E9.v5", @"uni27E9.v6", @"uni27E9.v7" }, // right angle brace
    }
};

NSString * const kMHMathFontSystemExtensibleBracketPartsGlyphNames[kMHBracketNumberOfVisibleBracketTypes][2][4] = {
    {
        { @"uni239D", @"uni239B", @"uni239C" },    // left parenthesis (lower hook, upper hook, extension piece)
        { @"uni23A0", @"uni239E", @"uni239F" }     // right parenthesis (lower hook, upper hook, extension piece)
    },
    {
        { @"uni23A3", @"uni23A1", @"uni23A2" },    // left square brace (lower hook, upper hook, extension piece)
        { @"uni23A6", @"uni23A4", @"uni23A5" }     // right square brace (lower hook, upper hook, extension piece)
    },
    {
        { @"uni23A3", nil, @"uni23A2" },    // left floor (lower hook, nil, extension piece)
        { @"uni23A6", nil, @"uni23A5" }     // right floor (lower hook, nil, extension piece)
    },
    {
        { nil, @"uni23A1", @"uni23A2" },    // left ceiling (nil, upper hook, extension piece)
        { nil, @"uni23A4", @"uni23A5" }     // right ceiling (nil, upper hook, extension piece)
    },
    {
        { nil, nil, @"uni23D0" },    // left vertical bar (nil, nil, extension piece)
        { nil, nil, @"uni23D0" }     // right vertical bar (nil, nil, extension piece)
    },
    {
        { nil, nil, @"dblverticalbar" },    // left double vertical bar (nil, nil, extension piece)
        { nil, nil, @"dblverticalbar" },    // right double vertical bar (nil, nil, extension piece)
    },
    {
        { @"uni23A9", @"uni23A7", @"uni23AA", @"uni23A8" },    // left curly brace (lower hook, upper hook, extension piece, middle piece)
        { @"uni23AD", @"uni23AB", @"uni23AA", @"uni23AC" }     // right curly brace (lower hook, upper hook, extension piece, middle piece)
    },
    {
        { nil, nil, nil, nil },
        { nil, nil, nil, nil }
    }
};



// Definitions for horizontal extensible symbols

NSString * const kMHMathFontSystemExtensibleHorizontalExtensibleSymbolVariantGlyphNames[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][kMHHorizontalExtensibleSymbolNumberOfGlyphVariants] = {
    { @"uni23DE", @"uni23DE.h1", @"uni23DE.h2", @"uni23DE.h3", @"uni23DE.h4", @"uni23DE.h5", @"uni23DE.h6", @"uni23DE.h7" },     // top curly brace
    { @"uni23DF", @"uni23DF.h1", @"uni23DF.h2", @"uni23DF.h3", @"uni23Df.h4", @"uni23DF.h5", @"uni23DF.h6", @"uni23DF.h7" },   // right curly brace
    { @"uni23B4", @"uni23B4.h1", @"uni23B4.h2", @"uni23B4.h3", @"uni23B4.h4", @"uni23B4.h5", @"uni23B4.h6", @"uni23B4.h7" },   // top square bracket
    { @"uni23B5", @"uni23B5.h1", @"uni23B5.h2", @"uni23B5.h3", @"uni23B5.h4", @"uni23B5.h5", @"uni23B5.h6", @"uni23B5.h7" },    // bottom square bracket
    { @"uni23DC", @"uni23DC.h1", @"uni23DC.h2", @"uni23DC.h3", @"uni23DC.h4", @"uni23DC.h5", @"uni23DC.h6", @"uni23DC.h7" },   // top parenthesis
    { @"uni23DD", @"uni23DD.h1", @"uni23DD.h2", @"uni23DD.h3", @"uni23DD.h4", @"uni23DD.h5", @"uni23DD.h6", @"uni23DD.h7" },    // bottom parenthesis
    { @"uni23E0", @"uni23E0.h1", @"uni23E0.h2", @"uni23E0.h3", @"uni23E0.h4", @"uni23E0.h5", @"uni23E0.h6", @"uni23E0.h7" },   // top tortoise shell bracket
    { @"uni23E1", @"uni23E1.h1", @"uni23E1.h2", @"uni23E1.h3", @"uni23E1.h4", @"uni23E1.h5", @"uni23E1.h6", @"uni23E1.h7" },    // bottom tortoise shell bracket
    { @"equal", nil, nil, nil, nil, nil, nil, nil },  // extensible equal sign (U+003D)
    { @"arrowright", nil, nil, nil, nil, nil, nil, nil },  // extensible right arrow (U+2192)
    { @"arrowdblright", nil, nil, nil, nil, nil, nil, nil },  // extensible double right arrow (U+21D2)
    { @"arrowleft", nil, nil, nil, nil, nil, nil, nil },  // extensible left arrow (U+2190)
    { @"arrowdblright", nil, nil, nil, nil, nil, nil, nil },  // extensible double left arrow (U+21D0)
    { @"arrowboth", nil, nil, nil, nil, nil, nil, nil },  // extensible left-right arrow (U+2194)
    { @"arrowdblboth", nil, nil, nil, nil, nil, nil, nil },  // extensible double left-right arrow (U+21D4)
};


NSString * const kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][4] = {
    { @"uni23DE.lft", @"uni23DE.rt", @"uni23DE.ex", @"uni23DE.md" },    // top curly brace (left hook, right hook, extension piece, middle piece)
    { @"uni23DF.lft", @"uni23DF.rt", @"uni23DF.ex", @"uni23DF.md" },     // bottom curly brace (left hook, right hook, extension piece, middle piece)
    { @"uni23B4.lft", @"uni23B4.rt", @"uni23B4.ex" },    // top square bracket (left hook, right hook, extension piece)
    { @"uni23B5.lft", @"uni23B5.rt", @"uni23B5.ex" },    // bottom square bracket (left hook, right hook, extension piece)
    { @"uni23DC.lft", @"uni23DC.rt", @"uni23DC.ex" },    // top parenthesis (left hook, right hook, extension piece)
    { @"uni23DD.lft", @"uni23DD.rt", @"uni23DD.ex" },     // bottom parenthesis (left hook, right hook, extension piece)
    { @"uni23E0.lft", @"uni23E0.rt", @"uni23E0.ex" },    // top tortoise shell bracket (left hook, right hook, extension piece)
    { @"uni23E1.lft", @"uni23E1.rt", @"uni23E1.ex" },     // bottom tortoise shell bracket (left hook, right hook, extension piece)
    { @"equal.lft", @"equal.rt", @"equal.ex" },  // extensible equal sign (nil, right endpiece, extension piece), U+003D
    { @"arrowright.lft", @"arrowright.rt", @"arrowright.ex" },  // extensible right arrow (nil, right endpiece, extension piece), U+2192
    { @"arrowdblright.lft", @"arrowdblright.rt", @"arrowdblright.ex" },  // extensible double right arrow (nil, right endpiece, extension piece), U+21D2
    { @"arrowleft.lft", @"arrowleft.rt", @"arrowleft.ex" },  // extensible left arrow (nil, right endpiece, extension piece), U+2192
    { @"arrowdblleft.lft", @"arrowdblleft.rt", @"arrowdblleft.ex" },  // extensible double left arrow (nil, right endpiece, extension piece), U+21D0
    { @"arrowboth.lft", @"arrowboth.rt", @"arrowboth.ex" },  // extensible left-right arrow (nil, right endpiece, extension piece), U+2194
    { @"arrowdblboth.lft", @"arrowdblboth.rt", @"arrowdblboth.ex" }  // extensible double left-right arrow (nil, right endpiece, extension piece), U+21D4
};




// Definitions for extensible radical signs

NSString * const kMHMathFontSystemExtensibleRadicalVariantGlyphNames[kMHRadicalNumberOfGlyphVariants] = {
    @"radical", @"radical.v1", @"radical.v2", @"radical.v3", @"radical.v4"
};
NSString * const kMHMathFontSystemExtensibleRadicalMainPart = @"uni23B7";
NSString * const kMHMathFontSystemExtensibleRadicalVerticalExtensionPart = @"radical.ex";






@implementation MHMathFontSystem (ExtensibleSymbols)





#pragma mark - Extensible brackets

// FIXME: it's illogical for this method to need the font size - improve
- (void)lazilyLoadBracketGlyphDataWithPointSize:(CGFloat)pointSize
{
    // lazily retrieve the bounding boxes of all bracket glyph variants in the current font
    
    NSFont *mathFont = [self fontWithPointSize:pointSize traits:MHMathFontTraitRoman];
    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)mathFont, nil);
    MHMathFontUnitsPerEm = CGFontGetUnitsPerEm(cgFont);
    
    int bracTypeInd, orientationInd, variantInd;
    for (bracTypeInd = 0; bracTypeInd < kMHBracketNumberOfVisibleBracketTypes; bracTypeInd++) {
        for (orientationInd = 0; orientationInd < 2; orientationInd++) {
            for (variantInd = 0; variantInd < kMHBracketNumberOfGlyphVariants; variantInd++) {
                MHMathFontBracketGlyphs[bracTypeInd][orientationInd][variantInd] =
                CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)(kMHMathFontSystemExtensibleBracketVariantGlyphNames[bracTypeInd][orientationInd][variantInd]));
                
                // FIXME: this line can be moved outside the innermost loop so the "1" becomes an "8" ?
                CGFontGetGlyphBBoxes(cgFont, &(MHMathFontBracketGlyphs[bracTypeInd][orientationInd][variantInd]), 1, &(MHMathFontBracketGlyphBoundingBoxes[bracTypeInd][orientationInd][variantInd]));
                
                CGFontGetGlyphAdvances(cgFont, &(MHMathFontBracketGlyphs[bracTypeInd][orientationInd][variantInd]), 1, &(MHMathFontBracketGlyphAdvances[bracTypeInd][orientationInd][variantInd]));
            }
        }
    }
    CGFontRelease(cgFont);
    MHMathFontBracketDataPrepared = true;
}

- (NSString *)glyphNameForBracketOfType:(MHBracketType)bracketType
                            orientation:(MHBracketOrientation)bracketOrientation
        forEnclosingHeightAboveMathAxis:(CGFloat)height
                          withPointSize:(CGFloat)pointSize
                          getDimensions:(MHDimensions *)dimensionsPtr
{
    int variantInd;
    if (!MHMathFontBracketDataPrepared)
        [self lazilyLoadBracketGlyphDataWithPointSize:pointSize];
    
    // See page 152 of The TeXBook for an explanation of the idea behind these definitions
    static CGFloat delimiterShortfall = 5.0;
    static CGFloat delimiterFactor = 0.9;
    
    CGFloat twiceHeightInFontUnits =  height / pointSize * (CGFloat)(2 * MHMathFontUnitsPerEm);
    CGFloat delimiterShortfallInFontUnits = delimiterShortfall / pointSize * (CGFloat)MHMathFontUnitsPerEm;

    for (variantInd = 0; variantInd < kMHBracketNumberOfGlyphVariants; variantInd++) {
        if ((MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].size.height
            >= twiceHeightInFontUnits - delimiterShortfallInFontUnits
            && MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].size.height >= delimiterFactor*twiceHeightInFontUnits) ||
            (bracketType == MHBracketTypeAngleBrace && variantInd==kMHBracketNumberOfGlyphVariants-1)) {
                // for angle brackets, if the largest size isn't tall enough we still return it
            (*dimensionsPtr).width =
            MHMathFontBracketGlyphAdvances[bracketType][bracketOrientation][variantInd] / (CGFloat)MHMathFontUnitsPerEm * pointSize;
//            (bracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].origin.x
//             +bracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
            (*dimensionsPtr).depth =
            -MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            (*dimensionsPtr).height =
            (MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].origin.y +
            MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            return kMHMathFontSystemExtensibleBracketVariantGlyphNames[bracketType][bracketOrientation][variantInd];
        }
    }
    
    // for angle brackets, if the largest size isn't tall enough we still return it
    if (bracketType == MHBracketTypeAngleBrace)
        return kMHMathFontSystemExtensibleBracketVariantGlyphNames[MHBracketTypeAngleBrace][bracketOrientation][kMHBracketNumberOfGlyphVariants-1];

    // For other bracket types we return nil, which will trigger the algorithm for generating an extensible bracket
    return nil;
}


// FIXME: finish this
- (NSString *)glyphNameForBracketOfType:(MHBracketType)bracketType
                            orientation:(MHBracketOrientation)bracketOrientation
                           variantLevel:(NSUInteger)level
                          withPointSize:(CGFloat)pointSize
                          getDimensions:(MHDimensions *)dimensionsPtr
{
    if (!MHMathFontBracketDataPrepared)
        [self lazilyLoadBracketGlyphDataWithPointSize:pointSize];

    NSUInteger actualLevel = level;
    if (actualLevel < 1)
        actualLevel = 1;
    if (actualLevel > kMHBracketNumberOfGlyphVariants)
        actualLevel = kMHBracketNumberOfGlyphVariants;
    
    NSUInteger variantInd = actualLevel-1;
    (*dimensionsPtr).width =
    MHMathFontBracketGlyphAdvances[bracketType][bracketOrientation][variantInd] / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*dimensionsPtr).depth =
    -MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*dimensionsPtr).height =
    (MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].origin.y +
    MHMathFontBracketGlyphBoundingBoxes[bracketType][bracketOrientation][variantInd].size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    return kMHMathFontSystemExtensibleBracketVariantGlyphNames[bracketType][bracketOrientation][variantInd];
}


- (void)getExtensibleBracketPartsOfType:(MHBracketType)bracketType
                            orientation:(MHBracketOrientation)bracketOrientation
                          withPointSize:(CGFloat)pointSize
                  getLowerHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)lowerHookGlyphNamePtr
                 getLowerHookDimensions:(MHDimensions *)lowerHookDimensionsPtr
                  getUpperHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)upperHookGlyphNamePtr
                 getUpperHookDimensions:(MHDimensions *)upperHookDimensionsPtr
             getExtensionPieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)extensionPieceGlyphNamePtr
            getExtensionPieceDimensions:(MHDimensions *)extensionPieceDimensionsPtr
                getMiddlePieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)middlePieceGlyphNamePtr
               getMiddlePieceDimensions:(MHDimensions *)middlePieceDimensionsPtr
{
    static bool bracketExtensionPartsDataPrepared;
    static CGGlyph bracketPartGlyphs[kMHBracketNumberOfVisibleBracketTypes][2][4];
    static CGRect bracketPartGlyphBoundingBoxes[kMHBracketNumberOfVisibleBracketTypes][2][4];
    static int bracketPartGlyphAdvances[kMHBracketNumberOfVisibleBracketTypes][2][4];
    static int fontUnitsPerEm;
    
    if (!bracketExtensionPartsDataPrepared) {
        // lazily retrieve the bounding boxes of all bracket glyph variants in the current font
        
        NSFont *mathFont = [self fontWithPointSize:pointSize traits:MHMathFontTraitRoman];
        CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)mathFont, nil);
        fontUnitsPerEm = CGFontGetUnitsPerEm(cgFont);
        
        int bracTypeInd, orientationInd, partInd;
        for (bracTypeInd = 0; bracTypeInd < kMHBracketNumberOfVisibleBracketTypes; bracTypeInd++) {
            for (orientationInd = 0; orientationInd < 2; orientationInd++) {
                for (partInd = 0; partInd < 4; partInd++) {
                    if (kMHMathFontSystemExtensibleBracketPartsGlyphNames[bracTypeInd][orientationInd][partInd]) {
                        bracketPartGlyphs[bracTypeInd][orientationInd][partInd] =
                        CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)(kMHMathFontSystemExtensibleBracketPartsGlyphNames[bracTypeInd][orientationInd][partInd]));
                    
                        // FIXME: this line can be moved outside the innermost loop so the "1" becomes an "8" ?
                        CGFontGetGlyphBBoxes(cgFont, &(bracketPartGlyphs[bracTypeInd][orientationInd][partInd]), 1, &(bracketPartGlyphBoundingBoxes[bracTypeInd][orientationInd][partInd]));
                        
                        CGFontGetGlyphAdvances(cgFont, &(bracketPartGlyphs[bracTypeInd][orientationInd][partInd]), 1, &(bracketPartGlyphAdvances[bracTypeInd][orientationInd][partInd]));
                    }
                }
            }
        }
        CGFontRelease(cgFont);
        bracketExtensionPartsDataPrepared = true;
    }
    
    MHBracketType effectiveBracketType = (bracketType < kMHBracketNumberOfVisibleBracketTypes ? bracketType :
                                                    MHBracketTypeParenthesis);

    *lowerHookGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleBracketPartsGlyphNames[effectiveBracketType][bracketOrientation][0];
    *upperHookGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleBracketPartsGlyphNames[effectiveBracketType][bracketOrientation][1];
    *extensionPieceGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleBracketPartsGlyphNames[effectiveBracketType][bracketOrientation][2];
    *middlePieceGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleBracketPartsGlyphNames[effectiveBracketType][bracketOrientation][3];
    
    // Compute the bounding boxes in points
    if (*lowerHookGlyphNamePtr) {
        (*lowerHookDimensionsPtr).width =
        bracketPartGlyphAdvances[effectiveBracketType][bracketOrientation][0] / (CGFloat)fontUnitsPerEm * pointSize;
//        (bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][0].origin.x
//         +bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][0].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
        (*lowerHookDimensionsPtr).depth =
        -bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][0].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*lowerHookDimensionsPtr).height =
        (bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][0].origin.y +
        bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][0].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }

    if (*upperHookGlyphNamePtr) {
        (*upperHookDimensionsPtr).width =
        bracketPartGlyphAdvances[effectiveBracketType][bracketOrientation][1] / (CGFloat)fontUnitsPerEm * pointSize;
//        (bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][1].origin.x
//        +bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][1].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
        (*upperHookDimensionsPtr).depth =
        -bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][1].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*upperHookDimensionsPtr).height =
        (bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][1].origin.y +
        bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][1].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }
    
    if (*extensionPieceGlyphNamePtr) {
        (*extensionPieceDimensionsPtr).width =
        bracketPartGlyphAdvances[effectiveBracketType][bracketOrientation][2] / (CGFloat)fontUnitsPerEm * pointSize;
//        (bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][2].origin.x
//        +bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][2].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
        (*extensionPieceDimensionsPtr).depth =
        -bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][2].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*extensionPieceDimensionsPtr).height =
        (bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][2].origin.y +
        bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][2].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }

    if (*middlePieceGlyphNamePtr) {
        (*middlePieceDimensionsPtr).width =
        bracketPartGlyphAdvances[effectiveBracketType][bracketOrientation][3] / (CGFloat)fontUnitsPerEm * pointSize;
//        (bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][3].origin.x
//        +bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][3].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
        (*middlePieceDimensionsPtr).depth =
        -bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][3].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*middlePieceDimensionsPtr).height =
        (bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][3].origin.y +
        bracketPartGlyphBoundingBoxes[effectiveBracketType][bracketOrientation][3].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }
}




#pragma mark - Horizontal extensible symbols

- (void)lazilyLoadHorizontalExtensibleSymbolGlyphDataWithPointSize:(CGFloat)pointSize
{
    // lazily retrieve the bounding boxes of all bracket glyph variants in the current font
    
    NSFont *mathFont = [self fontWithPointSize:pointSize traits:MHMathFontTraitRoman];
    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)mathFont, nil);
    MHMathFontUnitsPerEm = CGFontGetUnitsPerEm(cgFont);
    
    int bracTypeInd, variantInd;
    for (bracTypeInd = 0; bracTypeInd < kMHHorizontalExtensibleSymbolNumberOfSymbolTypes; bracTypeInd++) {
        for (variantInd = 0; variantInd < kMHHorizontalExtensibleSymbolNumberOfGlyphVariants; variantInd++) {
            if (kMHMathFontSystemExtensibleHorizontalExtensibleSymbolVariantGlyphNames[bracTypeInd][variantInd]) {
                MHMathFontHorizontalExtensibleSymbolGlyphs[bracTypeInd][variantInd] =
                CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)(kMHMathFontSystemExtensibleHorizontalExtensibleSymbolVariantGlyphNames[bracTypeInd][variantInd]));
                // FIXME: this line can be moved outside the innermost loop so the "1" becomes an "8" ?
                CGFontGetGlyphBBoxes(cgFont, &(MHMathFontHorizontalExtensibleSymbolGlyphs[bracTypeInd][variantInd]), 1, &(MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracTypeInd][variantInd]));
                CGFontGetGlyphAdvances(cgFont, &(MHMathFontHorizontalExtensibleSymbolGlyphs[bracTypeInd][variantInd]), 1, &(MHMathFontHorizontalExtensibleSymbolGlyphAdvances[bracTypeInd][variantInd]));
            }
        }
    }
    CGFontRelease(cgFont);
    MHMathFontHorizontalExtensibleSymbolDataPrepared = true;
}

- (NSString *)glyphNameForHorizontalExtensibleSymbolOfType:(MHHorizontalExtensibleSymbolType)bracketType
                                forEnclosingWidth:(CGFloat)width
                                    withPointSize:(CGFloat)pointSize
                                    getDimensions:(MHDimensions *)dimensionsPtr
{
    int variantInd;
    if (!MHMathFontHorizontalExtensibleSymbolDataPrepared)
        [self lazilyLoadHorizontalExtensibleSymbolGlyphDataWithPointSize:pointSize];
    
    // FIXME: the delimiter shortfall code is for vertical brackets - do we need it for horizontal extensible symbols?
    // See page 152 of The TeXBook for an explanation of the idea behind these definitions
    static CGFloat delimiterShortfall = -8.0; //5.0; // FIXME: Temporary values - improve
    static CGFloat delimiterFactor = 1.0; //0.9;
    
    CGFloat widthInFontUnits =  width / pointSize * (CGFloat)(MHMathFontUnitsPerEm);
    CGFloat delimiterShortfallInFontUnits = delimiterShortfall / pointSize * (CGFloat)MHMathFontUnitsPerEm;
    
    for (variantInd = 0; variantInd < kMHHorizontalExtensibleSymbolNumberOfGlyphVariants; variantInd++) {
        
        if (MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracketType][variantInd].size.width
            >= widthInFontUnits - delimiterShortfallInFontUnits
            && MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracketType][variantInd].size.width >= delimiterFactor*widthInFontUnits) {
            (*dimensionsPtr).width =
            MHMathFontHorizontalExtensibleSymbolGlyphAdvances[bracketType][variantInd] / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            (*dimensionsPtr).depth =
            -MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracketType][variantInd].origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            (*dimensionsPtr).height =
            (MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracketType][variantInd].origin.y +
            MHMathFontHorizontalExtensibleSymbolGlyphBoundingBoxes[bracketType][variantInd].size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            return kMHMathFontSystemExtensibleHorizontalExtensibleSymbolVariantGlyphNames[bracketType][variantInd];
        }
    }
    
    // If we got this far it means the standard bracket glyph variants aren't big enough, so return nil, which will trigger the algorithm for generating an extensible bracket
    return nil;
}

- (void)getExtensibleHorizontalExtensibleSymbolPartsOfType:(MHHorizontalExtensibleSymbolType)bracketType
                                    withPointSize:(CGFloat)pointSize
                             getLeftHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)leftHookGlyphNamePtr
                            getLeftHookDimensions:(MHDimensions *)leftHookDimensionsPtr
                            getRightHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)rightHookGlyphNamePtr
                           getRightHookDimensions:(MHDimensions *)rightHookDimensionsPtr
                       getExtensionPieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)extensionPieceGlyphNamePtr
                      getExtensionPieceDimensions:(MHDimensions *)extensionPieceDimensionsPtr
                          getMiddlePieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)middlePieceGlyphNamePtr
                         getMiddlePieceDimensions:(MHDimensions *)middlePieceDimensionsPtr
{
    static bool horizontalExtensibleSymbolExtensionPartsDataPrepared;
    static CGGlyph horizontalExtensibleSymbolPartGlyphs[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][4];
    static CGRect horizontalExtensibleSymbolPartGlyphBoundingBoxes[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][4];
    static int horizontalExtensibleSymbolPartGlyphAdvances[kMHHorizontalExtensibleSymbolNumberOfSymbolTypes][4];
    static int fontUnitsPerEm;
    
    if (!horizontalExtensibleSymbolExtensionPartsDataPrepared) {
        // lazily retrieve the bounding boxes of all bracket glyph variants in the current font
        
        NSFont *mathFont = [self fontWithPointSize:pointSize traits:MHMathFontTraitRoman];
        CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)mathFont, nil);
        fontUnitsPerEm = CGFontGetUnitsPerEm(cgFont);
        
        int bracTypeInd, partInd;
        for (bracTypeInd = 0; bracTypeInd < kMHHorizontalExtensibleSymbolNumberOfSymbolTypes; bracTypeInd++) {
            for (partInd = 0; partInd < 4; partInd++) {
                if (kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[bracTypeInd][partInd]) {
                    
                    horizontalExtensibleSymbolPartGlyphs[bracTypeInd][partInd] =
                    CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)(kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[bracTypeInd][partInd]));
                
                    // FIXME: this line can be moved outside the innermost loop so the "1" becomes an "8" ?
                    CGFontGetGlyphBBoxes(cgFont, &(horizontalExtensibleSymbolPartGlyphs[bracTypeInd][partInd]), 1, &(horizontalExtensibleSymbolPartGlyphBoundingBoxes[bracTypeInd][partInd]));
                    
                    CGFontGetGlyphAdvances(cgFont, &(horizontalExtensibleSymbolPartGlyphs[bracTypeInd][partInd]), 1, &(horizontalExtensibleSymbolPartGlyphAdvances[bracTypeInd][partInd]));
                }
            }
        }
        CGFontRelease(cgFont);
        horizontalExtensibleSymbolExtensionPartsDataPrepared = true;
    }
    
    MHHorizontalExtensibleSymbolType effectiveBracketType = (bracketType < kMHHorizontalExtensibleSymbolNumberOfSymbolTypes ? bracketType :
                                                    MHHorizontalExtensibleSymbolOverbrace);  // Just for safety - make sure we use a legal bracket type

    *leftHookGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[effectiveBracketType][0];
    *rightHookGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[effectiveBracketType][1];
    *extensionPieceGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[effectiveBracketType][2];
    *middlePieceGlyphNamePtr = (NSString *)kMHMathFontSystemExtensibleHorizontalExtensibleSymbolPartsGlyphNames[effectiveBracketType][3];
    
    // Compute the bounding boxes in points
    if (*leftHookGlyphNamePtr) {
        (*leftHookDimensionsPtr).width =
        horizontalExtensibleSymbolPartGlyphAdvances[effectiveBracketType][0] / (CGFloat)fontUnitsPerEm * pointSize;
//        (bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][0].origin.x
//         +bracketPartGlyphBoundingBoxes[bracketType][bracketOrientation][0].size.width) / (CGFloat)fontUnitsPerEm * pointSize;
        (*leftHookDimensionsPtr).depth =
        -horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][0].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*leftHookDimensionsPtr).height =
        (horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][0].origin.y +
        horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][0].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }

    if (*rightHookGlyphNamePtr) {
        (*rightHookDimensionsPtr).width =
        horizontalExtensibleSymbolPartGlyphAdvances[effectiveBracketType][1] / (CGFloat)fontUnitsPerEm * pointSize;
        (*rightHookDimensionsPtr).depth =
        -horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][1].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*rightHookDimensionsPtr).height =
        (horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][1].origin.y +
        horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][1].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }
    
    if (*extensionPieceGlyphNamePtr) {
        (*extensionPieceDimensionsPtr).width =
        horizontalExtensibleSymbolPartGlyphAdvances[effectiveBracketType][2] / (CGFloat)fontUnitsPerEm * pointSize;
        (*extensionPieceDimensionsPtr).depth =
        -horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][2].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*extensionPieceDimensionsPtr).height =
        (horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][2].origin.y +
        horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][2].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }

    if (*middlePieceGlyphNamePtr) {
        (*middlePieceDimensionsPtr).width =
        horizontalExtensibleSymbolPartGlyphAdvances[effectiveBracketType][3] / (CGFloat)fontUnitsPerEm * pointSize;
        (*middlePieceDimensionsPtr).depth =
        -horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][3].origin.y / (CGFloat)fontUnitsPerEm * pointSize;
        (*middlePieceDimensionsPtr).height =
        (horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][3].origin.y +
        horizontalExtensibleSymbolPartGlyphBoundingBoxes[effectiveBracketType][3].size.height) / (CGFloat)fontUnitsPerEm * pointSize;
    }
}




#pragma mark - Extensible radical signs


// FIXME: it's illogical for this method to need the font size - improve
- (void)lazilyLoadRadicalGlyphDataWithPointSize:(CGFloat)pointSize
{
    // lazily retrieve the bounding boxes of all bracket glyph variants in the current font
    
    NSFont *mathFont = [self fontWithPointSize:pointSize traits:MHMathFontTraitRoman];
    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)mathFont, nil);
    MHMathFontUnitsPerEm = CGFontGetUnitsPerEm(cgFont);
    
    // Get the glyph, bounding box and glyph advance for the standard radical sign glyph variants
    int variantInd;
    for (variantInd = 0; variantInd < kMHRadicalNumberOfGlyphVariants; variantInd++) {
        MHMathFontRadicalGlyphs[variantInd] =
        CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)(kMHMathFontSystemExtensibleRadicalVariantGlyphNames[variantInd]));
        
        // FIXME: this line can be moved outside the innermost loop so the "1" becomes a "5" ?
        CGFontGetGlyphBBoxes(cgFont, &(MHMathFontRadicalGlyphs[variantInd]), 1, &(MHMathFontRadicalGlyphBoundingBoxes[variantInd]));
        
        CGFontGetGlyphAdvances(cgFont, &(MHMathFontRadicalGlyphs[variantInd]), 1, &(MHMathFontRadicalGlyphAdvances[variantInd]));
    }
    
    // Get the glyph, bounding box and glyph advance for the extensible radical sign and the vertical extension piece
    MHMathFontRadicalExtensibleMainPartGlyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)kMHMathFontSystemExtensibleRadicalMainPart);
    CGFontGetGlyphBBoxes(cgFont, &MHMathFontRadicalExtensibleMainPartGlyph, 1, &MHMathFontRadicalExtensibleMainPartBoundingBox);
    CGFontGetGlyphAdvances(cgFont, &MHMathFontRadicalExtensibleMainPartGlyph, 1, &MHMathFontRadicalExtensibleMainPartAdvance);

    MHMathFontRadicalExtensibleExtensionPartGlyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)kMHMathFontSystemExtensibleRadicalVerticalExtensionPart);
    CGFontGetGlyphBBoxes(cgFont, &MHMathFontRadicalExtensibleExtensionPartGlyph, 1, &MHMathFontRadicalExtensibleExtensionPartBoundingBox);
    CGFontGetGlyphAdvances(cgFont, &MHMathFontRadicalExtensibleExtensionPartGlyph, 1, &MHMathFontRadicalExtensibleExtensionPartAdvance);


    CGFontRelease(cgFont);
    MHMathFontRadicalDataPrepared = true;
}


- (NSString *)glyphNameForRadicalSignEnclosingTotalHeight:(CGFloat)totalHeight
                                            withPointSize:(CGFloat)pointSize
                                            getDimensions:(MHDimensions *)dimensionsPtr
{
    int variantInd;
    if (!MHMathFontRadicalDataPrepared)
        [self lazilyLoadRadicalGlyphDataWithPointSize:pointSize];
    
    CGFloat heightInFontUnits =  totalHeight / pointSize * (CGFloat)(MHMathFontUnitsPerEm);

    CGFloat bodyTopPadding = 1/10.0 * (CGFloat)(MHMathFontUnitsPerEm);   // FIXME: make this a font parameter that can be adjusted
        
    for (variantInd = 0; variantInd < kMHRadicalNumberOfGlyphVariants; variantInd++) {
        if (MHMathFontRadicalGlyphBoundingBoxes[variantInd].size.height >= heightInFontUnits + bodyTopPadding) {
            (*dimensionsPtr).width =
            MHMathFontRadicalGlyphAdvances[variantInd] / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            (*dimensionsPtr).depth =
            -MHMathFontRadicalGlyphBoundingBoxes[variantInd].origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            (*dimensionsPtr).height =
            (MHMathFontRadicalGlyphBoundingBoxes[variantInd].origin.y +
            MHMathFontRadicalGlyphBoundingBoxes[variantInd].size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;
            return kMHMathFontSystemExtensibleRadicalVariantGlyphNames[variantInd];
        }
    }
    
    // The total height is too big for any of the fixed-height glyphs, so we return nil, which will trigger the algorithm for generating an extensible radical
    return nil;
}


- (void)getExtensibleRadicalPartsWithPointSize:(CGFloat)pointSize
                          getMainPartGlyphName:(NSString * _Null_unspecified * _Null_unspecified)mainPartPtr
                         getMainPartDimensions:(MHDimensions *)mainPartDimensionsPtr
                 getVerticalExtensionGlyphName:(NSString * _Null_unspecified * _Null_unspecified)extensionPtr
                getVerticalExtensionDimensions:(MHDimensions *)extensionDimensionsPtr
{
    *mainPartPtr = kMHMathFontSystemExtensibleRadicalMainPart;
    *extensionPtr = kMHMathFontSystemExtensibleRadicalVerticalExtensionPart;
    
    if (!MHMathFontRadicalDataPrepared)
        [self lazilyLoadRadicalGlyphDataWithPointSize:pointSize];


    (*mainPartDimensionsPtr).width = MHMathFontRadicalExtensibleMainPartAdvance / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*mainPartDimensionsPtr).depth = -MHMathFontRadicalExtensibleMainPartBoundingBox.origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*mainPartDimensionsPtr).height =
    (MHMathFontRadicalExtensibleMainPartBoundingBox.origin.y +
    MHMathFontRadicalExtensibleMainPartBoundingBox.size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;

    (*extensionDimensionsPtr).width = MHMathFontRadicalExtensibleExtensionPartAdvance / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*extensionDimensionsPtr).depth = -MHMathFontRadicalExtensibleExtensionPartBoundingBox.origin.y / (CGFloat)MHMathFontUnitsPerEm * pointSize;
    (*extensionDimensionsPtr).height =
    (MHMathFontRadicalExtensibleExtensionPartBoundingBox.origin.y +
    MHMathFontRadicalExtensibleExtensionPartBoundingBox.size.height) / (CGFloat)MHMathFontUnitsPerEm * pointSize;
}






@end
