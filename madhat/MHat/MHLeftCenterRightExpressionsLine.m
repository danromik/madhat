//
//  MHLeftCenterRightExpressionsLine.m
//  MadHat
//
//  Created by Dan Romik on 11/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHLeftCenterRightExpressionsLine.h"
#import "MHStyleIncludes.h"

NSString * const kMHLeftRightExpressionsCommandName = @"left right line";
NSString * const kMHLeftCenterRightExpressionsCommandName = @"left center right line";

NSString * const kMHLeftCenterRightExpressionsUnderlineAttributeName = @"underline";
NSString * const kMHLeftCenterRightExpressionsOverlineAttributeName = @"overline";

NSString * const kMHLeftCenterRightExpressionsUnderlineNodeName = @"underline";
NSString * const kMHLeftCenterRightExpressionsOverlineNodeName = @"overline";

@interface MHLeftCenterRightExpressionsLine ()
{
    MHExpression *_leftExpression;
    MHExpression *_centerExpression;
    MHExpression *_rightExpression;
    bool _underline;
    bool _overline;
}

@property bool underline;
@property bool overline;

@end

@implementation MHLeftCenterRightExpressionsLine


#pragma mark - Constructors

+ (instancetype)leftRightLineWithLeftSideExpression:(MHExpression *)leftExpression rightSideExpression:(MHExpression *)rightExpression
{
    return [[self alloc] initWithLeftSideExpression:(MHExpression *)leftExpression
                                   centerExpression:nil
                                rightSideExpression:(MHExpression *)rightExpression];
}

+ (instancetype)leftCenterRightLineWithLeftSideExpression:(MHExpression *)leftExpression
                                         centerExpression:(MHExpression *)centerExpression
                                      rightSideExpression:(MHExpression *)rightExpression;
{
    return [[self alloc] initWithLeftSideExpression:(MHExpression *)leftExpression
                                   centerExpression:centerExpression
                                rightSideExpression:(MHExpression *)rightExpression];
}

- (instancetype)initWithLeftSideExpression:(MHExpression *)leftExpression
                          centerExpression:(MHExpression *)centerExpression
                       rightSideExpression:(MHExpression *)rightExpression
{
    if (self = [super init]) {
        _leftExpression = (leftExpression ? leftExpression : [MHExpression expression]);
        _centerExpression = (centerExpression ? centerExpression : [MHExpression expression]);
        _rightExpression = (rightExpression ? rightExpression : [MHExpression expression]);
    }
    return self;
}

#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    bool includeCenter = false;
    if ([name isEqualToString:kMHLeftRightExpressionsCommandName]
        || (includeCenter = [name isEqualToString:kMHLeftCenterRightExpressionsCommandName])) {
        
        MHLeftCenterRightExpressionsLine *expressionToReturn;
        
        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        bool turnOnUnderline = false;
        bool turnOnOverline = false;
        if (attributes) {
            MHExpression *underlineExpression = attributes[kMHLeftCenterRightExpressionsUnderlineAttributeName];
            turnOnUnderline = [underlineExpression boolValue];
            MHExpression *overlineExpression = attributes[kMHLeftCenterRightExpressionsOverlineAttributeName];
            turnOnOverline = [overlineExpression boolValue];
        }
        
        if (includeCenter) {
            MHExpression *leftExpression = [argument expressionFromDelimitedBlockAtIndex:0];
            MHExpression *centerExpression = ([argument numberOfDelimitedBlocks] >= 2 ? [argument expressionFromDelimitedBlockAtIndex:1] :
                                              [MHExpression expression]);
            MHExpression *rightExpression = ([argument numberOfDelimitedBlocks] >= 3 ? [argument expressionFromDelimitedBlockAtIndex:2]
                                             :[MHExpression expression]);
            expressionToReturn = [self leftCenterRightLineWithLeftSideExpression:leftExpression
                                                                centerExpression:centerExpression
                                                             rightSideExpression:rightExpression];
        }
        else {
            MHExpression *leftExpression = [argument expressionFromDelimitedBlockAtIndex:0];
            MHExpression *rightExpression = ([argument numberOfDelimitedBlocks] >= 2 ? [argument expressionFromDelimitedBlockAtIndex:1] :
                                             [MHExpression expression]);
            expressionToReturn = [self leftRightLineWithLeftSideExpression:leftExpression rightSideExpression:rightExpression];
        }
        if (turnOnUnderline)
            expressionToReturn.underline = true;
        if (turnOnOverline)
            expressionToReturn.overline = true;
        return expressionToReturn;
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHLeftRightExpressionsCommandName, kMHLeftCenterRightExpressionsCommandName ];
}


#pragma mark - Typesetting and sprite kit node

