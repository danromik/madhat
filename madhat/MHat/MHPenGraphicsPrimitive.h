//
//  MHPenGraphicsPrimitive.h
//  MadHat
//
//  Created by Dan Romik on 8/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGraphicsPrimitive.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHPenGraphicsPrimitive : MHGraphicsPrimitive

+ (instancetype)penGraphicsWithMoveToAbsolutePoint:(CGPoint)point;
+ (instancetype)penGraphicsWithLineToAbsolutePoint:(CGPoint)point;
+ (instancetype)penGraphicsWithCurveWithAbsolutePoints:(CGPoint)point1  :(CGPoint)point2  :(CGPoint)point3;

+ (instancetype)penGraphicsWithPenMoveForward:(CGFloat)units;


@end

NS_ASSUME_NONNULL_END
