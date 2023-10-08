//
//  MHExpression.m
//  MadHat
//
//  Created by Dan Romik on 10/20/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHExpression.h"
#import "MHSourceCodeTextStorage.h"
#import "MHTextAtom.h"
#import <objc/runtime.h>

NSString * const kMHExpressionFalseBooleanValue = @"no";
NSString * const kMHExpressionTrueBooleanValue = @"yes";

@implementation MHExpression {
    MHDimensions _dimensions;
    NSPoint _position;
    MHExpressionPresentationMode _presentationMode;
    NSRange _codeRange;          // the range of letters in the source code associated with the expression  // FIXME: location measured relative to the beginning of the containing paragraph, right?
}



#pragma mark - Constructors

+ (instancetype)expression
{
    return [[self alloc] init];
}

+ (instancetype)booleanExpressionWithValue:(bool)value
{
    return [MHTextAtom textAtomWithString:(value ? kMHExpressionTrueBooleanValue : kMHExpressionFalseBooleanValue)];
}



#pragma mark - typesetting and reformatting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    _dimensions.width = 0.0;
    _dimensions.height = 0.0;
    _dimensions.depth = 0.0;
    
    // Typeset any attached content
    NSArray <MHExpression *> *attachedContent = self.attachedContent;
    if (attachedContent) {
        for (MHExpression *attachedExpression in attachedContent) {
            [attachedExpression typesetWithContextManager:contextManager];
        }
    }
}

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
        
    MHOutlinerVisibilityState visibilityState = [contextManager currentOutlinerVisibilityState];
//    bool slideTransitionVisibilityHidden = (contextManager.currentSlideTransitionVisibilityState == MHSlideTransitionVisibilityStateHidden);
    bool outlinerVisibilityHidden = (visibilityState != MHOutlinerVisibilityStateVisible);
    
//    bool hideExpression = (contextManager.currentSlideTransitionVisibilityState == MHSlideTransitionVisibilityStateHidden)
//                                || (visibilityState != MHOutlinerVisibilityStateVisible);

    
    
    // Handling of the node state related to the outliner
    if (animationType == MHReformattingAnimationTypeOutliner) {
        SKAction *action = [SKAction fadeAlphaTo:(outlinerVisibilityHidden ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
        [self.spriteKitNode runAction:action];
    }
    else {
        self.spriteKitNode.alpha = (outlinerVisibilityHidden ? 0.0 : 1.0);
    }
    
    
    // FIXME: the code handling slide transitions was expanded and moved to the MHParagraph and MHSlideFragment classes, so commented out the bit below (will delete it eventually). Not sure if the current solution is optimal, but it works from a functionality perspective. Consider possible ways to refactor and continue improving this.
    
//    // Handling of the node state related to the slide transition
//    static const CGFloat animationOffset = 50.0;
//
//    CGFloat slideTransitionOffset = self.spriteKitNode.slideTransitionOffset;
////    CGFloat parentSlideTransitionOffset = self.parent.spriteKitNode.slideTransitionOffset;
//    CGFloat newSlideTransitionOffset = slideTransitionOffset;
//    if (slideTransitionOffset == 0.0 && slideTransitionVisibilityHidden)
//        newSlideTransitionOffset = animationOffset;
//    else if (slideTransitionOffset != 0.0 && !slideTransitionVisibilityHidden)
//        newSlideTransitionOffset = 0.0;
//
//    if (newSlideTransitionOffset != slideTransitionOffset) {
//        self.spriteKitNode.slideTransitionOffset = newSlideTransitionOffset;
//
//        CGPoint position = self.spriteKitNode.position;
//        CGPoint newPosition = position;
//        newPosition.x += (slideTransitionOffset == 0.0 ? animationOffset : -animationOffset);
////        if (parentSlideTransitionOffset == slideTransitionOffset) {
//            if (animated) {
//                SKAction *action = [SKAction moveTo:newPosition duration:kMHDefaultAnimationDuration];
//                [self.spriteKitNode runAction:action];
//            }
//            else {
//                self.spriteKitNode.position = newPosition;
//            }
////        }
//    }
    
}




#pragma mark - Properties

- (MHExpressionPresentationMode)presentationMode
{
    return _presentationMode;
}
- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    if (_presentationMode != presentationMode) {
        _presentationMode = presentationMode;
        
        // Destroy the existing sprite kit node
        [_spriteKitNode removeFromParent];
        _spriteKitNode = nil;   // need to recreate node when changing to a new presentation mode
    }
}

- (NSPoint)position
{
    return _position;
}

- (void)setPosition:(NSPoint)position
{
    _position = position;
    if (_spriteKitNode)
        _spriteKitNode.position = _position;
}

- (void)setPosition:(NSPoint)position animated:(bool)animated
{
    _position = position;
    if (_spriteKitNode) {
        if (animated) {
            SKAction *action = [SKAction moveTo:position duration:kMHDefaultNodePositionAnimationDuration];
            [_spriteKitNode runAction:action];
        }
        else {
            _spriteKitNode.position = _position;
        }
    }
}

- (MHDimensions)dimensions
{
    return _dimensions;
}

