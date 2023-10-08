//
//  MHScriptedExpression.m
//  MadHat
//
//  Created by Dan Romik on 10/21/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHScriptedExpression.h"

NSString * const kMHScriptedExpressionSubscriptCommandName = @"subscript";
NSString * const kMHScriptedExpressionSuperscriptCommandName = @"superscript";
NSString * const kMHScriptedExpressionSubsuperscriptCommandName = @"subsuperscript";


// See pages 140-141 in The TeXBook
NSUInteger const kMHScriptedExpressionSuperscriptNestingLevels[kMHNumberOfNestingLevels] = {
    4, 5, 4, 5, 6, 7, 6, 7
};
NSUInteger const kMHScriptedExpressionSubscriptNestingLevels[kMHNumberOfNestingLevels] = {
    5, 5, 5, 5, 7, 7, 7, 7
};

@interface MHScriptedExpression ()
{
    MHExpression *_body;
    MHExpression *_subscript;
    MHExpression *_superscript;
}

@end


@implementation MHScriptedExpression

#pragma mark - Constructor method

+ (instancetype)scriptedExpressionWithBody:(MHExpression *)body
                                 subscript:(MHExpression *)subscript
                               superscript:(MHExpression *)superscript
{
    
    return [[self alloc] initWithBody:body subscript:subscript superscript:superscript];
}

- (instancetype)initWithBody:(MHExpression *)body subscript:(MHExpression *)subscript superscript:(MHExpression *)superscript
{
    if (self = [super init]) {
        self.body = body;
        self.subscript = subscript;
        self.superscript = superscript;
    }
    return self;
}

- (NSArray <MHExpression *> *)subexpressions
{
    return @[ _body, _subscript, _superscript ];
}



#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name
              withParameters:(nullable NSDictionary *)parameters
                    argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHScriptedExpressionSubscriptCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        MHExpression *bodyExpression = (numberOfDelimitedBlocks >= 1 ?
                                        [argument expressionFromDelimitedBlockAtIndex:0] : [MHExpression expression]);
        MHExpression *subscriptExpression = (numberOfDelimitedBlocks >= 2 ?
                                             [argument expressionFromDelimitedBlockAtIndex:1] : [MHExpression expression]);
        MHExpression *superscriptExpression = [MHExpression expression];
        return [self scriptedExpressionWithBody:bodyExpression subscript:subscriptExpression superscript:superscriptExpression];
    }
    if ([name isEqualToString:kMHScriptedExpressionSuperscriptCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        MHExpression *bodyExpression = (numberOfDelimitedBlocks >= 1 ?
                                        [argument expressionFromDelimitedBlockAtIndex:0] : [MHExpression expression]);
        MHExpression *superscriptExpression = (numberOfDelimitedBlocks >= 2 ?
                                             [argument expressionFromDelimitedBlockAtIndex:1] : [MHExpression expression]);
        MHExpression *subscriptExpression = [MHExpression expression];
        return [self scriptedExpressionWithBody:bodyExpression subscript:subscriptExpression superscript:superscriptExpression];
    }
    if ([name isEqualToString:kMHScriptedExpressionSubsuperscriptCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        MHExpression *bodyExpression = (numberOfDelimitedBlocks >= 1 ?
                                        [argument expressionFromDelimitedBlockAtIndex:0] : [MHExpression expression]);
        MHExpression *subscriptExpression = (numberOfDelimitedBlocks >= 2 ?
                                             [argument expressionFromDelimitedBlockAtIndex:1] : [MHExpression expression]);
        MHExpression *superscriptExpression = (numberOfDelimitedBlocks >= 3 ?
                                               [argument expressionFromDelimitedBlockAtIndex:2] : [MHExpression expression]);
        return [self scriptedExpressionWithBody:bodyExpression subscript:subscriptExpression superscript:superscriptExpression];
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHScriptedExpressionSubscriptCommandName ];
}



# pragma mark - Properties

- (MHExpression *)body
{
    return _body;
}
- (void)setBody:(MHExpression *)newBody
{
    _body.parent = nil;
    _body = newBody;
    _body.parent = self;
    _body.presentationMode = self.presentationMode;
    _body.nestingLevel = self.nestingLevel;
}

- (MHExpression *)subscript
{
    return _subscript;
}
- (void)setSubscript:(MHExpression *)newSubscript
{
    _subscript.parent = nil;
    _subscript = newSubscript;
    _subscript.parent = self;
    _subscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[self.nestingLevel];
    _subscript.presentationMode = self.presentationMode;
}

- (MHExpression *)superscript
{
    return _superscript;
}
- (void)setSuperscript:(MHExpression *)newSuperscript
{
    _superscript.parent = nil;
    _superscript = newSuperscript;
    _superscript.parent = self;
    _superscript.nestingLevel = kMHScriptedExpressionSuperscriptNestingLevels[self.nestingLevel];
    _superscript.presentationMode = self.presentationMode;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    _body.nestingLevel = nestingLevel;
    _subscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[nestingLevel];
    _superscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[nestingLevel];
}

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassCompoundExpression;
}

