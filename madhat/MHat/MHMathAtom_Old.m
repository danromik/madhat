////
////  MHMathAtom.m
////  MadHat
////
////  Created by Dan Romik on 1/9/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHMathAtom.h"
//#import "NSString+MathConversion.h"
//
//@interface MHMathAtom () {
//    bool _usesGlyphEncoding;
//    MHTypographyClass _typographyClass;
//}
//@end
//
//@implementation MHMathAtom
//
//#pragma mark - Constructor methods
//
//- (instancetype)initWithString:(NSString *)string typographyClass:(MHTypographyClass)typographyClass
//{
//    if (self = [super init]) {
//        _text = string;
//        _typographyClass = typographyClass;
//    }
//    return self;
//}
//
//+ (instancetype)atomWithString:(NSString *)string typographyClass:(MHTypographyClass)typographyClass
//{
//    return [[self alloc] initWithString:string typographyClass:typographyClass];
//}
//
////- (instancetype)initWithRomanMathVar:(NSString *)varName
////{
////    if (self = [self initWithString:varName]) {
////        _typographyClass = MHTypographyClassRomanMathVariable;
////    }
////    return self;
////}
////
////+ (instancetype)atomWithMathRomanVar:(NSString *)varName
////{
////    return [[self alloc] initWithRomanMathVar:varName];
////}
////
////- (instancetype)initWithBinaryRelation:(NSString *)symbol
////{
////    if (self = [self initWithString:symbol]) {
////        _typographyClass = MHTypographyClassBinaryRelation;
////    }
////    return self;
////}
////
////+ (instancetype)atomWithBinaryRelation:(NSString *)symbol
////{
////    return [[self alloc] initWithBinaryRelation:symbol];
////}
////
////- (instancetype)initWithBinaryOperator:(NSString *)symbol
////{
////    if (self = [self initWithString:symbol]) {
////        _typographyClass = MHTypographyClassBinaryOperator;
////    }
////    return self;
////}
////
////+ (instancetype)atomWithBinaryOperator:(NSString *)symbol
////{
////    return [[self alloc] initWithBinaryOperator:symbol];
////}
//
//- (instancetype)initWithGlyphName:(NSString *)glyphName typographyClass:(MHTypographyClass)typographyClass
//{
//    if (self = [self initWithString:glyphName]) {
//        _usesGlyphEncoding = true;
//        _typographyClass = typographyClass;
//    }
//    return self;
//}
//
//+ (instancetype)atomWithGlyphName:(NSString *)glyphName typographyClass:(MHTypographyClass)typographyClass
//{
//    return [[self alloc] initWithGlyphName:glyphName typographyClass:(MHTypographyClass)typographyClass];
//}
//
//
//
//
//# pragma mark - Properties
//
//- (NSString *)text
//{
//    if (_typographyClass == MHTypographyClassItalicMathVariable)
//        return [NSString stringByConvertingRomanCharactersInString:_text toMathFontTrait:MHMathFontTraitItalic];
//        return _text;
//}
//
//- (MHTypographyClass)typographyClass
//{
//    return _typographyClass;
//}
//
//- (short int)italicCorrection
//{
//    // FIXME: a temporary hack - this information should be read from the font
//    static short int lowercaseItalicCorrections[26] = {
//        0, 14, 25, 24, 0, 90, 25, 0, 0, 13,
//        15, 0, 0, 0, 12, 15, 34, 13, 0, 0,
//        0, 11, 3, 0, 28, 30
//    };
//    static short int uppercaseItalicCorrections[26] = {
//        0, 25, 73, 4, 54, 134, 0, 78, 85, 106,
//        68, 0, 102, 106, 5, 140, 0, 24, 60, 148,
//        105, 214, 132, 51, 209, 68
//    };
//    
//    if (!self.usesGlyphEncoding) {
//        if (_text.length == 1 && _typographyClass == MHTypographyClassItalicMathVariable) {
//            unichar theChar = [_text characterAtIndex:0];
//            if (theChar >= 'a' && theChar <= 'z') {
//                short int offset = theChar - 'a';
//                return lowercaseItalicCorrections[offset];
//            }
//            if (theChar >= 'A' && theChar <= 'Z') {
//                short int offset = theChar - 'A';
//                return uppercaseItalicCorrections[offset];
//            }
//        }
//        if ([self.text isEqualToString:@"∫"])
//            return 100;
//    }
//    else if ([self.text isEqualToString:@"integral.v1"])
//        return 300;
//    return super.italicCorrection;
//}
//
//
//- (bool)usesGlyphEncoding
//{
//    return _usesGlyphEncoding;
//}
//
//- (NSString *)stringValue
//{
//    return _text;
//}
//
//@end
