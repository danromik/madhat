////
////  MHMathAtom+MHCommand.m
////  MadHat
////
////  Created by Dan Romik on 10/31/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//#import "MHMathAtom+MHCommand.h"
//
//
////@implementation NSString (HexValueExtension)
////
////- (NSString *)stringFromHexUnicodeValue
////{
////    unsigned int hexValue;
////    bool success = [[NSScanner scannerWithString:self] scanHexInt:&hexValue];
////    if (success) {
////        return [NSString stringWithFormat:@"%C",(unichar)hexValue];
////    }
////    return @"";
////}
////
////- (NSString *)stringWithCircumflexDiacritic
////{
////    return [self stringByAppendingFormat:@"%C",0x0302];
////}
////
////- (NSString *)stringWithTildeDiacritic
////{
////    return [self stringByAppendingFormat:@"%C",0x0303];
////}
////
////@end
//
//
//@implementation MHMathAtom (MHCommand)
//
////+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHExpression *)expression
////{
//////    // FIXME: these commands need more work
//////
//////    // A command to produce a string by entering its unicode hex representation
//////    // For example, "\hexstr[68656C6C6F]" should produce the string "hello"
//////    if ([name isEqualToString:kMHStandardPackageCommandNameUnicharFromHex]) {
//////        NSString *outputString = [expression.stringValue stringFromHexUnicodeValue];
//////        return [self atomWithString:outputString];
//////    }
//////    else if ([name isEqualToString:kMHStandardPackageCommandNameHat]) {
//////        NSString *outputString = [expression.stringValue stringWithCircumflexDiacritic];
//////        MHTextAtom *atom = [self atomWithString:outputString];
//////        atom.typographyClass = expression.typographyClass;  // FIXME: this results in incorrect behavior
//////        return atom;
//////    }
//////    else if ([name isEqualToString:kMHStandardPackageCommandNameTilde]) {
//////        NSString *outputString = [expression.stringValue stringWithTildeDiacritic];
//////        MHTextAtom *atom = [self atomWithString:outputString];
//////        atom.typographyClass = expression.typographyClass;  // FIXME: this results in incorrect behavior
//////        return atom;
//////    }
////
////    // We didn't find a command, so call the alternative method that ignores the argument
////    return [self commandNamed:name withParameters:parameters];
////}
//
//+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHExpression *)expression
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
//    NSString *string = parameters[@"symbol"];   // FIXME: literal strings in code - bad
//    NSString *typographyClassString = parameters[@"typographyclass"]; // FIXME: literal strings in code - bad
//    MHTypographyClass typographyClass = [(NSNumber *)(MHExpressionTypographyClassFromString[typographyClassString]) unsignedIntValue];
//    bool isLimitsOperator = [(NSNumber *)parameters[@"limitsoperator"] boolValue];
//
//    MHMathAtom *atom;
//    if (string) {
//        atom = [self atomWithString:string typographyClass:typographyClass];
//    }
//    else {
//        // a symbol was not provided, so the next thing to try is whether the command provides a glyph name
//        string = parameters[@"glyphname"];
//        if (!string)
//            return nil; // no symbol and no glyph name - can't do anything useful
//        atom = [self atomWithGlyphName:string typographyClass:typographyClass];
//    }
//    if (isLimitsOperator)
//        atom.isLimitsOperator = true;
//    return atom;
//}
//
//
//
//@end
