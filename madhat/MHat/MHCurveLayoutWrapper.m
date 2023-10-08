//
//  MHCurveLayoutWrapper.m
//  MadHat
//
//  Created by Dan Romik on 8/1/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCurveLayoutWrapper.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHTextAtom.h"
#import "MHTextNode.h"
#import "MHGraphicsCanvas.h"
#import "DRSmartBezierPath.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"

NSString * const kMHCurveLayoutCommandName = @"curved text layout";


@interface MHCurveLayoutWrapper ()
{
    MHHorizontalLayoutContainer *_graphicsPathExpression;
}

@end



@implementation MHCurveLayoutWrapper



#pragma mark - Constructors

+ (instancetype)curveLayoutWrapperWithContents:(MHExpression *)contents
                        graphicsPathExpression:(MHHorizontalLayoutContainer *)graphicsPathExpression
{
    return [[self alloc] initWithContents:contents graphicsPathExpression:graphicsPathExpression];
}

- (instancetype)initWithContents:(MHExpression *)contents
          graphicsPathExpression:(MHHorizontalLayoutContainer *)graphicsPathExpression
{
    if (self = [super initWithContents:contents]) {
        _graphicsPathExpression = graphicsPathExpression;
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(nullable NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHCurveLayoutCommandName] && [argument numberOfDelimitedBlocks]>=2) {
        MHHorizontalLayoutContainer *pathExpression = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:0];  // FIXME: casting is bad - improve to remove assumptions
        MHExpression *contents = [argument expressionFromDelimitedBlockAtIndex:1];
        
        return [self curveLayoutWrapperWithContents:contents graphicsPathExpression:pathExpression];
    }
    
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHCurveLayoutCommandName ];
}


#pragma mark - Splittable

- (bool)splittable
{
    return false;
}

- (bool)atomicForReformatting
{
    // FIXME: this is temporary and needs to be improved. Logically it doesn't make sense to return true, since ideally the contents of a curved layout wrapper should be able to contain things like slide fragments. However, with the current implementation of curved layout that involves creating new nodes that behave differently from the spriteKitNode property, it is necessary to do this, otherwise we get incorrect behavior in collapsible sections.
    // (a similar issue exists in the MHStyledTextWrapper class)
    return true;
}
    
    
#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    [_graphicsPathExpression typesetWithContextManager:contextManager];

    // create a graphics path to use for the text layout
    CGMutablePathRef mutablePath = nil;
    NSArray <MHExpression *> *flattenedPathExpressionList = [_graphicsPathExpression flattenedListOfUnsplittableComponents];
    for (MHExpression *subexpression in flattenedPathExpressionList) {
        if ([subexpression conformsToProtocol:@protocol(MHGraphicsExpressionWithPath)]) {
            CGPathRef subexpressionPath = [(NSObject <MHGraphicsExpressionWithPath> *)subexpression graphicsPath];
            if (mutablePath == nil) {
                mutablePath = CGPathCreateMutable();
            }
            CGPathAddPath(mutablePath, nil, subexpressionPath);
        }
    }
    
    if (!mutablePath)   // no primitives with a graphics path were found in the graphics path expression
        return;
    
    
    MHExpression *myContentsExpression = self.contents;
    if (![myContentsExpression isKindOfClass:[MHHorizontalLayoutContainer class]]) {
        // FIXME: this is a clunky workaround for a structural problem I need to fix involving an incompatibility between my assumptions on the class of the contents and what the code actually states the assumptions are - improve
        return;
    }
    
    MHHorizontalLayoutContainer *myContents = (MHHorizontalLayoutContainer *)myContentsExpression;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    
    // FIXME: This implementation is not very good OO practice (violates Demeter's principle etc)
    
    // the path is stored in the canvas coordinate system. Convert it to the node coordinate system
    MHDimensions canvasDimensions = contextManager.graphicsCanvasDimensions;
    MHGraphicsRectangle viewRectangle = contextManager.graphicsViewRectangle;
    CGAffineTransform affineTransform = CGAffineTransformIdentity;
    affineTransform = CGAffineTransformScale(affineTransform, canvasDimensions.width/(viewRectangle.maxX-viewRectangle.minX),
                                             canvasDimensions.height/(viewRectangle.maxY-viewRectangle.minY));
    affineTransform = CGAffineTransformTranslate(affineTransform, -viewRectangle.minX, -viewRectangle.minY);
    CGPathRef transformedPath;
    transformedPath = CGPathCreateCopyByTransformingPath(mutablePath, &affineTransform);
    
    // with the transformed path, create a smart Bezier path that knows how to make arc length calculations
    DRSmartBezierPath *bezierPath = [DRSmartBezierPath bezierPathWithCGPath:transformedPath];
    CGPathRelease(transformedPath);

    // now lay out the contents along the path
    NSArray <MHExpression *> *flattenedContents = [myContents flattenedListOfUnsplittableComponents];
    for (MHExpression *subexpression in flattenedContents) {
        SKNode *subexpressionNode = subexpression.spriteKitNode;
        SKNode *subexpressionNodeParent = subexpressionNode.parent;
        CGPoint subexpressionPosition = [mySpriteKitNode convertPoint:subexpression.position fromNode:subexpressionNodeParent];
        CGFloat distanceAlongCurve;
        CGPoint curvePosition;
        CGPoint tangentVector;
        if ([subexpression isMemberOfClass:[MHTextAtom class]]) {
            // FIXME: badly written hack to split atom into single character nodes that can be laid out along the path. IMPROVE
            MHTextNode *textNode = (MHTextNode *)subexpressionNode;        // FIXME: casting - bad to make assumptions
            textNode.hidden = true;
            NSArray <SKNode *> *singleCharNodes = [textNode createTextNodesForIndividualGlyphs];
            for (MHTextNode *singleCharNode in singleCharNodes) {
                CGPoint theCharPosition = singleCharNode.position;
                distanceAlongCurve = subexpressionPosition.x + theCharPosition.x;
                curvePosition = [bezierPath pointAtArcLengthParameter:distanceAlongCurve
                                                 tangentVectorPointer:&tangentVector];
                CGFloat curveTangentAngle = M_PI_2 - atan2(tangentVector.x, tangentVector.y);
                singleCharNode.position = [mySpriteKitNode convertPoint:curvePosition toNode:subexpressionNodeParent];
                singleCharNode.zRotation = curveTangentAngle;  // FIXME: this should be a property of the expression, not the node
                singleCharNode.name = @"singlecharnodes";
                [subexpressionNodeParent addChild:singleCharNode];
            }
        }
        else {
            distanceAlongCurve = subexpressionPosition.x;
            curvePosition = [bezierPath pointAtArcLengthParameter:distanceAlongCurve
                                             tangentVectorPointer:&tangentVector];
            CGFloat curveTangentAngle = M_PI_2 - atan2(tangentVector.x, tangentVector.y);
            subexpression.position = [mySpriteKitNode convertPoint:curvePosition toNode:subexpressionNodeParent];
            subexpressionNode.zRotation = curveTangentAngle;  // FIXME: this should be a property of the expression, not the node
        }
    }
}


