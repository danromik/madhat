//
//  MHLeftCenterRightExpressionsLine.h
//  MadHat
//
//  Created by Dan Romik on 11/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHContainer.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHLeftCenterRightExpressionsLine : MHContainer <MHCommand>

+ (instancetype)leftRightLineWithLeftSideExpression:(MHExpression *)leftExpression rightSideExpression:(MHExpression *)rightExpression;
+ (instancetype)leftCenterRightLineWithLeftSideExpression:(MHExpression *)leftExpression
                                         centerExpression:(MHExpression *)centerExpression
                                      rightSideExpression:(MHExpression *)rightExpression;

@end

NS_ASSUME_NONNULL_END