- (MHTypographyClass)leftTypographyClass
{
    return self.body.leftTypographyClass;
}

- (MHTypographyClass)rightTypographyClass
{
    return MHTypographyClassCompoundExpression;
}

- (bool)splittable  // FIXME: seems unnecessary, this behavior is inherited from the superclass
{
    return false;
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"{%@}_{%@}^{%@}", _body.stringValue, _subscript.stringValue, _superscript.stringValue];
}

- (NSString *) exportedLaTeXValue //RS-this has been improved so that the latex string does not include empty expressions when a supercript or subscript is absent.
//FIXME: Need more robust way than comparing self.superscript.strinValue with @"" to check if prescript or postscript is absent.
{
    if ([self.superscript.stringValue isEqualToString: @""] &&
         [self.subscript.stringValue isEqualToString: @""])
    {
        return self.body.exportedLaTeXValue;
    }
    else if ([self.superscript.stringValue isEqualToString: @""])
    {
        return [NSString stringWithFormat:@"%@_{%@}", self.body.exportedLaTeXValue,
                self.subscript.exportedLaTeXValue];
    }
    else if ([self.subscript.stringValue isEqualToString: @""])
    {
        return [NSString stringWithFormat:@"%@^{%@}", self.body.exportedLaTeXValue,
                self.superscript.exportedLaTeXValue];
    }
    else
    {
        return [NSString stringWithFormat:@"%@_{%@}^{%@}", self.body.exportedLaTeXValue,
         self.subscript.exportedLaTeXValue,
         self.superscript.exportedLaTeXValue];
    }
}




#pragma mark - MHBracket protocol

- (bool)heightIsAdjustable
{
    MHExpression *myBody = self.body;
    return ([myBody conformsToProtocol:@protocol(MHBracket)] && [(id <MHBracket>)myBody heightIsAdjustable]);
}

- (MHBracketOrientation)orientation
{
    // FIXME: maybe make this more robust by checking first that myBody actually conforms to the MHBracket protocol?
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    return myBody.orientation;
}
- (void)setOrientation:(MHBracketOrientation)orientation
{
    // FIXME: maybe make this more robust by checking first that myBody actually conforms to the MHBracket protocol?
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    myBody.orientation = orientation;
}


- (MHDimensions)dimensionsIgnoringWidth
{
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    return myBody.dimensionsIgnoringWidth;
}

- (void)setDimensionsIgnoringWidth:(MHDimensions)dimensions
{
    // FIXME: not sure this is a robust solution, improve
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    myBody.dimensionsIgnoringWidth = dimensions;
//    if (_spriteKitNode) {
//        // FIXME: this approach isn't very good object-oriented programming
//        SKNode *spriteKitNodeParent = _spriteKitNode.parent;
//        [_spriteKitNode removeFromParent];
//        _spriteKitNode = nil;
//        [spriteKitNodeParent addChild:self.spriteKitNode];
//    }
}

- (NSUInteger)sizeVariant
{
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    return myBody.sizeVariant;
}

- (void)setSizeVariant:(NSUInteger)sizeVariant
{
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    myBody.sizeVariant = sizeVariant;
}

- (MHBracketType)type
{
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    return myBody.type;
}

- (void)setType:(MHBracketType)type
{
    MHExpression <MHBracket> *myBody = (MHExpression <MHBracket> *)self.body;
    myBody.type = type;
}







