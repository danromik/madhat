//
//  MHMathAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHMathAtom.h"
#import "MHMathGlyphAtom.h"
#import "NSString+MathConversion.h"
#import "MHStyleIncludes.h"



//C-style arrays and values used for Greek letters in exportedLaTexValue method.
static const char *lowerCaseGreekLaTeXCommands[25]=
{"\\alpha ","\\beta ","\\gamma ","\\delta ","\\epsilon ","\\zeta ",
 "\\eta ","\\theta ","\\iota ","\\kappa ","\\lambda ", "\\mu ","\\nu ",
 "\\xi ","o ","\\pi ","\\rho ","\\sigma ","\\tau ","\\upsilon ",
    "\\phi ","\\chi ","\\psi ","\\omega ","\0"};
static const char *upperCaseGreekLaTeXCommands[25]=
{"A ","B ","\\Gamma ","\\Delta ","E ","Z ",
 "H ","\\Theta ","I ","K ","\\Lambda ","M ","N ",
 "\\Xi ","O ","\\Pi ","P ","\\Sigma ","T ","\\Upsilon ",
    "\\Phi ","X ","\\Psi ","\\Omega ","\0"};
static const unichar alpha = 945;
static const unichar rho = 961;
static const unichar sigma = 963;
static const unichar omega = 969;
static const unichar Alpha = 913;
static const unichar Rho = 929;
static const unichar Sigma = 931;
static const unichar Omega = 937;

//lDict is a lookup table for coverting MHMathAtoms to LaTeX code in exportedLaTeXValue method.
//lDict includes all but the following MHMathAtoms:
//  (1) These are dealt with by a differnet lookup mechanism: greek letters, greek differentials, derivatives
//  (2) These will inherit the same latex string as their MHTextAtom _text string. We save time by
//      not using lDict: +(plus), /(dividedby), -(minus), *(convolve)
//  (3) Everything whose string is a glyphname is omitted, i.e. bigintgral, bigcountourint, bigproduct, etc...

static NSDictionary * lDict = nil;
void lDictInitializer(void);//This silences the warning that lDictInitializer is not preceeded by a prototype.
void lDictInitializer()
{
    if (lDict == nil)
    {
        lDict=@{
            @"−":@"- ", @"∗":@"*", @"≠":@"\\neq ", @"×":@"\\times ", @"′":@"' ",
            @"⋅":@"\\cdot ", @"≤":@"\\leq ", @"≥":@"\\geq ", @"…":@"\\dots ", @"#":@"\\# ",
            @"←":@"\\leftarrow ", @"→":@"\\rightarrow ", @"↑":@"\\uparrow ", @"↓":@"\\downarrow ",
            @"↔":@"\\leftrightarrow ", @"⇒":@"\\Rightarrow ", @"⇐":@"\\Leftarrow ",
            @"⇔":@"\\Leftrightarrow ", @"⟼":@"\\mapsto ", @"≈":@"\\approx ", @"≡":@"\\equiv ",
            @"~":@"\\sim ", @"∊":@"\\in ", @"⊂":@"\\subset ", @"⊆":@"\\subseteq ", @"⊃":@"\\supset ",
            @"⊇":@"\\supseteq ", @"∩":@"\\cap ", @"⋂":@"\\bigcap ", @"∪":@"\\cup ", @"⋃":@"\\bigcup ",
            @"∧":@"\\land ", @"⋀":@"\\bigwedge ", @"∨":@"\\lor ", @"⋁":@"\\bigvee ", @"±":@"\\pm ",
            @"∓":@"\\mp ", @"·":@"\\cdot ", @"•":@"\\bullet ", @"⋯":@"\\cdots ", @"⋮":@"\\,\\vdots ",
            @"⋱":@"\\ddots ", @"⋰":@"\\,\\iddots ", @"∫":@"\\int ", @"∮":@"\\oint ", @"∑":@"\\sum ",
            @"Π":@"\prod ", @"∇":@"\\nabla ", @"lim":@"\\lim ", @"min":@"\\min ", @"max":@"\\max ",
            @"inf":@"\\inf ", @"sup":@"\\sup ", @"det":@"\\det ", @"∞":@"\\infty ", @"ℕ":@"\\mathbb{N} ",
            @"ℤ":@"\\mathbb{Z} ", @"ℚ":@"\\mathbb{Q} ", @"ℝ":@"\\mathbb{R} ", @"ℂ":@"\\mathbb{C} ",
            @"ℏ":@"\\hslash ", @"sin":@"\\sin ", @"cos":@"\\cos ", @"tan":@"\\tan ", @"𝜕":@"\\partial ",
            @"sec":@"\\sec ", @"cosec":@"\\csc ", @"arccos":@"\\arccos ", @"arcsin":@"\\arcsin ",
            @"arctan":@"\\arctan ", @"exp":@"\\exp ", @"log":@"\\log ", @"ln":@"\\ln "
        };
    }
}


