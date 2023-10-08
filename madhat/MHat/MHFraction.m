//
//  MHFraction.m
//  MadHat
//
//  Created by Dan Romik on 10/25/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MadHat.h"
#import "MHFraction.h"
#import "MHBracket.h"
#import "MHMathAtom.h"
#import "MHStyleIncludes.h"


NSString * const kMHFractionCommandNameFraction = @"fraction";
NSString * const kMHFractionCommandNameFractionNoLine = @"quasifraction";
NSString * const kMHFractionCommandNameBinomial = @"binomial";
//NSString * const kMHFractionCommandNameLegendreSymbol = @"legendresymbol";    // FIXME: disabling this, seems not useful enough to clutter up the command system
NSString * const kMHFractionCommandNameContinuedFraction = @"continued fraction";

NSString * const kMHFractionFractionLineNodeName = @"MHFractionFractionLineNodeName";

static NSUInteger const kMHFractionNumeratorNestingLevels[kMHNumberOfNestingLevels] = {
    2, 3, 4, 5, 6, 7, 6, 7
};
static NSUInteger const kMHFractionDenominatorNestingLevels[kMHNumberOfNestingLevels] = {
    3, 3, 5, 5, 7, 7, 7, 7
};

@interface MHFraction ()
{
    MHExpression *_numerator;
    MHExpression *_denominator;
    bool _showsFractionLine;
}

@end


@implementation MHFraction

#pragma mark - Constructor methods

+ (instancetype)fractionWithNumerator:(MHExpression *)numerator denominator:(MHExpression *)denominator
{
    return [[self alloc] initWithNumerator:numerator denominator:denominator showsFractionLine:true];
}

+ (instancetype)noLineFractionWithNumerator:(MHExpression *)numerator denominator:(MHExpression *)denominator
{
    return [[self alloc] initWithNumerator:numerator denominator:denominator showsFractionLine:false];
}

- (instancetype)initWithNumerator:(MHExpression *)numerator denominator:(MHExpression *)denominator showsFractionLine:(bool)showsFractionLine
{
    if (self = [super init]) {      // FIXME: this should call the superclass's designated initializer
        self.numerator = numerator;
        self.denominator = denominator;
        _showsFractionLine = showsFractionLine;
    }
    return self;
}



#pragma mark - MHCommand protocol


+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:(NSString *)kMHFractionCommandNameFraction]) {
            return [self fractionWithNumerator:[argument expressionFromDelimitedBlockAtIndex:0]
                                   denominator:[argument expressionFromDelimitedBlockAtIndex:1]];
    }
    if ([name isEqualToString:(NSString *)kMHFractionCommandNameFractionNoLine]) {
        return [self noLineFractionWithNumerator:[argument expressionFromDelimitedBlockAtIndex:0]
                                     denominator:[argument expressionFromDelimitedBlockAtIndex:1]];
    }

//    bool binomial;
//    bool legendreSymbol = false;
//    if ((binomial = [name isEqualToString:kMHFractionCommandNameBinomial])
//        || (legendreSymbol = [name isEqualToString:(NSString *)kMHFractionCommandNameLegendreSymbol])) {

    if ([name isEqualToString:kMHFractionCommandNameBinomial]) {
        MHHorizontalLayoutContainer *container = [MHHorizontalLayoutContainer expression];
        MHBracket *leftParenthesis = [MHBracket bracketWithType:MHBracketTypeParenthesis
                                                                        orientation:MHBracketLeftOrientation
                                                                            variant:MHBracketDynamicallyDeterminedSize];
        MHFraction *fraction;
        MHExpression *numerator = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *denominator = [argument expressionFromDelimitedBlockAtIndex:1];
//        if (binomial) {
//            fraction = [self noLineFractionWithNumerator:numerator denominator:denominator];
//        }
//        else {
//            fraction = [self fractionWithNumerator:numerator denominator:denominator];
//        }
        
        fraction = [self noLineFractionWithNumerator:numerator denominator:denominator];
        
        MHBracket *rightParenthesis = [MHBracket bracketWithType:MHBracketTypeParenthesis
                                                                         orientation:MHBracketRightOrientation
                                                                             variant:MHBracketDynamicallyDeterminedSize];

        [container addSubexpression:leftParenthesis];
        [container addSubexpression:fraction];
        [container addSubexpression:rightParenthesis];
        return container;
    }
    if ([name isEqualToString:kMHFractionCommandNameContinuedFraction]) {
        
        // FIXME: refactor this to be its own method
        
        NSUInteger numberOfBlocks = [argument numberOfDelimitedBlocks];
        if (numberOfBlocks < 1) {
            return nil;
        }
        
        MHMathAtom *oneExpression;
        MHExpression *currentExpression = [argument expressionFromDelimitedBlockAtIndex:numberOfBlocks - 1];
        MHExpression *previousExpression;
        
        NSInteger blockIndex = numberOfBlocks-2;
        
        while (blockIndex >= 0) {
            previousExpression = currentExpression;
            currentExpression = [MHHorizontalLayoutContainer expression];
            MHExpression *currentBlock = [argument expressionFromDelimitedBlockAtIndex:blockIndex];
            [(MHHorizontalLayoutContainer *)currentExpression addSubexpression:currentBlock];     // FIXME: refactor to eliminate casting
            
            MHMathAtom *plusSign = [MHMathAtom mathAtomWithString:@"+" typographyClass:MHTypographyClassBinaryOperator];
            [(MHHorizontalLayoutContainer *)currentExpression addSubexpression:plusSign];     // FIXME: refactor to eliminate casting
            
            MHMathAtom *oneExpression = [MHMathAtom mathAtomWithString:@"1" typographyClass:MHTypographyClassNumber];
            MHFraction *fraction = [MHFraction fractionWithNumerator:oneExpression denominator:previousExpression];
            [(MHHorizontalLayoutContainer *)currentExpression addSubexpression:fraction];     // FIXME: refactor to eliminate casting
            
            blockIndex--;
        }
        
        oneExpression = [MHMathAtom mathAtomWithString:@"1" typographyClass:MHTypographyClassNumber];
        
        return [MHFraction fractionWithNumerator:oneExpression denominator:currentExpression];
    }

    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHFractionCommandNameFraction,
        kMHFractionCommandNameFractionNoLine,
        kMHFractionCommandNameBinomial,
        kMHFractionCommandNameContinuedFraction,
