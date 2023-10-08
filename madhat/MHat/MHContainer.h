//
//  MHContainer.h
//  MadHat
//
//  Created by Dan Romik on 7/28/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHContainer : MHExpression

- (NSArray <MHExpression *> *)subexpressions;   // any subclass must implement this or have a superclass that implements this

@end

NS_ASSUME_NONNULL_END
