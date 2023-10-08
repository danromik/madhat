//
//  MHQuotedCodeExpression.m
//  MadHat
//
//  Created by Dan Romik on 8/4/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHQuotedCodeExpression.h"
#import "MHParser.h"
#import "MHTypesettingContextManager+TypingStyle.h"

// FIXME: much of the code in this class is identical to code in the MHQuotedCodeParagraph class - violates DRY principle, improve

@interface MHQuotedCodeExpression ()
{
    BOOL _textWasCopied;
}
@end


@implementation MHQuotedCodeExpression

+ (instancetype)quotedCodeExpressionWithCodeString:(NSString *)code inTextMode:(bool)inTextMode
{
    NSAttributedString *syntaxColoredCode = [MHParser syntaxColoredCodeFromCode:code
                                                            codeFormattingStyle:(inTextMode ? MHParserCodeFormattingText :
                                                                                 MHParserCodeFormattingMathWithoutMathParagraphPrefix)];
    return [self richTextAtomWithAttributedString:syntaxColoredCode];
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSMutableAttributedString *transformedAttributedString = [_attributedString mutableCopy];
    CGFloat fontSize = contextManager.baseFontSize;
    NSFontManager *sharedFontManager = [NSFontManager sharedFontManager];
    NSUInteger syntaxColoredCodeLength = _attributedString.length;
    for (NSUInteger charIndex = 0; charIndex < syntaxColoredCodeLength; charIndex++) {
        NSFont *fontFromSyntaxColoredCode = [_attributedString attribute:NSFontAttributeName atIndex:charIndex effectiveRange:nil];
        NSFont *convertedFont = [sharedFontManager convertFont:fontFromSyntaxColoredCode toSize:fontSize];
        [transformedAttributedString addAttribute:NSFontAttributeName value:convertedFont range:NSMakeRange(charIndex, 1)];
    }
    _attributedString = [transformedAttributedString copy];

    [super typesetWithContextManager:contextManager];

    self.spriteKitNode.ownerExpression = self;
    self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
}


#pragma mark - Mouse clicks and hovering behavior

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:_attributedString.string forType:NSStringPboardType];
    _textWasCopied = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(resetTextWasCopiedFlag) withObject:nil afterDelay:2.0];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHNotebookPageShowTransientStatusMessageNotification
                                                        object:self
                                                      userInfo:@{ kMHNotebookPageShowTransientStatusMessageMessageKey :
                                                                      NSLocalizedString(@"Code copied", @"") }];
}


- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    if (_textWasCopied) {
        return nil; // NSLocalizedString(@"Code copied", @"");
    }
    return NSLocalizedString(@"Copy code to clipboard", @"");
}

- (void)resetTextWasCopiedFlag
{
    _textWasCopied = NO;
}




@end
