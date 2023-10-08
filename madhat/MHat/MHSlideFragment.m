//
//  MHSlideFragment.m
//  MadHat
//
//  Created by Dan Romik on 7/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSlideFragment.h"
#import "SKEase.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"


NSString * const kMHSlideFragmentCommandName = @"slide fragment";



@interface MHSlideFragment ()
{
    CGVector _onScreenTransitionCurrentOffsetVector;
    
    MHSlideTransition * _Nullable _transitionIn;     // if nil, that means there is no transition in, the fragment is initially visible
    MHSlideTransition * _Nullable _transitionOut;    // if nil, that means there is no transition out, the fragment will remain on screen once it becomes visible
    NSArray <MHSlideTransition *> * _Nullable _onScreenTransitions;     // if nil, there are no on screen transitions
    NSArray <MHSlideTransition *> * _Nullable _propertyChangeTransitions;     // if nil, there are no property change transitions

    bool _insideGraphicsCanvas;
    MHGraphicsRectangle _viewRectangle;
    MHDimensions _graphicsCanvasDimensions;
}

@end


@implementation MHSlideFragment

#pragma mark - Constructors



+ (instancetype)slideFragmentWithContents:(MHExpression *)contents
                             transitionIn:(nullable MHSlideTransition *)transitionIn
                            transitionOut:(nullable MHSlideTransition *)transitionOut
                      onScreenTransitions:(nullable NSArray <MHSlideTransition *> *)onScreenTransitions
                propertyChangeTransitions:(nullable NSArray <MHSlideTransition *> *)propertyChangeTransitions
{
    return [[self alloc] initWithContents:contents
                             transitionIn:transitionIn
                            transitionOut:transitionOut
                      onScreenTransitions:onScreenTransitions
                propertyChangeTransitions:propertyChangeTransitions];
}

- (instancetype)initWithContents:(MHExpression *)contents
                    transitionIn:(nullable MHSlideTransition *)transitionIn
                   transitionOut:(nullable MHSlideTransition *)transitionOut
             onScreenTransitions:(nullable NSArray <MHSlideTransition *> *)onScreenTransitions
       propertyChangeTransitions:(nullable NSArray <MHSlideTransition *> *)propertyChangeTransitions
{
    if (self = [super initWithContents:contents]) {
        _transitionIn = transitionIn;
        _transitionOut = transitionOut;
        _onScreenTransitions = onScreenTransitions;
        _propertyChangeTransitions = propertyChangeTransitions;
    }
    return self;
}