#pragma mark - Rendering into a graphics context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    // FIXME: very hack-y, non-OO code. Improve
    
    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    MHHorizontalLayoutContainer *myContents = (MHHorizontalLayoutContainer *)self.contents;
    NSArray <MHExpression *> *flattenedContents = [myContents flattenedListOfUnsplittableComponents];
    for (MHExpression *subexpression in flattenedContents) {
        SKNode *subexpressionNode = subexpression.spriteKitNode;
        SKNode *subexpressionNodeParent = subexpressionNode.parent;
        if ([subexpression isMemberOfClass:[MHTextAtom class]] && ((MHTextAtom *)subexpression).stringValue.length>1) {
            // FIXME: very badly written hack to split atom into single character nodes that can be laid out along the path. IMPROVE
            NSArray <SKNode *> *singleCharNodes = [subexpressionNodeParent objectForKeyedSubscript:@"singlecharnodes"];
            
            for (SKNode *singleCharNode in singleCharNodes) {
                CGPoint theCharPosition = singleCharNode.position;
                CGPoint theCharPositionInMyNodeCoordinates = [mySpriteKitNode convertPoint:theCharPosition fromNode:subexpressionNodeParent];
                CGFloat theCharAngle = singleCharNode.zRotation;
                
                CGContextTranslateCTM(pdfContext, theCharPositionInMyNodeCoordinates.x, theCharPositionInMyNodeCoordinates.y);
                CGContextRotateCTM(pdfContext, theCharAngle);
                // FIXME: add this
                NSLog(@"need to add code to render a glyph from MHCurveLayout into a PDF context");
                CGContextRotateCTM(pdfContext, -theCharAngle);
                CGContextTranslateCTM(pdfContext, -theCharPositionInMyNodeCoordinates.x, -theCharPositionInMyNodeCoordinates.y);
            }
        }
        else {
            CGPoint position = subexpression.position;
            CGPoint positionInMyNodeCoordinates = [mySpriteKitNode convertPoint:position fromNode:subexpressionNodeParent];
            CGFloat rotationAgle = subexpression.spriteKitNode.zRotation;
            CGContextTranslateCTM(pdfContext, positionInMyNodeCoordinates.x, positionInMyNodeCoordinates.y);
            CGContextRotateCTM(pdfContext, rotationAgle);
            [subexpression renderToPDFWithContextManager:contextManager];
            CGContextRotateCTM(pdfContext, -rotationAgle);
            CGContextTranslateCTM(pdfContext, -positionInMyNodeCoordinates.x, -positionInMyNodeCoordinates.y);
        }
    }
    
    CGContextRestoreGState(pdfContext);
}


    
    
    
#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHCurveLayoutWrapper *myCopy = [[self class] curveLayoutWrapperWithContents:self.contents
                                                         graphicsPathExpression:[_graphicsPathExpression logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


@end
