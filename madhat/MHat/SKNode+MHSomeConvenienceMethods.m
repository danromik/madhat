//
//  SKNode+MHSomeConvenienceMethods.m
//  MadHat
//
//  Created by Dan Romik on 2/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SKNode+MHSomeConvenienceMethods.h"
#import "MHSpriteKitScene.h"
#import "SKEase.h"

NSString * const MHSKNodeOwnerKey = @"MHSKNodeOwner";
NSString * const MHSKNodeOwnerAcceptsClicksKey = @"MHSKNodeOwnerAcceptsClicks";
NSString * const MHSKNodeSlideTransitionOffsetKey = @"MHSKNodeSlideTransitionOffset";

NSString * const MHSKNodeOriginalHOffsetBooleanKey = @"MHSKNodeOriginalHOffsetBoolean";
NSString * const MHSKNodePositionTypeKey = @"MHSKNodePositionType";
NSString * const MHSKNodeDestinationPointWhileAnimatingKey = @"MHSKNodeDestinationPointWhileAnimating";

NSString * const kMHSKNodeSlideTransitionAnimationActionKey = @"slidetransition";


@implementation SKNode (MHSomeConvenienceMethods)


#pragma mark - Owner expressions

// FIXME: this next bit with the conditional include is a bit of a mess. Clean it up after the dust settles from the memory leak and list bullet item issue

#define AVOID_MEMORY_LEAKS_BUT_CRASH_WHEN_USING_OUTLINER


#ifdef AVOID_MEMORY_LEAKS_BUT_CRASH_WHEN_USING_OUTLINER
// FIXME: this version of the code fixes a bug that causes a huge memory leak. But then that causes a new bug where trying to click a list bullet item causes a crash, so I'm disabling it for now with a conditional compile flag AVOID_MEMORY_LEAKS_BUT_CRASH_WHEN_USING_OUTLINER. Need to fix this and then remove the other version and the conditional compile flag

// Update: I fixed the crashing bug by modifying the method unnumberedListItemMarkerExpression in MHListStyle. Not ideal, but it works for now
- (MHExpression *)ownerExpression
{
    NSValue *myOwnerValue = self.userData[MHSKNodeOwnerKey];
    if (myOwnerValue) {
        MHExpression *myOwner = [myOwnerValue nonretainedObjectValue];
        return myOwner;
    }
    SKNode *myParent = self.parent;
    if (myParent)
        return myParent.ownerExpression;
    return nil;
}

- (void)setOwnerExpression:(MHExpression *)ownerExpression
{
    NSMutableDictionary *userData = self.userData;
    if (!userData) {
        userData = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.userData = userData;
    }
    
    if (ownerExpression) {
        // since ownerExpression is a weak property, we package it into an NSValue as an unretained object to avoid it being retained when storing it in the mutable dictionary
        // (see the discussion here: https://stackoverflow.com/questions/8748736/weak-object-in-an-nsdictionary )
        NSValue *ownerExpressionValue = [NSValue valueWithNonretainedObject:ownerExpression];
        userData[MHSKNodeOwnerKey] = ownerExpressionValue;
    }
    else {
        [userData removeObjectForKey:MHSKNodeOwnerKey];
    }
}
#else
//// FIXME: this is the older version of the code, with the memory leak in place but a functioning outliner
//- (MHExpression *)ownerExpression
//{
//    MHExpression *myOwner = self.userData[MHSKNodeOwnerKey];
//    if (myOwner) {
//        return myOwner;
//    }
//    SKNode *myParent = self.parent;
//    if (myParent)
//        return myParent.ownerExpression;
//    return nil;
//}
//
//- (void)setOwnerExpression:(MHExpression *)ownerExpression
//{
//    NSMutableDictionary *userData = self.userData;
//    if (!userData) {
//        if (ownerExpression) {
//            userData = [[NSMutableDictionary alloc] initWithCapacity:0];
//            self.userData = userData;
//        }
//        else return;
//    }
//    
//    if (ownerExpression) {
//        userData[MHSKNodeOwnerKey] = ownerExpression;
//    }
//    else {
//        [userData removeObjectForKey:MHSKNodeOwnerKey];
//    }
//}
#endif




- (bool)ownerExpressionAcceptsMouseClicks
{
    NSNumber *value = self.userData[MHSKNodeOwnerAcceptsClicksKey];
    return [value boolValue];
}

- (void)setOwnerExpressionAcceptsMouseClicks:(bool)ownerExpressionAcceptsMouseClicks
{
    NSMutableDictionary *userData = self.userData;
    if (!userData) {
        userData = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.userData = userData;
    }
    userData[MHSKNodeOwnerAcceptsClicksKey] = [NSNumber numberWithBool:ownerExpressionAcceptsMouseClicks];
}

// FIXME: a non-recursive implementation would probably be a tiny bit more efficient
- (SKNode *)mouseClickAcceptingAncestor
{
    if (self.ownerExpressionAcceptsMouseClicks)
        return self;
    SKNode *myParent = self.parent;
    if (myParent)
        return myParent.mouseClickAcceptingAncestor;
    return nil;
}