//        kMHFractionCommandNameLegendreSymbol
    ];
}




#pragma mark - Subexpressions

- (NSArray <MHExpression *> *)subexpressions
{
    return @[ _numerator, _denominator ];
}


#pragma mark - Properties

- (MHExpression *)numerator
{
    return _numerator;
}

- (void)setNumerator:(MHExpression *)numerator
{
    _numerator.parent = nil;
    _numerator = numerator;
    _numerator.parent = self;
    numerator.nestingLevel = kMHFractionNumeratorNestingLevels[self.nestingLevel];
    _numerator.presentationMode = self.presentationMode;
}

- (MHExpression *)denominator
{
    return _denominator;
}

- (void)setDenominator:(MHExpression *)denominator
{
    _denominator.parent = nil;
    _denominator = denominator;
    _denominator.parent = self;
    denominator.nestingLevel = kMHFractionDenominatorNestingLevels[self.nestingLevel];
    _denominator.presentationMode = self.presentationMode;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    _numerator.nestingLevel = kMHFractionNumeratorNestingLevels[nestingLevel];
    _denominator.nestingLevel = kMHFractionDenominatorNestingLevels[nestingLevel];
}

- (bool)showsFractionLine
{
    return _showsFractionLine;
}

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassCompoundExpression;
}
- (MHTypographyClass)leftTypographyClass
{
    return MHTypographyClassCompoundExpression;
}
- (MHTypographyClass)rightTypographyClass
{
    return MHTypographyClassCompoundExpression;
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@/%@", _numerator.stringValue, _denominator.stringValue];
}

- (NSString *)exportedLaTeXValue
{
    if (!_showsFractionLine) {
        // FIXME: for binomial coefficients, this will typeset correctly but produces bad latex code - improve
        return [NSString stringWithFormat:@"{{%@}\\atop{%@}}", _numerator.exportedLaTeXValue,_denominator.exportedLaTeXValue];
    }
    
 return [NSString stringWithFormat:@"\\frac{%@}{%@}",
         _numerator.exportedLaTeXValue, _denominator.exportedLaTeXValue];
}






