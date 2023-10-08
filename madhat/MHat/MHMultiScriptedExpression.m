//
//  MHMultiScriptedExpression.m
//  MadHat
//
//  Created by Dan Romik on 8/17/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHMultiScriptedExpression.h"

NSString * const kMHMultiScriptedExpressionMultiScriptCommandName = @"multiscript";


@interface MHMultiScriptedExpression ()
{
    MHExpression *_presubscript;
    MHExpression *_presuperscript;
}

@end

@implementation MHMultiScriptedExpression


#pragma mark - Constructor methods

+ (instancetype)scriptedExpressionWithBody:(MHExpression *)body
                                 subscript:(MHExpression *)subscript
                               superscript:(MHExpression *)superscript
                              presubscript:(MHExpression *)presubscript
                            presuperscript:(MHExpression *)presuperscript
{
    return [[self alloc] initWithBody:body subscript:subscript superscript:superscript presubscript:presubscript presuperscript:presuperscript];
}

- (instancetype)initWithBody:(MHExpression *)body
                   subscript:(MHExpression *)subscript
                 superscript:(MHExpression *)superscript
                presubscript:(MHExpression *)presubscript
              presuperscript:(MHExpression *)presuperscript
{
    if (self = [super initWithBody:body subscript:subscript superscript:superscript]) {
        self.presubscript = presubscript;
        self.presuperscript = presuperscript;
    }
    return self;
}


#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name
              withParameters:(nullable NSDictionary *)parameters
                    argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHMultiScriptedExpressionMultiScriptCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        MHExpression *bodyExpression = (numberOfDelimitedBlocks >= 1 ?
                                        [argument expressionFromDelimitedBlockAtIndex:0] : [MHExpression expression]);
        MHExpression *subscriptExpression = (numberOfDelimitedBlocks >= 2 ?
                                             [argument expressionFromDelimitedBlockAtIndex:1] : [MHExpression expression]);
        MHExpression *superscriptExpression = (numberOfDelimitedBlocks >= 3 ?
                                               [argument expressionFromDelimitedBlockAtIndex:2] : [MHExpression expression]);
        MHExpression *presubscriptExpression = (numberOfDelimitedBlocks >= 4 ?
                                                [argument expressionFromDelimitedBlockAtIndex:3] : [MHExpression expression]);
        MHExpression *presuperscriptExpression = (numberOfDelimitedBlocks >= 5 ?
                                                  [argument expressionFromDelimitedBlockAtIndex:4] : [MHExpression expression]);
        return [self scriptedExpressionWithBody:bodyExpression
                                      subscript:subscriptExpression
                                    superscript:superscriptExpression
                                   presubscript:presubscriptExpression
                                 presuperscript:presuperscriptExpression];
    }
    return nil;
}

- (NSArray <MHExpression *> *)subexpressions
{
    return @[ self.body, self.subscript, self.superscript, _presubscript, _presuperscript ];
}


#pragma mark - Properties

- (MHExpression *)presubscript
{
    return _presubscript;
}
- (void)setPresubscript:(MHExpression *)newPresubscript
{
    _presubscript.parent = nil;
    _presubscript = newPresubscript;
    _presubscript.parent = self;
    _presubscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[self.nestingLevel];
    _presubscript.presentationMode = self.presentationMode;
}

- (MHExpression *)presuperscript
{
    return _presuperscript;
}
- (void)setPresuperscript:(MHExpression *)newPresuperscript
{
    _presuperscript.parent = nil;
    _presuperscript = newPresuperscript;
    _presuperscript.parent = self;
    _presuperscript.nestingLevel = kMHScriptedExpressionSuperscriptNestingLevels[self.nestingLevel];
    _presuperscript.presentationMode = self.presentationMode;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    _presubscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[nestingLevel];
    _presuperscript.nestingLevel = kMHScriptedExpressionSubscriptNestingLevels[nestingLevel];
}