#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHSlideFragmentCommandName]) {

        NSInteger fromIndex;
        NSInteger toIndex;

        
        // parse the arguments for the transition in and transition out indices
        MHExpression *fromIndexExpression = [argument expressionFromDelimitedBlockAtIndex:0];
        NSString *fromIndexString = [fromIndexExpression stringValue];
        if ([fromIndexString isEqualToString:@""]) {
            fromIndex = 0;
        }
        else {
            fromIndex = [fromIndexString intValue]-1;
            if (fromIndex < 0)
                fromIndex = 0;
        }

        MHExpression *toIndexExpression = [argument expressionFromDelimitedBlockAtIndex:1];
        NSString *toIndexString = [toIndexExpression stringValue];
        if ([toIndexString isEqualToString:@""]) {
            toIndex = -1;   // this will cause the transitionOut animation to be null, signifying that the fragment should never disappear after appearing
        }
        else {
            toIndex = [toIndexString intValue]-1;
            if (toIndex < 0)
                toIndex = 0;
        }

        MHExpression *contents = [argument expressionFromDelimitedBlockAtIndex:2];

        double durationIn = kMHDefaultSlideTransitionAnimationDuration;
        MHSlideTransitionAnimationType animationInType = MHSlideTransitionAnimationFadeIn;  // FIXME: have the context manager provide the default animation type
        MHSlideTransitionAnimationProfileType animationInProfile = MHSlideTransitionAnimationProfileEaseOut;

        double durationOut = kMHDefaultSlideTransitionAnimationDuration;
        MHSlideTransitionAnimationType animationOutType = MHSlideTransitionAnimationFadeOut;    // FIXME: have the context manager provide the default animation type
        MHSlideTransitionAnimationProfileType animationOutProfile = MHSlideTransitionAnimationProfileEaseOut;
        
        MHSlideTransition *transitionIn = nil;
        MHSlideTransition *transitionOut = nil;

        NSMutableArray <MHSlideTransition *> *onScreenTransitions;
        NSMutableArray <MHSlideTransition *> *propertyChangeTransitions;

        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        if (attributes) {
            
            // parse the attributes for the transition in
            MHExpression *animationInTypeExpression = attributes[kMHSlideTransitionAttributeNameAnimateIn];
            if (animationInTypeExpression) {
                NSString *animationInTypeString = animationInTypeExpression.stringValue;
                if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromLeft])
                    animationInType = MHSlideTransitionAnimationSlideFromLeft;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromRight])
                    animationInType = MHSlideTransitionAnimationSlideFromRight;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromTop])
                    animationInType = MHSlideTransitionAnimationSlideFromTop;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromBottom])
                    animationInType = MHSlideTransitionAnimationSlideFromBottom;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueFadeIn])
                    animationInType = MHSlideTransitionAnimationFadeIn;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueHelicopter])
                    animationInType = MHSlideTransitionAnimationHelicopterIn;
                else if ([animationInTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueNoAnimation])
                    animationInType = MHSlideTransitionAnimationNone;
                else {
                    // ignoring - a default value was already set above for the animation type
                }
            }
            MHExpression *animationDurationInExpression = attributes[kMHSlideTransitionAttributeNameDurationIn];
            if (animationDurationInExpression) {
                durationIn = [animationDurationInExpression floatValue];
            }
            MHExpression *animationInProfileExpression = attributes[kMHSlideTransitionAttributeNameAnimationProfileIn];
            if (animationInProfileExpression) {
                NSString *animationInProfileString = [animationInProfileExpression stringValue];
                if ([animationInProfileString isEqualToString:kMHSlideTransitionAttributeValueEaseAnimationProfile])
                    animationInProfile = MHSlideTransitionAnimationProfileEaseOut;
                else if ([animationInProfileString isEqualToString:kMHSlideTransitionAttributeValueLinearAnimationProfile])
                    animationInProfile = MHSlideTransitionAnimationProfileLinear;
                else if ([animationInProfileString isEqualToString:kMHSlideTransitionAttributeValueBounceAnimationProfile])
                    animationInProfile = MHSlideTransitionAnimationProfileBounce;
                else if ([animationInProfileString isEqualToString:kMHSlideTransitionAttributeValueElasticAnimationProfile])
                    animationInProfile = MHSlideTransitionAnimationProfileElastic;
            }
            
            
            // parse the attributes for the transition out
            MHExpression *animationOutTypeExpression = attributes[kMHSlideTransitionAttributeNameAnimateOut];
            if (animationOutTypeExpression) {
                NSString *animationOutTypeString = animationOutTypeExpression.stringValue;
                if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideToLeft])
                    animationOutType = MHSlideTransitionAnimationSlideToLeft;
                else if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideToRight])
                    animationOutType = MHSlideTransitionAnimationSlideToRight;
                else if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideToTop])
                    animationOutType = MHSlideTransitionAnimationSlideToTop;
                else if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideToBottom])
                    animationOutType = MHSlideTransitionAnimationSlideToBottom;
                else if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueFadeOut])
                    animationOutType = MHSlideTransitionAnimationFadeOut;
                else if ([animationOutTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueNoAnimation])
                    animationOutType = MHSlideTransitionAnimationNone;
                else {
                    // ignoring - a default value was already set above for the animation type
                }
            }
            MHExpression *animationDurationOutExpression = attributes[kMHSlideTransitionAttributeNameDurationOut];
            if (animationDurationOutExpression) {
                durationOut = [animationDurationOutExpression floatValue];
            }
            MHExpression *animationOutProfileExpression = attributes[kMHSlideTransitionAttributeNameAnimationProfileOut];
            if (animationOutProfileExpression) {
                NSString *animationOutProfileString = [animationOutProfileExpression stringValue];
                if ([animationOutProfileString isEqualToString:kMHSlideTransitionAttributeValueEaseAnimationProfile])
                    animationOutProfile = MHSlideTransitionAnimationProfileEaseOut;
                else if ([animationOutProfileString isEqualToString:kMHSlideTransitionAttributeValueLinearAnimationProfile])
                    animationOutProfile = MHSlideTransitionAnimationProfileLinear;
                else if ([animationOutProfileString isEqualToString:kMHSlideTransitionAttributeValueBounceAnimationProfile])
                    animationOutProfile = MHSlideTransitionAnimationProfileBounce;
                else if ([animationOutProfileString isEqualToString:kMHSlideTransitionAttributeValueElasticAnimationProfile])
                    animationOutProfile = MHSlideTransitionAnimationProfileElastic;
            }

            
            // parse the on screen position change transitions
            MHExpression *onScreenTransitionExpression = attributes[kMHSlideTransitionAttributeNameMoveOnTransition];
            CGVector onScreenTransitionAnimationVector;
            if (onScreenTransitionExpression) {
                if ([onScreenTransitionExpression isKindOfClass:[MHContainer class]]) {
                    MHLinearContainer *onScreenTransitionArguments = (MHLinearContainer *)onScreenTransitionExpression;
                    
                    NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [onScreenTransitionArguments delimitedBlockTable];
                    NSUInteger numRows = delimitedBlockTable.count;
                    for (NSUInteger counter = 0; counter+1 < numRows; counter += 2) {
                        NSArray <MHExpression *> *transitionIndexRow = delimitedBlockTable[counter];
                        NSArray <MHExpression *> *movementPointRow = delimitedBlockTable[counter+1];
                        if (transitionIndexRow.count >= 1) {
                            MHExpression *transitionIndexExpression = transitionIndexRow[0];
                            NSUInteger onScreenTransitionIndex = [transitionIndexExpression intValue] - 1;
                            
                            if (movementPointRow.count >= 2) {
                                MHExpression *xCoordinateMovement = movementPointRow[0];
                                MHExpression *yCoordinateMovement = movementPointRow[1];
                                onScreenTransitionAnimationVector.dx = [xCoordinateMovement floatValue];
                                onScreenTransitionAnimationVector.dy = [yCoordinateMovement floatValue];
                                
                                if (!onScreenTransitions)
                                    onScreenTransitions = [[NSMutableArray alloc] initWithCapacity:0];
                                MHSlideTransition *transition = [MHSlideTransition
                                                                 slideTransitionWithTransitionIndex:onScreenTransitionIndex
                                                                 animationType:MHSlideTransitionAnimationSlideByVector
                                                                 animationProfile:MHSlideTransitionAnimationProfileEaseOut
                                                                 animationDuration:kMHDefaultSlideTransitionAnimationDuration
                                                                 animationVector:onScreenTransitionAnimationVector
                                                                  propertyName:nil
                                                                 propertyValue:nil
                                                                 delayUntilTransition:0.0]; // the last argument is ignored in this situation
                                
                                [onScreenTransitions addObject:transition];
                                
                            }
                        }
                    }
                    
                    // after reading the transitions into the array, sort them in increasing order of their transition indices, to allow some flexibility in how the user might choose to provide the parameters
                    [onScreenTransitions sortUsingSelector:@selector(compareByTransitionIndicesTo:)];
                }
            }
            
            
            // parse the property change transitions
            MHExpression *propertyChangeTransitionExpression = attributes[kMHSlideTransitionAttributeNamePropertyChangeOnTransition];
            NSMutableArray *propertyValuesArray;
            if (propertyChangeTransitionExpression) {
                if ([propertyChangeTransitionExpression isKindOfClass:[MHContainer class]]) {
                    MHLinearContainer *propertyChangeTransitionArguments = (MHLinearContainer *)propertyChangeTransitionExpression;
                    
                    NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [propertyChangeTransitionArguments delimitedBlockTable];
                    NSUInteger numRows = delimitedBlockTable.count;
                    for (NSUInteger counter = 0; counter+1 < numRows; counter += 2) {
                        NSArray <MHExpression *> *transitionIndexAndPropertyNameRow = delimitedBlockTable[counter];
                        NSArray <MHExpression *> *propertyValuesRow = delimitedBlockTable[counter+1];
                        if (transitionIndexAndPropertyNameRow.count >= 2) {
                            MHExpression *transitionIndexExpression = transitionIndexAndPropertyNameRow[0];
                            NSUInteger propertyChangeTransitionIndex = [transitionIndexExpression intValue] - 1;
                            MHExpression *propertyNameExpression = transitionIndexAndPropertyNameRow[1];
                            NSString *propertyName = [propertyNameExpression stringValue];
                            
                            if (propertyValuesRow.count >= 1 && propertyName.length >= 1) {
                                propertyValuesArray = [[NSMutableArray alloc] initWithCapacity:0];
                                for (MHExpression *propertyValueExpression in propertyValuesRow) {
                                    double propertyValue = [propertyValueExpression floatValue];
                                    NSNumber *propertyValueNumber = [NSNumber numberWithDouble:propertyValue];
                                    [propertyValuesArray addObject:propertyValueNumber];
                                }
                                
                                if (!propertyChangeTransitions)
                                    propertyChangeTransitions = [[NSMutableArray alloc] initWithCapacity:0];
                                MHSlideTransition *transition = [MHSlideTransition
                                                                 slideTransitionWithTransitionIndex:propertyChangeTransitionIndex
                                                                 animationType:MHSlideTransitionAnimationSlideByVector
                                                                 animationProfile:MHSlideTransitionAnimationProfileEaseOut
                                                                 animationDuration:kMHDefaultSlideTransitionAnimationDuration
                                                                 animationVector:CGVectorMake(0.0, 0.0)
                                                                 propertyName:propertyName
                                                                 propertyValue:[NSArray arrayWithArray:propertyValuesArray]
                                                                 delayUntilTransition:0.0]; // the last argument is ignored in this situation
                                
                                [propertyChangeTransitions addObject:transition];
                            }
                        }
                    }
                    
                    // after reading the transitions into the array, sort them in increasing order of their transition indices, to allow some flexibility in how the user might choose to provide the parameters
                    [propertyChangeTransitions sortUsingSelector:@selector(compareByTransitionIndicesTo:)];
                }
            }
        }
        
        if (fromIndex > 0) {
            transitionIn = [MHSlideTransition slideTransitionWithTransitionIndex:fromIndex
                                                                   animationType:animationInType
                                                                animationProfile:animationInProfile
                                                               animationDuration:durationIn
                                                                 animationVector:CGVectorMake(0.0, 0.0)
                                                                    propertyName:nil
                                                                   propertyValue:nil
                                                            delayUntilTransition:0.0]; // the last argument is ignored in this situation
        }
        
        if (toIndex >= fromIndex) {
            transitionOut = [MHSlideTransition slideTransitionWithTransitionIndex:toIndex+1     // (adding 1, the actual transition out occurs in the next transition after "toIndex")
                                                                    animationType:animationOutType
                                                                 animationProfile:animationOutProfile
                                                                animationDuration:durationOut
                                                                  animationVector:CGVectorMake(0.0, 0.0)
                                                                     propertyName:nil
                                                                    propertyValue:nil
                                                             delayUntilTransition:0.0]; // the last argument is ignored in this situation
        }

        MHSlideFragment *slideFragment = [self slideFragmentWithContents:contents
                                                            transitionIn:transitionIn
                                                           transitionOut:transitionOut
                                                     onScreenTransitions:onScreenTransitions
                                               propertyChangeTransitions:propertyChangeTransitions];
        
        return slideFragment;
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHSlideFragmentCommandName ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];

    _insideGraphicsCanvas = contextManager.graphicsCanvasCurrentlyActive;
    if (_insideGraphicsCanvas) {
        _viewRectangle = contextManager.graphicsViewRectangle;
        _graphicsCanvasDimensions = contextManager.graphicsCanvasDimensions;
    }
}