// FIXME: a non-recursive implementation would probably be a tiny bit more efficient
- (MHSpriteKitScene *)enclosingSpriteKitScene
{
    if ([self isKindOfClass:[MHSpriteKitScene class]])
        return (MHSpriteKitScene *)self;
    SKNode *myParent = self.parent;
    if (myParent)
        return [myParent enclosingSpriteKitScene];
    return nil;
}




#pragma mark - Some additional user data dictionary properties



- (MHNodeFormattingPositionType)currentNodePositionType
{
    NSNumber *positionTypeNumber = self.userData[MHSKNodePositionTypeKey];
    return (positionTypeNumber ? [positionTypeNumber intValue] : MHNodePositionDefault);
}

- (void)setCurrentNodePositionType:(MHNodeFormattingPositionType)positionType
{
    NSMutableDictionary *userData = self.userData;
    if (!userData) {
        userData = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.userData = userData;
    }
    if (positionType != MHNodePositionDefault) {
        userData[MHSKNodePositionTypeKey] = [NSNumber numberWithInt:positionType];
    }
    else {
        [userData removeObjectForKey:MHSKNodePositionTypeKey];
    }
}

- (CGPoint)destinationPointWhileAnimating
{
    NSValue *pointValue = self.userData[MHSKNodeDestinationPointWhileAnimatingKey];
    return (pointValue ? [pointValue pointValue] : CGPointZero);
}

- (void)setDestinationPointWhileAnimating:(CGPoint)point
{
    NSMutableDictionary *userData = self.userData;
    if (!userData) {
        userData = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.userData = userData;
    }
    if (point.x != 0.0 || point.y != 0.0) {
        userData[MHSKNodeDestinationPointWhileAnimatingKey] = [NSValue valueWithPoint:point];
    }
    else {
        [userData removeObjectForKey:MHSKNodeDestinationPointWhileAnimatingKey];
    }
}

#pragma mark - slide transition animations

// FIXME: this code needs to be refactored. These calculations are quite similar to things done in the reformatWithContextManager method of the class file MHSlideFragment.m, so it would be better to put everything (or as much as possible) in one place. (Maybe in MHExpression.m? Another issue is that SKNode+MHSomeConvenienceMethods.m deals with sprite kit nodes, which is a lower level than the abstraction level of expressions. So it would probably be more logical to have a category on MHExpression that encapsulates all this animation code.)


- (void)moveToSlidePositionWithNoAnimation:(MHNodeFormattingPositionType)position
{
    [self animatedSlideFromSlidePosition:MHNodePositionDefault
                         toSlidePosition:position
                           animationType:MHSlideTransitionAnimationNone
                                duration:0.0                                        // ignored, since there is no animation
                                 profile:MHSlideTransitionAnimationProfileEaseOut   // ignored, since there is no animation
     ];
}