#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];

    MHDimensions myDimensions, bodyDimensions, subscriptDimensions, superscriptDimensions, presubscriptDimensions, presuperscriptDimensions;
    NSPoint subscriptPosition, superscriptPosition, presubscriptPosition, presuperscriptPosition;

    MHExpression *myBody = self.body;
    MHExpression *mySubscript = self.subscript;
    MHExpression *mySuperscript = self.superscript;
    MHExpression *myPresubscript = self.presubscript;
    MHExpression *myPresuperscript = self.presuperscript;

    bodyDimensions = myBody.dimensions;
    subscriptDimensions = mySubscript.dimensions;
    superscriptDimensions = mySuperscript.dimensions;
    presubscriptDimensions = myPresubscript.dimensions;
    presuperscriptDimensions = myPresuperscript.dimensions;

    NSUInteger nestingLevel = self.nestingLevel;
    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];


    NSFont *mathFont = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];
    CGFloat xHeight = mathFont.xHeight;

    // figure out subscript and superscript position
    
    // FIXME: improve this
    // Note: the TeX rules for positioning of subscripts and superscripts are described in Sections 756-758, pages 316-317 of Knuth's TeX: The Program and in Rule 18 on pages 445-446 of The TeXBook
    
    short int bodyLeftPadding = 75;            // FIXME: make this a font parameter
    
    short int italicCorrection = myBody.leftItalicCorrection;   // FIXME: this needs to be read from the font. (Reference: Section 543, p. 218 of Knuth's TeX: The Program)
    
    [self calculateSubscriptAndSuperscriptVerticalPositionsForBodyDimensions:bodyDimensions
                                                         subscriptDimensions:presubscriptDimensions
                                                       superscriptDimensions:presuperscriptDimensions
                                                                     xHeight:xHeight
                                                        subscriptYPositionPtr:&(presubscriptPosition.y)
                                                      superscriptYPositionPtr:&(presuperscriptPosition.y)];
    

    CGFloat rightShift = fmax(presubscriptDimensions.width, presuperscriptDimensions.width - emWidth * (float)italicCorrection/1000.0)
                            + emWidth * (float)bodyLeftPadding/1000.0;
    myBody.position = CGPointMake(rightShift, 0.0);

    subscriptPosition = mySubscript.position;
    subscriptPosition.x += rightShift;
    mySubscript.position = subscriptPosition;

    superscriptPosition = mySuperscript.position;
    superscriptPosition.x += rightShift;
    mySuperscript.position = superscriptPosition;
    
    if (presubscriptDimensions.width < presuperscriptDimensions.width - emWidth * (float)italicCorrection/1000.0) {
        presubscriptPosition.x = presuperscriptDimensions.width - emWidth * (float)italicCorrection/1000.0 - presubscriptDimensions.width;
        presuperscriptPosition.x = 0.0;
    }
    else {
        presubscriptPosition.x = 0.0;
        presuperscriptPosition.x = presubscriptDimensions.width - presuperscriptDimensions.width + emWidth * (float)italicCorrection/1000.0;
    }
    myPresubscript.position = presubscriptPosition;
    myPresuperscript.position = presuperscriptPosition;

    myDimensions = self.dimensions;
    myDimensions.width = rightShift + myDimensions.width;
    myDimensions.height = fmax(myDimensions.height, presuperscriptPosition.y+presuperscriptDimensions.height);
    myDimensions.depth = fmax(myDimensions.depth, -presubscriptPosition.y+presubscriptDimensions.depth);

    self.dimensions = myDimensions;
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHMultiScriptedExpression *myCopy = [[self class] scriptedExpressionWithBody:[self.body logicalCopy]
                                                                       subscript:[self.subscript logicalCopy]
                                                                     superscript:[self.superscript logicalCopy]
                                                                    presubscript:[_presubscript logicalCopy]
                                                                  presuperscript:[_presuperscript logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



//- (NSString *) exportedLaTeXValue //RS - It looks like an exportedLaTexValue method is not needed here. Why not? Because its only added value over the same method in the parent class would be to implement prescripts. But those can't be done in LaTeX, and the multiscript command is already implemented in such a way that its call to the parent method exports to latex the correct expression, except with all prescripts absent. Anyway, below is a working implementation of the empty-block hack normally used in LaTeX.
//{
//    if ([self.presubscript.stringValue isEqualToString: @""] && [self.presuperscript.stringValue isEqualToString: @""])
//    {
//        return [super exportedLaTeXValue];
//    }
//    else if ([self.presubscript.stringValue isEqualToString: @""])
//    {
//        return [NSString stringWithFormat: @"{^%@}%@",self.presuperscript.exportedLaTeXValue,[super exportedLaTeXValue]];
//    }
//    else if ([self.presuperscript.exportedLaTeXValue isEqualToString: @""])
//    {
//        return [NSString stringWithFormat: @"{_{%@}}%@",self.presubscript.exportedLaTeXValue,[super exportedLaTeXValue]];
//    }
//    else
//    {
//        return [NSString stringWithFormat: @"{_{%@}^{%@}}%@",self.presubscript.exportedLaTeXValue,
//                self.presuperscript.exportedLaTeXValue, [super exportedLaTeXValue]];
//    }
//}



@end
