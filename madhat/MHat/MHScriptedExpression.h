//
//  MHScriptedExpression.h
//  MadHat
//
//  Created by Dan Romik on 10/21/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MHContainer.h"
#import "MHBracket.h"
#import "MHCommand.h"
#import "MHTypesettingContextManager.h"
#import "MHStyleIncludes.h"


extern NSUInteger const kMHScriptedExpressionSuperscriptNestingLevels[kMHNumberOfNestingLevels];
extern NSUInteger const kMHScriptedExpressionSubscriptNestingLevels[kMHNumberOfNestingLevels];

NS_ASSUME_NONNULL_BEGIN

@interface MHScriptedExpression : MHContainer <MHBracket, MHCommand>

@property (readonly) MHExpression *body;
@property MHExpression *subscript;
@property MHExpression *superscript;

// FIXME: make subscript and superscript nullable arguments to allow for one of them being absent?
+ (instancetype)scriptedExpressionWithBody:(MHExpression *)body
                                 subscript:(MHExpression *)subscript
                               superscript:(MHExpression *)superscript;

- (instancetype)initWithBody:(MHExpression *)body subscript:(MHExpression *)subscript superscript:(MHExpression *)superscript;


// used by the MHMultiScriptedExpression subclass to compute positions for the presubscript and presuperscript (since the formulas are the same in that case)
- (void)calculateSubscriptAndSuperscriptVerticalPositionsForBodyDimensions:(MHDimensions)bodyDimensions
                                                       subscriptDimensions:(MHDimensions)subscriptDimensions
                                                     superscriptDimensions:(MHDimensions)superscriptDimensions
                                                                   xHeight:(CGFloat)xHeight
                                                     subscriptYPositionPtr:(CGFloat *)subscriptYPositionPtr
                                                   superscriptYPositionPtr:(CGFloat *)superscriptYPositionPtr;


@end

NS_ASSUME_NONNULL_END
