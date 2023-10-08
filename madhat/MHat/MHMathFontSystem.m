//
//  MHMathFontSystem.m
//  MadHat
//
//  Created by Dan Romik on 11/24/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "MHMathFontSystem.h"

#define kMHMathFontSystemMinPointSizeToCache        6
#define kMHMathFontSystemMaxPointSizeToCache        36



// FIXME: these settings need to be initialized/loaded from a math kern file in the MHMathFontSystem class, leaving them here for now
// FIXME: rename this variable once it's in the right place
// Numbers are in thousandths of an em width (FIXME: since NSFont doesn't provide em width, I'm using point size for now)
// Settings I'm working on for CMU Serif font:
short int MHMathTypesettingDefaultKerningMatrix[MHTypographyNumberOfClasses][MHTypographyNumberOfClasses] = {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 192, 364, 59, 25, 117, 63, 112, 144 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 277, 315, 0, 0, 63, 0, 0, 0 },
    { 0, 165, 0, 0, 0, 0, 147, 169, 232, 0, 203, 202 },
    { 0, 243, 0, 0, 0, 0, 295, 257, 351, 0, 0, 410 },
    { 0, 146, 0, 120, 248, 262, 157, 134, 148, 98, 0, 0 },
    { 0, 0, 0, 97, 244, 320, 150, 144, 87, 117, 85, 143 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 228, 0, 98 },
    { 0, 140, 0, 33, 246, 320, 92, 170, 156, 0, 0, 0 },
    { 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 139, 0, 139, 225, 316, 238, 152, 299, 98, 0, 216 }
};

//short int MHMathTypesettingDefaultKerningMatrix[MHTypographyNumberOfClasses][MHTypographyNumberOfClasses] = {
//    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//    { 0, 0, 0, 0, 192, 364, 59, 25, 117, 112, 112, 144 },
//    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//    { 0, 0, 0, 0, 277, 315, 0, 0, 63, 0, 0, 0 },
//    { 0, 165, 0, 0, 0, 0, 147, 169, 232, 0, 203, 202 },
//    { 0, 243, 0, 0, 0, 0, 295, 257, 351, 0, 0, 410 },
//    { 0, 146, 0, 120, 248, 262, 157, 134, 148, 98, 0, 0 },
//    { 0, 0, 0, 97, 244, 320, 150, 144, 87, 117, 85, 143 },
//    { 0, 101, 0, 0, 0, 0, 0, 0, 0, 228, 0, 102 },
//    { 0, 140, 0, 33, 246, 320, 92, 170, 156, 0, 0, 0 },
//    { 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 0 },
//    { 0, 139, 0, 139, 225, 316, 238, 152, 299, 143, 0, 216 }
//};

short int MHMathTypesettingDefaultTrackingFactors[kMHNumberOfNestingLevels] = {
    1000, 400, 1000, 400, 1000, 400, 1000, 400
};  // proportionality factors measured in thousandth of a unit

short int MHMathTypesettingDefaultMathAxisHeight = 250;      // measured in thousandths of an em width

short int MHMathTypesettingDefaultFractionLineThickness = 40;      // measured in thousandths of an ex height

CGFloat MHMathTypesettingDefaultNestingLevelRescalingFactors[kMHNumberOfNestingLevels] = {
    1.0, 1.0, 1.0, 1.0, 0.75, 0.75, 0.5, 0.5
};




@interface MHMathFontSystem () {
    NSFont *romanFont[kMHMathFontSystemMaxPointSizeToCache-kMHMathFontSystemMinPointSizeToCache];
    NSFont *italicFont[kMHMathFontSystemMaxPointSizeToCache-kMHMathFontSystemMinPointSizeToCache];
    NSFont *boldFont[kMHMathFontSystemMaxPointSizeToCache-kMHMathFontSystemMinPointSizeToCache];
    NSFont *boldItalicFont[kMHMathFontSystemMaxPointSizeToCache-kMHMathFontSystemMinPointSizeToCache];
    
    short int _nestingLevelMathTrackingFactors[kMHNumberOfNestingLevels];
    short int _mathKerningMatrix[MHTypographyNumberOfClasses][MHTypographyNumberOfClasses];
}
@end

@implementation MHMathFontSystem


#pragma mark - Constructor method

