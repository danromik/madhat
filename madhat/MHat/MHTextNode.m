//
//  MHTextNode.m
//  MadHat
//
//  Created by Dan Romik on 7/31/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MHTextNode.h"
#import "MHGlyphManager.h"

NSString * const kMHTextNodeGlyphNode = @"MHTextNodeGlyphNode";


@interface MHTextNode ()
{
    NSString *_text;
    
    NSFont *_font; // FIXME: I don't want each text node to have to remember its font but need this for PDF rendering. Is there any way to avoid this?
}

@end



@implementation MHTextNode


+ (instancetype)textNodeWithString:(NSString *)string
{
    return [[[self class] alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string
{
    if (self = [super init]) {
        _text = string;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] textNodeWithString:[self.text copy]];
}



- (void)configureWithFont:(NSFont *)font
                    color:(NSColor *)color
          backgroundColor:(nullable NSColor *)backgroundColor
              underlining:(bool)underlining
            strikethrough:(bool)strikethrough
{
    _font = font;  // FIXME: not good

    [self removeChildrenInArray:[self objectForKeyedSubscript:kMHTextNodeGlyphNode]];
    
    // render the string in the specified font as a bezier path
    
    NSDictionary *attrs =  [NSDictionary dictionaryWithObjectsAndKeys: font, kCTFontAttributeName, nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:_text attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    
    CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
    _dimensions.width = 0.0;
    _dimensions.depth = -font.descender;
    _dimensions.height = font.ascender;
    for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
        // get Glyph & Glyph-data
        CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
        CGGlyph glyph;
        CGPoint position;
        CGSize advance;
        CTRunGetGlyphs(run, thisGlyphRange, &glyph);
        CTRunGetPositions(run, thisGlyphRange, &position);
        CTRunGetAdvances(run, thisGlyphRange, &advance);
        
        _dimensions.width += advance.width;
        
        MHRenderedGlyphTexture *renderedGlyphTexture = [[MHGlyphManager defaultManager] renderedGlyphTextureForGlyph:glyph font:font];
        
        SKSpriteNode *renderedGlyphNode = [SKSpriteNode spriteNodeWithTexture:renderedGlyphTexture.texture];
        renderedGlyphNode.position = NSMakePoint(-kMHGlyphPaddingForTexture + position.x,-kMHGlyphPaddingForTexture + position.y);
        renderedGlyphNode.size = renderedGlyphTexture.glyphSize;
        renderedGlyphNode.anchorPoint = renderedGlyphTexture.glyphAnchorPoint;
        renderedGlyphNode.name = kMHTextNodeGlyphNode;
        
        [self addChild:renderedGlyphNode];
        renderedGlyphNode.color = color;
        renderedGlyphNode.colorBlendFactor = 1.0;
    }
    
    CFRelease(line);
        
    [super configureWithFont:font
                       color:color
             backgroundColor:backgroundColor
                 underlining:underlining
               strikethrough:strikethrough];
    

}




- (void)renderInPDFContext:(CGContextRef)pdfContext
{
    // call the super method to get correct behavior for underlining, strikethrough, and highlighting
    [super renderInPDFContext:pdfContext];

    CGContextSaveGState(pdfContext);

    // Write the glyphs into the PDF context
    
    // Set the correct color by looking up the color of one of the glyph nodes (I assume all of them have the same color, so it doesn't matter which one we get)
    SKSpriteNode *glyphNode = (SKSpriteNode *)[self childNodeWithName:kMHTextNodeGlyphNode];
    if (glyphNode) {
        NSColor *glyphColor = glyphNode.color;
        CGContextSetFillColorWithColor(pdfContext, [glyphColor CGColor]);
    }
    
    // Now iterate over the glyphs using CoreText
    CTFontRef ctFont = (__bridge CTFontRef)_font;
    CGFontRef cgFont = CTFontCopyGraphicsFont(ctFont, NULL);
    CGContextSetFont(pdfContext, cgFont);
    CGFontRelease(cgFont);
    CGContextSetFontSize(pdfContext, CTFontGetSize(ctFont));
    
    // FIXME: with the code snippet below I'm writing the glyphs into the document one at a time. There's probably a quicker/simpler approach that writes the entire string in one go
    NSDictionary *attrs =  [NSDictionary dictionaryWithObjectsAndKeys: _font, kCTFontAttributeName, nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:_text attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
    CFArrayRef runArray = CTLineGetGlyphRuns(line);

    CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
    for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
        // get glyph & glyph data
        CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
        CGGlyph glyph;
        CGPoint position;
        CGSize advance;
        CTRunGetGlyphs(run, thisGlyphRange, &glyph);
        CTRunGetPositions(run, thisGlyphRange, &position);
        CTRunGetAdvances(run, thisGlyphRange, &advance);
        
        // Write the glyph
        CGContextShowGlyphsAtPositions(pdfContext, &glyph, &position, 1);
    }
    CFRelease(line);
    CGContextRestoreGState(pdfContext);
}

- (NSArray <SKShapeNode *> *)createTextNodesForIndividualGlyphs
{
    // FIXME: this seems to work but could break at any time as it is based on lots of assumptions that are not guaranteed to hold - improve
    NSArray <SKShapeNode *> *glyphNodes = (NSArray <SKShapeNode *> *)[self objectForKeyedSubscript:kMHTextNodeGlyphNode];
    [self removeChildrenInArray:glyphNodes];
    return glyphNodes;
}


@end
