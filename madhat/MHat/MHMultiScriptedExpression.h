//
//  MHMultiScriptedExpression.h
//  MadHat
//
//  Created by Dan Romik on 8/17/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHScriptedExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHMultiScriptedExpression : MHScriptedExpression

@property MHExpression *presubscript;
@property MHExpression *presuperscript;

+ (instancetype)scriptedExpressionWithBody:(MHExpression *)body
                                 subscript:(MHExpression *)subscript
                               superscript:(MHExpression *)superscript
                              presubscript:(MHExpression *)presubscript
                            presuperscript:(MHExpression *)presuperscript;


@end

NS_ASSUME_NONNULL_END
