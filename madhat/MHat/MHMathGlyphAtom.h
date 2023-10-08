//
//  MHMathGlyphAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGlyphAtom.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHMathGlyphAtom : MHGlyphAtom

+ (instancetype)mathGlyphAtomWithGlyphName:(NSString *)string typographyClass:(MHTypographyClass)typographyClass;

@property bool isLimitsOperator;


@end

NS_ASSUME_NONNULL_END
