//
//  MHFraction.h
//  MadHat
//
//  Created by Dan Romik on 10/25/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHContainer.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHFraction : MHContainer <MHCommand>

@property MHExpression *numerator;
@property MHExpression *denominator;

@property (readonly) bool showsFractionLine;       // defaults to YES

+ (instancetype)fractionWithNumerator:(MHExpression *)numerator denominator:(MHExpression *)denominator;

+ (instancetype)noLineFractionWithNumerator:(MHExpression *)numerator denominator:(MHExpression *)denominator;

@end

NS_ASSUME_NONNULL_END
