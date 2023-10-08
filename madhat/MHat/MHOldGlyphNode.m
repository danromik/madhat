////
////  MHOldGlyphNode.m
////  MadHat
////
////  Created by Dan Romik on 7/10/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHOldGlyphNode.h"
//#import "NSBezierPath+QuartzUtilities.h"
//
//@interface MHOldGlyphNode ()
//{
//    NSString *_glyphName;
//    
//    NSFont *myFont; // FIXME: I don't want each text node to have to remember its font. Is there any way to avoid this?
//}
//@end
//
//@implementation MHOldGlyphNode
//
//+ (instancetype)glyphNodeWithGlyphName:(NSString *)glyphName
//{
//    return [[[self class] alloc] initWithGlyphName:glyphName];
//}
//
//- (instancetype)initWithGlyphName:(NSString *)glyphName
//{
//    if (self = [super init]) {
//        _glyphName = glyphName;
//    }
//    return self;
//}
//
//- (instancetype)copyWithZone:(NSZone *)zone
//{
//    return [[self class] glyphNodeWithGlyphName:[self.glyphName copy]];
//}
//
//- (void)configureWithFont:(NSFont *)font
//                    color:(NSColor *)color
//          backgroundColor:(nullable NSColor *)backgroundColor
//              underlining:(bool)underlining
//{
//
//    myFont = font;  // FIXME: not good
//    
//    self.lineWidth = 0.25;  // FIXME: this gives good results, but think about whether this is "scientifically" correct
//    self.fillColor = color;
//    self.strokeColor = color;
//
//    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)font, nil);
//
//    CGGlyph glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)_glyphName);
//    
//    if (!glyph) {
//        glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)@"question");
//    }
//    
//    CGRect glyphBBox;
//    CGRect glyphBBoxInPoints;
//    int glyphAdvance;
//    CGFloat glyphAdvanceInPoints;
//    CGFontGetGlyphBBoxes(cgFont, &glyph, 1, &glyphBBox);
//    CGFontGetGlyphAdvances(cgFont, &glyph, 1, &glyphAdvance);
//    CGFloat emWidth = font.pointSize;
//    int unitsPerEm = CGFontGetUnitsPerEm(cgFont);
//    glyphBBoxInPoints.origin.x = glyphBBox.origin.x/unitsPerEm * emWidth;
//    glyphBBoxInPoints.origin.y = glyphBBox.origin.y/unitsPerEm * emWidth;
//    glyphBBoxInPoints.size.width = glyphBBox.size.width/unitsPerEm * emWidth;
//    glyphBBoxInPoints.size.height = glyphBBox.size.height/unitsPerEm * emWidth;
//    glyphAdvanceInPoints = ((float)glyphAdvance)/unitsPerEm * emWidth;
//    
//    _dimensions.width = glyphAdvanceInPoints;
//    _dimensions.depth = -glyphBBoxInPoints.origin.y;
//    _dimensions.height = glyphBBoxInPoints.origin.y + glyphBBoxInPoints.size.height;
//                
//    NSBezierPath *path = [NSBezierPath bezierPath];
//    [path moveToPoint:NSZeroPoint];
//    [path appendBezierPathWithCGGlyph:glyph inFont:font];
//    
//    CGFontRelease(cgFont);
//    
//    self.path = [path quartzPath];
//    
//    [super configureWithFont:font color:color backgroundColor:backgroundColor underlining:false];
//}
//
//
//- (MHDimensions)dimensions
//{
//    return _dimensions;
//}
//
//
//- (void)renderInCGContext:(CGContextRef)context
//{
//    // This code supersedes the Bezier path rendering code in the MHOldTextualElementNode renderInCGContext: method with
//    // text-drawing code. This way if we generate a PDF the file will be more compact and the user can select text in it
//    // (plus there are other obvious benefits related to accessibility)
//
//    [super renderInCGContext:context];
//
//    CGContextSaveGState(context);
//    
//    CGContextSetFillColorWithColor(context, [self.fillColor CGColor]);
//    CTFontRef ctFont = (__bridge CTFontRef)myFont;
//    CGFontRef cgFont = CTFontCopyGraphicsFont(ctFont, NULL);
//    CGContextSetFont(context, cgFont);
//    CGContextSetFontSize(context, CTFontGetSize(ctFont));
//    
//    CGGlyph glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)_glyphName);
//    
//    if (!glyph) {
//        glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)@"question");      // FIXME: maybe find something more creative than a questio mark...
//    }
//    
//    CGPoint position = CGPointZero;
//    CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
//    
//    CGFontRelease(cgFont);
//
//    CGContextRestoreGState(context);
//}
//
//
//
//@end
