//
//  MHStyledMathWrapper.h
//  MadHat
//
//  Created by Dan Romik on 8/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHStyledMathWrapper : MHWrapper <MHCommand>

+ (instancetype)styledMathWrapperWithMathFontVariant:(MHMathFontVariant)mathFontVariant contents:(MHExpression *)contents;

@end

NS_ASSUME_NONNULL_END
