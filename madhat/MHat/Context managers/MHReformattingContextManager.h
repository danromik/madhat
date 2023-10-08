//
//  MHReformattingContextManager.h
//  MadHat
//
//  Created by Dan Romik on 6/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MHSlideTransition.h"


// A bit mask encoding the different combinations of outliner visibility states
typedef enum : NSUInteger {
    MHOutlinerVisibilityStateVisible = 0,
    MHOutlinerVisibilityStateHiddenDueToCurrentNodeCollapsedPart = 1,
    MHOutlinerVisibilityStateHiddenDueToAncestorNodeCollapsedPart = 2
} MHOutlinerVisibilityState;


// FIXME: in the current version of the code I think this typedef isn't used anywhere, maybe remove it
// Possible visibility states associated with slide transitions
typedef enum {
    MHSlideTransitionVisibilityStateVisible = 0,
    MHSlideTransitionVisibilityStateHidden = 1
} MHSlideTransitionVisibilityState;


typedef enum {
    MHReformattingAnimationTypeNone = 0,
    MHReformattingAnimationTypeOutliner = 1,
    MHReformattingAnimationTypeSlideTransition = 2
} MHReformattingAnimationType;


extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimation;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimateIn;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimateOut;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameMoveOnTransition;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNamePropertyChangeOnTransition;

extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideFromRight;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideFromLeft;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideFromTop;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideFromBottom;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideToRight;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideToLeft;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideToTop;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueSlideToBottom;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueFadeIn;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueFadeOut;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueHelicopter;
extern NSString * _Nonnull const kMHSlideTransitionAnimationTypeAttributeValueNoAnimation;

extern NSString * _Nonnull const kMHSlideTransitionAttributeNameDuration;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameDurationIn;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameDurationOut;

extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimationProfile;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimationProfileIn;
extern NSString * _Nonnull const kMHSlideTransitionAttributeNameAnimationProfileOut;

extern NSString * _Nonnull const kMHSlideTransitionAttributeValueEaseAnimationProfile;
extern NSString * _Nonnull const kMHSlideTransitionAttributeValueLinearAnimationProfile;
extern NSString * _Nonnull const kMHSlideTransitionAttributeValueBounceAnimationProfile;
extern NSString * _Nonnull const kMHSlideTransitionAttributeValueElasticAnimationProfile;





NS_ASSUME_NONNULL_BEGIN

@interface MHReformattingContextManager : NSObject


// Multi-part slides and slide transitions
@property NSUInteger currentSlideTransitionIndex;
@property (readonly) NSUInteger slideCounter;
//@property (readonly) NSUInteger maxSlideCounter;  // disabling this, might add it back later if it seems like a good idea
@property (readonly) MHSlideTransitionVisibilityState currentSlideTransitionVisibilityState;
@property (readonly) MHSlideTransitionAnimationType currentAnimationType;
@property (readonly) double currentAnimationDuration;
@property (readonly) MHSlideTransitionAnimationProfileType currentAnimationProfile;
@property (readonly) NSArray <MHSlideTransition *> *slideTransitions;

- (void)insertSlideTransition:(MHSlideTransition *)slideTransition;
//- (void)registerSlideFragmentVisibleFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;      // disabling this, might add it back later if it seems like a good idea


// Outliner
@property (readonly) MHOutlinerVisibilityState currentOutlinerVisibilityState;
@property (readonly) CGFloat currentVerticalOffsetOfCollapsedSections;

- (void)incrementOutlinerNestingLevel;                          // called when a new outliner sublist is opened
- (void)decrementOutlinerNestingLevel;                          // called when the current sublist is closed
- (void)setOutlinerNestingLevel:(NSUInteger)nestingLevel;       // called to force the nesting level to a specific number by opening/closing an appropriate number of sublists
- (void)beginOutlinerNode:(bool)isCurrentlyCollapsed;           // called when a new item starts
- (void)markBeginningOfMainPartOfCurrentNode;    // called to indicate a marker for the start of the collapsible section for the current outliner item
- (void)incrementCollapsedSectionsVerticalOffsetBy:(CGFloat)offset; // called to indicate a difference between collapsed and uncollapsed height of a section that's currently collapsed





// FIXME: this method is similar to MHTypesettingContextManager, should we refactor to a shared superclass of both classes?
- (void)resetToDefaultState;





@end

NS_ASSUME_NONNULL_END
