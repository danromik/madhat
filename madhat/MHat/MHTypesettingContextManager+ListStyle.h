//
//  MHTypesettingContextManager+ListStyle.h
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHTypesettingContextManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTypesettingContextManager (ListStyle)


@property (readonly) NSUInteger logicalIndentLevel;
- (void)incrementLogicalIndentLevel;
- (void)decrementLogicalIndentLevel;

- (void)setListItemType:(MHListItemType)listItemType;
- (MHListItemType)readAndResetListItemType;   // returns the current list item marker status and sets it to off

- (MHExpression *)listItemMarkerExpressionForType:(MHListItemType)type;


@end

NS_ASSUME_NONNULL_END
