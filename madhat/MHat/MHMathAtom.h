//
//  MHMathAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTextAtom.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHMathAtom : MHTextAtom <MHCommand>


+ (instancetype)mathAtomWithString:(NSString *)string typographyClass:(MHTypographyClass)typographyClass;


@end

NS_ASSUME_NONNULL_END
