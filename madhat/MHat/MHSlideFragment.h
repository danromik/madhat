//
//  MHSlideFragment.h
//  MadHat
//
//  Created by Dan Romik on 7/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MHSlideFragment <NSObject>
@property (readonly) bool overrideDefaultBehaviorInSlideTransitions;
@end


@interface MHSlideFragment : MHWrapper <MHCommand, MHSlideFragment>


+ (instancetype)slideFragmentWithContents:(MHExpression *)contents
                             transitionIn:(nullable MHSlideTransition *)transitionIn       // passing nil means there will be no transition in, i.e., the fragment will always be visible
                            transitionOut:(nullable MHSlideTransition *)transitionOut      // passing nil means there will be no transition out, i.e., the fragment will remain on screen once it becomes visible
                      onScreenTransitions:(nullable NSArray <MHSlideTransition *> *)onScreenTransitions   // passing nil or an empty array means there will be no on screen transitions
                propertyChangeTransitions:(nullable NSArray <MHSlideTransition *> *)propertyChangeTransitions;   // passing nil or an empty array means there will be no on screen transitions




@end


NS_ASSUME_NONNULL_END
