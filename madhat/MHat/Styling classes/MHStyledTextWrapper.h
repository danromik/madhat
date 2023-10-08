//
//  MHStyledTextWrapper.h
//  MadHat
//
//  Created by Dan Romik on 8/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"
#import "MHTypingStyle.h"

NS_ASSUME_NONNULL_BEGIN

// FIXME: this typedef is almost identical to the MHTypingStyleTextType typedef in MHTypingStyle.h. Is it good coding practice to have two small variations on the same idea? Is there a more efficient way to organize things?
typedef enum {
    MHStyledTextNormalStyle = 0,
    MHStyledTextHeaderStyle = 1,
    MHStyledTextSubheaderStyle = 2,
    MHStyledTextSubsubheaderStyle = 3,
    MHStyledTextParagraphHeaderStyle = 4,
    MHStyledTextSuperheaderStyle = 5,
    MHStyledTextBoldStyle = 6,
    MHStyledTextItalicStyle = 7,
    MHStyledTextHighlightStyle = 8,
    MHStyledTextUnderlineStyle = 9,
    MHStyledTextStrikethroughStyle = 10,
    MHStyledTextCustomStyle = 11,
} MHStyledTextType;


@interface MHStyledTextWrapper : MHWrapper <MHCommand, MHOutlinerItemMarker>

//@property (readonly) MHTypingStyleTextType textType;
@property (readonly) MHStyledTextType textType;

+ (instancetype)styledTextWrapperWithTextType:(MHStyledTextType)textType contents:(MHExpression *)contents;

@end

NS_ASSUME_NONNULL_END
