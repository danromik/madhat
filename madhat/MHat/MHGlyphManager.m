//
//  MHGlyphManager.m
//  MadHat
//
//  Created by Dan Romik on 8/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHGlyphManager.h"
#import "MHRenderedGlyphTexture.h"

static MHGlyphManager *_defaultManager;

const CGFloat kMHGlyphPaddingForTexture = 4.0;                  // how many pixels of padding to add on each side before rendering a texture? Choosing the best value involves a tradeoff - a higher value gives better glyph rendering fidelity, but increases the time and memory requirements for rendering, hurting overall performance

static const CGFloat kMHGlyphTextureScalingFactor = 2.0;        // by what factor shall we scale up the image size?


@interface MHGlyphManager ()
{
    // these two arrays are synced with each other: at any time, the k-th element of one should be thought of as a key to the k-th element of the other
    // (in other words, it is a simple implementation of an ordered dictionary)
    NSMutableArray <NSFont *> *_fontsArray;
    NSMutableArray <NSMutableDictionary <NSNumber *, MHRenderedGlyphTexture *> *> *_textureDictionariesArray;
    
    CGColorRef _whiteColor;     // we'll be using this a lot, might as well cache it to save a couple of unnecessary method calls in each render cycle
}

@end

@implementation MHGlyphManager

+ (instancetype)defaultManager
{
    if (!_defaultManager) {
        _defaultManager = [[MHGlyphManager alloc] init];
    }
    return _defaultManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _whiteColor = [[NSColor whiteColor] CGColor];
        CFRetain(_whiteColor);
        _fontsArray = [[NSMutableArray alloc] initWithCapacity:0];
        _textureDictionariesArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (MHRenderedGlyphTexture *)renderedGlyphTextureForGlyph:(CGGlyph)glyph font:(NSFont *)font
{
    NSMutableDictionary <NSNumber *, MHRenderedGlyphTexture *> *texturesDictionaryForFont;
    MHRenderedGlyphTexture *alreadyRenderedTexture;
    // look for the font in the fonts array
    NSUInteger index = 0;
    for (NSFont *alreadyEncounteredFont in _fontsArray) {
        if ([alreadyEncounteredFont isEqual:font]) {
            texturesDictionaryForFont = _textureDictionariesArray[index];
            NSNumber *glyphNumber = [NSNumber numberWithShort:glyph];
            alreadyRenderedTexture = texturesDictionaryForFont[glyphNumber];
            
            // push the font and the associated textures dictionary to the top of the array to speed up look-up for the next time a texture is looked up (which statistically speaking is quite likely to be with the same font)
            [_fontsArray removeObjectAtIndex:index];
            [_fontsArray insertObject:alreadyEncounteredFont atIndex:0];
            
            [_textureDictionariesArray removeObjectAtIndex:index];
            [_textureDictionariesArray insertObject:texturesDictionaryForFont atIndex:0];
            
            if (alreadyRenderedTexture) {
                // the texture has already been rendered - return it
                return alreadyRenderedTexture;
            }
            break;
        }
        index++;
    }
    
    // If we reached here, the glyph has not been rendered yet, so render it into a texture, and save the texture for future use.
    
    // Get path of glyph
    CGPathRef glyphPath = CTFontCreatePathForGlyph((CTFontRef)font, glyph, NULL);
    
    CGRect glyphBoundingBox = CGPathGetPathBoundingBox(glyphPath);
    CGRect glyphBoundingBoxWithPadding = NSMakeRect(glyphBoundingBox.origin.x - kMHGlyphPaddingForTexture, glyphBoundingBox.origin.y - kMHGlyphPaddingForTexture,
                                                     glyphBoundingBox.size.width + 2.0 * kMHGlyphPaddingForTexture, glyphBoundingBox.size.height + 2.0 * kMHGlyphPaddingForTexture);
    CGSize imageSize = NSMakeSize(ceil(kMHGlyphTextureScalingFactor * glyphBoundingBoxWithPadding.size.width),
                                  ceil(kMHGlyphTextureScalingFactor * glyphBoundingBoxWithPadding.size.height));

    CGSize glyphSize = NSMakeSize(imageSize.width / kMHGlyphTextureScalingFactor, imageSize.height / kMHGlyphTextureScalingFactor);
    CGPoint glyphAnchorPoint = NSMakePoint(-glyphBoundingBox.origin.x/glyphBoundingBoxWithPadding.size.width,
                                           -glyphBoundingBox.origin.y/glyphBoundingBoxWithPadding.size.height);

    
    NSNumber *glyphNumber = [NSNumber numberWithShort:glyph];
    MHRenderedGlyphTexture *texture = texturesDictionaryForFont[glyphNumber];

    NSImage *image = [[NSImage alloc] initWithSize:imageSize];
    [image lockFocus];
    CGContextRef graphicsContextForImage = [NSGraphicsContext currentContext].CGContext;
        
    CGContextScaleCTM(graphicsContextForImage, kMHGlyphTextureScalingFactor, kMHGlyphTextureScalingFactor);
    CGContextTranslateCTM(graphicsContextForImage, kMHGlyphPaddingForTexture - glyphBoundingBox.origin.x,
                          kMHGlyphPaddingForTexture - glyphBoundingBox.origin.y);
    CGContextSetAllowsAntialiasing(graphicsContextForImage, YES);

    // now render the glyph path into the image
    // a bit counterintuitively, it turns out to be best to draw the glyph textures in white. This is because I am using SKSpriteKit's color and colorBlendFactor properties to tint the glyph's texture in the correct color I want the glyph to be drawn in (typically, black), and the nature of the tinting/blending SpriteKit applies is such that it only works in the desired way when the texture is white
    // a related discussion is found here: https://stackoverflow.com/questions/30383315/sprite-color-not-changing-in-swift-ios
    CGContextSetFillColorWithColor(graphicsContextForImage, _whiteColor);
    CGContextAddPath(graphicsContextForImage, glyphPath);
    CGContextFillPath(graphicsContextForImage);
    CGPathRelease(glyphPath);
    
    [image unlockFocus];
    texture = [MHRenderedGlyphTexture renderedGlyphTextureWithImage:image glyphSize:glyphSize glyphAnchorPoint:glyphAnchorPoint];
    
    // if this is the first time processing a glyph for this font, create a new textures dictionary for the font
    if (!texturesDictionaryForFont) {
        texturesDictionaryForFont = [[NSMutableDictionary alloc] initWithCapacity:0];
        [_fontsArray addObject:font];
        [_textureDictionariesArray addObject:texturesDictionaryForFont];
    }
    
    // add the rendered texture to the textures dictionary associated with the font
    texturesDictionaryForFont[glyphNumber] = texture;

    return texture;
}

@end
