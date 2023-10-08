//
//  MHTypesettingContextManager+ParagraphStyle.h
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHTypesettingContextManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTypesettingContextManager (ParagraphStyle)

@property MHParagraphType paragraphType;
@property BOOL paragraphHasIndentSuppressed;
@property BOOL paragraphForcedAsNewParagraph;

- (MHParagraphBoxType)readAndResetParagraphBoxType;
- (void)beginBox;
- (void)endBox;
- (void)markBoxDivider;

- (CGFloat)absoluteLineSpacingForPresentationMode:(MHExpressionPresentationMode)mode;
- (CGFloat)absoluteLineHeightForPresentationMode:(MHExpressionPresentationMode)mode;

@property (nullable) NSColor *paragraphBackgroundColor;
@property (nullable) NSColor *paragraphFrameColor;
@property CGFloat paragraphFrameThickness;



@end

NS_ASSUME_NONNULL_END