@interface MHMathAtom () {
    MHTypographyClass _typographyClass;
    MHMathFontVariant _mathFontVariant;
}
@end

@implementation MHMathAtom


#pragma mark - Constructor methods

- (instancetype)initWithString:(NSString *)string typographyClass:(MHTypographyClass)typographyClass
{
    if (self = [super init]) {
        _text = string;
        _typographyClass = typographyClass;
        if (_typographyClass == MHTypographyClassItalicMathVariable) {
            _mathFontVariant = MHMathFontVariantItalic;
        }
        else {
            _mathFontVariant = MHMathFontVariantDefault;
        }
    }
    return self;
}

+ (instancetype)mathAtomWithString:(NSString *)string typographyClass:(MHTypographyClass)typographyClass
{
    return [[self alloc] initWithString:string typographyClass:typographyClass];
}


#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    // Read the current math font variant from the context manager
    _mathFontVariant = contextManager.mathFontVariant;
    
    if (_spriteKitNode) {
        // FIXME: seems wasteful to create the spriteKitNode property and then destroy and recreate it, and moreover it is done for all math atoms so potentially creates a not insignificant amount of overhead. IMPROVE. There's a similar issue (and much more wasteful) in the MHTextAtom class
        SKNode *spriteKitnodeParent = _spriteKitNode.parent;
        [_spriteKitNode removeFromParent];
        _spriteKitNode = nil;
        SKNode *newSpriteKitNode = self.spriteKitNode;
        [spriteKitnodeParent addChild:newSpriteKitNode];
    }
    
    [super typesetWithContextManager:contextManager];
}



# pragma mark - Properties

- (NSString *)text
{
    if (_mathFontVariant == MHMathFontVariantDefault) {
        if (_typographyClass == MHTypographyClassItalicMathVariable) {
            return [NSString stringByConvertingRomanCharactersInString:_text
                                                     toMathFontVariant:MHMathFontVariantItalic];
        }
        return _text;
    }
    return [NSString stringByConvertingRomanCharactersInString:_text
                                             toMathFontVariant:_mathFontVariant];
}

// A small optimization here: since I'm using one of the bits of the _typographyClass field to store the isLimitsOperator boolean (see the -isLimitsOperator method), make sure to return the value with that bit (and the ones above it, which are not used) zeroed out
// FIXME: this code is also copy-pasted in the MHMathGlyphAtom class. Violates DRY, figure out a way to share code between the two classes
// FIXME: it may be a good idea to rename the _typographyClass instance variable to emphasize that it contains more than just the typographyClass-valued property. This could prevent confusion and bugs popping up in the future
- (MHTypographyClass)typographyClass
{
    return _typographyClass & 2047;
}

