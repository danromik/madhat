//
//  MHVideo.h
//  MadHat
//
//  Created by Dan Romik on 8/27/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

extern NSString * _Nonnull const kMHVideoCommandName;

NS_ASSUME_NONNULL_BEGIN

@interface MHVideo : MHExpression <MHCommand, MHAnimatableExpression>

+ (instancetype)videoWithVideoIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
