//
//  MHWrapper.h
//  MadHat
//
//  Created by Dan Romik on 7/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHWrapper : MHContainer <MHSplittableExpression, MHDecomposableForReformatting>

@property MHExpression *contents;

- (instancetype)initWithContents:(MHExpression *)contents;

@end

NS_ASSUME_NONNULL_END