- (instancetype)initWithFontFamilyName:(NSString *)familyName
{
    if (self = [super init]) {
        _fontFamilyName = familyName;
        
        _mathAxisHeight = MHMathTypesettingDefaultMathAxisHeight;
        _fractionLineThickness = MHMathTypesettingDefaultFractionLineThickness;
        
        short int i, j;
        for (j=0; j<=kMHNumberOfNestingLevels; j++)
            _nestingLevelMathTrackingFactors[j] = MHMathTypesettingDefaultTrackingFactors[j];
        
        for (i=0; i<MHTypographyNumberOfClasses; i++)
            for (j=0; j<MHTypographyNumberOfClasses; j++)
                _mathKerningMatrix[i][j] = MHMathTypesettingDefaultKerningMatrix[i][j];
        
        int index;
        for (index = kMHMathFontSystemMinPointSizeToCache; index < kMHMathFontSystemMaxPointSizeToCache; index++) {
            romanFont[index - kMHMathFontSystemMinPointSizeToCache] = [NSFont fontWithName:familyName size:index];
            if (!romanFont[index - kMHMathFontSystemMinPointSizeToCache]) {
                NSLog(@"Couldn't find roman math font of size %d, using system font instead", index);
                romanFont[index - kMHMathFontSystemMinPointSizeToCache] = [NSFont systemFontOfSize:index];
            }

            italicFont[index - kMHMathFontSystemMinPointSizeToCache] =
            [[NSFontManager sharedFontManager] convertFont:romanFont[index - kMHMathFontSystemMinPointSizeToCache] toHaveTrait:NSFontItalicTrait];
            if (!italicFont[index - kMHMathFontSystemMinPointSizeToCache]) {
                NSLog(@"Couldn't find italic variant, using roman font instead");
                italicFont[index - kMHMathFontSystemMinPointSizeToCache] = romanFont[index - kMHMathFontSystemMinPointSizeToCache];
            }

            boldFont[index - kMHMathFontSystemMinPointSizeToCache] =
            [[NSFontManager sharedFontManager] convertFont:romanFont[index - kMHMathFontSystemMinPointSizeToCache] toHaveTrait:NSFontBoldTrait];
            if (!boldFont[index - kMHMathFontSystemMinPointSizeToCache]) {
                NSLog(@"Couldn't find bold variant, using roman font instead");
                boldFont[index - kMHMathFontSystemMinPointSizeToCache] = romanFont[index - kMHMathFontSystemMinPointSizeToCache];
            }

            boldItalicFont[index - kMHMathFontSystemMinPointSizeToCache] =
            [[NSFontManager sharedFontManager] convertFont:romanFont[index - kMHMathFontSystemMinPointSizeToCache] toHaveTrait:NSFontBoldTrait | NSFontItalicTrait];
            if (!boldItalicFont[index - kMHMathFontSystemMinPointSizeToCache]) {
                NSLog(@"Couldn't find bold italic variant, using roman font instead");
                boldItalicFont[index - kMHMathFontSystemMinPointSizeToCache] = romanFont[index - kMHMathFontSystemMinPointSizeToCache];
            }

        }
    }
    return self;
}



#pragma mark - Serialization

- (NSString *)serializedStringRepresentation
{
    NSMutableString *mutableString = [[NSMutableString alloc] initWithCapacity:0];
    [mutableString appendFormat:@"%@\n%d\n%d", self.fontFamilyName, self.mathAxisHeight, self.fractionLineThickness];
    for (NSUInteger rowIndex = 0; rowIndex < MHTypographyNumberOfClasses; rowIndex++) {
        for (NSUInteger columnIndex = 0; columnIndex < MHTypographyNumberOfClasses; columnIndex++) {
            [mutableString appendFormat:@"\n%d", _mathKerningMatrix[rowIndex][columnIndex]];
        }
    }
    return [NSString stringWithString:mutableString];
}

