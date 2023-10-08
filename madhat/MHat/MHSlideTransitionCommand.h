//
//  MHSlideTransitionCommand.h
//  MadHat
//
//  Created by Dan Romik on 6/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN



@interface MHSlideTransitionCommand : MHCommand


+ (instancetype)slideTransitionCommandWithSlideTransition:(MHSlideTransition *)slideTransition;


@end

NS_ASSUME_NONNULL_END
