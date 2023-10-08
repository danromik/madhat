//
//  MHCheckboxExpression.m
//  MadHat
//
//  Created by Dan Romik on 11/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCheckboxExpression.h"
#import "MHCheckboxNode.h"
#import "MHTypesettingContextManager.h"
#import "MHStyleIncludes.h"

NSString * const kMHCheckboxCommandName = @"checkbox";

@interface MHCheckboxExpression ()
{
    bool _checked;
}

@end

@implementation MHCheckboxExpression

#pragma mark - Constructors

+ (instancetype)checkboxExpression:(bool)checked
{
    return [[self alloc] initChecked:checked];
}

- (instancetype)initChecked:(bool)checked
{
    if (self = [super init]) {
        _checked = checked;
    }
    return self;
}

#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHCheckboxCommandName]) {
        bool checked = [argument boolValue];
        return [self checkboxExpression:checked];
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHCheckboxCommandName ];
}



#pragma mark Typesetting and spriteKitNode

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [MHCheckboxNode checkboxNode:_checked];
        _spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
        _spriteKitNode.ownerExpression = self;
    }
    return _spriteKitNode;
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSFont *font = [contextManager textFontForPresentationMode:self.presentationMode nestingLevel:self.nestingLevel];
        
    bool highlightingOn = contextManager.textHighlighting;
    MHCheckboxNode *mySpriteKitNode = (MHCheckboxNode *)(self.spriteKitNode);
    [mySpriteKitNode configureWithFont:font
                                 color:contextManager.textForegroundColor
                       backgroundColor:(highlightingOn ? contextManager.textHighlightColor : nil)
                           underlining:contextManager.textUnderlining
                         strikethrough:contextManager.textStrikethrough];
    self.dimensions = mySpriteKitNode.dimensions;
}


#pragma mark - Mouse clicks

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    [self toggle];
}

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    return NSLocalizedString(@"Toggle checkbox", @"");
}


#pragma mark - Properties

- (bool)checked
{
    return _checked;
}

- (void)setChecked:(bool)checked
{
    _checked = checked;
    ((MHCheckboxNode *)_spriteKitNode).checked = _checked;
}

- (void)toggle
{
    self.checked = !self.checked;
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHCheckboxExpression *myCopy = [[self class] checkboxExpression:_checked];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


@end
