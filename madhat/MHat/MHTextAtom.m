//
//  MHTextAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTextAtom.h"
#import "MHOldTextNode.h"
#import "MHStyleIncludes.h"
#import "MHTextNode.h"
#import "NSString+TextSubstitution.h"


 
@interface MHTextAtom ()
{
    MHTextSubstitutionType _substitutionType;
}

@property MHTextNode *spriteKitNode;    // redeclare the property as an MHTextNode instance to improve type checking


@end


@implementation MHTextAtom

@dynamic spriteKitNode; // tells the compiler the property is already implemented by a superclass and does not need to be synthesized


+ (instancetype)textAtomWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string
{
    if (self = [super init]) {
        _text = string;
    }
    return self;
}

#pragma mark - Properties

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassText;
}

- (NSString *)text
{
    return (_substitutionType == MHTextSubstitutionNone ? _text : [_text stringByApplyingSubstitution:_substitutionType]);
}

- (NSString *)stringValue
{
    return self.text;
}




#pragma mark - spriteKitNode

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [MHTextNode textNodeWithString:self.text];
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
    else if (typographyClass == MHTypographyClassItalicMathVariable) {
        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitItalic];
    }
    else {
        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitRoman];
    }
    
    _substitutionType = contextManager.textSubstitutionType;
    
    if (_substitutionType != MHTextSubstitutionNone && _spriteKitNode) {
        // FIXME: seems wasteful to create the spriteKitNode property and then destroy and recreate it. Fortunately it only happens when text substitution is turned on, which would be only rarely, so leaving it for now. IMPROVE. There's a similar issue in the MHMathAtom class.

        SKNode *spriteKitnodeParent = _spriteKitNode.parent;
        [_spriteKitNode removeFromParent];
        _spriteKitNode = nil;
        SKNode *newSpriteKitNode = self.spriteKitNode;
        [spriteKitnodeParent addChild:newSpriteKitNode];
    }
    
    bool highlightingOn = contextManager.textHighlighting;
    MHTextNode *textNode = self.spriteKitNode;
    [textNode configureWithFont:font
                          color:contextManager.textForegroundColor
                backgroundColor:(highlightingOn ? contextManager.textHighlightColor : nil)
                    underlining:contextManager.textUnderlining
                  strikethrough:contextManager.textStrikethrough];
    self.dimensions = textNode.dimensions;
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHTextAtom *myCopy = [[self class] textAtomWithString:[_text copy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


-(NSString *)exportedLaTeXValue //RS - use _text here and not self.text
{
    return _text;
}



@end
