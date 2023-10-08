//
//  MHListCommand.m
//  MadHat
//
//  Created by Dan Romik on 8/8/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHListCommand.h"
#import "MHReformattingContextManager.h"
#import "MHStyleIncludes.h"

NSString * const kMHListIncrementLogicalIndentLevelCommandName = @"begin list";
NSString * const kMHListDecrementLogicalUnindentLevelCommandName = @"end list";
NSString * const kMHListUnnumberedListItemCommandName = @"list item";
NSString * const kMHNumberedListItemCommandName = @"num item";
NSString * const kMHCheckboxListItemCommandName = @"checkbox item";
NSString * const kMHListCollapsibleSectionStartMarkerCommandName = @"collapse here";


@interface MHListCommand ()
{
    MHListCommandType _type;
    bool _isCollapsed;
}

@end


@implementation MHListCommand


#pragma mark - Constructors

+ (instancetype)listCommandWithType:(MHListCommandType)type
{
    return [[self alloc] initWithListCommand:type];
}

- (instancetype)initWithListCommand:(MHListCommandType)type
{
    if (self = [super init]) {
        _type = type;
    }
    return self;
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHListIncrementLogicalIndentLevelCommandName]) {
        return [self listCommandWithType:MHListCommandListIndent];
    }
    if ([name isEqualToString:kMHListDecrementLogicalUnindentLevelCommandName]) {
        return [self listCommandWithType:MHListCommandListUnindent];
    }
    if ([name isEqualToString:kMHListUnnumberedListItemCommandName]) {
        return [self listCommandWithType:MHListCommandUnnumberedItem];
    }
    if ([name isEqualToString:kMHNumberedListItemCommandName]) {
        return [self listCommandWithType:MHListCommandNumberedItem];
    }
    if ([name isEqualToString:kMHListCollapsibleSectionStartMarkerCommandName]) {
        return [self listCommandWithType:MHListCommandCollapsibleSectionStartMarker];
    }
    if ([name isEqualToString:kMHCheckboxListItemCommandName]) {
        return [self listCommandWithType:MHListCommandCheckboxItem];
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHListIncrementLogicalIndentLevelCommandName,
        kMHListDecrementLogicalUnindentLevelCommandName,
        kMHListUnnumberedListItemCommandName,
        kMHNumberedListItemCommandName,
        kMHCheckboxListItemCommandName,
        kMHListCollapsibleSectionStartMarkerCommandName
    ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    MHDimensions myDimensions;
    switch (_type) {
        case MHListCommandListIndent:
            [contextManager incrementLogicalIndentLevel];
            break;
        case MHListCommandListUnindent:
            [contextManager decrementLogicalIndentLevel];
            break;
        case MHListCommandUnnumberedItem:
            [contextManager setListItemType:MHListItemUnnumbered];
            [contextManager setOutlinerItemStartMarker:self];
            break;
        case MHListCommandNumberedItem:
            [contextManager setListItemType:MHListItemNumbered];
            [contextManager setOutlinerItemStartMarker:self];
            break;
        case MHListCommandCheckboxItem:
            [contextManager setListItemType:MHListItemCheckbox];
            break;
        case MHListCommandCollapsibleSectionStartMarker:
            [contextManager setCollapsibleSectionStartMarker:self];
            break;
    }
    
    // for a list item command, we give it a height and depth equal to the current font's ascender and descender lengths, to make sure the line containing the item marker will be formatted properly (mainly in case the line is empty or has only white space)
    bool commandIsListItem = (_type == MHListCommandUnnumberedItem || _type == MHListCommandNumberedItem
                              || _type == MHListCommandCheckboxItem);
    if (commandIsListItem) {
        NSFont *font = [contextManager textFontForPresentationMode:self.presentationMode nestingLevel:self.nestingLevel];
        myDimensions.height = font.ascender;
        myDimensions.depth = -font.descender;
        myDimensions.width = 0.0;
        self.dimensions = myDimensions;
    }
}

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    [super reformatWithContextManager:contextManager animationType:animationType];
    
    switch (_type) {
        case MHListCommandListIndent:
            [contextManager incrementOutlinerNestingLevel];
            break;
        case MHListCommandListUnindent:
            [contextManager decrementOutlinerNestingLevel];
            break;
        case MHListCommandUnnumberedItem:
        case MHListCommandNumberedItem:
        case MHListCommandCheckboxItem:
            [contextManager beginOutlinerNode:_isCollapsed];
            break;
        case MHListCommandCollapsibleSectionStartMarker:
            [contextManager markBeginningOfMainPartOfCurrentNode];
            break;
    }
}


#pragma mark - Properties

- (MHListCommandType)type
{
    return _type;
}


#pragma mark - MHOutlinerItemMarker protocol

- (bool)isCollapsed
{
    return _isCollapsed;
}

- (void)setIsCollapsed:(bool)isCollapsed
{
    _isCollapsed = isCollapsed;
}

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    return _isCollapsed ? NSLocalizedString(@"Expand outliner item", @"") : NSLocalizedString(@"Collapse outliner item", @"");
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHListCommand *myCopy = [[self class] listCommandWithType:_type];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



- (NSString *)exportedLaTeXValue
{
    switch (_type) {
        case MHListCommandListIndent:
            return @"\\begin{itemize}";
        case MHListCommandListUnindent:
            return @"\\end{itemize}";
        case MHListCommandNumberedItem:
        case MHListCommandUnnumberedItem:
            return @"\\item ";
        default:
            break;
    }
    return super.exportedLaTeXValue;
}

@end
