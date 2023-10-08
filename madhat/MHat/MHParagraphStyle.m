//
//  MHParagraphStyle.m
//  MadHat
//
//  Created by Dan Romik on 2/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHParagraphStyle.h"

@interface MHParagraphStyle ()
{
    MHParagraphType _paragraphType;
    MHParagraphBoxType _paragraphBoxType;
    NSColor *_paragraphBackgroundColor;
    NSColor *_paragraphFrameColor;
    CGFloat _paragraphFrameThickness;
}


@end

@implementation MHParagraphStyle


#pragma mark - Constructor methods

+ (instancetype)defaultStyle
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        _paragraphType = MHParagraphNone;
        _paragraphBoxType = MHParagraphBoxTypeNoBox;
        _paragraphFrameThickness = 1.0;
        
        _paragraphFrameColor = [NSColor blackColor];
    }
    return self;
}


// This constructor is used by the copy method. Not safe to use directly.
- (instancetype)initWithParagraphType:(MHParagraphType)paragraphType
                     paragraphBoxType:(MHParagraphBoxType)paragraphBoxType
                      backgroundColor:(nullable NSColor *)paragraphBackgroundColor
                           frameColor:(nullable NSColor *)paragraphFrameColor
                       frameThickness:(CGFloat)frameThickness
{
    if (self = [self init]) {
        _paragraphType = paragraphType;
        _paragraphBoxType = paragraphBoxType;
        _paragraphBackgroundColor = paragraphBackgroundColor;
        _paragraphFrameColor = paragraphFrameColor;
        _paragraphFrameThickness = frameThickness;
    }
    return self;
}


#pragma mark - Properties

// Used by the isEqual: method. Not safe to use for any other purpose
- (MHParagraphType)unsafeParagraphType
{
    return _paragraphType;
}

- (void)setParagraphType:(MHParagraphType)paragraphType
{
    _paragraphType = paragraphType;
}
- (MHParagraphType)paragraphType
{
    return _paragraphType;
}

- (BOOL)paragraphHasIndentSuppressed
{
    return ((self.paragraphType & MHParagraphSuppressParagraphIndentBitMask) != 0);
}

- (void)setParagraphHasIndentSuppressed:(BOOL)newValue
{
    MHParagraphType parType = self.paragraphType;
    self.paragraphType = (newValue ? (parType|MHParagraphSuppressParagraphIndentBitMask) : (parType&MHParagraphDoNotSuppressParagraphIndentBitMask));
}

- (BOOL)paragraphForcedAsNewParagraph
{
    return ((self.paragraphType & MHParagraphForceNewParagraphBitMask) != 0);
}

- (void)setParagraphForcedAsNewParagraph:(BOOL)newValue
{
    MHParagraphType parType = self.paragraphType;
    self.paragraphType = (newValue ? (parType|MHParagraphForceNewParagraphBitMask) : (parType&MHParagraphDoNotForceNewParagraphBitMask));
}

// Used by the isEqual: method. Not safe to use for any other purpose
- (MHParagraphBoxType)unsafeParagraphBoxType
{
    return _paragraphBoxType;
}

- (void)setParagraphBoxType:(MHParagraphBoxType)paragraphBoxType
{
    _paragraphBoxType = paragraphBoxType;
}

- (MHParagraphBoxType)readAndResetParagraphBoxType
{
    MHParagraphBoxType boxType = _paragraphBoxType;
    switch (boxType) {
        case MHParagraphBoxTypeNoBox:
        case MHParagraphBoxTypeBoxBody:
            break;
        case MHParagraphBoxTypeBoxHeader:
        case MHParagraphBoxTypeBoxDivider:
            _paragraphBoxType = MHParagraphBoxTypeBoxBody;
            break;
        case MHParagraphBoxTypeBoxFooter:
            _paragraphBoxType = MHParagraphBoxTypeNoBox;
            break;
    }
    return boxType;
}

- (NSColor *)paragraphBackgroundColor
{
    return _paragraphBackgroundColor;
}

- (void)setParagraphBackgroundColor:(NSColor *)newColor
{
    _paragraphBackgroundColor = newColor;
}

- (NSColor *)paragraphFrameColor
{
    return _paragraphFrameColor;
}

- (void)setParagraphFrameColor:(NSColor *)newColor
{
    _paragraphFrameColor = newColor;
}

- (CGFloat)paragraphFrameThickness
{
    return _paragraphFrameThickness;
}

- (void)setParagraphFrameThickness:(CGFloat)paragraphFrameThickness
{
    _paragraphFrameThickness = paragraphFrameThickness;
}



# pragma mark - NSCopying protocol

- (instancetype)copyWithZone:(NSZone *)zone
{
return [[[self class] alloc] initWithParagraphType:_paragraphType
                                  paragraphBoxType:_paragraphBoxType
                                   backgroundColor:_paragraphBackgroundColor
                                        frameColor:_paragraphFrameColor
                                    frameThickness:_paragraphFrameThickness];
}


- (BOOL)isEqual:(id)object
{
    if (![object isMemberOfClass:[self class]])
        return NO;

    MHParagraphStyle *otherParagraphStyle = object;

    NSColor *otherParagraphStyleBackgroundColor;
    NSColor *otherParagraphStyleFrameColor;

    return (otherParagraphStyle.unsafeParagraphType == _paragraphType)
    && (otherParagraphStyle.unsafeParagraphBoxType == _paragraphBoxType)
    && ([(otherParagraphStyleBackgroundColor = otherParagraphStyle.paragraphBackgroundColor) isEqual:_paragraphBackgroundColor]
        || (!otherParagraphStyleBackgroundColor && !_paragraphBackgroundColor))
    && ([(otherParagraphStyleFrameColor = otherParagraphStyle.paragraphFrameColor) isEqual:_paragraphFrameColor]
        || (!otherParagraphStyleFrameColor && !_paragraphFrameColor))
    && (otherParagraphStyle.paragraphFrameThickness == _paragraphFrameThickness);
}





@end