#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    MHDimensions myDimensions, bodyDimensions, subscriptDimensions, superscriptDimensions;
    NSPoint subscriptPosition, superscriptPosition;

    MHExpression *myBody = self.body;
    MHExpression *mySubscript = self.subscript;
    MHExpression *mySuperscript = self.superscript;
    
    bodyDimensions = myBody.dimensions;
    subscriptDimensions = mySubscript.dimensions;
    superscriptDimensions = mySuperscript.dimensions;

    NSUInteger nestingLevel = self.nestingLevel;
    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];

    if (myBody.isLimitsOperator) {
        
        float bottomSpacing = 3.0/24.0; // FIXME: make this a math font parameter
        float topSpacing = 2.0/24.0; // FIXME: make this a math font parameter

        myDimensions.width = fmax(bodyDimensions.width, fmax(subscriptDimensions.width, superscriptDimensions.width));
        myDimensions.height = bodyDimensions.height + topSpacing * emWidth + superscriptDimensions.depth + superscriptDimensions.height;
        myDimensions.depth = bodyDimensions.depth + bottomSpacing * emWidth + subscriptDimensions.height + subscriptDimensions.depth;

        // figure out subscript and superscript position
        subscriptPosition.x = (myDimensions.width - subscriptDimensions.width)/2.0;
        superscriptPosition.x = (myDimensions.width - superscriptDimensions.width)/2.0;
        
        subscriptPosition.y = - bodyDimensions.depth - bottomSpacing * emWidth - subscriptDimensions.height;
        superscriptPosition.y = bodyDimensions.height + topSpacing * emWidth + superscriptDimensions.depth;

        myBody.position = NSMakePoint((myDimensions.width - bodyDimensions.width)/2.0, 0.0);
        mySubscript.position = subscriptPosition;
        mySuperscript.position = superscriptPosition;
    }
    else {
        myBody.position = NSMakePoint(0.0, 0.0);

        NSFont *mathFont = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];
        CGFloat xHeight = mathFont.xHeight;

        // figure out subscript and superscript position
        
        // FIXME: improve this
        // Note: the TeX rules for positioning of subscripts and superscripts are described in Sections 756-758, pages 316-317 of Knuth's TeX: The Program and in Rule 18 on pages 445-446 of The TeXBook
        
        short int bodyRightPadding = 75;            // FIXME: make this a font parameter
        
        short int italicCorrection = myBody.rightItalicCorrection;   // FIXME: this needs to be read from the font. (Reference: Section 543, p. 218 of Knuth's TeX: The Program)
        
        // FIXME: implement the precise algorithm for positioning of subscripts and superscripts, described in Sections 756-758, pages 316-317 of Knuth's TeX: The Program
        
        [self calculateSubscriptAndSuperscriptVerticalPositionsForBodyDimensions:bodyDimensions
                                                             subscriptDimensions:subscriptDimensions
                                                           superscriptDimensions:superscriptDimensions
                                                                         xHeight:xHeight
                                                            subscriptYPositionPtr:&(subscriptPosition.y)
                                                          superscriptYPositionPtr:&(superscriptPosition.y)];
        

        superscriptPosition.x = bodyDimensions.width + emWidth * (float)bodyRightPadding/1000.0;
        subscriptPosition.x = superscriptPosition.x - emWidth * (float)italicCorrection/1000.0;
        
        mySubscript.position = subscriptPosition;
        mySuperscript.position = superscriptPosition;

        myDimensions.width = fmax(subscriptPosition.x + subscriptDimensions.width, superscriptPosition.x + superscriptDimensions.width);
        myDimensions.height = fmax(bodyDimensions.height, superscriptPosition.y+superscriptDimensions.height);
        myDimensions.depth = fmax(bodyDimensions.depth, -subscriptPosition.y+subscriptDimensions.depth);
    }
    self.dimensions = myDimensions;
}

- (void)calculateSubscriptAndSuperscriptVerticalPositionsForBodyDimensions:(MHDimensions)bodyDimensions
                                                       subscriptDimensions:(MHDimensions)subscriptDimensions
                                                     superscriptDimensions:(MHDimensions)superscriptDimensions
                                                                   xHeight:(CGFloat)xHeight
                                                      subscriptYPositionPtr:(CGFloat *)subscriptYPositionPtr
                                                    superscriptYPositionPtr:(CGFloat *)superscriptYPositionPtr
{
    // FIXME: implement the precise algorithm for positioning of subscripts and superscripts, described in Sections 756-758, pages 316-317 of Knuth's TeX: The Program
    short int subscriptVerticalOffset = 1250;    // FIXME: make this a font parameter
    short int superscriptVerticalOffset = 1000;  // FIXME: make this a font parameter
    
    *subscriptYPositionPtr = -bodyDimensions.depth - subscriptDimensions.height + xHeight * (float)subscriptVerticalOffset/1000.0;
    *superscriptYPositionPtr = bodyDimensions.height - xHeight * (float)superscriptVerticalOffset/1000.0;
}





#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHScriptedExpression *myCopy = [[self class] scriptedExpressionWithBody:[_body logicalCopy]
                                                                  subscript:[_subscript logicalCopy]
                                                                superscript:[_superscript logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}






#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ body=%@ subscr=%@ superscr=%@>",
            [self className], self.body.description, self.subscript.description, self.superscript.description];
}



@end