+ (instancetype)fontFamilyFromSerializedStringRepresentation:(NSString *)string
{
    NSArray <NSString *> *components = [string componentsSeparatedByString:@"\n"];
    NSUInteger numComponents = components.count;
    if (numComponents == 0) {
        NSLog(@"FIXME: no components to font string");
        return [[[self class] alloc] initWithFontFamilyName:@"Helvetica"];
    }
    MHMathFontSystem *newFontFamily = [[[self class] alloc] initWithFontFamilyName:components[0]];
    
    if (numComponents >= 2)
        newFontFamily.mathAxisHeight = [components[1] intValue];
    
    if (numComponents >= 3)
        newFontFamily.fractionLineThickness = [components[2] intValue];
    if (numComponents >= 3 + MHTypographyNumberOfClasses*MHTypographyNumberOfClasses) {
        short int *mathKerningMatrix = newFontFamily.mathKerningMatrix;
        for (NSUInteger index = 0; index < MHTypographyNumberOfClasses*MHTypographyNumberOfClasses; index++) {
            mathKerningMatrix[index] = [components[index+3] intValue];
        }
    }
    else
        NSLog(@"FIXME: missing components in font string");
    return newFontFamily;
}


# pragma mark - Various methods

// This looks like it should be done through property autosynthesis, but the compiler complains about a type mismatch if I don't include it (looks like a bug in the property autosynthesis feature)
- (short int *)nestingLevelMathTrackingFactors
{
    return _nestingLevelMathTrackingFactors;
}

- (short int *)mathKerningMatrix
{
    return (short int *)_mathKerningMatrix; // FIXME: this is a bit sketchy, can it be improved? I have to cast or the compiler complains
}


- (short int)kernWidthForLeftTypographyClass:(MHTypographyClass)leftClass rightTypographyClass:(MHTypographyClass)rightClass
{
    return _mathKerningMatrix[leftClass][rightClass];
}

- (NSFont *)fontWithPointSize:(CGFloat)pointSize traits:(MHMathFontTraits)traits
{
    int roundedPointSize = floorf(pointSize);
    if (pointSize == (CGFloat)roundedPointSize && pointSize >= kMHMathFontSystemMinPointSizeToCache
                                                && pointSize <= kMHMathFontSystemMaxPointSizeToCache) {
        
        if (traits == 0) {
            return romanFont[roundedPointSize - kMHMathFontSystemMinPointSizeToCache];
        }
        else if (traits == MHMathFontTraitItalic) {
            return italicFont[roundedPointSize - kMHMathFontSystemMinPointSizeToCache];
        }
        else if (traits == MHMathFontTraitBold) {
            return boldFont[roundedPointSize - kMHMathFontSystemMinPointSizeToCache];
        }
        else
            return boldItalicFont[roundedPointSize - kMHMathFontSystemMinPointSizeToCache];
    }
    
    NSFont *font = [NSFont fontWithName:_fontFamilyName size:pointSize];
    NSFont *fontWithTraits;
    if (!font)
        font = [NSFont systemFontOfSize:pointSize];
    
//    NSLog(@"math font system using font that was not cached, pointsize=%f", pointSize);

    if (traits == MHMathFontTraitRoman) {
        return font;
    }
    else if (traits == MHMathFontTraitItalic) {
        fontWithTraits = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontItalicTrait];
        return (fontWithTraits ? fontWithTraits : [NSFont systemFontOfSize:pointSize]);
    }
    else if (traits == MHMathFontTraitBold) {
        fontWithTraits = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait];
        return (fontWithTraits ? fontWithTraits : [NSFont systemFontOfSize:pointSize]);
    }
    else {   // bold and italic (the only option left)
        fontWithTraits = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait|NSFontItalicTrait];
        return (fontWithTraits ? fontWithTraits : [NSFont systemFontOfSize:pointSize]);
    }

    return [NSFont systemFontOfSize:pointSize];     // if all else fails...
}




#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MHMathFontSystem *myCopy = [[[self class] alloc] initWithFontFamilyName:self.fontFamilyName];
    myCopy.mathAxisHeight = self.mathAxisHeight;
    myCopy.fractionLineThickness = self.fractionLineThickness;
    short int *myMathKerningMatrix = self.mathKerningMatrix;
    short int *myCopyMathKerningMatrix = myCopy.mathKerningMatrix;
    
    // Copy the kerning table
    for (NSUInteger index = 0; index < MHTypographyNumberOfClasses*MHTypographyNumberOfClasses; index++) {
        myCopyMathKerningMatrix[index] = myMathKerningMatrix[index];
    }
    
    return myCopy;
}





@end
