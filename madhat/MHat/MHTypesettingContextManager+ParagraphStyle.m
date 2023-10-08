//
//  MHTypesettingContextManager+ParagraphStyle.m
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTypesettingContextManager+ParagraphStyle.h"
#import "MHStyleIncludes.h"


#import <AppKit/AppKit.h>


@implementation MHTypesettingContextManager (ParagraphStyle)


- (MHParagraphType)paragraphType
{
    return [_currentParagraphStyle paragraphType];
}

- (void)setParagraphType:(MHParagraphType)type
{
    [_currentParagraphStyle setParagraphType:type];
}

- (BOOL)paragraphHasIndentSuppressed
{
    return _currentParagraphStyle.paragraphHasIndentSuppressed;
}

- (void)setParagraphHasIndentSuppressed:(BOOL)newValue
{
    _currentParagraphStyle.paragraphHasIndentSuppressed = newValue;
}

- (BOOL)paragraphForcedAsNewParagraph
{
    return _currentParagraphStyle.paragraphForcedAsNewParagraph;
}

- (void)setParagraphForcedAsNewParagraph:(BOOL)newValue
{
    _currentParagraphStyle.paragraphForcedAsNewParagraph = newValue;
}

- (void)setParagraphBoxType:(MHParagraphBoxType)type
{
    [_currentParagraphStyle setParagraphBoxType:type];
}

- (void)beginBox
{
    [self setParagraphBoxType:MHParagraphBoxTypeBoxHeader];
    [self setParagraphType:MHParagraphBeginBox];
}

- (void)endBox
{
    [self setParagraphBoxType:MHParagraphBoxTypeBoxFooter];
    [self setParagraphType:MHParagraphEndBox];
}

- (void)markBoxDivider
{
    [self setParagraphBoxType:MHParagraphBoxTypeBoxDivider];
    [self setParagraphType:MHParagraphBoxDivider];
}

- (MHParagraphBoxType)readAndResetParagraphBoxType
{
    return [_currentParagraphStyle readAndResetParagraphBoxType];
}

- (CGFloat)absoluteLineSpacingForPresentationMode:(MHExpressionPresentationMode)mode
{
    NSFont *theFont = [self textFontForPresentationMode:mode nestingLevel:0];
    return (self.lineSpacing - 1.0) * (theFont.ascender - theFont.descender + theFont.leading);
}

- (CGFloat)absoluteLineHeightForPresentationMode:(MHExpressionPresentationMode)mode
{
    NSFont *theFont = [self textFontForPresentationMode:mode nestingLevel:0];
    return theFont.ascender - theFont.descender + theFont.leading;
}

- (nullable NSColor *)paragraphBackgroundColor
{
    return _currentParagraphStyle.paragraphBackgroundColor;
}

- (void)setParagraphBackgroundColor:(NSColor *)paragraphBackgroundColor
{
    _currentParagraphStyle.paragraphBackgroundColor = paragraphBackgroundColor;
}

- (nullable NSColor *)paragraphFrameColor
{
    return _currentParagraphStyle.paragraphFrameColor;
}

- (void)setParagraphFrameColor:(NSColor *)paragraphFrameColor
{
    _currentParagraphStyle.paragraphFrameColor = paragraphFrameColor;
}

- (CGFloat)paragraphFrameThickness
{
    return _currentParagraphStyle.paragraphFrameThickness;
}

- (void)setParagraphFrameThickness:(CGFloat)paragraphFrameThickness
{
    _currentParagraphStyle.paragraphFrameThickness = paragraphFrameThickness;
}



@end
