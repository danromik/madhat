//
//  MHReformattingContextManager.m
//  MadHat
//
//  Created by Dan Romik on 6/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHReformattingContextManager.h"

// FIXME: the variable and method names here are bad, improve them

typedef enum {
    MHOutlinerNodeStateExpanded,
    MHOutlinerNodeStatePrefixOfCollapsedNode,
    MHOutlinerNodeStateMainPartOfCollapsedNode
} MHOutlinerNodeState;

NSString * const kMHSlideTransitionAttributeNameAnimation = @"animate in";
NSString * const kMHSlideTransitionAttributeNameAnimateIn = @"animate in";
NSString * const kMHSlideTransitionAttributeNameAnimateOut = @"animate out";
NSString * const kMHSlideTransitionAttributeNameMoveOnTransition = @"move on transition";
NSString * const kMHSlideTransitionAttributeNamePropertyChangeOnTransition = @"change on transition";

NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideFromRight = @"slide from right";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideFromLeft = @"slide from left";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideFromTop = @"slide from top";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideFromBottom = @"slide from bottom";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideToRight = @"slide to right";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideToLeft = @"slide to left";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideToTop = @"slide to top";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueSlideToBottom = @"slide to bottom";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueFadeIn = @"fade in";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueFadeOut = @"fade out";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueHelicopter = @"helicopter";
NSString * const kMHSlideTransitionAnimationTypeAttributeValueNoAnimation = @"none";

NSString * const kMHSlideTransitionAttributeNameDuration = @"animation in duration";
NSString * const kMHSlideTransitionAttributeNameDurationIn = @"animation in duration";
NSString * const kMHSlideTransitionAttributeNameDurationOut = @"animation out duration";

NSString * const kMHSlideTransitionAttributeNameAnimationProfile = @"animation in profile";
NSString * const kMHSlideTransitionAttributeNameAnimationProfileIn = @"animation in profile";
NSString * const kMHSlideTransitionAttributeNameAnimationProfileOut = @"animation out profile";
NSString * const kMHSlideTransitionAttributeValueEaseAnimationProfile = @"ease";
NSString * const kMHSlideTransitionAttributeValueLinearAnimationProfile = @"linear";
NSString * const kMHSlideTransitionAttributeValueBounceAnimationProfile = @"bounce";
NSString * const kMHSlideTransitionAttributeValueElasticAnimationProfile = @"elastic";



@interface MHReformattingContextManager ()
{
    // Slides
    NSUInteger _slideCounter;
    NSUInteger _currentSlideTransitionIndex;
    NSUInteger _maxSlideFragmentVisibleIndex;
    
    NSMutableArray <MHSlideTransition *> *_slideTransitions;
    
    // Outliner
    NSUInteger _outlinerNestingLevel;

    MHOutlinerNodeState _currentOutlinerNodeState;
    NSMutableArray <NSNumber *> *_outlinerCollapseStatesStack;  // a stack of state values encoding the states of all the hierarchy levels above the current one
    
    bool _currentNodeIsDescendantOfMainPartOfCollapsedNode;
    
    CGFloat _collapsedSectionsVerticalOffset;
}
@end

@implementation MHReformattingContextManager


#pragma mark - Constructor and initialization/reset

- (instancetype)init
{
    if (self = [super init]) {
        _outlinerCollapseStatesStack = [[NSMutableArray alloc] initWithCapacity:0];
        _slideTransitions = [[NSMutableArray alloc] initWithCapacity:0];
        [self resetToDefaultState];
    }
    return self;
}


- (void)resetToDefaultState
{
    _slideCounter = 0;
    _maxSlideFragmentVisibleIndex = 0;
    _outlinerNestingLevel = 0;
    [_outlinerCollapseStatesStack removeAllObjects];
    [_slideTransitions removeAllObjects];
    
    _currentOutlinerNodeState = MHOutlinerNodeStateExpanded;
    
    _currentNodeIsDescendantOfMainPartOfCollapsedNode = false;
    _collapsedSectionsVerticalOffset = 0.0;
}



#pragma mark - Slide transitions

- (NSUInteger)currentSlideTransitionIndex
{
    return _currentSlideTransitionIndex;
}

- (void)setCurrentSlideTransitionIndex:(NSUInteger)currentSlideTransitionIndex
{
    _currentSlideTransitionIndex = currentSlideTransitionIndex;
}

- (NSUInteger)slideCounter
{
    return _slideCounter;
}

- (MHSlideTransitionAnimationType)currentAnimationType
{
    // FIXME: the fact that this condition is sometimes satisfied probably means the handling of slide transitions can be improved
    if (_slideTransitions.count == 0) {
        return MHSlideTransitionAnimationNone;
    }
    MHSlideTransition *slideTransition = [_slideTransitions lastObject];
    return slideTransition.animationType;
}

- (double)currentAnimationDuration
{
    // FIXME: the fact that this condition is sometimes satisfied probably means the handling of slide transitions can be improved
    if (_slideTransitions.count == 0) {
        return kMHDefaultSlideTransitionAnimationDuration;
    }
    MHSlideTransition *slideTransition = [_slideTransitions lastObject];
    return slideTransition.animationDuration;
}

