//
//  MHBoxCommand.h
//  MadHat
//
//  Created by Dan Romik on 9/27/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    MHBoxCommandBeginBox,
    MHBoxCommandEndBox,
    MHBoxCommandBoxDivider,    // FIXME: add this
    MHBoxCommandBoxFrameWidth,
} MHBoxCommandType;

@interface MHBoxCommand : MHCommand

+ (instancetype)beginBoxCommand;
+ (instancetype)endBoxCommand;
+ (instancetype)boxDividerCommand;
+ (instancetype)boxFrameWidthCommand:(CGFloat)frameWidth;

@end

NS_ASSUME_NONNULL_END