- (void)setDimensions:(MHDimensions)dimensions
{
    _dimensions = dimensions;
    
//    // *** not clear if this is good coding practice - temporary fix to prevent subclasses from causing unexpected trouble: ***
//    if (_spriteKitNode && [_spriteKitNode isKindOfClass:[SKSpriteNode class]]) {
//        ((SKSpriteNode *)_spriteKitNode).size = CGSizeMake(dimensions.width, dimensions.height+dimensions.depth);
//        ((SKSpriteNode *)_spriteKitNode).anchorPoint = CGPointMake(0.0, dimensions.depth/(dimensions.height+dimensions.depth));
//    }
    
    // *** subclasses that use a class other than SKSpriteNode for their spriteKitNode property need to implement ***
    // *** their own way of resizing the node ***
}

- (short int)italicCorrection
{
    return 0;
}

- (short int)leftItalicCorrection
{
    return self.italicCorrection;
}

- (short int)rightItalicCorrection
{
    return self.italicCorrection;
}

- (short int)topDecorationPositioningOffset
{
    return 0;
}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [SKNode node];   // The default behavior is an empty node
        _spriteKitNode.ownerExpression = self;        
    }
    return _spriteKitNode;
}

- (bool)splittable
{
    return false;
}

- (bool)atomicForReformatting
{
    return true;
}

- (NSString *)stringValue
{
    return @"";
}

- (NSString *)exportedLaTeXValue
{
    return @"(???)";
}

- (float)floatValue
{
    return [self.stringValue floatValue];
}

- (int)intValue
{
    return [self.stringValue intValue];
}


- (bool)boolValue
{
    return [self.stringValue isEqualToString:kMHExpressionTrueBooleanValue];
}

- (bool)isLimitsOperator
{
    return false;
}

- (MHMathParagraphAlignmentRole)mathParagraphAlignmentRole
{
    MHTypographyClass typographyClass = self.typographyClass;
    switch (typographyClass) {
        case MHTypographyClassBinaryRelation:
            return MHMathParagraphTabStop;
        case MHTypographyClassBinaryOperator:
            return MHMathParagraphDiscretionaryLineBreaking;
        default:
            return MHMathParagraphNoAlignmentRole;
    }
}

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassUnknown;
}

- (MHTypographyClass)leftTypographyClass
{
    return self.typographyClass;
}

- (MHTypographyClass)rightTypographyClass
{
    return self.typographyClass;
}

- (bool)highlighted
{
    if (!_spriteKitNode)
        return false;
    SKNode *highlightNode = [_spriteKitNode childNodeWithName:@"highlight"];
    return (highlightNode != nil);
}

- (void)setHighlighted:(bool)highlighted
{
    // FIXME: I disabled highlighting temporarily for MHParagraph and MHVerticalLayoutExpression. Make sure to restore this as appropriate when the highlighting and mouse event code becomes more stable
    
    // FIXME: disabling highlighting for now, might re-enable it later (uncomment the code below)
//    SKNode *existingHighlightNode = [self.spriteKitNode childNodeWithName:@"highlight"];
//    if (highlighted) {
//        if (!existingHighlightNode) {
//            MHDimensions myDimensions = self.dimensions;
//            NSRect rect;
//            rect.origin.x =  -1.0;
//            rect.origin.y = -myDimensions.depth - 1.0;
//            rect.size.width = myDimensions.width + 2.0;
//            rect.size.height = myDimensions.depth + myDimensions.height + 2.0;
//            SKShapeNode *highlightNode = [SKShapeNode shapeNodeWithRect:rect];
//            highlightNode.strokeColor = [NSColor colorWithWhite:0.75 alpha:1.0];
////            highlightNode.fillColor = [NSColor colorWithRed:1.0 green:1.0 blue:0.75 alpha:1.0];
//            highlightNode.lineWidth = 3.0;      // for debugging
//            highlightNode.name = @"highlight";
//            highlightNode.zPosition = -20.0;
//            [self.spriteKitNode addChild:highlightNode];
//        }
//    }
//    else if (existingHighlightNode)
//        [existingHighlightNode removeFromParent];
}

- (MHExpression *)rootAncestor
{
    MHExpression *ancestor = self;
    MHExpression *parentOfAncestor = ancestor.parent;
    while (parentOfAncestor) {
        ancestor = parentOfAncestor;
        parentOfAncestor = ancestor.parent;
    }
    return ancestor;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHExpression *myCopy = [[self class] expression];
    
    // FIXME: this pair of lines is repeated many times in the code. Turn this into a macro maybe?
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Code linkbacks

- (void)applyCodeRangeLinkbackToCode:(NSObject <MHSourceCodeString> *)code
{
    [code setExpression:self forCodeRange:_codeRange];
}


#pragma mark - Experimental

- (MHLayoutType)layoutPreference
{
    return MHLayoutHorizontal;
}

- (NSArray <MHExpression *> *)attachedContent
{
    return nil;
}


#pragma mark - Interactivity

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    // Default implementation does nothing
}


#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>", [self className]];
}


#pragma mark - Coding safety definitions

- (NSArray *)flattenedListOfUnsplittableComponents
{
    NSAssert1(false, @"A method of the MHSplittableExpression protocol was called in an object of class %@. The class must conform to this protocol if its splittable property returns 'true'", self.className);
    return nil;
}

- (NSArray <MHExpression *> *)flattenedListOfAtomicComponentsForSlideTransitions
{
    NSAssert1(false, @"A method of the MHDecomposableForReformatting protocol was called in an object of class %@. The class must conform to this protocol if its atomicForReformatting property returns 'false'", self.className);
    return nil;
}


#pragma mark - Rendering in graphics contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [self.spriteKitNode renderInPDFContext:contextManager.pdfContext];
}



#pragma mark - Experimental

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    return nil;
}


@end
