//
//  MHCheckboxExpression.h
//  MadHat
//
//  Created by Dan Romik on 11/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHCheckboxExpression : MHExpression <MHCommand>

@property bool checked;

+ (instancetype)checkboxExpression:(bool)checked;

- (void)toggle;

@end

NS_ASSUME_NONNULL_END
