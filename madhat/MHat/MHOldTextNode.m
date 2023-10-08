////
////  MHOldTextNode.m
////  MadHat
////
////  Created by Dan Romik on 7/9/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHOldTextNode.h"
//
//#define kMHOldTextNodeDefaultFont  [NSFont systemFontOfSize:16]
//
//@interface MHOldTextNode ()
//{
//    NSString *_text;
//    
//    NSFont *myFont; // FIXME: I don't want each text node to have to remember its font but need this for PDF rendering. Is there any way to avoid this?
//}
//
//
//@end
//
//@implementation MHOldTextNode
//
//+ (instancetype)textNodeWithString:(NSString *)string
//{
//    return [[[self class] alloc] initWithString:string];
//}
//
//- (instancetype)initWithString:(NSString *)string
//{
//    if (self = [super init]) {
//        _text = string;
//    }
//    return self;
//}
//
//- (instancetype)copyWithZone:(NSZone *)zone
//{
//    return [[self class] textNodeWithString:[self.text copy]];
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
//    self.lineWidth = 0.26;  // FIXME: this gives good results, but think about whether this is "scientifically" correct
//    self.fillColor = color;
//    self.strokeColor = color;
////    self.lineCap = kCALineCapButt;
////    self.lineJoin = kCALineJoinRound;
//    
//    CGMutablePathRef letters = CGPathCreateMutable();
//
//    NSDictionary *attrs =  [NSDictionary dictionaryWithObjectsAndKeys: font, kCTFontAttributeName, nil];
//    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:_text attributes:attrs];
//    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
//    CFArrayRef runArray = CTLineGetGlyphRuns(line);
//    
////    CGRect firstGlyphRect;  // I use this to calculate the left side bearing of the first glyph // FIXME: doesn't seem needed anymore, commenting out
//
//    // for each RUN
//    CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
//    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
//    _dimensions.width = 0.0;
//    for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
//        // get Glyph & Glyph-data
//        CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
//        CGGlyph glyph;
//        CGPoint position;
//        CGSize advance;
//        CTRunGetGlyphs(run, thisGlyphRange, &glyph);
//        CTRunGetPositions(run, thisGlyphRange, &position);
//        CTRunGetAdvances(run, thisGlyphRange, &advance);
//        
//        _dimensions.width += advance.width;
//
////        // Get the bounding rect for the first glyph, which in particular includes the left side bearing as the glyph x origin
////        if (runGlyphIndex == 0) {
////            CTFontGetBoundingRectsForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &glyph, &firstGlyphRect, 1);
////        }
//
//        // Get path of outline
//        CGPathRef letter = CTFontCreatePathForGlyph((CTFontRef)font, glyph, NULL);
//        
//        // FIXME: some issues to investigate here with the shift of the x and y position by 1 point
//        CGAffineTransform t = CGAffineTransformMakeTranslation(position.x+1, position.y+1); // Here, the +1 in the y coordinate gives slightly more pleasing results, with the glyph aligning well with the bottom of the baseline. The +1 in the x coordinate matches the earlier positioning using SKSimpleTextNode (and the earlier version of the class MHTextAtom) better, though still not perfectly
//        
//        CGPathAddPath(letters, &t, letter);
//        CGPathRelease(letter);
//    }
//    
//    CFRelease(line);
//  
//    // FIXME: the next line causes the text to be underlined. Need to add logic to decide when to do this
//    if (underlining)
//        CGPathAddRect(letters, nil, CGRectMake(0.0, -1.0, _dimensions.width, 0.7));
//
//    _dimensions.depth = -font.descender;
//    _dimensions.height = font.ascender;
//    
//    if (!CGPathIsEmpty(letters))
//        self.path = letters;
//    
//    CGPathRelease(letters);
//    
//    [super configureWithFont:font color:color backgroundColor:backgroundColor underlining:underlining];
//}
//
//
//- (MHDimensions)dimensions
//{
//    return _dimensions;
//}
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
//    CGFontRelease(cgFont);
//    CGContextSetFontSize(context, CTFontGetSize(ctFont));
//    
//    NSDictionary *attrs =  [NSDictionary dictionaryWithObjectsAndKeys: myFont, kCTFontAttributeName, nil];
//    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:_text attributes:attrs];
//    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
//    CFArrayRef runArray = CTLineGetGlyphRuns(line);
//
//    // for each RUN
//    CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
//    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
//    for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
//        // get Glyph & Glyph-data
//        CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
//        CGGlyph glyph;
//        CGPoint position;
//        CGSize advance;
//        CTRunGetGlyphs(run, thisGlyphRange, &glyph);
//        CTRunGetPositions(run, thisGlyphRange, &position);
//        CTRunGetAdvances(run, thisGlyphRange, &advance);
//        
//        position.x = position.x + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
//        position.y = position.y + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
//        CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
//    }
//    
//    CFRelease(line);
//    
//    CGContextRestoreGState(context);
//}
//
//
//
//
//
//// FIXME: experimental code to implement layout of text along a curve. Kind of a temporary hack, needs to be improved
//- (NSArray <MHOldTextNode *> *)createTextNodesForIndividualGlyphs
//{
//    // FIXME: some main issues with this implementation that need fixing are:
//    // FIXME: 1. it loses kerning information, and
//    // FIXME: 2. composed characters aren't typeset correctly
//    
//    NSUInteger textLength = _text.length;
//    NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity:textLength];
//    NSRange charRange;
//    charRange.length = 1;
//    NSColor *color = self.fillColor;
//    CGFloat xOffset = 0.0;
//    for (charRange.location = 0; charRange.location < textLength; charRange.location++) {
//        NSString *singleCharSubstring = [_text substringWithRange:charRange];
//        MHOldTextNode *singleCharNode = [MHOldTextNode textNodeWithString:singleCharSubstring];
//        [singleCharNode configureWithFont:myFont color:color backgroundColor:nil underlining:false];
//        singleCharNode.position = CGPointMake(xOffset, 0.0);
//        xOffset += singleCharNode.dimensions.width;
//        [nodes addObject:singleCharNode];
//    }
//    return nodes;
//}
//
//@end
