//
//  MHSlideTransition.h
//  MadHat
//
//  Created by Dan Romik on 7/17/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    // no animation
    MHSlideTransitionAnimationNone = 0,
    // animations in
    MHSlideTransitionAnimationSlideFromRight = 1,
    MHSlideTransitionAnimationSlideFromLeft = 2,
    MHSlideTransitionAnimationSlideFromTop = 3,
    MHSlideTransitionAnimationSlideFromBottom = 4,
    MHSlideTransitionAnimationFadeIn = 5,
    MHSlideTransitionAnimationHelicopterIn = 6,
    // animations out
    MHSlideTransitionAnimationSlideToRight = 7,
    MHSlideTransitionAnimationSlideToLeft = 8,
    MHSlideTransitionAnimationSlideToTop = 9,
    MHSlideTransitionAnimationSlideToBottom = 10,
    MHSlideTransitionAnimationFadeOut = 11,
    // on-screen animations
    MHSlideTransitionAnimationSlideByVector = 12,
    MHSlideTransitionAnimationPropertyChange = 13,
    // transitions between pages
    MHSlideTransitionTimedTransitionToNextPage = 14
} MHSlideTransitionAnimationType;

// Animation profiles for slide transition animations
typedef enum {
    MHSlideTransitionAnimationProfileEaseOut = 0,         // the default
    MHSlideTransitionAnimationProfileBounce = 1,
    MHSlideTransitionAnimationProfileLinear = 2,
    MHSlideTransitionAnimationProfileElastic = 3,
} MHSlideTransitionAnimationProfileType;


NS_ASSUME_NONNULL_BEGIN

@interface MHSlideTransition : NSObject

+ (instancetype)slideTransitionWithTransitionIndex:(NSUInteger)transitionIndex
                                     animationType:(MHSlideTransitionAnimationType)type
                                  animationProfile:(MHSlideTransitionAnimationProfileType)profile
                                 animationDuration:(NSTimeInterval)duration
                                   animationVector:(CGVector)animationVector
                                      propertyName:(nullable NSString *)propertyName
                                     propertyValue:(nullable NSArray <NSNumber *> *)propertyValue
                              delayUntilTransition:(NSTimeInterval)delayUntilTransition;

@property MHSlideTransitionAnimationType animationType;             // used by some, not all, types of transitions
@property NSUInteger transitionIndex;
@property MHSlideTransitionAnimationProfileType animationProfile;   // used by some, not all, types of transitions
@property NSTimeInterval animationDuration;         // used by some, not all, types of transitions
@property CGVector animationVector;                 // used by some, not all, types of transitions
@property NSString *propertyName;                   // used by property change transitions
@property NSArray <NSNumber *> *propertyValue;                   // used by property change transitions
@property NSTimeInterval delayUntilTransition;      // used by some, not all, types of transitions to describe how long to wait until performing the transition in autoplay mode

- (NSComparisonResult)compareByTransitionIndicesTo:(MHSlideTransition *)anotherAnimation;    // used to sort animations in increasing order of their transition indices

@end


@protocol MHSlideTransitionAnimatablePropertyExpression <NSObject>

- (void)beginPropertyChangeBlock;

// these two methods must be called inside a beginPropertyChangeBlock/endPropertyChangeBlockAndApplyChanges block
- (void)restorePropertiesToInitialState;
- (void)changeProperty:(NSString *)propertyName to:(NSArray <NSNumber *> *)newPropertyValue;

- (void)endPropertyChangeBlockAndApplyChanges:(bool)animated;

@end

NS_ASSUME_NONNULL_END