- (NSArray <MHExpression *> *)subexpressions
{
    return @[ _leftExpression, _centerExpression, _rightExpression ];
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    MHDimensions leftExpressionDimensions = _leftExpression.dimensions;
    MHDimensions centerExpressionDimensions = _centerExpression.dimensions;
    MHDimensions rightExpressionDimensions = _rightExpression.dimensions;
    
    MHDimensions myDimensions;
    
    myDimensions.depth = fmax(fmax(leftExpressionDimensions.depth, centerExpressionDimensions.depth), rightExpressionDimensions.depth);
    myDimensions.height = fmax(fmax(leftExpressionDimensions.height, centerExpressionDimensions.height), rightExpressionDimensions.height);
    
    myDimensions.width = contextManager.textWidth;
    
    _leftExpression.position = CGPointZero;
    _centerExpression.position = CGPointMake((myDimensions.width - centerExpressionDimensions.width)/2.0, 0.0);
    _rightExpression.position = CGPointMake(myDimensions.width - rightExpressionDimensions.width, 0.0);
    
    [[_spriteKitNode childNodeWithName:kMHLeftCenterRightExpressionsUnderlineNodeName] removeFromParent];
    [[_spriteKitNode childNodeWithName:kMHLeftCenterRightExpressionsOverlineNodeName] removeFromParent];

    // FIXME: improve
    static const CGFloat underlineVOffset = 6.0;
    static const CGFloat overlineVOffset = 2.0;

    if (_underline) {
        CGMutablePathRef underlinePath = CGPathCreateMutable();
        CGPathMoveToPoint(underlinePath, nil, 0.0, -underlineVOffset);
        CGPathAddLineToPoint(underlinePath, nil, myDimensions.width, -underlineVOffset);
        SKShapeNode *underlineNode = [SKShapeNode shapeNodeWithPath:underlinePath];
        CGPathRelease(underlinePath);
        underlineNode.strokeColor = contextManager.textForegroundColor;
        underlineNode.name = kMHLeftCenterRightExpressionsUnderlineNodeName;
        [self.spriteKitNode addChild:underlineNode];
    }
    
    if (_overline) {
        CGMutablePathRef underlinePath = CGPathCreateMutable();
        CGPathMoveToPoint(underlinePath, nil, 0.0, myDimensions.height + overlineVOffset);
        CGPathAddLineToPoint(underlinePath, nil, myDimensions.width, myDimensions.height + overlineVOffset);
        SKShapeNode *underlineNode = [SKShapeNode shapeNodeWithPath:underlinePath];
        CGPathRelease(underlinePath);
        underlineNode.strokeColor = contextManager.textForegroundColor;
        underlineNode.name = kMHLeftCenterRightExpressionsOverlineNodeName;
        [self.spriteKitNode addChild:underlineNode];
    }


    self.dimensions = myDimensions;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHLeftCenterRightExpressionsLine *myCopy = [[self class] leftCenterRightLineWithLeftSideExpression:[_leftExpression logicalCopy]
                                                                                      centerExpression:[_centerExpression logicalCopy]
                                                                                   rightSideExpression:[_rightExpression logicalCopy]];
    myCopy.codeRange = self.codeRange;
    myCopy.underline = _underline;
    myCopy.overline = _overline;
    return myCopy;
}



# pragma mark - Rendering to graphics context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;
    
    // FIXME: repetitive, violates DRY. Refactor to merge these two if clauses into a single one with a loop
    if (_underline) {
        SKShapeNode *underlineNode = (SKShapeNode *)[self.spriteKitNode
                                                     childNodeWithName:kMHLeftCenterRightExpressionsUnderlineNodeName];
        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [underlineNode.strokeColor CGColor]);
        
        // FIXME: setting line width of the overline/underline to half a point in the exported PDF since that seems to give a visually nice result for a small font size, but I'm not sure if it'll always be the best thing to do - IMPROVE
        CGContextSetLineWidth(pdfContext, 0.5); // underlineNode.lineWidth);
        
        CGContextSetLineCap(pdfContext, underlineNode.lineCap);
        CGContextAddPath(pdfContext, underlineNode.path);
        CGContextDrawPath(pdfContext, kCGPathStroke);
        CGContextRestoreGState(pdfContext);
    }

    if (_overline) {
        SKShapeNode *overlineNode = (SKShapeNode *)[self.spriteKitNode
                                                    childNodeWithName:kMHLeftCenterRightExpressionsOverlineNodeName];
        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [overlineNode.strokeColor CGColor]);
        
        // FIXME: setting line width of the overline/underline to half a point in the exported PDF since that seems to give a visually nice result for a small font size, but I'm not sure if it'll always be the best thing to do - IMPROVE
        CGContextSetLineWidth(pdfContext, 0.5); // overlineNode.lineWidth);
        
        CGContextSetLineCap(pdfContext, overlineNode.lineCap);
        CGContextAddPath(pdfContext, overlineNode.path);
        CGContextDrawPath(pdfContext, kCGPathStroke);
        CGContextRestoreGState(pdfContext);
    }
}


@end
