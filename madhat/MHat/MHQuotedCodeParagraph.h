//
//  MHQuotedCodeParagraph.h
//  MadHat
//
//  Created by Dan Romik on 8/18/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHParagraph.h"
#import "MHParser.h"

NS_ASSUME_NONNULL_BEGIN


@interface MHQuotedCodeParagraph : MHParagraph

+ (instancetype)quotedCodeParagraphWithCodeString:(NSString *)code inTextMode:(bool)inTextMode;

@end

NS_ASSUME_NONNULL_END
