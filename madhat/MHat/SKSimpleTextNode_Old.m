////
////  SKSimpleTextNode.m
////  MH
////
////  Created by Dan Romik on 12/19/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//#import "SKSimpleTextNode.h"
//#import "NSBezierPath+QuartzUtilities.h"
//
//
//
//// Comment this out to revert to older code that does not use the SKUShapeNode class
//#define USING_SKUTILITIES
//
//#ifdef USING_SKUTILITIES
////#import "SKUtilities2.h"
//#import "SKUShapeNode.h"
//#endif
//
//
//
//@interface SKSimpleTextNode () {
////    NSFont *font;
//    NSString *text;
//#ifdef USING_SKUTILITIES
//    SKUShapeNode *glyphsNode;
//#else
//    SKShapeNode *glyphsNode;
//#endif
//}
//@end
//
//@implementation SKSimpleTextNode
//
//+ (instancetype)textNodeWithString:(NSString *)string
//{
//    return [[self alloc] initWithString:(NSString *)string];
//}
//
//- (instancetype)initWithString:(NSString *)string
//{
//    if (self = [super init]) {
//        text = string;
////        font = [NSFont systemFontOfSize:16];
//    }
//    return self;
//}
//
//- (MHDimensions)configureWithFont:(NSFont *)font
//                            color:(NSColor *)color
//                  backgroundColor:(nullable NSColor *)backgroundColor
//                  textIsGlyphName:(bool)textIsGlyph
//{
//    MHDimensions dimensions;
//    dimensions.width = 0.0;
//    dimensions.depth = 0.0;
//    dimensions.height = 0.0;
//    
//    [self removeAllChildren];
//    
//    if (textIsGlyph) {
//        CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)font, nil);
//
//        CGGlyph glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)text);
//        
//        if (!glyph) {
//            glyph = CGFontGetGlyphWithGlyphName(cgFont, (CFStringRef)@"question");
//        }
//        
//        CGRect glyphBBox;
//        CGRect glyphBBoxInPoints;
//        int glyphAdvance;
//        CGFloat glyphAdvanceInPoints;
//        CGFontGetGlyphBBoxes(cgFont, &glyph, 1, &glyphBBox);
//        CGFontGetGlyphAdvances(cgFont, &glyph, 1, &glyphAdvance);
//        CGFloat emWidth = font.pointSize;
//        int unitsPerEm = CGFontGetUnitsPerEm(cgFont);
//        glyphBBoxInPoints.origin.x = glyphBBox.origin.x/unitsPerEm * emWidth;
//        glyphBBoxInPoints.origin.y = glyphBBox.origin.y/unitsPerEm * emWidth;
//        glyphBBoxInPoints.size.width = glyphBBox.size.width/unitsPerEm * emWidth;
//        glyphBBoxInPoints.size.height = glyphBBox.size.height/unitsPerEm * emWidth;
//        glyphAdvanceInPoints = ((float)glyphAdvance)/unitsPerEm * emWidth;
//        
//        dimensions.width = glyphAdvanceInPoints;
//        dimensions.depth = -glyphBBoxInPoints.origin.y;
//        dimensions.height = glyphBBoxInPoints.origin.y + glyphBBoxInPoints.size.height;
//                    
//        NSBezierPath *path = [NSBezierPath bezierPath];
//        [path moveToPoint:NSZeroPoint];
//        [path appendBezierPathWithCGGlyph:glyph inFont:font];
//
//#ifdef USING_SKUTILITIES
//        glyphsNode = [SKUShapeNode shapeWithPath:[path quartzPath] andColor:color];
////        glyphsNode.fillColor = color;
//        glyphsNode.strokeColor = color;  // according to SKUtilities2 docs, this is the correct way to render a path with no stroke
//        glyphsNode.lineWidth = 0.5; // this seems to match what SKLabelNode renders
//
//        [self addChild:glyphsNode];
//        
//        glyphsNode.position = CGPointMake(0,1); // this works (giving glyphs that align vertically with output produced by SKLabelNode) but I don't understand why it's needed. Maybe something to do with the 0.5-width line stroke? This suggests that SKLabelNode also has a similar stroke line width. Whether this produces the most pleasing/typographically correct output, I don't really know.
//#else
//        glyphsNode = [SKShapeNode shapeNodeWithPath:[path quartzPath]];
//        glyphsNode.fillColor = color;
//        glyphsNode.strokeColor = color;
//        glyphsNode.lineWidth = 0.0001;
//
//        [self addChild:glyphsNode];
//#endif
//        
//        // FIXME: need to add node for background color
//        
//        return dimensions;
//    }
//    
//    // Code adapted from https://stackoverflow.com/questions/10599355/ios-uibezierpath-that-follows-the-shape-of-a-font
//    CGMutablePathRef letters = CGPathCreateMutable();
//
//    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                           font, kCTFontAttributeName,
//                           nil];
//    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text
//                                                                     attributes:attrs];
//    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
//    CFArrayRef runArray = CTLineGetGlyphRuns(line);
//    
//    CGRect firstGlyphRect;  // I use this to calculate the left side bearing of the first glyph
//
//    // for each RUN
//    CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
//    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
//    for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
//        // get Glyph & Glyph-data
//        CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
//        CGGlyph glyph;
//        CGPoint position;
//        CTRunGetGlyphs(run, thisGlyphRange, &glyph);
//        CTRunGetPositions(run, thisGlyphRange, &position);
//
//        // Get the bounding rect for the first glyph, which in particular includes the left side bearing as the glyph x origin
//        if (runGlyphIndex == 0) {
//            CTFontGetBoundingRectsForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &glyph, &firstGlyphRect, 1);
////            NSLog(@"%f %f %f %f", firstGlyphRect.origin.x, firstGlyphRect.origin.y, firstGlyphRect.size.width, firstGlyphRect.size.height);
//        }
//
//        // Get path of outline
//        CGPathRef letter = CTFontCreatePathForGlyph((CTFontRef)font, glyph, NULL);
//        CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
//        CGPathAddPath(letters, &t, letter);
//        CGPathRelease(letter);
//    }
//    
//    // This works but results in glyphs that are too fat due to the bezier path stroke (which has to be turned on to activate antialiasing, and cannot be done with a line width less than 1.0 - apparently a bug in the API)
//    // Not adding the node as a subchild for now, see below for an approach that works better despite being kind of hackish
//#ifdef USING_SKUTILITIES
//    glyphsNode = (SKUShapeNode *)[SKShapeNode shapeNodeWithPath:letters];   // FIXME: using this for now but this is terrible coding, seriously needs to be cleaned up
//
////    glyphsNode = [SKUShapeNode shapeWithPath:letters andColor:color]; // FIXME: this result in incorrect node dimensions so I'm commenting it out for now
//    
////    glyphsNode.fillColor = color;
////    glyphsNode.strokeColor = color;
////    glyphsNode.lineWidth = 0.00000001;
////    [self addChild:glyphsNode];
//#else
//    glyphsNode = [SKShapeNode shapeNodeWithPath:letters];
////    glyphsNode.fillColor = color;
////    glyphsNode.strokeColor = color;
////    glyphsNode.lineWidth = 0.00000001;
////    [self addChild:glyphsNode];
//#endif
//    
//    // Instead I add a SKLabelNode that's shifted to the right by an amount equal to the left side bearing of the first glyph
//    // This seems to work and the rendering quality is better, though not sure about performance
//    // FIXME: eventually a better solution should be found to optimize performance
//    NSDictionary *attributesDict = @{
//        NSFontAttributeName : font,
//        NSForegroundColorAttributeName : color
//    };
//    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
//                                                                         attributes:attributesDict];
//    SKLabelNode *textNode = [SKLabelNode labelNodeWithAttributedText:attributedText];
//    textNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
//    textNode.position = CGPointMake(firstGlyphRect.origin.x, 0.0);
//    [self addChild:textNode];
//    
//    if (backgroundColor) {
//        CGFloat ascender = font.ascender;
//        CGFloat descender = font.descender;
//        SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor size:CGSizeMake(glyphsNode.frame.size.width, ascender-descender)];
//        backgroundNode.anchorPoint = CGPointZero;
//        backgroundNode.position = CGPointMake(0,descender);
//        backgroundNode.zPosition = -100.0;
//        [self addChild:backgroundNode];
//    }
//    
//    CGPathRelease(letters);
//    
//    return dimensions;
//}
//
//- (CGRect)frame
//{
//    CGPoint position = self.position;
//    CGRect glyphsNodeFrame = glyphsNode.frame;
//    
//    return CGRectMake(position.x, position.y, glyphsNodeFrame.origin.x + glyphsNodeFrame.size.width,
//                      glyphsNodeFrame.origin.y + glyphsNodeFrame.size.height);
//}
//
//@end
