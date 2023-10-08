//
//  MHGraphicsCommand.h
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHGraphicsCommand : MHCommand


+ (instancetype)lineThicknessCommand:(CGFloat)lineThickness;
+ (instancetype)markerTypeCommandWithType:(MHGraphicsMarkerType)markerType;
+ (instancetype)markerScaleCommand:(CGFloat)markerScale;


@end

NS_ASSUME_NONNULL_END
