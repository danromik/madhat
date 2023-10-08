//
//  MHRenderedGlyphTexture.h
//  MadHat
//
//  Created by Dan Romik on 8/4/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  a container for a SKTexture that stores a bit of additional useful information relevant to rendered glyphs
//  (This would make more sense as a subclass of SKTexture rather than a container, but I couldn't make that work because the +textureWithImage: constructor method of SKTexture returns an SKTexture object even if it is called on a subclass. Looks like a bug, the documentation says this method should return an instancetype type.)
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHRenderedGlyphTexture : NSObject

@property (readonly) SKTexture *texture;
@property (readonly) CGSize glyphSize;
@property (readonly) CGPoint glyphAnchorPoint;

+ (instancetype)renderedGlyphTextureWithImage:(NSImage *)image glyphSize:(CGSize)glyphSize glyphAnchorPoint:(CGPoint)glyphAnchorPoint;

@end

NS_ASSUME_NONNULL_END
