//
//  MHSlideTransitionCommand.m
//  MadHat
//
//  Created by Dan Romik on 6/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHSlideTransitionCommand.h"
#import "MHHorizontalLayoutContainer.h"



NSString * const kMHSlideTransitionCommandNameSamePageSlideTransition = @"pause";
NSString * const kMSlideTransitionCommandNameTimedTransitionToNextPage = @"next page in";




@interface MHSlideTransitionCommand ()
{
    MHSlideTransition *_slideTransition;
}

@end


@implementation MHSlideTransitionCommand


#pragma mark - Initializers



+ (instancetype)slideTransitionCommandWithSlideTransition:(MHSlideTransition *)slideTransition
{
    return [[self alloc] initWithSlideTransition:slideTransition];
}

- (instancetype)initWithSlideTransition:(MHSlideTransition *)slideTransition
{
    if (self = [super init]) {
        _slideTransition = slideTransition;
    }
    return self;
}



#pragma mark - reformat method


- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [contextManager incrementSlideTransitionCounter];
}

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    [super reformatWithContextManager:contextManager animationType:animationType];
    [contextManager insertSlideTransition:_slideTransition];
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    bool isSamePageSlideTransitionCommand;
    bool isTimedTransitionToNextPageCommand;
    
    if ((isSamePageSlideTransitionCommand = [name isEqualToString:kMHSlideTransitionCommandNameSamePageSlideTransition])
        || (isTimedTransitionToNextPageCommand = [name isEqualToString:kMSlideTransitionCommandNameTimedTransitionToNextPage])) {
        double delay = [argument floatValue];
        double duration = kMHDefaultSlideTransitionAnimationDuration;
        MHSlideTransitionAnimationType animationType = (isSamePageSlideTransitionCommand ? MHSlideTransitionAnimationSlideFromRight :
                                                        MHSlideTransitionTimedTransitionToNextPage);
        MHSlideTransitionAnimationProfileType animationProfile = MHSlideTransitionAnimationProfileEaseOut;

        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        if (isSamePageSlideTransitionCommand && attributes) {
            MHExpression *animationTypeExpression = attributes[kMHSlideTransitionAttributeNameAnimation];
            if (animationTypeExpression) {
                NSString *animationTypeString = animationTypeExpression.stringValue;
                if ([animationTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromLeft])
                    animationType = MHSlideTransitionAnimationSlideFromLeft;
                else if ([animationTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromTop])
                    animationType = MHSlideTransitionAnimationSlideFromTop;
                else if ([animationTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueSlideFromBottom])
                    animationType = MHSlideTransitionAnimationSlideFromBottom;
                else if ([animationTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueFadeIn])
                    animationType = MHSlideTransitionAnimationFadeIn;
                else if ([animationTypeString isEqualToString:kMHSlideTransitionAnimationTypeAttributeValueNoAnimation])
                    animationType = MHSlideTransitionAnimationNone;
                else
                    animationType = MHSlideTransitionAnimationSlideFromRight;   // FIXME: have the context manager provide the default animation type
            }
            
            MHExpression *animationDurationExpression = attributes[kMHSlideTransitionAttributeNameDuration];
            if (animationDurationExpression) {
                duration = [animationDurationExpression floatValue];
            }
            
            MHExpression *animationProfileExpression = attributes[kMHSlideTransitionAttributeNameAnimationProfile];
            if (animationProfileExpression) {
                NSString *animationProfileString = [animationProfileExpression stringValue];
                if ([animationProfileString isEqualToString:kMHSlideTransitionAttributeValueEaseAnimationProfile])
                    animationProfile = MHSlideTransitionAnimationProfileEaseOut;
                else if ([animationProfileString isEqualToString:kMHSlideTransitionAttributeValueLinearAnimationProfile])
                    animationProfile = MHSlideTransitionAnimationProfileLinear;
                else if ([animationProfileString isEqualToString:kMHSlideTransitionAttributeValueBounceAnimationProfile])
                    animationProfile = MHSlideTransitionAnimationProfileBounce;
                else if ([animationProfileString isEqualToString:kMHSlideTransitionAttributeValueElasticAnimationProfile])
                    animationProfile = MHSlideTransitionAnimationProfileElastic;
            }
        }
        
        MHSlideTransition *slideTransition = [MHSlideTransition slideTransitionWithTransitionIndex:0    // this is ignored as we do not know at this point the transition index when the transition will take place
                                                                                     animationType:animationType
                                                                                  animationProfile:animationProfile
                                                                                 animationDuration:duration
                                                                                   animationVector:(CGVector)CGVectorMake(0.0, 0.0)
                                                                                      propertyName:nil
                                                                                     propertyValue:nil
                                                                              delayUntilTransition:delay];
        return [self slideTransitionCommandWithSlideTransition:slideTransition];
    }

    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHSlideTransitionCommandNameSamePageSlideTransition
    ];
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHSlideTransitionCommand *myCopy = [[self class] slideTransitionCommandWithSlideTransition:[_slideTransition copy]];
    
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end
