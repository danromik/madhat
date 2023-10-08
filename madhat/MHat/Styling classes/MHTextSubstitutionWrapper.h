//
//  MHTextSubstitutionWrapper.h
//  MadHat
//
//  Created by Dan Romik on 8/5/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTextSubstitutionWrapper : MHWrapper <MHCommand>

+ (instancetype)textSubstitutionWrapperWithSubstitutionType:(MHTextSubstitutionType)substitutionType contents:(MHExpression *)contents;

@end

NS_ASSUME_NONNULL_END
