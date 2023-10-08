//
//  MHRichTextAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/13/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHRichTextAtom : MHExpression
{
@protected
    NSAttributedString *_attributedString;
}


+ (instancetype)richTextAtomWithAttributedString:(NSAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
