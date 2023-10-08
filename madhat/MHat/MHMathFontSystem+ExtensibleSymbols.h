//
//  MHMathFontSystem+ExtensibleSymbols.h
//  MadHat
//
//  Created by Dan Romik on 7/12/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHMathFontSystem.h"


NS_ASSUME_NONNULL_BEGIN

@interface MHMathFontSystem (ExtensibleSymbols)


// Getting glyphs for extensible brackets
- (NSString *)glyphNameForBracketOfType:(MHBracketType)bracketType
                            orientation:(MHBracketOrientation)bracketOrientation
        forEnclosingHeightAboveMathAxis:(CGFloat)height
                          withPointSize:(CGFloat)pointSize
                          getDimensions:(MHDimensions *)dimensionsPtr;

- (NSString *)glyphNameForBracketOfType:(MHBracketType)bracketType
                            orientation:(MHBracketOrientation)bracketOrientation
                           variantLevel:(NSUInteger)level
                          withPointSize:(CGFloat)pointSize
                          getDimensions:(MHDimensions *)dimensionsPtr;

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
               getMiddlePieceDimensions:(MHDimensions *)middlePieceDimensionsPtr;


// Getting glyphs for extensible horizontal brackets
- (NSString *)glyphNameForHorizontalExtensibleSymbolOfType:(MHHorizontalExtensibleSymbolType)bracketType
                                forEnclosingWidth:(CGFloat)width
                                    withPointSize:(CGFloat)pointSize
                                    getDimensions:(MHDimensions *)dimensionsPtr;

- (void)getExtensibleHorizontalExtensibleSymbolPartsOfType:(MHHorizontalExtensibleSymbolType)bracketType
                                    withPointSize:(CGFloat)pointSize
                             getLeftHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)leftHookGlyphNamePtr
                            getLeftHookDimensions:(MHDimensions *)lowerHookDimensionsPtr
                            getRightHookGlyphName:(NSString * _Null_unspecified * _Null_unspecified)rightHookGlyphNamePtr
                           getRightHookDimensions:(MHDimensions *)upperHookDimensionsPtr
                       getExtensionPieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)extensionPieceGlyphNamePtr
                      getExtensionPieceDimensions:(MHDimensions *)extensionPieceDimensionsPtr
                          getMiddlePieceGlyphName:(NSString * _Null_unspecified * _Null_unspecified)middlePieceGlyphNamePtr
                         getMiddlePieceDimensions:(MHDimensions *)middlePieceDimensionsPtr;



// Getting glyphs for extensible radical signs
- (NSString *)glyphNameForRadicalSignEnclosingTotalHeight:(CGFloat)totalHeight
                                            withPointSize:(CGFloat)pointSize
                                            getDimensions:(MHDimensions *)dimensionsPtr;

- (void)getExtensibleRadicalPartsWithPointSize:(CGFloat)pointSize
                          getMainPartGlyphName:(NSString * _Null_unspecified * _Null_unspecified)mainPartPtr
                         getMainPartDimensions:(MHDimensions *)mainPartDimensionsPtr
        getVerticalExtensionGlyphName:(NSString * _Null_unspecified * _Null_unspecified)extensionPtr
                getVerticalExtensionDimensions:(MHDimensions *)extensionDimensionsPtr;




@end

NS_ASSUME_NONNULL_END
