//
//  MHGlyphNode.m
//  MadHat
//
//  Created by Dan Romik on 8/3/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHGlyphNode.h"
#import "MHGlyphManager.h"


NSString * const kMHGlyphNodeGlyphNode = @"MHGlyphNodeGlyphNode";

NSString * const kMHOldGlyphNodeGlyphNameForUnknown = @"question";


@interface MHGlyphNode ()
{
    NSString *_glyphName;
    
    NSFont *_font; // FIXME: I don't want each glyph node to have to remember its font but need this for PDF rendering. Is there any way to avoid this?
}


@end

@implementation MHGlyphNode

+ (instancetype)glyphNodeWithGlyphName:(NSString *)glyphName
{
    return [[[self class] alloc] initWithGlyphName:glyphName];
}

- (instancetype)initWithGlyphName:(NSString *)glyphName
{
    if (self = [super init]) {
        _glyphName = glyphName;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] glyphNodeWithGlyphName:[self.glyphName copy]];
}


- (void)configureWithFont:(NSFont *)font
                    color:(NSColor *)color
          backgroundColor:(nullable NSColor *)backgroundColor
              underlining:(bool)underlining
            strikethrough:(bool)strikethrough
{
    _font = font;  // FIXME: not good

    // render the string in the specified font as a bezier path
    
    [self removeChildrenInArray:[self objectForKeyedSubscript:kMHGlyphNodeGlyphNode]];
    
    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)font, nil);
    CGGlyph glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)_glyphName);
    if (!glyph) {
        glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)kMHOldGlyphNodeGlyphNameForUnknown);
    }

    CGRect glyphBBox;
    CGRect glyphBBoxInPoints;
    int glyphAdvance;
    CGFloat glyphAdvanceInPoints;
    CGFontGetGlyphBBoxes(cgFont, &glyph, 1, &glyphBBox);
    CGFontGetGlyphAdvances(cgFont, &glyph, 1, &glyphAdvance);
    CGFloat emWidth = font.pointSize;
    int unitsPerEm = CGFontGetUnitsPerEm(cgFont);
    glyphBBoxInPoints.origin.x = glyphBBox.origin.x/unitsPerEm * emWidth;
    glyphBBoxInPoints.origin.y = glyphBBox.origin.y/unitsPerEm * emWidth;
    glyphBBoxInPoints.size.width = glyphBBox.size.width/unitsPerEm * emWidth;
    glyphBBoxInPoints.size.height = glyphBBox.size.height/unitsPerEm * emWidth;
    glyphAdvanceInPoints = ((float)glyphAdvance)/unitsPerEm * emWidth;
    
    _dimensions.width = glyphAdvanceInPoints;
    _dimensions.depth = -glyphBBoxInPoints.origin.y;
    _dimensions.height = glyphBBoxInPoints.origin.y + glyphBBoxInPoints.size.height;
        
    MHRenderedGlyphTexture *renderedGlyphTexture = [[MHGlyphManager defaultManager] renderedGlyphTextureForGlyph:glyph font:font];
    
    SKSpriteNode *renderedGlyphNode = [SKSpriteNode spriteNodeWithTexture:renderedGlyphTexture.texture];
    renderedGlyphNode.position = NSMakePoint(-kMHGlyphPaddingForTexture, -kMHGlyphPaddingForTexture);
    renderedGlyphNode.size = renderedGlyphTexture.glyphSize;
    renderedGlyphNode.anchorPoint = renderedGlyphTexture.glyphAnchorPoint;
    renderedGlyphNode.name = kMHGlyphNodeGlyphNode;
        
    [self addChild:renderedGlyphNode];
    renderedGlyphNode.color = color;
    renderedGlyphNode.colorBlendFactor = 1.0;
    
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

    // Write the glyph into the PDF context
    
    // Set the correct color by looking up the color of the glyph node
    SKSpriteNode *glyphNode = (SKSpriteNode *)[self childNodeWithName:kMHGlyphNodeGlyphNode];
    if (glyphNode) {
        NSColor *glyphColor = glyphNode.color;
        CGContextSetFillColorWithColor(pdfContext, [glyphColor CGColor]);
    }
    
    CTFontRef ctFont = (__bridge CTFontRef)_font;
    CGFontRef cgFont = CTFontCopyGraphicsFont(ctFont, NULL);
    CGGlyph glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)_glyphName);
    if (!glyph) {
        glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)kMHOldGlyphNodeGlyphNameForUnknown);
    }
    CGContextSetFont(pdfContext, cgFont);
    CGFontRelease(cgFont);
    CGContextSetFontSize(pdfContext, CTFontGetSize(ctFont));
    
    // Write the glyph in the context
    CGPoint position = CGPointZero; // FIXME: is this correct?
    CGContextShowGlyphsAtPositions(pdfContext, &glyph, &position, 1);

    CGContextRestoreGState(pdfContext);
}







@end
