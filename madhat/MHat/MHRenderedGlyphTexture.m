//
//  MHRenderedGlyphTexture.m
//  MadHat
//
//  Created by Dan Romik on 8/4/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHRenderedGlyphTexture.h"

@interface MHRenderedGlyphTexture ()
{
    SKTexture *_texture;
    CGSize _glyphSize;
    CGPoint _glyphAnchorPoint;
}

@end

@implementation MHRenderedGlyphTexture

+ (instancetype)renderedGlyphTextureWithImage:(NSImage *)image glyphSize:(CGSize)glyphSize glyphAnchorPoint:(CGPoint)glyphAnchorPoint
{
    return [[self alloc] initWithImage:image glyphSize:glyphSize glyphAnchorPoint:glyphAnchorPoint];
}

- (instancetype)initWithImage:(NSImage *)image glyphSize:(CGSize)glyphSize glyphAnchorPoint:(CGPoint)glyphAnchorPoint
{
    if (self = [super init]) {
        _glyphSize = glyphSize;
        _glyphAnchorPoint = glyphAnchorPoint;
        _texture = [SKTexture textureWithImage:image];
    }
    return self;
}


@end
