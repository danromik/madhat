//
//  MHCurveLayoutWrapper.h
//  MadHat
//
//  Created by Dan Romik on 8/1/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHCurveLayoutWrapper : MHWrapper <MHCommand>

+ (instancetype)curveLayoutWrapperWithContents:(MHExpression *)contents
                        graphicsPathExpression:(MHHorizontalLayoutContainer *)graphicsPathExpression;


@end

NS_ASSUME_NONNULL_END