- (MHSlideTransitionAnimationProfileType)currentAnimationProfile
{
    // FIXME: the fact that this condition is sometimes satisfied probably means the handling of slide transitions can be improved
    if (_slideTransitions.count == 0) {
        return MHSlideTransitionAnimationProfileEaseOut;
    }
    MHSlideTransition *slideTransition = [_slideTransitions lastObject];
    return slideTransition.animationProfile;
}

- (MHSlideTransitionVisibilityState)currentSlideTransitionVisibilityState
{
    return (_slideCounter > _currentSlideTransitionIndex ? MHSlideTransitionVisibilityStateHidden : MHSlideTransitionVisibilityStateVisible);
}

- (void)insertSlideTransition:(MHSlideTransition *)slideTransition
{
    [_slideTransitions addObject:slideTransition];
    if (slideTransition.animationType != MHSlideTransitionTimedTransitionToNextPage)
        _slideCounter++;
}

// this code tries to make it so that a slide fragment's range of visible slide indices will affect the total number of slides on the page. Commenting it out for now since it interfered with trying to keep page slide numbers in sync during incremental typesetting
//- (void)registerSlideFragmentVisibleFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
//{
//    if (toIndex != NSUIntegerMax && _maxSlideFragmentVisibleIndex < (NSUInteger)toIndex)
//        _maxSlideFragmentVisibleIndex = toIndex;
//}
//
//- (NSUInteger)maxSlideCounter
//{
//    return (_maxSlideFragmentVisibleIndex > _slideCounter ? _maxSlideFragmentVisibleIndex : _slideCounter);
//}






#pragma mark - Outliner

- (void)incrementOutlinerNestingLevel
{
    // Push the current state into the stack
    NSNumber *currentState = [NSNumber numberWithInt:_currentOutlinerNodeState];

    [_outlinerCollapseStatesStack addObject:currentState];

    // Update the value of _currentNodeIsDescendantOfMainPartOfCollapsedNode by OR-ing the previous value with an appropriate boolean
    _currentNodeIsDescendantOfMainPartOfCollapsedNode =
        _currentNodeIsDescendantOfMainPartOfCollapsedNode ||
        (_currentOutlinerNodeState == MHOutlinerNodeStateMainPartOfCollapsedNode);
    
    // Keep track of what level we're at (mainly to avoid going below 0 when decrementing)
    _outlinerNestingLevel++;
    
    // Set the initial state for the outliner node at the new hierarchy level
    _currentOutlinerNodeState = MHOutlinerNodeStateExpanded;
}

- (void)decrementOutlinerNestingLevel
{
    if (_outlinerNestingLevel > 0) {
        _outlinerNestingLevel--;
        
        // Retrieve the previous state from the stack
        NSNumber *currentState = [_outlinerCollapseStatesStack lastObject];
        _currentOutlinerNodeState = [currentState intValue];
        
        // Remove that item from the stack
        [_outlinerCollapseStatesStack removeLastObject];
        
                
        // Recalculate the _currentNodeIsDescendantOfMainPartOfCollapsedNode variable as an OR of booleans computed for each saved state in the stack
        // FIXME: in principle we could keep a separate stack of these values to make things marginally more efficient, but given that the depth of this stack will rarely exceed 3 or 4 this seems hardly worth the trouble
        for (NSNumber *outlinerNodeState in _outlinerCollapseStatesStack) {
            MHOutlinerNodeState state = [outlinerNodeState intValue];
            if (state == MHOutlinerNodeStateMainPartOfCollapsedNode) {
                _currentNodeIsDescendantOfMainPartOfCollapsedNode = true;
                return;
            }
        }
        // if we reached this far, the correct value is 'false'
        _currentNodeIsDescendantOfMainPartOfCollapsedNode = false;
    }
}

- (void)setOutlinerNestingLevel:(NSUInteger)nestingLevel
{
    while (_outlinerNestingLevel != nestingLevel) {
        if (_outlinerNestingLevel < nestingLevel)
            [self incrementOutlinerNestingLevel];
        else
            [self decrementOutlinerNestingLevel];
    }
}

- (void)beginOutlinerNode:(bool)isCurrentlyCollapsed
{
    // Set the new state for the current item
    _currentOutlinerNodeState = (isCurrentlyCollapsed ? MHOutlinerNodeStatePrefixOfCollapsedNode : MHOutlinerNodeStateExpanded);
}

- (void)markBeginningOfMainPartOfCurrentNode
{
    // This affects the state only if we are in the prefix of a collapsed node
    if (_currentOutlinerNodeState == MHOutlinerNodeStatePrefixOfCollapsedNode)
        _currentOutlinerNodeState = MHOutlinerNodeStateMainPartOfCollapsedNode;
}

- (MHOutlinerVisibilityState)currentOutlinerVisibilityState
{
    return (_currentOutlinerNodeState == MHOutlinerNodeStateMainPartOfCollapsedNode ?
            MHOutlinerVisibilityStateHiddenDueToCurrentNodeCollapsedPart : 0) |
            (_currentNodeIsDescendantOfMainPartOfCollapsedNode ? MHOutlinerVisibilityStateHiddenDueToAncestorNodeCollapsedPart : 0);
}

- (CGFloat)currentVerticalOffsetOfCollapsedSections
{
    return _collapsedSectionsVerticalOffset;
}

- (void)incrementCollapsedSectionsVerticalOffsetBy:(CGFloat)offset
{
    _collapsedSectionsVerticalOffset += offset;
}




@end
