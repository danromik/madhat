//
//  MHGlyphManager.h
//  MadHat
//
//  Created by Dan Romik on 8/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import "MHRenderedGlyphTexture.h"

extern const CGFloat kMHGlyphPaddingForTexture;

NS_ASSUME_NONNULL_BEGIN

@interface MHGlyphManager : NSObject

+ (instancetype)defaultManager;     // a singleton object that can be accessed by all users of the class

- (MHRenderedGlyphTexture *)renderedGlyphTextureForGlyph:(CGGlyph)glyph font:(NSFont *)font;

@end

NS_ASSUME_NONNULL_END
