//
//  MHParagraph.m
//  MadHat
//
//  Created by Dan Romik on 11/3/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHParagraph.h"
#import "MHSlideFragment.h"
#import "MHStyleIncludes.h"

NSString * const kMHParagraphFrameNodeName = @"paragraph_frame";
NSString * const kMHParagraphFrameLinesNodeName = @"paragraph_frame_lines";

NSString * const kMHParagraphAlignmentAttributeName = @"align";
NSString * const kMHParagraphAlignmentAttributeRaggedLeft = @"left";
NSString * const kMHParagraphAlignmentAttributeCenter = @"center";
NSString * const kMHParagraphAlignmentAttributeRaggedRight = @"right";

const CGFloat kMHParagraphLogicalIndentationMultiplier = 36.0;  // by how many points do we indent list items to the right for each indentation level?  // FIXME: make this a configurable parameter
const CGFloat kMHParagraphBoxLeftRightPadding = 20.0;   // how much padding, in points, is used for boxes to the left and right     // FIXME: make this a configurable parameter

@interface MHParagraph ()
{
    MHTypesettingState *_memoizedStateBeforeTypesetting;
    MHTypesettingState *_memoizedStateAfterTypesetting;
    
    NSArray <MHExpression *> * _attachedContent;
    
    MHParagraphVerticalPadding _verticalPadding;    // FIXME: added as a temporary hack, improve
    MHParagraphBoxType _boxType;
    
    NSUInteger _numberOfSlideTransitions;
}

@end

@implementation MHParagraph

@dynamic dimensions;


#pragma mark - Properties

- (bool)locallyScoped
{
    return false;
}

- (MHLayoutType)layoutPreference
{
    return MHLayoutVertical;
}

- (NSArray <MHExpression *> *)attachedContent
{
    return _attachedContent;
}

- (void)setAttachedContent:(NSArray<MHExpression *> *)attachedContent
{
    _attachedContent = attachedContent;
}

- (MHParagraphType)type
{
    MHDimensions myDimensions = self.dimensions;
    return ((myDimensions.depth == 0.0 && myDimensions.height == 0.0) ? MHParagraphNone : MHParagraphNormal);
}

- (NSUInteger)numberOfSlideTransitions
{
    return _numberOfSlideTransitions;
}

#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSUInteger slideTransitionCounterAtBeginning = contextManager.slideTransitionCounter;
    [super typesetWithContextManager:contextManager];
    NSUInteger slideTransitionCounterAtEnd = contextManager.slideTransitionCounter;
    _numberOfSlideTransitions = slideTransitionCounterAtEnd - slideTransitionCounterAtBeginning;
    
    MHParagraphBoxType boxType = [contextManager readAndResetParagraphBoxType];
    self.boxType = boxType;

    // FIXME: with good design the snippet below should be inherited by the MHExpression implementation. However the chain of calls to super is broken with the MHHorizontalLayoutContainer class, whose implementation of typesetWithContextManager currently does not call the super implementation (for reasons to do with typesetting of expandable brackets apparently). This should be fixed at some point
    // Typeset any attached content
    NSArray <MHExpression *> *attachedContent = self.attachedContent;
    if (attachedContent) {
        for (MHExpression *attachedExpression in attachedContent) {
            [attachedExpression typesetWithContextManager:contextManager];
        }
    }
    
    MHDimensions myDimensions;
    
    // The width is read from the context manager
    myDimensions.width = contextManager.textWidth;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;
    self.dimensions = myDimensions;
}

- (void)doPostTypesettingHousekeeping
{
    MHDimensions myDimensions = self.dimensions;

    // add a physics body, which is used to detect which paragraph is in the page viewer view visible rectangle
    CGSize physicsBodySize = CGSizeMake(myDimensions.width, myDimensions.height + myDimensions.depth);
    CGPoint physicsBodyCenter = CGPointMake(myDimensions.width/2.0, (myDimensions.height - myDimensions.depth)/2.0);
    self.spriteKitNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:physicsBodySize center:physicsBodyCenter];
}


#pragma mark - Reformatting

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    // In a previous version, we called super to recursively reformat subcontainers using the implementation of the superclass,
    // and did some additional processing related to the outliner
    // In the current implementation we don't call super, but iterate through the subexpressions (duplicating that aspect of the superclass
    // implementation) in a specialized way that takes care of slide transitions
