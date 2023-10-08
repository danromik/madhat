//
//  MHRadical.h
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHRadical : MHWrapper  <MHCommand>

+ (instancetype)radicalWithContents:(MHExpression *)contents;


@end

NS_ASSUME_NONNULL_END
