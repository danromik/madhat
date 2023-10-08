////
////  MHMultiformMathAtom.m
////  MadHat
////
////  Created by Dan Romik on 1/4/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHMultiformMathAtom.h"
//
//@interface MHMultiformMathAtom () {
//    bool _inlineModeUsesGlyphEncoding;
//    bool _displayModeUsesGlyphEncoding;
//    NSString *_inlineModeText;
//    NSString *_displayModeText;
//    bool _inlineModeIsLimitsOperator;
//    bool _displayModeIsLimitsOperator;
//    MHTypographyClass _typographyClass;
//}
//
//@end
//
//
//@implementation MHMultiformMathAtom
//
//
//+ (instancetype)atomWithInlineModeString:(NSString *)inlineString
//                       displayModeString:(NSString *)displayString
//             inlineModeUsesGlyphEncoding:(bool)inlineUsesGlyph
//            displayModeUsesGlyphEncoding:(bool)displayUsesGlyph
//                         typographyClass:(MHTypographyClass)typographyClass
//              inlineModeIsLimitsOperator:(bool)inlineIsLimits
//             displayModeIsLimitsOperator:(bool)displayIsLimits
//{
//    return [[self alloc] initWithInlineModeString:inlineString
//                                displayModeString:displayString
//                      inlineModeUsesGlyphEncoding:inlineUsesGlyph
//                     displayModeUsesGlyphEncoding:displayUsesGlyph
//                                  typographyClass:typographyClass
//                       inlineModeIsLimitsOperator:inlineIsLimits
//                      displayModeIsLimitsOperator:displayIsLimits];
//}
//
//- (instancetype)initWithInlineModeString:(NSString *)inlineString
//                       displayModeString:(NSString *)displayString
//             inlineModeUsesGlyphEncoding:(bool)inlineUsesGlyph
//            displayModeUsesGlyphEncoding:(bool)displayUsesGlyph
//                         typographyClass:(MHTypographyClass)typographyClass
//              inlineModeIsLimitsOperator:(bool)inlineIsLimits
//             displayModeIsLimitsOperator:(bool)displayIsLimits
//{
//    if (self = [super init]) {
//        _inlineModeText = inlineString;
//        _displayModeText = displayString;
//        _inlineModeUsesGlyphEncoding = inlineUsesGlyph;
//        _displayModeUsesGlyphEncoding = displayUsesGlyph;
//        _typographyClass = typographyClass;
//        _inlineModeIsLimitsOperator = inlineIsLimits;
//        _displayModeIsLimitsOperator = displayIsLimits;
//    }
//    return self;
//}
//
//
//
//
//- (NSString *)text
//{
//    return (self.nestingLevel <= 1 ? _displayModeText : _inlineModeText);
//}
//
//// FIXME: this needs refactoring. This property was declared private in MHTextAtom so this class shouldn't know about it
//- (bool)usesGlyphEncoding
//{
//    return (self.nestingLevel <= 1 ? _displayModeUsesGlyphEncoding : _inlineModeUsesGlyphEncoding);
//}
//
//- (bool)isLimitsOperator
//{
//    return (self.nestingLevel <= 1 ? _displayModeIsLimitsOperator : _inlineModeIsLimitsOperator);
//}
//
//- (MHTypographyClass)typographyClass
//{
//    return _typographyClass;
//}
//
//+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(nonnull MHHorizontalLayoutContainer *)expression
//{
//    static NSDictionary *MHExpressionTypographyClassFromString; // FIXME: should this be a global variable? Should it be declared outside the current method scope? Should it be accessed via an accessor?
// 
//    if (!MHExpressionTypographyClassFromString) {
//        MHExpressionTypographyClassFromString = @{
//            @"text" : [NSNumber numberWithInt:MHTypographyClassText],
//            @"number" : [NSNumber numberWithInt:MHTypographyClassNumber],
//            @"unaryprefix" : [NSNumber numberWithInt:MHTypographyClassUnaryPrefixOperator],
//            @"unarypostfix" : [NSNumber numberWithInt:MHTypographyClassUnaryPostfixOperator],
//            @"binaryop" : [NSNumber numberWithInt:MHTypographyClassBinaryOperator],
//            @"binaryrel" : [NSNumber numberWithInt:MHTypographyClassBinaryRelation],
//            @"mathroman" : [NSNumber numberWithInt:MHTypographyClassRomanMathVariable],
//            @"mathitalic" : [NSNumber numberWithInt:MHTypographyClassItalicMathVariable],
//            @"leftbracket" : [NSNumber numberWithInt:MHTypographyClassLeftBracket],
//            @"rightbracket" : [NSNumber numberWithInt:MHTypographyClassRightBracket],
//            @"mathpunct" : [NSNumber numberWithInt:MHTypographyClassPunctuation],
//            @"mathcompound" : [NSNumber numberWithInt:MHTypographyClassCompoundExpression],
//        };
//    }
//    
//    
//    
//    NSString *typographyClassString = parameters[@"typographyclass"]; // FIXME: literal strings in code - bad
//    MHTypographyClass typographyClass = [(NSNumber *)(MHExpressionTypographyClassFromString[typographyClassString]) unsignedIntValue];
//
//    NSDictionary *inlineParameters = parameters[@"inlineparams"];
//    NSDictionary *displayParameters = parameters[@"displayparams"];
//
//    bool inlineIsLimitsOperator = [(NSNumber *)inlineParameters[@"limitsoperator"] boolValue];
//    bool displayIsLimitsOperator = [(NSNumber *)displayParameters[@"limitsoperator"] boolValue];
//    
//    bool inlineUsesGlyphEncoding = false;
//    bool displayUsesGlyphEncoding = false;
//
//    NSString *inlineString = inlineParameters[@"symbol"];   // FIXME: literal strings in code - bad
//    if (!inlineString) {
//        inlineUsesGlyphEncoding = true;
//        inlineString = inlineParameters[@"glyphname"];
//    }
//
//    NSString *displayString = displayParameters[@"symbol"];   // FIXME: literal strings in code - bad
//    if (!displayString) {
//        displayUsesGlyphEncoding = true;
//        displayString = displayParameters[@"glyphname"];
//    }
//    
//    if (!inlineString || !displayString)
//        return nil;     // couldn't get one of the strings, this shouldn't happen
//    
//    return [self atomWithInlineModeString:inlineString
//                        displayModeString:displayString
//              inlineModeUsesGlyphEncoding:inlineUsesGlyphEncoding
//             displayModeUsesGlyphEncoding:displayUsesGlyphEncoding
//                          typographyClass:typographyClass
//               inlineModeIsLimitsOperator:inlineIsLimitsOperator
//              displayModeIsLimitsOperator:displayIsLimitsOperator];
//}
//
//
//
//@end
