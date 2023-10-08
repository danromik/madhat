//
//  MHGlyphAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGlyphAtom.h"
#import "MHGlyphNode.h"
#import "MHStyleIncludes.h"

NSString * const kMHGlyphCommandNameGlyph = @"glyph";

@interface MHGlyphAtom ()

@property MHGlyphNode *spriteKitNode;    // redeclare the property as an MHGlyphNode instance to improve type checking


@end


@implementation MHGlyphAtom

@dynamic spriteKitNode; // tells the compiler the property is already implemented by a superclass and does not need to be synthesized


+ (instancetype)glyphAtomWithGlyphName:(NSString *)glyphName
{
    return [[[self class] alloc] initWithGlyphName:glyphName];
}

- (instancetype)initWithGlyphName:(NSString *)glyphName
{
    if (self = [super init]) {
        _glyphName = glyphName;
    }
    return self;
}

#pragma mark - Properties

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassText;
}

- (NSString *)glyphName
{
    return _glyphName;
}

- (NSString *)stringValue
{
    return self.glyphName;  // FIXME: is this logical?
}

-(NSString *)exportedLaTeXValue //RS
{
    if ([_glyphName isEqualToString: @"integral.v1"])
        return @"\\int";
    else if ([_glyphName isEqualToString: @"contourintegral.v1"])
        return @"\\oint";
    else if ([_glyphName isEqualTo: @"summation.v1"])
        return @"\\sum";
    else if ([_glyphName isEqualToString: @"product.v1"])
        return @"\\prod";

    else if ([_glyphName isEqualToString: @"uni222C.v1"])
        return @"\\iint";
    else if ([_glyphName isEqualToString: @"uni222D.v1"])
        return @"\\iiint";
    else
        return super.exportedLaTeXValue;
//        return @"?ga?";
}




#pragma mark - spriteKitNode

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [MHGlyphNode glyphNodeWithGlyphName:_glyphName];
        _spriteKitNode.ownerExpression = self;
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
    else {
        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitRoman];
    }
    
    bool highlightingOn = contextManager.textHighlighting;
    MHGlyphNode *glyphNode = self.spriteKitNode;
    [glyphNode configureWithFont:font
                           color:contextManager.textForegroundColor
                 backgroundColor:(highlightingOn ? contextManager.textHighlightColor : nil)
                     underlining:contextManager.textUnderlining
                   strikethrough:contextManager.textStrikethrough];
    self.dimensions = glyphNode.dimensions;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHGlyphAtom *myCopy = [[self class] glyphAtomWithGlyphName:[_glyphName copy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHGlyphCommandNameGlyph]) {
        // FIXME: problems with this command that need fixing:
        // 1. there should be a way to specify the typography class.
        // 2. "stringValue" sometimes returns incorrect values, especially when parsing in math mode.
        // 3. it needs to be made clearer which font is used to select the glyph. Maybe have separate commands for a math font glyph and a text font glyph? right now the glyph is typeset in the text font
        return [MHGlyphAtom glyphAtomWithGlyphName:argument.stringValue];
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHGlyphCommandNameGlyph ];
}



@end
