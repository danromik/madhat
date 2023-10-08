//
//  MHTypesettingContextManager+ListStyle.m
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTypesettingContextManager+ListStyle.h"
#import "MHStyleIncludes.h"

#import <AppKit/AppKit.h>


@implementation MHTypesettingContextManager (ListStyle)



- (NSUInteger)logicalIndentLevel
{
    return _currentListStyle.logicalIndentLevel;
}

- (void)incrementLogicalIndentLevel
{
    [_currentListStyle incrementLogicalIndentLevel];
}

- (void)decrementLogicalIndentLevel
{
    [_currentListStyle decrementLogicalIndentLevel];
}

- (void)setListItemType:(MHListItemType)listItemType
{
    [_currentListStyle setListItemType:listItemType];
    if (listItemType != MHListItemNone) {
        [self setParagraphType:MHParagraphListItem];
    }
}

- (MHListItemType)readAndResetListItemType
{
    return [_currentListStyle readAndResetListItemType];
}


- (MHExpression *)listItemMarkerExpressionForType:(MHListItemType)type
{
    return [_currentListStyle listItemMarkerExpressionForType:type
                                              foregroundColor:self.textForegroundColor
                                                     fontSize:self.baseFontSize];
}


@end
