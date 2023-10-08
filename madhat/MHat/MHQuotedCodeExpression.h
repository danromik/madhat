//
//  MHQuotedCodeExpression.h
//  MadHat
//
//  Created by Dan Romik on 8/4/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHRichTextAtom.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHQuotedCodeExpression : MHRichTextAtom

+ (instancetype)quotedCodeExpressionWithCodeString:(NSString *)code inTextMode:(bool)inTextMode;

@end

NS_ASSUME_NONNULL_END