//    [super reformatWithContextManager:contextManager animationType:animationType];

    NSUInteger currentSlideTransitionIndex = contextManager.currentSlideTransitionIndex;    // this won't change throughout the method execution
    NSUInteger slideCounter = contextManager.slideCounter; // this could change as we recursively call the reformat method on subexpressions
    NSUInteger newSlideCounter;
    
    
//    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    NSArray *subexpressions = [self flattenedListOfAtomicComponentsForSlideTransitions];   // this will take longer to run, but will do the processing at the level of atomic expressions for slide transitions, which gives the correct behavior
    
    for (MHExpression *subexpression in subexpressions) {
        SKNode *subexpressionSpriteKitNode = subexpression.spriteKitNode;
        [subexpression reformatWithContextManager:contextManager animationType:animationType];
        newSlideCounter = contextManager.slideCounter;

        // FIXME: three method calls to the context manager. Is refactoring to get the same information with one method call worth the gain in efficiency?
        MHSlideTransitionAnimationType slideTransitionAnimationType = contextManager.currentAnimationType;
        MHSlideTransitionAnimationProfileType animationProfile = contextManager.currentAnimationProfile;
        double animationDuration = contextManager.currentAnimationDuration;
        
        MHNodeFormattingPositionType positionForAnimationType;
        switch (slideTransitionAnimationType) {
            case MHSlideTransitionAnimationSlideFromRight:
            case MHSlideTransitionAnimationSlideFromLeft:
            case MHSlideTransitionAnimationSlideFromTop:
            case MHSlideTransitionAnimationSlideFromBottom:
                positionForAnimationType = (MHNodeFormattingPositionType)slideTransitionAnimationType;
                break;
            case MHSlideTransitionAnimationNone:
            case MHSlideTransitionAnimationFadeIn:
                positionForAnimationType = MHNodePositionOffScreenRight;
                break;
            default:
                // This should never be executed, but just on the off-chance...
                positionForAnimationType = MHNodePositionDefault;
                break;
        }
        
        bool overrideDefaultBehaviorInSlideTransitions = false;
        if ([subexpression conformsToProtocol:@protocol(MHSlideFragment)])
            overrideDefaultBehaviorInSlideTransitions = ((NSObject <MHSlideFragment> *)subexpression).overrideDefaultBehaviorInSlideTransitions;

        if (overrideDefaultBehaviorInSlideTransitions) {
            // do nothing
        }
        else if (animationType == MHReformattingAnimationTypeSlideTransition
                 && currentSlideTransitionIndex != 0 && slideTransitionAnimationType != MHSlideTransitionAnimationNone) {
            // for the initial slide state, no animation is performed
            // if the slide break counter equals the current transition index, perform an animation
            slideCounter = newSlideCounter;
            if (slideCounter < currentSlideTransitionIndex) {
                [subexpressionSpriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionDefault];
            }
            else if (slideCounter > currentSlideTransitionIndex) {
                // the expression should be in the off-screen position
                [subexpressionSpriteKitNode moveToSlidePositionWithNoAnimation:positionForAnimationType];
            }
            else {  // the case when slideCounter == currentSlideTransitionIndex
                [subexpressionSpriteKitNode animatedSlideFromSlidePosition:positionForAnimationType
                                                           toSlidePosition:MHNodePositionDefault
                                                             animationType:slideTransitionAnimationType
                                                                  duration:animationDuration
                                                                   profile:animationProfile];
            }
        }
        else {  // reformatting without animation
            slideCounter = newSlideCounter;
            // check if the slide break counter equals or exceeds the current transition index, and set the subexpression's offset
            // based on that
            if (slideCounter <= currentSlideTransitionIndex) {
                // the expression should be in the default position
                [subexpressionSpriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionDefault];
            }
            else {
                // the expression should be in the off-screen position
                [subexpressionSpriteKitNode moveToSlidePositionWithNoAnimation:positionForAnimationType];
            }
        }
    }


    // outliner-related handling
    MHOutlinerVisibilityState visibilityState = [contextManager currentOutlinerVisibilityState];
    
    if (visibilityState & MHOutlinerVisibilityStateHiddenDueToAncestorNodeCollapsedPart) {
        MHDimensions myDimensions = self.dimensions;
        CGFloat offset = myDimensions.depth + myDimensions.height;
        [contextManager incrementCollapsedSectionsVerticalOffsetBy:offset];
    }
    else if (visibilityState & MHOutlinerVisibilityStateHiddenDueToCurrentNodeCollapsedPart) {
        CGFloat offset = [self verticalOffsetOfFollowingContentWhenCollapsedAtCurrentHierarchyLevel];
        [contextManager incrementCollapsedSectionsVerticalOffsetBy:offset];
    }
    
    
    bool hideFrameNode = (slideCounter > currentSlideTransitionIndex) || (visibilityState != MHOutlinerVisibilityStateVisible);
    SKNode *frameNode = [self.spriteKitNode childNodeWithName:kMHParagraphFrameNodeName];
    if (animationType == MHReformattingAnimationTypeOutliner) {
        SKAction *frameNodeAction = [SKAction fadeAlphaTo:(hideFrameNode ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
        [frameNode runAction:frameNodeAction];
    }
    else {
        CGFloat newAlpha = (hideFrameNode ? 0.0 : 1.0);
        frameNode.alpha = newAlpha;
    }
}

- (CGFloat)verticalOffsetOfFollowingContentWhenCollapsedAtCurrentHierarchyLevel
{
    MHDimensions myDimensions = self.dimensions;
    return myDimensions.depth + myDimensions.height;
}

- (bool)hasVisibleContentWhenCollapsed
{
    return false;
}


// FIXME: this is kind of a hack - improve
- (MHParagraphVerticalPadding)verticalPadding
{
    return _verticalPadding;
}

- (void)setVerticalPadding:(MHParagraphVerticalPadding)verticalPadding
{
    _verticalPadding = verticalPadding;
    
    SKShapeNode *oldBackgroundColorNode = (SKShapeNode *)[_spriteKitNode childNodeWithName:kMHParagraphFrameNodeName];
    if (oldBackgroundColorNode) {
        SKShapeNode *frameLinesnode = (SKShapeNode *)[oldBackgroundColorNode childNodeWithName:kMHParagraphFrameLinesNodeName];
        CGFloat frameThickness = frameLinesnode.lineWidth;
        
        SKShapeNode *newBackgroundColorNode = [self newParagraphBackgroundNodeWithBoxType:_boxType
                                                                               frameColor:oldBackgroundColorNode.strokeColor
                                                                          backgroundColor:oldBackgroundColorNode.fillColor
                                                                           frameThickness:frameThickness];

        [oldBackgroundColorNode removeFromParent];
        
        [_spriteKitNode addChild:newBackgroundColorNode];
    }
}


# pragma mark - Paragraph frames (experimental at this point)

- (SKShapeNode *)newParagraphBackgroundNodeWithBoxType:(MHParagraphBoxType)boxType
                                            frameColor:(nullable NSColor *)frameColor
                                       backgroundColor:(nullable NSColor *)backgroundColor
                                        frameThickness:(CGFloat)frameThickness
{
    MHDimensions myDimensions = self.dimensions;
    
    // FIXME: The numerical parameters below should be made customizable at some point
    SKShapeNode *paragraphFrameNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, -_verticalPadding.postParagraphSpacing, myDimensions.width, myDimensions.height + _verticalPadding.preParagraphSpacing + _verticalPadding.postParagraphSpacing)];
    
    if (frameColor) {
        CGMutablePathRef frameLinesPath = CGPathCreateMutable();
        
        switch (boxType) {
            case MHParagraphBoxTypeBoxHeader:
                CGPathMoveToPoint(frameLinesPath, nil, 0.0, 0.0);
                CGPathAddLineToPoint(frameLinesPath, nil, myDimensions.width, 0.0);
                break;
            case MHParagraphBoxTypeBoxBody:
                CGPathMoveToPoint(frameLinesPath, nil, 0.0, -myDimensions.depth-_verticalPadding.postParagraphSpacing);
                CGPathAddLineToPoint(frameLinesPath, nil, 0.0, myDimensions.height+_verticalPadding.preParagraphSpacing);
                CGPathMoveToPoint(frameLinesPath, nil, myDimensions.width, -myDimensions.depth-_verticalPadding.postParagraphSpacing);
                CGPathAddLineToPoint(frameLinesPath, nil, myDimensions.width, myDimensions.height+_verticalPadding.preParagraphSpacing);
                break;
            case MHParagraphBoxTypeBoxFooter:
            case MHParagraphBoxTypeBoxDivider:
                CGPathMoveToPoint(frameLinesPath, nil, 0.0, _verticalPadding.preParagraphSpacing);
                CGPathAddLineToPoint(frameLinesPath, nil, 0.0, 0.0);
                CGPathAddLineToPoint(frameLinesPath, nil, myDimensions.width, 0.0);
                CGPathAddLineToPoint(frameLinesPath, nil, myDimensions.width, _verticalPadding.preParagraphSpacing);
                break;
            default:
                break;
        }

        SKShapeNode *frameLinesNode = [SKShapeNode shapeNodeWithPath:frameLinesPath];
        CGPathRelease(frameLinesPath);
        frameLinesNode.strokeColor = frameColor;
        [paragraphFrameNode addChild:frameLinesNode];
        frameLinesNode.lineWidth = frameThickness;
        frameLinesNode.name = kMHParagraphFrameLinesNodeName;
    }
    
    paragraphFrameNode.fillColor = backgroundColor;
    paragraphFrameNode.strokeColor = frameColor;
    paragraphFrameNode.lineWidth = 0.0;
    paragraphFrameNode.name = kMHParagraphFrameNodeName;
    paragraphFrameNode.zPosition = (boxType == MHParagraphBoxTypeBoxBody ? -200.0 : -190.0);
    return paragraphFrameNode;
}





