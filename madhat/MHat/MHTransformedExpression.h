//
//  MHTransformedExpression.h
//  MadHat
//
//  Created by Dan Romik on 7/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum {
    MHExpressionTranslationRelativeToCorner,
    MHExpressionTranslationRelativeToCenter
} MHExpressionTranslationCenteringType;


@interface MHTransformedExpression : MHWrapper <MHCommand>

@property CGPoint translationPoint;
@property MHExpressionTranslationCenteringType centeringType;

+ (instancetype)transformedExpressionWithContents:(MHExpression *)contents
                                 translationPoint:(CGPoint)point
                                    centeringType:(MHExpressionTranslationCenteringType)centeringType;


@end

NS_ASSUME_NONNULL_END