- (void)animatedSlideFromSlidePosition:(MHNodeFormattingPositionType)fromPosition
                       toSlidePosition:(MHNodeFormattingPositionType)toPosition
                         animationType:(MHSlideTransitionAnimationType)animationType
                              duration:(double)duration
                               profile:(MHSlideTransitionAnimationProfileType)profile;
{
    // FIXME: eventually these values will have to come from the context manager and be passed as arguments to the method
    static const CGFloat slideTransitionAnimationXOffset = 1050.0;
    static const CGFloat slideTransitionAnimationYOffset = 800.0;

    static const CGPoint positionOffsetsFromDefault[5] = {
        // See the type definition for MHNodeFormattingPositionType
        0.0, 0.0,                                   // Default position
        slideTransitionAnimationXOffset, 0.0,       // Off-screen and to the right
        -slideTransitionAnimationXOffset, 0.0,      // Off-screen and to the left
        0.0, slideTransitionAnimationYOffset,       // Off-screen and above
        0.0, -slideTransitionAnimationYOffset       // Off-screen and below
    };
    
    [self completePendingSlideTransitionAnimation];

    MHNodeFormattingPositionType positionType = self.currentNodePositionType;
    CGPoint position = self.position;
    CGPoint newPosition;
    if (animationType == MHSlideTransitionAnimationNone) {
        newPosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[toPosition].x;
        newPosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[toPosition].y;
        self.position = newPosition;
        self.currentNodePositionType = toPosition;
    }
    else if (animationType == MHSlideTransitionAnimationFadeIn || animationType == MHSlideTransitionAnimationFadeOut) {
        // move to the default (on-screen) position
        newPosition.x = position.x - positionOffsetsFromDefault[positionType].x;
        newPosition.y = position.y - positionOffsetsFromDefault[positionType].y;
        self.position = newPosition;
        self.currentNodePositionType = MHNodePositionDefault;

        SKAction *action;
        if (animationType == MHSlideTransitionAnimationFadeIn) {
            self.alpha = 0.0;
            action = [SKAction fadeInWithDuration:duration];
        }
        else {
            self.alpha = 1.0;
            action = [SKAction fadeOutWithDuration:duration];
        }
        [self runSlideTransitionAnimationAction:action destinationPoint:newPosition];
    }
    else if (animationType == MHSlideTransitionAnimationHelicopterIn) {
        // performing a helicopter slide animation
        
        // first, move to the starting position, as specified in the provided argument but offset by a "helicopter offset"
        static const CGPoint helicopterOffset = { 0.0, 30.0 };
        
        newPosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[fromPosition].x + helicopterOffset.x;
        newPosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[fromPosition].y + helicopterOffset.y;
        self.position = newPosition;

        // now prepare the animation to the destination position by chaining together two actions
        
        CGPoint intermediatePosition;
        intermediatePosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[toPosition].x + helicopterOffset.x;
        intermediatePosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[toPosition].y + helicopterOffset.y;

        CGPoint finalPosition;
        finalPosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[toPosition].x;
        finalPosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[toPosition].y;

        // the SKAction class for the animation created below is a custom action created with the SpriteKit-Easing package, see these links:
        // Source for SpriteKit-Easing: https://github.com/buddingmonkey/SpriteKit-Easing
        // Additional links and libraries I could try that do/discuss similar things:
        // https://stackoverflow.com/questions/19095390/spritekit-skaction-easing
        // https://github.com/raywenderlich/SKTUtils
        // https://github.com/ataugeron/SpriteKit-Spring
        // https://github.com/craiggrummitt/SpriteKitEasingSwift
        //
        // An alternative, less flexible method using the standard SpriteKit SKAction:
        SKAction *firstAction = [SKAction moveTo:intermediatePosition duration:0.75*duration];
        SKAction *secondAction = [SKAction moveTo:finalPosition duration:0.25*duration];
        SKAction *chainedAction = [SKAction sequence:@[ firstAction, secondAction ]];

//        static CurveType curveTypes[] = { CurveTypeQuintic, CurveTypeBounce, CurveTypeLinear, CurveTypeElastic };
//        SKAction *firstAction = [SKEase MoveToWithNode:self
//                                          EaseFunction:curveTypes[profile]
//                                                  Mode:EaseOut
//                                                  Time:duration
//                                              ToVector:CGVectorMake(finalPosition.x, finalPosition.y)];
        
        // run the animation
        [self runSlideTransitionAnimationAction:chainedAction destinationPoint:finalPosition];

        self.currentNodePositionType = toPosition;
    }
    else {
        // performing a slide animation
        
        // first, move to the starting position
        newPosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[fromPosition].x;
        newPosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[fromPosition].y;
        self.position = newPosition;

        // now prepare the animation to the destination position
        CGPoint finalPosition;
        finalPosition.x = position.x - positionOffsetsFromDefault[positionType].x + positionOffsetsFromDefault[toPosition].x;
        finalPosition.y = position.y - positionOffsetsFromDefault[positionType].y + positionOffsetsFromDefault[toPosition].y;

        // the SKAction class for the animation created below is a custom action created with the SpriteKit-Easing package, see these links:
        // Source for SpriteKit-Easing: https://github.com/buddingmonkey/SpriteKit-Easing
        // Additional links and libraries I could try that do/discuss similar things:
        // https://stackoverflow.com/questions/19095390/spritekit-skaction-easing
        // https://github.com/raywenderlich/SKTUtils
        // https://github.com/ataugeron/SpriteKit-Spring
        // https://github.com/craiggrummitt/SpriteKitEasingSwift
        //
        // An alternative, less flexible method using the standard SpriteKit SKAction:
//        SKAction *action = [SKAction moveTo:subexpressionFinalPosition duration:kMHDefaultSlideTransitionAnimationDuration];
//        action.timingMode = SKActionTimingEaseOut;

        static CurveType curveTypes[] = { CurveTypeQuintic, CurveTypeBounce, CurveTypeLinear, CurveTypeElastic };
        SKAction *action = [SKEase MoveToWithNode:self
                                     EaseFunction:curveTypes[profile]
                                             Mode:EaseOut
                                             Time:duration
                                         ToVector:CGVectorMake(finalPosition.x, finalPosition.y)];
        
        // run the animation
        [self runSlideTransitionAnimationAction:action destinationPoint:finalPosition];

        self.currentNodePositionType = toPosition;
    }
}

- (void)runSlideTransitionAnimationAction:(SKAction *)action destinationPoint:(CGPoint)destination

{
    self.destinationPointWhileAnimating = destination;
    [self runAction:action withKey:kMHSKNodeSlideTransitionAnimationActionKey];
}

- (void)completePendingSlideTransitionAnimation
{
    SKAction *previousAction = [self actionForKey:kMHSKNodeSlideTransitionAnimationActionKey];
    if (previousAction) {
        // if there are any animations already running on the node, this could throw off our calculations, so cancel them, and move the node to where it should be at the end of the animation
        [self removeActionForKey:kMHSKNodeSlideTransitionAnimationActionKey];
        self.position = self.destinationPointWhileAnimating;
        self.destinationPointWhileAnimating = CGPointZero;
    }
}










- (void)renderInPDFContext:(CGContextRef)pdfContext
{
    // Default implementation does nothing
}

@end