#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    NSAssert(false, @"logicalCopy called on an abstract class MHParagraph - this should not happen");
    return nil;
}




- (void)setHighlighted:(bool)highlighted
{
    // FIXME: disabling this for now - improve
}




#pragma mark - Rendering to a PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    
    NSSize pageSize = contextManager.pageSize;
    CGFloat topMargin = contextManager.topMargin;
    CGFloat bottomMargin = contextManager.bottomMargin;
    CGFloat contentHeight = pageSize.height - topMargin - bottomMargin;
    MHDimensions myDimensions = self.dimensions;
    CGFloat myTotalHeight = myDimensions.depth + myDimensions.height;
    
    // Do we need to insert a page break before rendering?
    if (contextManager.filledVerticalSpaceOnCurrentPage + myTotalHeight > contentHeight) {
        // Close the current page
        [contextManager endPDFPage];

        // Start a new page and move the rendering origin to coincide with where our typesetting origin should appear on the page
        [contextManager beginPDFPage];
        CGContextTranslateCTM(pdfContext, self.position.x, -myTotalHeight);
    }
    
    [contextManager incrementFilledVerticalSpaceBy:myTotalHeight];

    // dealing with boxes
    SKNode *boxBackgroundNode = [_spriteKitNode childNodeWithName:kMHParagraphFrameNodeName];
    if ([boxBackgroundNode isKindOfClass:[SKShapeNode class]]) {
        
        SKShapeNode *shape = (SKShapeNode *)boxBackgroundNode;     // to let the compiler know we know this object is an instance of SKShapeNode

        CGContextSaveGState(pdfContext);
        CGContextSetFillColorWithColor(pdfContext, [shape.fillColor CGColor]);
        CGContextAddPath(pdfContext, shape.path);
        CGContextDrawPath(pdfContext, kCGPathFill);
        CGContextRestoreGState(pdfContext);
    }
    SKNode *boxFrameNode = [boxBackgroundNode childNodeWithName:kMHParagraphFrameLinesNodeName];
    if ([boxFrameNode isKindOfClass:[SKShapeNode class]]) {
        
        SKShapeNode *shape = (SKShapeNode *)boxFrameNode;     // to let the compiler know we know this object is an instance of SKShapeNode

        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [shape.strokeColor CGColor]);
        CGContextSetLineWidth(pdfContext, shape.lineWidth);
        CGContextSetLineCap(pdfContext, shape.lineCap);
        CGContextAddPath(pdfContext, shape.path);
        CGContextDrawPath(pdfContext, kCGPathStroke);
        CGContextRestoreGState(pdfContext);
    }

    [super renderToPDFWithContextManager:contextManager];
}


- (NSString *)exportedLaTeXValue
{
    return [NSString stringWithFormat:@"\n%@\n", super.exportedLaTeXValue];
}



@end