#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];

    MHDimensions myDimensions, numeratorDimensions, denominatorDimensions;
    NSPoint numeratorPosition, denominatorPosition;
    
    NSUInteger nestingLevel = self.nestingLevel;
    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];
    CGFloat mathAxisHeight = [contextManager mathAxisHeightForNestingLevel:nestingLevel];
    CGFloat fractionLineThickness = [contextManager fractionLineThicknessForNestingLevel:nestingLevel];
    
    CGFloat numeratorBottomPadding = ((CGFloat)100)/1000.0 * emWidth;    // FIXME: this parameter should be obtained from the math font through the typesetting context manager
    CGFloat denominatorTopPadding = ((CGFloat)100)/1000.0 * emWidth;     // FIXME: this parameter should be obtained from the math font through the typesetting context manager
    
    MHExpression *myNumerator = self.numerator;
    MHExpression *myDenominator = self.denominator;
    
    numeratorDimensions = myNumerator.dimensions;
    denominatorDimensions = myDenominator.dimensions;

    // figure out numerator and denominator position
    float maxWidth = fmax(numeratorDimensions.width, denominatorDimensions.width);
    numeratorPosition.x = (maxWidth - numeratorDimensions.width)/2.0;
    denominatorPosition.x = (maxWidth - denominatorDimensions.width)/2.0;
    
    numeratorPosition.y = mathAxisHeight + 1/2.0*fractionLineThickness + numeratorBottomPadding + numeratorDimensions.depth;
    denominatorPosition.y = mathAxisHeight - 1/2.0*fractionLineThickness - denominatorTopPadding - denominatorDimensions.height;
    
    myNumerator.position = numeratorPosition;
    myDenominator.position = denominatorPosition;

    myDimensions.width = fmax(numeratorDimensions.width, denominatorDimensions.width);
    myDimensions.height = mathAxisHeight + 1/2.0*fractionLineThickness + numeratorBottomPadding + numeratorDimensions.depth + numeratorDimensions.height;
    myDimensions.depth = -mathAxisHeight + 1/2.0*fractionLineThickness + denominatorTopPadding + denominatorDimensions.depth + denominatorDimensions.height;
    if (myDimensions.depth < 0.0)
        myDimensions.depth = 0.0;
    self.dimensions = myDimensions;

    [[_spriteKitNode childNodeWithName:kMHFractionFractionLineNodeName] removeFromParent];

    if (self.showsFractionLine) {
        // Old code: a simple filled rectangle using SKShapeNode. Disabling it since the SKShapeNode class has well-known behavior issues such as incorrect antialiasing
//        SKShapeNode *fractionLineNode = [SKShapeNode shapeNodeWithRect:
//                                         CGRectMake(0.0, mathAxisHeight - 1/2.0*fractionLineThickness,
//                                                    myDimensions.width, fractionLineThickness + 1.0)];
//        fractionLineNode.fillColor = contextManager.textForegroundColor;
//        fractionLineNode.name = kMHFractionFractionLineNodeName;
//        [_spriteKitNode addChild:fractionLineNode];
        
        
        
        // The fraction line will be a simple filled rectangle
        SKSpriteNode *fractionLineNode = [SKSpriteNode spriteNodeWithColor:contextManager.textForegroundColor size:CGSizeMake(myDimensions.width, fractionLineThickness)];
        fractionLineNode.position = CGPointMake(0.0, mathAxisHeight - fractionLineThickness/2.0);
        fractionLineNode.name = kMHFractionFractionLineNodeName;
        fractionLineNode.anchorPoint = CGPointZero;
        [_spriteKitNode addChild:fractionLineNode];
        
        
        
//        // New code: make it look nicer by giving it rounded caps     // FIXME: this would give the nicest look but caused weird issues with the positioning of the fraction line, disabling it for now
//        CGMutablePathRef fractionLinePath = CGPathCreateMutable();
//        CGPathMoveToPoint(fractionLinePath, nil, 0.0, mathAxisHeight);
//        CGPathAddLineToPoint(fractionLinePath, nil, myDimensions.width, mathAxisHeight);
//
//        // NOTE: in the renderToPDFWithContextManager method below we assume that this node is of class SKShapeNode!!!
//        SKShapeNode *fractionLineNode = [SKShapeNode shapeNodeWithPath:fractionLinePath];
//
//        CGPathRelease(fractionLinePath);
//
//        fractionLineNode.strokeColor = contextManager.textForegroundColor;
//        fractionLineNode.lineWidth = fractionLineThickness;
//        fractionLineNode.lineCap = kCGLineCapRound;
//        fractionLineNode.name = kMHFractionFractionLineNodeName;
//
//        [_spriteKitNode addChild:fractionLineNode];
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHFraction *myCopy = [[self class] fractionWithNumerator:[_numerator logicalCopy] denominator:[_denominator logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ numerator=%@ denominator=%@>",
            [self className],
            (self.numerator ? self.numerator.description : @"[none]"),
            (self.denominator ? self.denominator.description : @"[none]")];
}


# pragma mark - Rendering to graphics context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;
//    SKShapeNode *fractionLine = (SKShapeNode *)[self.spriteKitNode childNodeWithName:kMHFractionFractionLineNodeName];
//    if (fractionLine) {
//        CGContextSaveGState(context);
//        CGContextSetStrokeColorWithColor(context, [fractionLine.strokeColor CGColor]);
//        CGContextSetLineWidth(context, fractionLine.lineWidth);
//        CGContextSetLineCap(context, fractionLine.lineCap);
//        CGContextAddPath(context, fractionLine.path);
//        CGContextDrawPath(context, kCGPathStroke);
//        CGContextRestoreGState(context);
//    }

    // this corresponds to the use of SKSpriteNode to draw the fraction line (see the typesetWithContextManager: method implementation above)
    SKSpriteNode *fractionLine = (SKSpriteNode *)[self.spriteKitNode childNodeWithName:kMHFractionFractionLineNodeName];
    if (fractionLine) {
        CGContextSaveGState(pdfContext);
        CGContextSetFillColorWithColor(pdfContext, [fractionLine.color CGColor]);
//        CGContextSetLineWidth(context, fractionLine.lineWidth);
//        CGContextSetLineCap(context, fractionLine.lineCap);
//        CGContextAddPath(context, fractionLine.path);
        NSRect fractionLineRect = [fractionLine calculateAccumulatedFrame];
        CGContextFillRect(pdfContext, fractionLineRect);
        CGContextDrawPath(pdfContext, kCGPathFill);
        CGContextRestoreGState(pdfContext);
    }

}

@end
