//
//  MHListStyle.h
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "MHStyle.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    MHListItemNone = 0,
    MHListItemUnnumbered,
    MHListItemNumbered,
    MHListItemCheckbox,
} MHListItemType;


@class MHExpression;

@interface MHListStyle : MHStyle


@property (readonly) NSUInteger logicalIndentLevel;

- (void)incrementLogicalIndentLevel;
- (void)decrementLogicalIndentLevel;

- (void)setListItemType:(MHListItemType)listItemType;
- (MHListItemType)readAndResetListItemType;   // returns the current list item marker status and sets it to off

// FIXME: it's problematic to use attributed strings for the markers since the font, color information etc might be inconsistent with the general typing style. I fixed this by including the foreground color and font size in the method call, but this is an awkward and probably not the most robust solution. Improve
- (MHExpression *)unnumberedListItemMarkerExpressionWithForegroundColor:(NSColor *)foregroundColor fontSize:(CGFloat)fontSize;
- (MHExpression *)numberedListItemMarkerExpression;
- (MHExpression *)listItemMarkerExpressionForType:(MHListItemType)type
                                  foregroundColor:(NSColor *)foregroundColor
                                         fontSize:(CGFloat)fontSize;



@end

NS_ASSUME_NONNULL_END
