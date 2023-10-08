//
//  MHMultiformMathAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHMultiformMathAtom.h"
#import "MHTextNode.h"
#import "MHGlyphNode.h"
#import "MHStyleIncludes.h"

@interface MHMultiformMathAtom () {
    MHAtomStringType _inlineModeStringType;
    MHAtomStringType _displayModeStringType;
    NSString *_inlineModeString;
    NSString *_displayModeString;
    bool _inlineModeIsLimitsOperator;
    bool _displayModeIsLimitsOperator;
    MHTypographyClass _typographyClass;

    MHTextualElementNode *_inlineModeNode;
    MHTextualElementNode *_displayModeNode;
}
@end


@implementation MHMultiformMathAtom


#pragma mark - Constructors

+ (instancetype)atomWithInlineModeString:(NSString *)inlineString
                       displayModeString:(NSString *)displayString
                    inlineModeStringType:(MHAtomStringType)inlineStringType
                   displayModeStringType:(MHAtomStringType)displayStringType
                         typographyClass:(MHTypographyClass)typographyClass
              inlineModeIsLimitsOperator:(bool)inlineIsLimits
             displayModeIsLimitsOperator:(bool)displayIsLimits
{
    return [[self alloc] initWithInlineModeString:inlineString
                                displayModeString:displayString
                             inlineModeStringType:inlineStringType
                            displayModeStringType:displayStringType
                                  typographyClass:typographyClass
                       inlineModeIsLimitsOperator:inlineIsLimits
                      displayModeIsLimitsOperator:displayIsLimits];
}

- (instancetype)initWithInlineModeString:(NSString *)inlineString
                       displayModeString:(NSString *)displayString
                    inlineModeStringType:(MHAtomStringType)inlineStringType
                   displayModeStringType:(MHAtomStringType)displayStringType
                         typographyClass:(MHTypographyClass)typographyClass
              inlineModeIsLimitsOperator:(bool)inlineIsLimits
             displayModeIsLimitsOperator:(bool)displayIsLimits
{
    if (self = [super init]) {
        _inlineModeString = inlineString;
        _displayModeString = displayString;
        _inlineModeStringType = inlineStringType;
        _displayModeStringType = displayStringType;
        _typographyClass = typographyClass;
        _inlineModeIsLimitsOperator = inlineIsLimits;
        _displayModeIsLimitsOperator = displayIsLimits;
    }
    return self;
}


#pragma mark - Properties

- (bool)isLimitsOperator
{
    return (self.nestingLevel <= 1 ? _displayModeIsLimitsOperator : _inlineModeIsLimitsOperator);
}

- (MHTypographyClass)typographyClass
{
    return _typographyClass;
}

- (short int)italicCorrection
{
    // FIXME: a temporary hack - this information should be read from the font
    // FIXME: Also, try not to have duplication of code between here and the MHMathAtom and MHMathGlyphAtom classes
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
    
    bool isDisplayMode = self.nestingLevel <= 1;
    MHAtomStringType currentModeStringType;
    NSString *currentModeString;
    if (isDisplayMode) {
        currentModeString = _displayModeString;
        currentModeStringType = _displayModeStringType;
    }
    else {
        currentModeString = _inlineModeString;
        currentModeStringType = _inlineModeStringType;
    }
    if (currentModeStringType == MHAtomStringTypeText) {
        if (currentModeString.length == 1 && _typographyClass == MHTypographyClassItalicMathVariable) {
            unichar theChar = [currentModeString characterAtIndex:0];
            if (theChar >= 'a' && theChar <= 'z') {
                short int offset = theChar - 'a';
                return lowercaseItalicCorrections[offset];
            }
            if (theChar >= 'A' && theChar <= 'Z') {
                short int offset = theChar - 'A';
                return uppercaseItalicCorrections[offset];
            }
        }
        if ([currentModeString isEqualToString:@"∫"])
            return 100;
    }
    else if ([currentModeString isEqualToString:@"integral.v1"])
        return 300;
    if ([currentModeString isEqualToString:@"contourintegral.v1"])
        return 300;
    return super.italicCorrection;
}



#pragma mark - spriteKitNode

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [SKNode node];
        _spriteKitNode.ownerExpression = self;
        
        // We'll create nodes for both the inline mode and display mode scenarios. In the typesetWithContextManager: method we'll check which scenario applies and make only the relevant node visible
        // FIXME: this is a bit inefficient, think if there's a way to optimize for performance and if the performance gain will be worth the effort
        
        if (_inlineModeStringType == MHAtomStringTypeText) {
            _inlineModeNode = [MHTextNode textNodeWithString:_inlineModeString];
        }
        else {
            _inlineModeNode = [MHGlyphNode glyphNodeWithGlyphName:_inlineModeString];
        }

        if (_displayModeStringType == MHAtomStringTypeText) {
            _displayModeNode = [MHTextNode textNodeWithString:_displayModeString];
        }
        else {
            _displayModeNode = [MHGlyphNode glyphNodeWithGlyphName:_displayModeString];
        }
        
        [_spriteKitNode addChild:_inlineModeNode];
        [_spriteKitNode addChild:_displayModeNode];
    }
    return _spriteKitNode;
}