- (short int)italicCorrection
{
    // FIXME: a temporary hack - this information should be read from the font
    static short int lowercaseItalicCorrections[26] = {
        0, 14, 25, 24, 0, 90, 25, 0, 0, 13,
        15, 0, 0, 0, 12, 15, 34, 13, 0, 0,
        0, 11, 3, 0, 28, 30
    };
    static short int uppercaseItalicCorrections[26] = {
        0, 25, 73, 4, 54, 134, 0, 78, 85, 106,
        68, 0, 102, 106, 5, 140, 0, 24, 60, 148,
        105, 214, 132, 51, 209, 68
    };
    
    if (_text.length == 1 && _typographyClass == MHTypographyClassItalicMathVariable) {
        unichar theChar = [_text characterAtIndex:0];
        if (theChar >= 'a' && theChar <= 'z') {
            short int offset = theChar - 'a';
            return lowercaseItalicCorrections[offset];
        }
        if (theChar >= 'A' && theChar <= 'Z') {
            short int offset = theChar - 'A';
            return uppercaseItalicCorrections[offset];
        }
    }
    if ([self.text isEqualToString:@"∫"])
        return 100;

    return super.italicCorrection;
}

- (short int)topDecorationPositioningOffset
{
    // FIXME: a temporary hack - this information should be read from the font
    static short int lowercasePositioningOffsets[26] = {
        // these are values copied from FontForge, they don't seem to give correct behavior so I may not be using them correctly
//        324, 268, 359, 544, 333, 428, 419, 267, 258, 278,
//        268, 267, 454, 315, 345, 322, 395, 301, 310, 260,
//        351, 324, 435, 319, 324, 314
        // Switching to values I am manually setting as a temporary hack:
        260, 50, 260, 50, 260, 30, 260, 10, 30, 20,
        0, 0, 260, 260, 260, 260, 260, 260, 260, 30,
        260, 260, 260, 260, 260, 260
    };
//    static short int uppercasePositioningOffsets[26] = {
//        // these are values copied from FontForge, they don't seem to give correct behavior so I may not be using them correctly
////        481, 403, 559, 400, 464, 457, 554, 502, 287, 493,
////        515, 287, 585, 502, 519, 406, 519, 404, 442, 484,
////        490, 481, 620, 467, 481, 458
//        // Switching to values I am manually setting as a temporary hack:
//        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//        0, 0, 0, 0, 0, 0
//    };

        static short int lowercaseGreekPositioningOffsets[25] = {
            // these are values copied from FontForge, they don't seem to give correct behavior so I may not be using them correctly
    //        324, 268, 359, 544, 333, 428, 419, 267, 258, 278,
    //        268, 267, 454, 315, 345, 322, 395, 301, 310, 260,
    //        351, 324, 435, 319, 324, 314
            // Switching to values I am manually setting as a temporary hack:
            260, 50, 260, 50, 260, 20, 260, 20, 220, 220,
            20, 260, 260, 20, 240, 260, 260, 260, 260, 260,
            260, 260, 260, 50, 180
        };

    if (_text.length == 1) {
        unichar theChar = [_text characterAtIndex:0];
        
        if (_typographyClass == MHTypographyClassItalicMathVariable) {
            if (theChar >= 'a' && theChar <= 'z') {
                short int offset = theChar - 'a';
                return lowercasePositioningOffsets[offset];
            }
            // commenting out for now - it looks like returning a value of 0 is good enough for upper case letters
//            if (theChar >= 'A' && theChar <= 'Z') {
//                short int offset = theChar - 'A';
//                return uppercasePositioningOffsets[offset];
//            }
        }
        
        else if (_typographyClass == MHTypographyClassRomanMathVariable) {
            const unichar alphaChar = 0x03B1; // 'α'
            const unichar omegaChar = 0x03C9; // 'ω'
            
            if (theChar >= alphaChar && theChar <= omegaChar) {
                short int offset = theChar - alphaChar;
                return lowercaseGreekPositioningOffsets[offset];
            }
        }
    }
    return super.topDecorationPositioningOffset;
}


