//
//  SKNode+MHSomeConvenienceMethods.h
//  MadHat
//
//  Created by Dan Romik on 2/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <SpriteKit/SpriteKit.h>
#import "MHReformattingContextManager.h"



typedef enum {
    MHNodePositionDefault = 0,
    MHNodePositionOffScreenRight = 1,
    MHNodePositionOffScreenLeft = 2,
    MHNodePositionOffScreenTop = 3,
    MHNodePositionOffScreenBottom = 4
} MHNodeFormattingPositionType;

NS_ASSUME_NONNULL_BEGIN

@class MHExpression, MHSpriteKitScene;

@interface SKNode (MHSomeConvenienceMethods)

@property (weak) MHExpression *ownerExpression;

@property bool ownerExpressionAcceptsMouseClicks;
@property (readonly) SKNode *mouseClickAcceptingAncestor;
@property (readonly) MHSpriteKitScene *enclosingSpriteKitScene;

@property MHNodeFormattingPositionType currentNodePositionType;


- (void)moveToSlidePositionWithNoAnimation:(MHNodeFormattingPositionType)position;
- (void)animatedSlideFromSlidePosition:(MHNodeFormattingPositionType)fromPosition
                        toSlidePosition:(MHNodeFormattingPositionType)toPosition
                         animationType:(MHSlideTransitionAnimationType)animationType
                              duration:(double)duration
                               profile:(MHSlideTransitionAnimationProfileType)profile;

- (void)renderInPDFContext:(CGContextRef)pdfContext;    // Default implementation does nothing

@end

NS_ASSUME_NONNULL_END
