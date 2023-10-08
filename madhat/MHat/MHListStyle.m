//
//  MHListStyle.m
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHListStyle.h"
#import "MHTextAtom.h"
#import "MHRichTextAtom.h"
#import "MHFormattingCommand.h"
#import "MHCheckboxExpression.h"

#import <AppKit/AppKit.h>

@interface MHListStyle ()
{
    NSUInteger _logicalIndentLevel;
    MHListItemType _listItemType;
    NSMutableArray <NSNumber *> *_listItemNumberingStack;
    NSUInteger _listItemNumberAtCurrentLevel;
}

@end



@implementation MHListStyle


#pragma mark - Constructor

+ (instancetype)defaultStyle
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        _logicalIndentLevel = 0;
        _listItemNumberingStack = [NSMutableArray arrayWithCapacity:0];
        _listItemNumberAtCurrentLevel = 0;
        _listItemType = MHListItemNone;
    }
    return self;
}


// This constructor is used by the copy method. Not safe to use directly.
- (instancetype)initWithLogicalIndentLevel:(NSUInteger)logicalIndentLevel
                              listItemType:(MHListItemType)listItemType
                    listItemNumberingStack:(NSArray <NSNumber *> *)listItemNumberingStack
              listItemNumberAtCurrentLevel:(NSUInteger)listItemNumberAtCurrentLevel
{
    if (self = [self init]) {
        _logicalIndentLevel = logicalIndentLevel;
        _listItemType = listItemType;
        _listItemNumberAtCurrentLevel = listItemNumberAtCurrentLevel;
        _listItemNumberingStack = [listItemNumberingStack mutableCopy];
    }
    return self;
}







#pragma mark - Managing the style properties

- (NSUInteger)logicalIndentLevel
{
    return _logicalIndentLevel;
}


- (void)incrementLogicalIndentLevel
{
    if (_logicalIndentLevel > 0)
        [_listItemNumberingStack addObject:[NSNumber numberWithShort:_listItemNumberAtCurrentLevel]];
    _logicalIndentLevel++;
    _listItemNumberAtCurrentLevel = 0;
}

- (void)decrementLogicalIndentLevel
{
    if (_logicalIndentLevel > 0) {
        _logicalIndentLevel--;
        NSNumber *itemNumber = [_listItemNumberingStack lastObject];
        _listItemNumberAtCurrentLevel = itemNumber.shortValue;
        [_listItemNumberingStack removeLastObject];
    }
}


// Used by the isEqual: method. Not safe to use for any other purpose
- (MHListItemType)unsafeListItemType
{
    return _listItemType;
}

- (void)setListItemType:(MHListItemType)listItemType
{
    if (_listItemType == MHListItemNone && listItemType != MHListItemNone) {
        _listItemNumberAtCurrentLevel++;
    }
    _listItemType = listItemType;
}

- (NSUInteger)listItemNumberAtCurrentLevel
{
    return _listItemNumberAtCurrentLevel;
}

// Used by the isEqual: method. Not safe to use for any other purpose
- (NSMutableArray <NSNumber *> *)unsafeListItemNumberingStack
{
    return _listItemNumberingStack;
}


- (MHListItemType)readAndResetListItemType
{
    MHListItemType currentType = _listItemType;
    _listItemType = MHListItemNone;
    return currentType;
}

