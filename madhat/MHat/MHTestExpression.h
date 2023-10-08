//
//  MHTestExpression.h
//  MadHat
//
//  Created by Dan Romik on 8/16/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTestExpression : MHExpression <MHCommand>

+ (instancetype)testExpressionWithDimensions:(MHDimensions)dimensions;

@end

NS_ASSUME_NONNULL_END
