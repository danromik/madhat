//
//  MHStyledTextWrapper.m
//  MadHat
//
//  Created by Dan Romik on 8/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHStyledTextWrapper.h"
#import "MHStyleIncludes.h"
#import "MHTextParagraph.h"     // FIXME: only needed because of a hack in the method mouseClickWithSubnode, delete this after improving the hack

NSString * const kMHStyledTextHeaderCommandName = @"header";
NSString * const kMHStyledTextSubheaderCommandName = @"subheader";
NSString * const kMHStyledTextSubsubheaderCommandName = @"subsubheader";
NSString * const kMHStyledTextParagraphHeaderCommandName = @"paragraph header";
NSString * const kMHStyledTextSuperheaderCommandName = @"superheader";
NSString * const kMHStyledTextBoldCommandName = @"bold text";
NSString * const kMHStyledTextItalicCommandName = @"italic text";
NSString * const kMHStyledTextHighlightCommandName = @"highlight";
NSString * const kMHStyledTextUnderlineCommandName = @"underline";
NSString * const kMHStyledTextStrikethroughCommandName = @"strikethrough";
NSString * const kMHStyledTextCustomStyledTextCommandName = @"styled";


@interface MHStyledTextWrapper ()
{
    MHStyledTextType _textType;
    NSString *_customStyleName;
    bool _isCollapsed;
}

@end

@implementation MHStyledTextWrapper



// FIXME: added this to fix a bug with collapsible sections not working. It helps, but is a bit illogical and means reformatting will not decompose the contents of a header/subheader/subsubheader, which could potentially be undesirable - improve. (A similar issue exists in the MHCurveLayoutWrapper class)
- (bool)atomicForReformatting
{
    return (_textType == MHStyledTextHeaderStyle || _textType == MHStyledTextSubheaderStyle || _textType == MHStyledTextSubsubheaderStyle);
}



#pragma mark - Constructors

+ (instancetype)styledTextWrapperWithTextType:(MHStyledTextType)textType contents:(MHExpression *)contents
{
    return [[self alloc] initWithTextType:textType contents:contents];
}

+ (instancetype)styledTextWrapperWithStyleName:(NSString *)styleName contents:(MHExpression *)contents
{
    return [[self alloc] initWithCustomStyleName:styleName contents:contents];
}

- (instancetype)initWithTextType:(MHStyledTextType)textType contents:(MHExpression *)contents
{
    if (self = [super initWithContents:contents]) {
        _textType = textType;
    }
    return self;
}