#pragma mark - typesetWithContextManager

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSFont *font;
    
    MHTypographyClass typographyClass = self.typographyClass;

    if (typographyClass == MHTypographyClassText) {
        font = [contextManager textFontForPresentationMode:self.presentationMode nestingLevel:self.nestingLevel];
    }
    else if (typographyClass == MHTypographyClassItalicMathVariable) {
        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitItalic];
    }
    else {
        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitRoman];
    }
    
    SKNode *mySpriteKitNode = self.spriteKitNode; mySpriteKitNode = nil;    // FIXME: this is to make sure spriteKitNote is loaded since I'm using lazy instantiation. Seems like bad practice to call an accessor to force an effect, maybe think of a better way to set things up
    NSColor *foregroundColor = contextManager.textForegroundColor;
    NSColor *backgroundColor = contextManager.textHighlightColor;
    
    bool isDisplayMode = (self.nestingLevel <= 1);
    
    MHDimensions nodeDimensions;
    bool highlightingOn = contextManager.textHighlighting;
    if (isDisplayMode) {
        _inlineModeNode.hidden = true;
        _displayModeNode.hidden = false;
        [_displayModeNode configureWithFont:font
                                      color:foregroundColor
                            backgroundColor:(highlightingOn ? backgroundColor : nil)
                                underlining:contextManager.textUnderlining
                              strikethrough:contextManager.textStrikethrough];
        nodeDimensions = _displayModeNode.dimensions;
    }
    else {
        _displayModeNode.hidden = true;
        _inlineModeNode.hidden = false;
        [_inlineModeNode configureWithFont:font
                                     color:foregroundColor
                           backgroundColor:(highlightingOn ? backgroundColor : nil)
                               underlining:contextManager.textUnderlining
                             strikethrough:contextManager.textStrikethrough];
        nodeDimensions = _inlineModeNode.dimensions;
    }
    self.dimensions = nodeDimensions;
}



#pragma mark - Rendering in graphics contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    bool isDisplayMode = (self.nestingLevel <= 1);
    if (isDisplayMode) {
        [_displayModeNode renderInPDFContext:pdfContext];
    }
    else {
        [_inlineModeNode renderInPDFContext:pdfContext];
    }
}



- (instancetype)logicalCopy
{
    MHMultiformMathAtom *myCopy = [[self class] atomWithInlineModeString:[_inlineModeString copy]
                                                       displayModeString:[_displayModeString copy]
                                                    inlineModeStringType:_inlineModeStringType
                                                   displayModeStringType:_displayModeStringType
                                                         typographyClass:_typographyClass
                                              inlineModeIsLimitsOperator:_inlineModeIsLimitsOperator
                                             displayModeIsLimitsOperator:_displayModeIsLimitsOperator];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
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
    
    
    
    NSString *typographyClassString = parameters[@"typographyclass"]; // FIXME: literal strings in code - bad
    MHTypographyClass typographyClass = [(NSNumber *)(MHExpressionTypographyClassFromString[typographyClassString]) unsignedIntValue];

    NSDictionary *inlineParameters = parameters[@"inlineparams"];
    NSDictionary *displayParameters = parameters[@"displayparams"];

    bool inlineIsLimitsOperator = [(NSNumber *)inlineParameters[@"limitsoperator"] boolValue];
    bool displayIsLimitsOperator = [(NSNumber *)displayParameters[@"limitsoperator"] boolValue];
    
    MHAtomStringType inlineModeStringType = MHAtomStringTypeText;
    MHAtomStringType displayModeStringType = MHAtomStringTypeText;

    NSString *inlineString = inlineParameters[@"symbol"];   // FIXME: literal strings in code - bad
    if (!inlineString) {
        inlineModeStringType = MHAtomStringTypeGlyph;
        inlineString = inlineParameters[@"glyphname"];
    }

    NSString *displayString = displayParameters[@"symbol"];   // FIXME: literal strings in code - bad
    if (!displayString) {
        displayModeStringType = MHAtomStringTypeGlyph;
        displayString = displayParameters[@"glyphname"];
    }
    
    if (!inlineString || !displayString) {
        NSLog(@"Error: incorrect command parameters specified for command class %@", [self class]);
        return nil;     // couldn't get one of the strings, this shouldn't happen
    }
    
    return [self atomWithInlineModeString:inlineString
                        displayModeString:displayString
              inlineModeStringType:inlineModeStringType
             displayModeStringType:displayModeStringType
                          typographyClass:typographyClass
               inlineModeIsLimitsOperator:inlineIsLimitsOperator
              displayModeIsLimitsOperator:displayIsLimitsOperator];
}



+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ @"(misc)" ];
}



-(NSString *)exportedLaTeXValue //RS
{
    bool isDisplayMode = self.nestingLevel <= 1;
    NSString *currentModeString;
    if (isDisplayMode)
        currentModeString = _displayModeString;
    else
        currentModeString = _inlineModeString;
    
    if ([currentModeString isEqualToString: @"integral.v1"])
        return @"\\int";
    else if ([currentModeString isEqualToString: @"contourintegral.v1"])
        return @"\\oint";
    else if ([currentModeString isEqualTo: @"summation.v1"])
        return @"\\sum";
    else if ([currentModeString isEqualToString: @"product.v1"])
        return @"\\prod";
    else if ([currentModeString isEqualToString: @"uni222C.v1"])
        return @"\\iint";
    else if ([currentModeString isEqualToString: @"uni222D.v1"])
        return @"\\iiint";
    else if ([currentModeString isEqualToString: @"∫"])
        return @"\\int";
    else if ([currentModeString isEqualToString: @"∮"])
        return @"\\oint";
    else if ([currentModeString isEqualToString: @"∑"])
        return @"\\sum";
    else if ([currentModeString isEqualToString: @"Π"])
        return @"\\prod";
    else if ([currentModeString isEqualToString: @"∬"])
        return @"\\iint";
    else if ([currentModeString isEqualToString: @"∬"])
        return @"\\iint";
    else if ([currentModeString isEqualToString: @"∭"])
        return @"\\iiint";
    else
        return @"?mma?";
}


@end