#pragma mark - Reformatting

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    [super reformatWithContextManager:contextManager animationType:animationType];
    NSUInteger currentSlideTransitionIndex = contextManager.currentSlideTransitionIndex;

    // register the slide transition with the context manager
    NSUInteger visibleFromIndex = (_transitionIn ? _transitionIn.transitionIndex : 0);
    NSUInteger visibleToIndex = (_transitionOut ? _transitionOut.transitionIndex - 1 : NSUIntegerMax);
//    [contextManager registerSlideFragmentVisibleFromIndex:visibleFromIndex
//                                                  toIndex:visibleToIndex];        // disabling this for now, might add it back later
    
    MHSlideTransitionAnimationType animationInType = _transitionIn.animationType;
    MHSlideTransitionAnimationType animationOutType = _transitionOut.animationType;
    
    SKNode *spriteKitNode = self.spriteKitNode;

    if (animationType == MHReformattingAnimationTypeSlideTransition && currentSlideTransitionIndex != 0 &&
        (animationInType != MHSlideTransitionAnimationNone || currentSlideTransitionIndex != visibleFromIndex) &&
        (animationOutType != MHSlideTransitionAnimationNone || currentSlideTransitionIndex != visibleToIndex+1)) {
        if (currentSlideTransitionIndex > visibleFromIndex && currentSlideTransitionIndex <= visibleToIndex) {
            
            // FIXME: It may be a good idea to refactor this code. These calculations are quite similar to things done in the category file SKNode+MHSomeConvenienceMethods.m, so it would be better to put everything (or as much as possible) in one place. (Maybe in MHExpression.m? Another issue is that SKNode+MHSomeConvenienceMethods.m deals with sprite kit nodes, which is a lower level than the abstraction level of expressions. So it would probably be more logical to have a category on MHExpression that encapsulates all this animation code.)
            
            // put the node in the default (on-screen) position
            [spriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionDefault];
            CGPoint spriteKitNodePosition = spriteKitNode.position;
            spriteKitNodePosition.x -= _onScreenTransitionCurrentOffsetVector.dx;
            spriteKitNodePosition.y -= _onScreenTransitionCurrentOffsetVector.dy;
            
            // handle on screen transitions
            CGVector cumulativeMovementVector = { 0.0, 0.0 };
            bool onScreenTransitionInProgress = false;
            for (MHSlideTransition *onScreenTransition in _onScreenTransitions) {
                CGVector onScreenTransitionAnimationVector = onScreenTransition.animationVector;
                CGVector onScreenTransitionAnimationVectorInNodeCoordinates;
                if (!_insideGraphicsCanvas) {
                    onScreenTransitionAnimationVectorInNodeCoordinates = onScreenTransitionAnimationVector;
                }
                else {
                    onScreenTransitionAnimationVectorInNodeCoordinates.dx
                    = onScreenTransitionAnimationVector.dx / (_viewRectangle.maxX - _viewRectangle.minX) * _graphicsCanvasDimensions.width;
                    onScreenTransitionAnimationVectorInNodeCoordinates.dy
                    = onScreenTransitionAnimationVector.dy / (_viewRectangle.maxY - _viewRectangle.minY) * _graphicsCanvasDimensions.height;
                }
                NSUInteger onScreenTransitionIndex = onScreenTransition.transitionIndex;
                if (onScreenTransitionIndex == currentSlideTransitionIndex) {
                    // perform the specified animation
                    
                    // first, move the node to the starting point of the animation
                    
                    spriteKitNodePosition.x += cumulativeMovementVector.dx;
                    spriteKitNodePosition.y += cumulativeMovementVector.dy;
                    spriteKitNode.position = spriteKitNodePosition;
                    
                    // now animate it by the movement vector for the current animation
                    SKAction *action = [SKAction moveBy:onScreenTransitionAnimationVectorInNodeCoordinates
                                               duration:kMHDefaultSlideTransitionAnimationDuration];
                    [spriteKitNode runAction:action];
                    onScreenTransitionInProgress = true;
                    
                    // record the offset vector after the animation
                    _onScreenTransitionCurrentOffsetVector = cumulativeMovementVector;
                    _onScreenTransitionCurrentOffsetVector.dx += onScreenTransitionAnimationVectorInNodeCoordinates.dx;
                    _onScreenTransitionCurrentOffsetVector.dy += onScreenTransitionAnimationVectorInNodeCoordinates.dy;
                    break;
                }
                else if (onScreenTransitionIndex > currentSlideTransitionIndex) {
                    // we've reached the first transition on the list that has an index greater than the current one
                    // so move the node by the current cumulative movement vector, with no animation
                    break;
                }
                // if we reached this far without breaking out of the loop, update the cumulative vector and keep going through the list
                cumulativeMovementVector.dx += onScreenTransitionAnimationVectorInNodeCoordinates.dx;
                cumulativeMovementVector.dy += onScreenTransitionAnimationVectorInNodeCoordinates.dy;
                _onScreenTransitionCurrentOffsetVector = cumulativeMovementVector;
            }
            if (!onScreenTransitionInProgress) {
                spriteKitNodePosition.x += _onScreenTransitionCurrentOffsetVector.dx;
                spriteKitNodePosition.y += _onScreenTransitionCurrentOffsetVector.dy;
                spriteKitNode.position = spriteKitNodePosition;
            }
            
            
            // handling property change transitions
            if (_propertyChangeTransitions.count > 0) {
                // look for a subexpression of the contents block that knows what to do with a property change instruction
                MHExpression <MHSlideTransitionAnimatablePropertyExpression> *propertyChangeReceiver = [self propertyChangeReceiverInContents];
                if (propertyChangeReceiver) {
                    // we found a subexpression that can handle the property change
                
                    bool startedAnimationBlock = false;
                    [propertyChangeReceiver beginPropertyChangeBlock];
                    [propertyChangeReceiver restorePropertiesToInitialState];
                    for (MHSlideTransition *propertyChangeTransition in _propertyChangeTransitions) {
                        NSArray <NSNumber *> *propertyChangeTransitionValue = propertyChangeTransition.propertyValue;
                        NSUInteger propertyChangeTransitionIndex = propertyChangeTransition.transitionIndex;
                        NSString *propertyName = propertyChangeTransition.propertyName;
                        if (propertyChangeTransitionIndex <= currentSlideTransitionIndex) {
                            
                            if (propertyChangeTransitionIndex == currentSlideTransitionIndex) {
                                if (!startedAnimationBlock) {
                                    // apply the property changes up to this point, without an animation
                                    [propertyChangeReceiver endPropertyChangeBlockAndApplyChanges:false];
                                    
                                    [propertyChangeReceiver beginPropertyChangeBlock];
                                    startedAnimationBlock = true;
                                }
                            }
                            
                            [propertyChangeReceiver changeProperty:propertyName to:propertyChangeTransitionValue];
                        }
                        else {
                            // this transition and all the ones that follow it on the list of property change transitions are not needed right now, so break out of the for loop
                            break;
                        }
                    }
                    // close the property change block, with or without an animation depending on whether we started an animation block
                    [propertyChangeReceiver endPropertyChangeBlockAndApplyChanges:startedAnimationBlock];
                }
            }
            
        }
        else if (currentSlideTransitionIndex == visibleFromIndex) {
            // animate the node according to the animation-in type
            
            MHNodeFormattingPositionType positionForAnimationInType;
            switch (animationInType) {
                case MHSlideTransitionAnimationSlideFromRight:
                    positionForAnimationInType = MHNodePositionOffScreenRight;
                    break;
                case MHSlideTransitionAnimationSlideFromLeft:
                    positionForAnimationInType = MHNodePositionOffScreenLeft;
                    break;
                case MHSlideTransitionAnimationSlideFromTop:
                    positionForAnimationInType = MHNodePositionOffScreenTop;
                    break;
                case MHSlideTransitionAnimationSlideFromBottom:
                    positionForAnimationInType = MHNodePositionOffScreenBottom;
                    break;
                case MHSlideTransitionAnimationHelicopterIn:
                    positionForAnimationInType = MHNodePositionOffScreenRight;
                    break;
                case MHSlideTransitionAnimationNone:
                case MHSlideTransitionAnimationFadeIn:
                    positionForAnimationInType = MHNodePositionOffScreenRight;
                    break;
                default:
                    // This should never be executed, but just on the off-chance...
                    positionForAnimationInType = MHNodePositionDefault;
                    break;
            }
            
            [spriteKitNode animatedSlideFromSlidePosition:positionForAnimationInType
                                          toSlidePosition:MHNodePositionDefault
                                            animationType:animationInType
                                                 duration:_transitionIn.animationDuration
                                                  profile:_transitionIn.animationProfile];
            
            if (_propertyChangeTransitions.count > 0) {
                MHExpression <MHSlideTransitionAnimatablePropertyExpression> *propertyChangeReceiver = [self propertyChangeReceiverInContents];
                [propertyChangeReceiver beginPropertyChangeBlock];
                [propertyChangeReceiver restorePropertiesToInitialState];
                [propertyChangeReceiver endPropertyChangeBlockAndApplyChanges:false];
            }
        }
        else if (currentSlideTransitionIndex == visibleToIndex+1) {
            // animate the node according to the animation-out type
            
            MHNodeFormattingPositionType positionForAnimationOutType;
            switch (animationOutType) {
                case MHSlideTransitionAnimationSlideToRight:
                    positionForAnimationOutType = MHNodePositionOffScreenRight;
                    break;
                case MHSlideTransitionAnimationSlideToLeft:
                    positionForAnimationOutType = MHNodePositionOffScreenLeft;
                    break;
                case MHSlideTransitionAnimationSlideToTop:
                    positionForAnimationOutType = MHNodePositionOffScreenTop;
                    break;
                case MHSlideTransitionAnimationSlideToBottom:
                    positionForAnimationOutType = MHNodePositionOffScreenBottom;
                    break;
                case MHSlideTransitionAnimationNone:
                case MHSlideTransitionAnimationFadeOut:
                    positionForAnimationOutType = MHNodePositionOffScreenRight;
                    break;
                default:
                    // This should never be executed, but just on the off-chance...
                    positionForAnimationOutType = MHNodePositionDefault;
                    break;
            }
            [spriteKitNode animatedSlideFromSlidePosition:MHNodePositionDefault
                                          toSlidePosition:positionForAnimationOutType
                                            animationType:animationOutType
                                                 duration:_transitionOut.animationDuration
                                                  profile:_transitionOut.animationProfile];
        }
        else {  // the scenario where the node should be hidden
            // put the node in the off-screen position
            [spriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionOffScreenRight];
        }
    }
    else {
        if (currentSlideTransitionIndex >= visibleFromIndex && currentSlideTransitionIndex <= visibleToIndex) {
            
            // FIXME: It may be a good idea to refactor this code. These calculations are quite similar to things done in the category file SKNode+MHSomeConvenienceMethods.m, so it would be better to put everything (or as much as possible) in one place. (Maybe in MHExpression.m? Another issue is that SKNode+MHSomeConvenienceMethods.m deals with sprite kit nodes, which is a lower level than the abstraction level of expressions. So it would probably be more logical to have a category on MHExpression that encapsulates all this animation code.)

            // put the node in the default (on-screen) position
            [spriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionDefault];
            CGPoint spriteKitNodePosition = spriteKitNode.position;
            spriteKitNodePosition.x -= _onScreenTransitionCurrentOffsetVector.dx;
            spriteKitNodePosition.y -= _onScreenTransitionCurrentOffsetVector.dy;
            _onScreenTransitionCurrentOffsetVector.dx = 0.0;
            _onScreenTransitionCurrentOffsetVector.dy = 0.0;
            
            // handle on screen transitions
            CGVector cumulativeMovementVector = { 0.0, 0.0 };
            for (MHSlideTransition *onScreenTransition in _onScreenTransitions) {
                CGVector onScreenTransitionAnimationVector = onScreenTransition.animationVector;
                CGVector onScreenTransitionAnimationVectorInNodeCoordinates;
                if (!_insideGraphicsCanvas) {
                    onScreenTransitionAnimationVectorInNodeCoordinates = onScreenTransitionAnimationVector;
                }
                else {
                    onScreenTransitionAnimationVectorInNodeCoordinates.dx
                    = onScreenTransitionAnimationVector.dx / (_viewRectangle.maxX - _viewRectangle.minX) * _graphicsCanvasDimensions.width;
                    onScreenTransitionAnimationVectorInNodeCoordinates.dy
                    = onScreenTransitionAnimationVector.dy / (_viewRectangle.maxY - _viewRectangle.minY) * _graphicsCanvasDimensions.height;
                }
                NSUInteger onScreenTransitionIndex = onScreenTransition.transitionIndex;
                if (onScreenTransitionIndex == currentSlideTransitionIndex) {
                    // record the offset vector after the animation
                    _onScreenTransitionCurrentOffsetVector = cumulativeMovementVector;
                    _onScreenTransitionCurrentOffsetVector.dx += onScreenTransitionAnimationVectorInNodeCoordinates.dx;
                    _onScreenTransitionCurrentOffsetVector.dy += onScreenTransitionAnimationVectorInNodeCoordinates.dy;
                    break;
                }
                else if (onScreenTransitionIndex > currentSlideTransitionIndex) {
                    // we've reached the first transition on the list that has an index greater than the current one
                    // so move the node by the current cumulative movement vector, with no animation
                    break;
                }
                // if we reached this far without breaking out of the loop, update the cumulative vector and keep going through the list
                cumulativeMovementVector.dx += onScreenTransitionAnimationVectorInNodeCoordinates.dx;
                cumulativeMovementVector.dy += onScreenTransitionAnimationVectorInNodeCoordinates.dy;
                _onScreenTransitionCurrentOffsetVector = cumulativeMovementVector;
            }
            spriteKitNodePosition.x += _onScreenTransitionCurrentOffsetVector.dx;
            spriteKitNodePosition.y += _onScreenTransitionCurrentOffsetVector.dy;
            spriteKitNode.position = spriteKitNodePosition;
            
            
            // handling property change transitions
            if (_propertyChangeTransitions.count > 0) {
                // look for a subexpression of the contents block that knows what to do with a property change instruction
                MHExpression <MHSlideTransitionAnimatablePropertyExpression> *propertyChangeReceiver = [self propertyChangeReceiverInContents];
                if (propertyChangeReceiver) {
                    // we found a subexpression that can handle the property change
                    [propertyChangeReceiver beginPropertyChangeBlock];
                    [propertyChangeReceiver restorePropertiesToInitialState];
                    for (MHSlideTransition *propertyChangeTransition in _propertyChangeTransitions) {
                        NSArray <NSNumber *> *propertyChangeTransitionValue = propertyChangeTransition.propertyValue;
                        NSUInteger propertyChangeTransitionIndex = propertyChangeTransition.transitionIndex;
                        NSString *propertyName = propertyChangeTransition.propertyName;
                        if (propertyChangeTransitionIndex <= currentSlideTransitionIndex) {
                            [propertyChangeReceiver changeProperty:propertyName to:propertyChangeTransitionValue];
                        }
                        else {
                            // this transition and all the ones that follow it on the list of property change transitions are not needed right now, so break out of the for loop
                            break;
                        }
                    }
                    // close the property change block, without an animation
                    [propertyChangeReceiver endPropertyChangeBlockAndApplyChanges:false];
                }
            }
            
        }
        else {
            // put the node in the off-screen position
            [spriteKitNode moveToSlidePositionWithNoAnimation:MHNodePositionOffScreenRight];
        }
    }

}