- (MHExpression *)unnumberedListItemMarkerExpressionWithForegroundColor:(NSColor *)foregroundColor fontSize:(CGFloat)fontSize
{
    NSString *markerString;
    switch (_logicalIndentLevel) {
        case 0:
            markerString = @"◆";
            break;
        case 1:
            markerString = @"•";
            break;
        case 2:
            markerString = @"○";
            break;
        case 3:
            markerString = @"▪";
            break;
        default:
            markerString = @"→";
            break;
    }
    
    // FIXME: the commented out code below caused a crash when using the outliner after fixing the memory leak bug. Replaced it with a modified version
//    // Now prepare a container to format the string in a font that has the relevant symbol. For now, I'm using Lucida Grande
//    // FIXME: this works but needs improvement
//    MHHorizontalLayoutContainer *container = [MHHorizontalLayoutContainer expression];
//    MHFormattingCommand *fontCommand = [MHFormattingCommand fontFormattingCommandWithType:MHFormattingCommandFont
//                                                                                 fontName:@"Lucida Grande"];
//    [container addSubexpression:fontCommand];
//    MHTextAtom *textAtom = [MHTextAtom textAtomWithString:markerString];
//    [container addSubexpression:textAtom];
//
//    // FIXME: this is to address a flaw in my system for adding marker items where the MHTextParagraph instance takes the spritekitnode of the returned marker item expression and adds it as a child to its spritekit node, overriding the usual mechanisms for propagating the presentation mode through the expression hierarchy - find a way to make this unnecessary
//    container.presentationMode = MHExpressionPresentationModePublishing;
//
//    return container;
    

    // FIXME: this version avoids crashing after fixing the memory leak bug by returning an MHRichTextAtom instead of a container expression, but isn't as good of a solution as the code above since the font size and foreground/background colors are fixed. It would be better to go back to using a container expression but figure out why the crashing occurs and fixing it.
    NSFont *markerFont = [NSFont fontWithName:@"Lucida Grande" size:fontSize];
    NSDictionary *attributes = @{ NSFontAttributeName : markerFont,
//                                  NSBackgroundColorAttributeName : [NSColor redColor],
                                  NSForegroundColorAttributeName : foregroundColor
    };
    NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:markerString attributes:attributes];
    MHExpression *richTextAtom = [MHRichTextAtom richTextAtomWithAttributedString:attribString];
    return richTextAtom;
}

- (MHExpression *)numberedListItemMarkerExpression
{
    NSMutableString *mutableString = [[NSMutableString alloc] initWithCapacity:0];
    for (NSNumber *itemNumber in _listItemNumberingStack) {
        NSUInteger numberValue = itemNumber.shortValue;
        [mutableString appendFormat:@"%lu.", numberValue];
    }
    [mutableString appendFormat:@"%lu.", _listItemNumberAtCurrentLevel];
    
    MHTextAtom *textAtom = [MHTextAtom textAtomWithString:[NSString stringWithString:mutableString]];
    return textAtom;
}

- (MHExpression *)checkboxListItemMarkerExpression
{
    return [MHCheckboxExpression checkboxExpression:false];
}

- (MHExpression *)listItemMarkerExpressionForType:(MHListItemType)type
                                  foregroundColor:(NSColor *)foregroundColor
                                         fontSize:(CGFloat)fontSize
{
    switch (type) {
        case MHListItemNumbered:
            return [self numberedListItemMarkerExpression];
        case MHListItemUnnumbered:
            return [self unnumberedListItemMarkerExpressionWithForegroundColor:foregroundColor fontSize:fontSize];
        case MHListItemCheckbox: {
            return [self checkboxListItemMarkerExpression];
        }
        default:
            return [MHTextAtom textAtomWithString:@"?"];
    }
}


#pragma mark - Copying and comparisons

- (instancetype)copyWithZone:(NSZone *)zone
{
        return [[[self class] alloc] initWithLogicalIndentLevel:_logicalIndentLevel
                                                   listItemType:_listItemType
                                         listItemNumberingStack:_listItemNumberingStack
                                   listItemNumberAtCurrentLevel:_listItemNumberAtCurrentLevel];
}

- (BOOL)isEqual:(id)object
{

    if (![object isMemberOfClass:[self class]])
        return NO;

    MHListStyle *otherListStyle = object;

    return (otherListStyle.logicalIndentLevel == self.logicalIndentLevel)
    && ([otherListStyle unsafeListItemType] == _listItemType)
    && (otherListStyle.listItemNumberAtCurrentLevel == _listItemNumberAtCurrentLevel)
    && ([[otherListStyle unsafeListItemNumberingStack] isEqual:_listItemNumberingStack]);
}




@end
