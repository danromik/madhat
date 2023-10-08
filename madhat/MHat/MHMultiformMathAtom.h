//
//  MHMultiformMathAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

typedef enum {
    MHAtomStringTypeText,
    MHAtomStringTypeGlyph,
} MHAtomStringType;

NS_ASSUME_NONNULL_BEGIN

@interface MHMultiformMathAtom : MHExpression <MHCommand>



+ (instancetype)atomWithInlineModeString:(NSString *)inlineString
                       displayModeString:(NSString *)displayString
                    inlineModeStringType:(MHAtomStringType)inlineStringType
                   displayModeStringType:(MHAtomStringType)displayStringType
                         typographyClass:(MHTypographyClass)typographyClass
              inlineModeIsLimitsOperator:(bool)inlineIsLimits
             displayModeIsLimitsOperator:(bool)displayIsLimits;



@end

NS_ASSUME_NONNULL_END
