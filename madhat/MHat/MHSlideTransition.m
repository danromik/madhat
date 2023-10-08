//
//  MHSlideTransition.m
//  MadHat
//
//  Created by Dan Romik on 7/17/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSlideTransition.h"


#define kMHSlideTransitionAnimationMinimalDuration      0.01
#define kMHSlideTransitionAnimationMaximalDuration      10.0
#define kMHSlideTransitionAnimationMaximalTransitionIndex   50

#define kMHSlideTransitionAnimationMaximalDelayUntilTransition   3600


@implementation MHSlideTransition

+ (instancetype)slideTransitionWithTransitionIndex:(NSUInteger)transitionIndex
                                     animationType:(MHSlideTransitionAnimationType)type
                                  animationProfile:(MHSlideTransitionAnimationProfileType)profile
                                 animationDuration:(NSTimeInterval)duration
                                   animationVector:(CGVector)animationVector
                                      propertyName:(nullable NSString *)propertyName
                                     propertyValue:(nullable NSArray <NSNumber *> *)propertyValue
                              delayUntilTransition:(NSTimeInterval)delayUntilTransition
{
    return [[self alloc] initWithTransitionIndex:transitionIndex
                                   animationType:type
                                animationProfile:profile
                               animationDuration:duration
                                 animationVector:animationVector
                                    propertyName:propertyName
                                   propertyValue:propertyValue
                            delayUntilTransition:delayUntilTransition];
}

- (instancetype)initWithTransitionIndex:(NSUInteger)transitionIndex
                          animationType:(MHSlideTransitionAnimationType)type
                       animationProfile:(MHSlideTransitionAnimationProfileType)profile
                      animationDuration:(NSTimeInterval)duration
                        animationVector:(CGVector)animationVector
                           propertyName:(nullable NSString *)propertyName
                          propertyValue:(nullable NSArray <NSNumber *> *)propertyValue
                   delayUntilTransition:(NSTimeInterval)delayUntilTransition;
{
    if (self = [super init]) {
        self.animationType = type;
        self.transitionIndex = (transitionIndex <= kMHSlideTransitionAnimationMaximalTransitionIndex ? transitionIndex :
                                kMHSlideTransitionAnimationMaximalTransitionIndex);
        self.animationProfile = profile;
        NSTimeInterval sanitizedDuration;
        if (duration < kMHSlideTransitionAnimationMinimalDuration)
            sanitizedDuration = kMHSlideTransitionAnimationMinimalDuration;
        else if (duration > kMHSlideTransitionAnimationMaximalDuration)
            sanitizedDuration = kMHSlideTransitionAnimationMaximalDuration;
        else
            sanitizedDuration = duration;
        self.animationDuration = sanitizedDuration;
        self.animationVector = animationVector;
        self.propertyName = propertyName;
        self.propertyValue = propertyValue;
        self.delayUntilTransition = (delayUntilTransition < 0.0 ? 0.0 :
                                     (delayUntilTransition > kMHSlideTransitionAnimationMaximalDelayUntilTransition ? kMHSlideTransitionAnimationMaximalDelayUntilTransition : delayUntilTransition));
    }
    return self;
}


- (NSComparisonResult)compareByTransitionIndicesTo:(MHSlideTransition *)anotherAnimation
{
    NSUInteger myTransitionIndex = self.transitionIndex;
    NSUInteger otherAnimationTransitionIndex = anotherAnimation.transitionIndex;
    if (myTransitionIndex == otherAnimationTransitionIndex)
        return NSOrderedSame;
    if (myTransitionIndex < otherAnimationTransitionIndex)
        return NSOrderedAscending;
    return NSOrderedDescending;
}



- (instancetype)copy
{
    MHSlideTransition *myCopy = [[self class] slideTransitionWithTransitionIndex:self.transitionIndex
                                                                   animationType:self.animationType
                                                                animationProfile:self.animationProfile
                                                               animationDuration:self.animationDuration
                                                                 animationVector:self.animationVector
                                                                    propertyName:self.propertyName
                                                                   propertyValue:[self.propertyValue copy]
                                                            delayUntilTransition:self.delayUntilTransition];
    return myCopy;
}


@end