- (NSString *)stringValue   // for the stringValue property, return the non-italicized version in case of italic variables
{
    return _text;
}

// A small optimization here: using one of the bits of the _typographyClass field to store the isLimitsOperator boolean
// FIXME: this code is also copy-pasted in the MHMathGlyphAtom class. Violates DRY, figure out a way to share code between the two classes
- (bool)isLimitsOperator
{
    return ((_typographyClass & 2048) == 2048 ? true : false);
}

- (void)setIsLimitsOperator:(bool)isLimitsOperator
{
    _typographyClass = (_typographyClass & 2047) | (isLimitsOperator ? 2048 : 0);
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHMathAtom *myCopy = [[self class] mathAtomWithString:[_text copy] typographyClass:_typographyClass];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


#pragma mark - MHCommand protocol


//
// FIXME: this method also handles commands with a glyph instead of a symbol. Those commands are routed to the MHMathGlyphAtom class. This works, but is a bit illogical to have those commands handled by the MHMathAtom class instead of by MHMathGlyphAtom. Think about whether it makes sense to reorganize things a bit to improve the logic
//
+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    static NSDictionary *MHExpressionTypographyClassFromString; // FIXME: should this be a global variable? Should it be declared outside the current method scope? Should it be accessed via an accessor?
 
    if (!MHExpressionTypographyClassFromString) {
        MHExpressionTypographyClassFromString = @{
            @"text" : [NSNumber numberWithInt:MHTypographyClassText],
            @"number" : [NSNumber numberWithInt:MHTypographyClassNumber],
            @"unaryprefix" : [NSNumber numberWithInt:MHTypographyClassUnaryPrefixOperator],
            @"unarypostfix" : [NSNumber numberWithInt:MHTypographyClassUnaryPostfixOperator],
            @"binaryop" : [NSNumber numberWithInt:MHTypographyClassBinaryOperator],
            @"binaryrel" : [NSNumber numberWithInt:MHTypographyClassBinaryRelation],
            @"mathroman" : [NSNumber numberWithInt:MHTypographyClassRomanMathVariable],
            @"mathitalic" : [NSNumber numberWithInt:MHTypographyClassItalicMathVariable],
            @"leftbracket" : [NSNumber numberWithInt:MHTypographyClassLeftBracket],
            @"rightbracket" : [NSNumber numberWithInt:MHTypographyClassRightBracket],
            @"mathpunct" : [NSNumber numberWithInt:MHTypographyClassPunctuation],
            @"mathcompound" : [NSNumber numberWithInt:MHTypographyClassCompoundExpression],
        };
    }
    
    NSString *string = parameters[@"symbol"];   // FIXME: literal strings in code - bad
    NSString *typographyClassString = parameters[@"typographyclass"]; // FIXME: literal strings in code - bad
    MHTypographyClass typographyClass = [(NSNumber *)(MHExpressionTypographyClassFromString[typographyClassString]) unsignedIntValue];
    bool isLimitsOperator = [(NSNumber *)parameters[@"limitsoperator"] boolValue];  // FIXME: literal strings in code - bad

    MHExpression *atom;
    if (string) {
        MHMathAtom *mathAtom = [MHMathAtom mathAtomWithString:string typographyClass:typographyClass];
        if (isLimitsOperator)
            mathAtom.isLimitsOperator = true;
        atom = mathAtom;
    }
    else {
        // a symbol was not provided, so the next thing to try is whether the command provides a glyph name
        string = parameters[@"glyphname"];  // FIXME: literal strings in code - bad
        if (!string)
            return nil; // no symbol and no glyph name - can't do anything useful
        MHMathGlyphAtom *mathGlyphAtom = [MHMathGlyphAtom mathGlyphAtomWithGlyphName:string typographyClass:typographyClass];
        if (isLimitsOperator)
            mathGlyphAtom.isLimitsOperator = true;
        atom = mathGlyphAtom;
    }
    return atom;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ @"(misc)" ];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"math atom: '%@', typography class=%d", self.text, self.typographyClass];
}