- (nullable MHExpression <MHSlideTransitionAnimatablePropertyExpression> *)propertyChangeReceiverInContents
{
    MHExpression <MHSlideTransitionAnimatablePropertyExpression> *propertyChangeReceiver = nil;
    MHExpression *myContents = self.contents;
    if ([myContents conformsToProtocol:@protocol(MHSlideTransitionAnimatablePropertyExpression)])
        propertyChangeReceiver = (MHExpression <MHSlideTransitionAnimatablePropertyExpression> *)myContents;
    else if ([myContents isKindOfClass:[MHContainer class]]) {
        MHContainer *myContentsContainer = (MHContainer *)myContents;
        for (MHExpression *subexpression in myContentsContainer.subexpressions) {
            if ([subexpression conformsToProtocol:@protocol(MHSlideTransitionAnimatablePropertyExpression)]) {
                propertyChangeReceiver = (MHExpression <MHSlideTransitionAnimatablePropertyExpression> *)subexpression;
                break;
            }
        }
    }
    
    return propertyChangeReceiver;
}




#pragma mark - Various methods to ensure correct behavior


- (bool)atomicForReformatting
{
    return true;
}



- (bool)overrideDefaultBehaviorInSlideTransitions
{
    return true;
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHSlideFragment *myCopy = [[self class] slideFragmentWithContents:[self.contents logicalCopy]
                                                         transitionIn:[_transitionIn copy]
                                                        transitionOut:[_transitionOut copy]
                                                  onScreenTransitions:[_onScreenTransitions copy]
                                            propertyChangeTransitions:[_propertyChangeTransitions copy]];

    myCopy.codeRange = self.codeRange;
    return myCopy;
}




@end
