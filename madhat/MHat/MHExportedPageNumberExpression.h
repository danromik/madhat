//
//  MHExportedPageNumberExpression.h
//  MadHat
//
//  Created by Dan Romik on 11/19/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHExportedPageNumberExpression : MHExpression <MHCommand>

+ (instancetype)exportedPageNumberExpression;

@end

NS_ASSUME_NONNULL_END