/*-----------------------------------------------------------------------------------------------------------------------------------------*/

//RS - C-style function to be used in the exportToLaTeX method below
static NSString * preExportedLaTeXValueForSingleCharacterAtoms (NSString * letter)
{
    if (letter.length == 1) //This is just an extra assertion.
    {
        unichar firstChar = [letter characterAtIndex:0];
        //The next 4 clauses check the range of this unichar value to see if greek and output appropriate
        //latex string from the lookup tables at the top of the file.
        
        if (alpha<=firstChar && firstChar<=rho)
        {
            NSString * lowerCaseGreekLaTeXCommand =
            [NSString stringWithUTF8String: lowerCaseGreekLaTeXCommands[firstChar-alpha]];
            return [NSString stringWithString: lowerCaseGreekLaTeXCommand];
        }
        else if (sigma<=firstChar && firstChar<=omega)
        {
            NSString * lowerCaseGreekLaTeXCommand =
            [NSString stringWithUTF8String: lowerCaseGreekLaTeXCommands[firstChar-alpha-1]];
            return [NSString stringWithString: lowerCaseGreekLaTeXCommand];
        }
        else if (Alpha<=firstChar && firstChar<=Rho)
        {
            NSString * upperCaseGreekLaTeXCommand =
            [NSString stringWithUTF8String: upperCaseGreekLaTeXCommands[firstChar-Alpha]];
            return [NSString stringWithString: upperCaseGreekLaTeXCommand];
        }
        else if (Sigma<=firstChar && firstChar<=Omega)
        {
            NSString * upperCaseGreekLaTeXCommand =
            [NSString stringWithUTF8String: upperCaseGreekLaTeXCommands[firstChar-Alpha-1]];
            return [NSString stringWithString: upperCaseGreekLaTeXCommand];
        }
        else //The parameter letter is not a greek letter.
        {
            return lDict[letter];
        }

    }
    return @"(?ma1?)"; //Error
}


-(NSString *)exportedLaTeXValue //RS
{
    lDictInitializer();
    NSString* text = _text;
    if (text.length == 1) //single-character math atoms
    {
        NSString* preExportedLatexValue = preExportedLaTeXValueForSingleCharacterAtoms(text);
        return (preExportedLatexValue != nil) ? preExportedLatexValue : text;
    }

    else if (text.length == 2) //partials and non-greek differentials
        {
            if ([text isEqual: @"𝜕"]) return @"\\partial ";
            //Looksl like this return is hit by "partial f" in MadHat
            //Not sure why the NSString "𝜕" has length two - is this stable?
            
            else if ([[text substringToIndex:1] isEqualTo: @"d"])
                return text; //Looks like this return is hit by "df" in MadHat.
            
            else
            {
                NSString *DictEntry = lDict[text];
                if (DictEntry != nil) return DictEntry;
                //else return @"(?ma2?)"; //Error
                else return text;
            }
        }
    else if (text.length == 3)
        {
            if ([[text substringToIndex:2] isEqualTo: @"𝑑"])
            //Not sure why "dalpha" has length 3 - is this stable?
            {
                return [@"d" stringByAppendingString:
                        preExportedLaTeXValueForSingleCharacterAtoms([text substringFromIndex:2])];
                        //This return is hit by dalpha.
            }
            else
            {
                NSString *DictEntry = lDict[text];
                if (DictEntry != nil) return DictEntry;
                //else return @"(?ma3?)"; //Error
                else return text;
            }
        }
    else
        {
            NSString *DictEntry = lDict[text];
            if (DictEntry != nil) return DictEntry;
            //else return @"(?ma!?)"; //Error
            else return text;
        }
}


/*-----------------------------------------------------------------------------------------------------------------------------------------*/




@end