- (instancetype)initWithCustomStyleName:(NSString *)styleName contents:(MHExpression *)contents
{
    if (self = [self initWithTextType:MHStyledTextCustomStyle contents:contents]) {
        _customStyleName = styleName;
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHStyledTextHeaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextHeaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextSubheaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextSubheaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextSubsubheaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextSubsubheaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextParagraphHeaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextParagraphHeaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextSuperheaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextSuperheaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextHeaderCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextHeaderStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextBoldCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextBoldStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextItalicCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextItalicStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextHighlightCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextHighlightStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextUnderlineCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextUnderlineStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextStrikethroughCommandName]) {
        return [self styledTextWrapperWithTextType:MHStyledTextStrikethroughStyle contents:argument];
    }
    if ([name isEqualToString:kMHStyledTextCustomStyledTextCommandName]) {
        if ([argument numberOfDelimitedBlocks] >= 2) {
            MHExpression *styleNameExpression = [argument expressionFromDelimitedBlockAtIndex:0];
            NSString *styleName = [styleNameExpression stringValue];
            MHExpression *styledBlockContents = [argument expressionFromDelimitedBlockAtIndex:1];
            if (styleName.length > 0)
                return [self styledTextWrapperWithStyleName:styleName contents:styledBlockContents];
        }
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHStyledTextHeaderCommandName,
              kMHStyledTextSubheaderCommandName,
              kMHStyledTextSubsubheaderCommandName,
              kMHStyledTextSuperheaderCommandName,
              kMHStyledTextParagraphHeaderCommandName,
              kMHStyledTextBoldCommandName,
              kMHStyledTextItalicCommandName,
              kMHStyledTextHighlightCommandName,
              kMHStyledTextUnderlineCommandName,
              kMHStyledTextStrikethroughCommandName,
              kMHStyledTextCustomStyledTextCommandName
    ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (_textType) {
        case MHStyledTextHeaderStyle:
            // code for collapsible sections:
            self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
            [contextManager setOutlinerItemStartMarker:self];

            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameHeader];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            contextManager.paragraphType = MHParagraphHeader;
            break;
        case MHStyledTextSubheaderStyle:
            // code for collapsible sections:
            self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
            [contextManager setOutlinerItemStartMarker:self];

            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameSubheader];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            contextManager.paragraphType = MHParagraphSubheader;
            break;
        case MHStyledTextSubsubheaderStyle:
            // code for collapsible sections:
            self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
            [contextManager setOutlinerItemStartMarker:self];

            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameSubsubheader];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            contextManager.paragraphType = MHParagraphSubsubheader;
            break;
        case MHStyledTextNormalStyle:
            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameNormalText];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            break;
        case MHStyledTextParagraphHeaderStyle:
            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameParagraphHeader];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            contextManager.paragraphType = MHParagraphParagraphHeader;
            break;
        case MHStyledTextSuperheaderStyle:
            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:kMHPredefinedTypesettingStateNameSuperheader];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            contextManager.paragraphType = MHParagraphSuperheader;
            break;
        case MHStyledTextBoldStyle: {
            // FIXME: is this bracketing necessary? And wouldn't a beginLocalScope/endLocalScope bracketing be more logical?
            bool currentTextBold = contextManager.textBold;
            contextManager.textBold = true;
            [super typesetWithContextManager:contextManager];
            contextManager.textBold = currentTextBold;
        }
            break;
        case MHStyledTextItalicStyle: {
            // FIXME: is this bracketing necessary? And wouldn't a beginLocalScope/endLocalScope bracketing be more logical?
            bool currentTextItalic = contextManager.textItalic;
            contextManager.textItalic = true;
            [super typesetWithContextManager:contextManager];
            contextManager.textItalic = currentTextItalic;
        }
            break;
        case MHStyledTextHighlightStyle: {
            // FIXME: is this bracketing necessary? And wouldn't a beginLocalScope/endLocalScope bracketing be more logical?
            bool currentTextHighlighting = contextManager.textHighlighting;
            contextManager.textHighlighting = true;
            [super typesetWithContextManager:contextManager];
            contextManager.textHighlighting = currentTextHighlighting;
        }
            break;
        case MHStyledTextUnderlineStyle: {
            // FIXME: is this bracketing necessary? And wouldn't a beginLocalScope/endLocalScope bracketing be more logical?
            bool currentTextUnderlining = contextManager.textUnderlining;
            contextManager.textUnderlining = true;
            [super typesetWithContextManager:contextManager];
            contextManager.textUnderlining = currentTextUnderlining;
            
        }
            break;
        case MHStyledTextStrikethroughStyle: {
            // FIXME: is this bracketing necessary? And wouldn't a beginLocalScope/endLocalScope bracketing be more logical?
            bool currentTextStrikethrough = contextManager.textStrikethrough;
            contextManager.textStrikethrough = true;
            [super typesetWithContextManager:contextManager];
            contextManager.textStrikethrough = currentTextStrikethrough;
        }
            break;
        case MHStyledTextCustomStyle:
            [contextManager beginLocalScope];
            [contextManager loadSavedTypesettingStateWithStyleName:_customStyleName];
            [super typesetWithContextManager:contextManager];
            [contextManager endLocalScope];
            break;
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHStyledTextWrapper *myCopy;
    if (_textType == MHStyledTextCustomStyle) {
        myCopy = [[self class] styledTextWrapperWithStyleName:[_customStyleName copy] contents:[self.contents logicalCopy]];
    }
    else {
        myCopy = [[self class] styledTextWrapperWithTextType:_textType contents:[self.contents logicalCopy]];
    }

    myCopy.codeRange = self.codeRange;
    return myCopy;
}





