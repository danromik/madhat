//
//  MHQuotedCodeParagraph.m
//  MadHat
//
//  Created by Dan Romik on 8/18/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHQuotedCodeParagraph.h"
#import "MHTypesettingContextManager.h"
#import "MHStyleIncludes.h"
#import "NSAttributedString+QuickLineBreaking.h"
#import "MHRichTextAtom.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeEditorThemeManager.h"

#import "MHMathParagraph.h"
#import "MHMathAtom.h"

// FIXME: much of the code in this class is identical to code in the MHQuotedCodeParagraph class - violates DRY principle, improve

static NSString * const kMHQuotedCodeParagraphBackgroundNodeName = @"MHQuotedCodeParagraphBackgroundCodeName";

@interface MHQuotedCodeParagraph ()
{
    NSAttributedString *_syntaxColoredCode;
    bool _inTextMode;
    NSArray <SKNode *> *_codeLineNodes;
    BOOL _textWasCopied;
}

@end


@implementation MHQuotedCodeParagraph


#pragma mark - Constructor methods

+ (instancetype)quotedCodeParagraphWithCodeString:(NSString *)code inTextMode:(bool)inTextMode
{
    NSAttributedString *syntaxColoredCode = [MHParser syntaxColoredCodeFromCode:code codeFormattingStyle:inTextMode ? MHParserCodeFormattingText : MHParserCodeFormattingMathWithMathParagraphPrefix];
    return [[self alloc] initWithSyntaxColoredCode:syntaxColoredCode inTextMode:inTextMode];
}

- (instancetype)initWithSyntaxColoredCode:(NSAttributedString *)syntaxColoredCode inTextMode:(bool)inTextMode
{
    if (self = [super init]) {
        _syntaxColoredCode = syntaxColoredCode;
        _inTextMode = inTextMode;
    }
    return self;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHQuotedCodeParagraph *myCopy = [[[self class] alloc] initWithSyntaxColoredCode:[_syntaxColoredCode copy] inTextMode:_inTextMode];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    static const CGFloat horizontalInset = 10.0;
    static const CGFloat verticalInset = 10.0;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    [mySpriteKitNode removeAllChildren];

    [super typesetWithContextManager:contextManager];
    
    NSUInteger logicalIndentLevel = contextManager.logicalIndentLevel;
    MHDimensions myDimensions = self.dimensions;    // this contains the width we will use for typesetting
    
    CGFloat quotedCodeWidth = myDimensions.width - logicalIndentLevel * kMHParagraphLogicalIndentationMultiplier - 2 * horizontalInset;
    
    NSMutableAttributedString *transformedSyntaxColoredCode = [_syntaxColoredCode mutableCopy];
    CGFloat fontSize = contextManager.baseFontSize;
    NSFontManager *sharedFontManager = [NSFontManager sharedFontManager];
    NSUInteger syntaxColoredCodeLength = _syntaxColoredCode.length;
    for (NSUInteger charIndex = 0; charIndex < syntaxColoredCodeLength; charIndex++) {
        NSFont *fontFromSyntaxColoredCode = [_syntaxColoredCode attribute:NSFontAttributeName atIndex:charIndex effectiveRange:nil];
        NSFont *convertedFont = [sharedFontManager convertFont:fontFromSyntaxColoredCode toSize:fontSize];
        [transformedSyntaxColoredCode addAttribute:NSFontAttributeName value:convertedFont range:NSMakeRange(charIndex, 1)];
    }
    _syntaxColoredCode = [transformedSyntaxColoredCode copy];
    
    NSArray <NSAttributedString *> *_codeLines = [_syntaxColoredCode layoutLinesWithWidth:quotedCodeWidth];
    NSMutableArray <SKNode *> *codeLineNodesMutable = [[NSMutableArray alloc] initWithCapacity:0];
    CGFloat vOffset = verticalInset;
    for (NSAttributedString *line in _codeLines) {
        MHRichTextAtom *richTextAtom = [MHRichTextAtom richTextAtomWithAttributedString:line];
        [richTextAtom typesetWithContextManager:contextManager];
        MHDimensions lineDimensions = richTextAtom.dimensions;
        vOffset += lineDimensions.height;
        SKNode *lineNode = richTextAtom.spriteKitNode;
        lineNode.ownerExpression = self;
        [mySpriteKitNode addChild:lineNode];
        lineNode.position = CGPointMake(horizontalInset + logicalIndentLevel * kMHParagraphLogicalIndentationMultiplier, -vOffset);
        vOffset += lineDimensions.depth;
        
        [codeLineNodesMutable addObject:lineNode];
    }
    _codeLineNodes = [NSArray arrayWithArray:codeLineNodesMutable];
    
    myDimensions.height = 0.0;
    myDimensions.depth = vOffset + verticalInset;       // FIXME: this works (typesets correctly), but in MHTextParagraph there is a comment "a paragraph is all height, no depth", so there is an inconsistency here that may create problems in the future and needs correcting
 
    MHSourceCodeEditorTheme *editorTheme = [[MHSourceCodeEditorThemeManager defaultManager] defaultThemeForQuotedCode];
    NSColor *backgroundColor = _inTextMode ? editorTheme.backgroundColor : editorTheme.mathModeBackgroundColor;
    SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor
                                                                size:CGSizeMake(myDimensions.width - logicalIndentLevel * kMHParagraphLogicalIndentationMultiplier, myDimensions.depth + myDimensions.height)];
    backgroundNode.anchorPoint = CGPointMake(0.0,1.0);
    backgroundNode.position = CGPointMake(logicalIndentLevel * kMHParagraphLogicalIndentationMultiplier, 0.0);
    backgroundNode.zPosition = -100.0;
    backgroundNode.name = kMHQuotedCodeParagraphBackgroundNodeName;
    [mySpriteKitNode addChild:backgroundNode];
    
    self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
    
    self.dimensions = myDimensions;
    
    [self doPostTypesettingHousekeeping];
}


- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    [super reformatWithContextManager:contextManager animationType:animationType];
    
    
    // a copy and paste of code from MHExpression's -reformat... method. We need this because the content is added as pure nodes with no associated expressions, so it doesn't get processed using the recursive mechanism that leads to MHExpression's reformat method being called
    // FIXME: this is obviously not good, OO-compliant design. Improve!
    MHOutlinerVisibilityState visibilityState = [contextManager currentOutlinerVisibilityState];
    bool outlinerVisibilityHidden = (visibilityState != MHOutlinerVisibilityStateVisible);
    // Handling of the node state related to the outliner
    if (animationType == MHReformattingAnimationTypeOutliner) {
        SKAction *action = [SKAction fadeAlphaTo:(outlinerVisibilityHidden ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
        [self.spriteKitNode runAction:action];
    }
    else {
        self.spriteKitNode.alpha = (outlinerVisibilityHidden ? 0.0 : 1.0);
    }
    
    // FIXME: because of the design of the class, reformatting in this class doesn't produce the intended results when there are slide transitions. This is because the code handling slide transitions is currently in the MHParagraph class, and iterates over subexpressions. Here the content is added as pure nodes with no associated expressions, so it doesn't get processed using that mechanism.
}


#pragma mark - Mouse clicks and hovering behavior

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:_syntaxColoredCode.string forType:NSStringPboardType];
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


- (MHParagraphType)type
{
    return MHParagraphQuotedCodeParagraph;
}


#pragma mark - Rendering to a PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);
    
    SKSpriteNode *backgroundNode = (SKSpriteNode *)[self.spriteKitNode childNodeWithName:kMHQuotedCodeParagraphBackgroundNodeName];
    NSColor *backgroundColor = backgroundNode.color;
    CGPoint backgroundNodePosition = backgroundNode.position;
    CGSize backgroundNodeSize = backgroundNode.size;
    CGPathRef rectanglePath = CGPathCreateWithRect(CGRectMake(backgroundNodePosition.x,
                                                              backgroundNodePosition.y - backgroundNodeSize.height,
                                                              backgroundNodeSize.width,
                                                              backgroundNodeSize.height), nil);
    CGColorRef cgColor = [backgroundColor CGColor];
    CGContextAddPath(pdfContext, rectanglePath);
    CGContextSetFillColorWithColor(pdfContext, cgColor);
    CGContextSetStrokeColorWithColor(pdfContext, cgColor);
    CGContextDrawPath(pdfContext, kCGPathFillStroke);
    
    for (SKNode *line in _codeLineNodes) {
        CGPoint position = line.position;
        
        CGContextTranslateCTM(pdfContext, position.x, position.y);
        NSArray <SKNode *> *children = line.children;
        for (SKNode *child in children) {
            CGPoint childPosition = child.position;
            CGContextTranslateCTM(pdfContext, childPosition.x, childPosition.y);
            [child renderInPDFContext:pdfContext];
            CGContextTranslateCTM(pdfContext, -childPosition.x, -childPosition.y);
        }
        CGContextTranslateCTM(pdfContext, -position.x, -position.y);
    }
    CGContextRestoreGState(pdfContext);
}


@end
