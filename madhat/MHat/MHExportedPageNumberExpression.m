//
//  MHExportedPageNumberExpression.m
//  MadHat
//
//  Created by Dan Romik on 11/19/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHExportedPageNumberExpression.h"
#import "MHTextNode.h"
#import "MHStyleIncludes.h"


NSString * const kMHExportedPageNumberCommandName = @"⌘exported page number";

NSString * const kMHExportedPageNumberNodeName = @"MHExportedPageNumberNodeName";

@interface MHExportedPageNumberExpression () {
    NSUInteger _exportedPageNumber;
}
@end


@implementation MHExportedPageNumberExpression


+ (instancetype)exportedPageNumberExpression
{
    return [[self alloc] init];
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHExportedPageNumberCommandName]) {
        return [MHExportedPageNumberExpression exportedPageNumberExpression];
    }
    
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHExportedPageNumberCommandName ];
}


#pragma mark - typesetWithContextManager

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    _exportedPageNumber = contextManager.exportedPageNumber;
    
    NSFont *font;
    font = [contextManager textFontForPresentationMode:self.presentationMode nestingLevel:self.nestingLevel];
    
    NSColor *foregroundColor = contextManager.textForegroundColor;
    NSColor *backgroundColor = contextManager.textHighlightColor;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    MHTextNode *pageNumberNode = [MHTextNode textNodeWithString:[NSString stringWithFormat:@"%lu", _exportedPageNumber]];
    pageNumberNode.name = kMHExportedPageNumberNodeName;
    [[mySpriteKitNode childNodeWithName:kMHExportedPageNumberNodeName] removeFromParent];
    [mySpriteKitNode addChild:pageNumberNode];
    
    bool highlightingOn = contextManager.textHighlighting;
    [pageNumberNode configureWithFont:font
                                  color:foregroundColor
                        backgroundColor:(highlightingOn ? backgroundColor : nil)
                            underlining:contextManager.textUnderlining
                          strikethrough:contextManager.textStrikethrough];
    self.dimensions = pageNumberNode.dimensions;
}



#pragma mark - Rendering in graphics contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [[self.spriteKitNode childNodeWithName:kMHExportedPageNumberNodeName] renderInPDFContext:contextManager.pdfContext];
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHExportedPageNumberExpression *myCopy = [[self class] exportedPageNumberExpression];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end