#pragma mark - Support for collapsible sections

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    if (_textType == MHStyledTextHeaderStyle)
        return (self.isCollapsed ? NSLocalizedString(@"Expand section", @"") : NSLocalizedString(@"Collapse section", @""));
    if (_textType == MHStyledTextSubheaderStyle)
        return (self.isCollapsed ? NSLocalizedString(@"Expand subsection", @"") : NSLocalizedString(@"Collapse subsection", @""));
    if (_textType == MHStyledTextSubsubheaderStyle)
        return (self.isCollapsed ? NSLocalizedString(@"Expand subsubsection", @"") : NSLocalizedString(@"Collapse subsubsection", @""));
    return nil;
}

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    if ((_textType == MHStyledTextHeaderStyle) ||
        (_textType == MHStyledTextSubheaderStyle) ||
        (_textType == MHStyledTextSubsubheaderStyle) ||
        (_textType == MHStyledTextSuperheaderStyle) ||
        (_textType == MHStyledTextParagraphHeaderStyle)) {
        
        // FIXME: the code below works but isn't very good/modular design - improve it at some point
        // we want the MHTextParagraph expression containing us to handle the mouse click, since that's where I put the logic for handling toggling the expanded/collapsed state and posting a notification
        MHExpression *ancestor = self.parent;
        while (ancestor && ![ancestor isKindOfClass:[MHTextParagraph class]])
            ancestor = ancestor.parent;
        [ancestor mouseClickWithEvent:event subnode:node];

        // If I decide to handle this here, this is the code to use:
//        self.isCollapsed = !(self.isCollapsed);
//        NSNotification *notification = [NSNotification notificationWithName:kMHInteractiveEventOutlinerNodeToggledNotification object:self];
//        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (bool)isCollapsed
{
    return _isCollapsed;
}

- (void)setIsCollapsed:(bool)isCollapsed
{
    _isCollapsed = isCollapsed;
}

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    if (_textType == MHStyledTextHeaderStyle || _textType == MHStyledTextSubheaderStyle || _textType == MHStyledTextSubsubheaderStyle) {
        contextManager.outlinerNestingLevel = (_textType == MHStyledTextHeaderStyle ? 0 : (_textType == MHStyledTextSubheaderStyle ? 1 : 2));
        [contextManager beginOutlinerNode:_isCollapsed];
    }
    
    [super reformatWithContextManager:contextManager animationType:animationType];
}

- (void)setHighlighted:(bool)highlighted
{
    // highlighting is disabled for collapsible section headers, since those have a hand pointer and an auxiliary hover text
    if (_textType == MHStyledTextHeaderStyle || _textType == MHStyledTextSubheaderStyle || _textType == MHStyledTextSubsubheaderStyle)
        return;

    [super setHighlighted:highlighted];
}

- (NSString*) exportedLaTeXValue
{
    NSString *stylingCommandFormattingString = nil;
    switch (_textType) {
        case MHStyledTextNormalStyle:
            stylingCommandFormattingString = @"\\textnormal{%@}";
            break;
        case MHStyledTextBoldStyle:
            stylingCommandFormattingString = @"\\textbf{%@}";
            break;
        case MHStyledTextItalicStyle:
            stylingCommandFormattingString = @"\\textit{%@}";
            break;
        case MHStyledTextUnderlineStyle:
            stylingCommandFormattingString = @"\\underline{%@}";
            break;
        case MHStyledTextHeaderStyle:
            stylingCommandFormattingString = @"\\section*{%@}";
            break;
        case MHStyledTextSubheaderStyle:
            stylingCommandFormattingString = @"\\subsection*{%@}";
            break;
        case MHStyledTextSubsubheaderStyle:
            stylingCommandFormattingString = @"\\subsubsection*{%@}";
            break;
        case MHStyledTextParagraphHeaderStyle:
            stylingCommandFormattingString = @"\\paragraph{%@}";
            break;
        case MHStyledTextSuperheaderStyle:
            stylingCommandFormattingString = @"\\chapter*{%@}";
            break;
        case MHStyledTextStrikethroughStyle:
            stylingCommandFormattingString = @"\\sout{%@}";    // requires ulem package to compile
            break;
        case MHStyledTextHighlightStyle:
            stylingCommandFormattingString = @"\\hl{%@}";  // requires soul package to compile
            break;
        case MHStyledTextCustomStyle:
            stylingCommandFormattingString = @"\\{{%@}}";  // FIXME: not a very useful implementation but at least it gives some indication that the text was in a wrapper - improve
            break;
    }
    
    return [NSString stringWithFormat:stylingCommandFormattingString, self.contents.exportedLaTeXValue];
}



@end
