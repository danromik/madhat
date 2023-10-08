////
////  MadHattributedStringTextAtom.m
////  MadHat
////
////  Created by Dan Romik on 6/30/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHAttributedStringTextAtom.h"
//
//@interface MHAttributedStringTextAtom ()
//{
//    NSAttributedString *_attributedString;
//}
//@end
//
//@implementation MHAttributedStringTextAtom
//
//+ (instancetype)atomWithAttributedString:(NSAttributedString *)attributedString
//{
//    return [[[self class] alloc] initWithAttributedString:attributedString];
//}
//
//- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
//{
//    if (self = [super init]) {
//        _attributedString = attributedString;
//    }
//    return self;
//}
//
//- (SKNode *)spriteKitNode
//{
//    if (!_spriteKitNode) {
//        SKLabelNode *labelNode = [SKLabelNode labelNodeWithAttributedText:_attributedString];
//        labelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
//        labelNode.ownerExpression = self;
//        _spriteKitNode = labelNode;
//    }
//    return _spriteKitNode;
//}
//
//- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
//{
//    MHDimensions myDimensions;
//    
//    NSRect stringRect = [_attributedString boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, 1000.0) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading];
//    
//    myDimensions.width = stringRect.origin.x + stringRect.size.width;
//    myDimensions.height = stringRect.origin.y + stringRect.size.height;
//    myDimensions.depth = -stringRect.origin.y;
//    
//    self.dimensions = myDimensions;
//}
//
//
//- (void)renderInCGContext:(CGContextRef)context
//{
//    // FIXME: this method doesn't work very well, needs more work.
//
//    CGContextSaveGState(context);
//    
//    NSFont *myFont = [[_attributedString fontAttributesInRange:NSMakeRange(0, _attributedString.length)] objectForKey:NSFontAttributeName];
//    CGFloat ascender = myFont.ascender;
//    CGFloat descender = myFont.descender;
//    CGFloat fontHeight = ascender - descender;
//    CTFontRef ctFont = (__bridge CTFontRef)myFont;
//    CGFontRef cgFont = CTFontCopyGraphicsFont(ctFont, NULL);
//    CGContextSetFont(context, cgFont);
//    CGContextSetFontSize(context, CTFontGetSize(ctFont));
//    
//    NSString *myString = _attributedString.string;
//
//    __block CGSize totalAdvance;
//    totalAdvance.width = 0;
//
//    [myString enumerateSubstringsInRange:NSMakeRange(0, myString.length)
//                                 options:NSStringEnumerationByComposedCharacterSequences
//                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
//        
//        NSString *stringFromChar = [myString substringWithRange:substringRange];
//        NSDictionary *attributesDict = [self->_attributedString attributesAtIndex:substringRange.location effectiveRange:nil];
//        NSColor *charForegroundColor = attributesDict[NSForegroundColorAttributeName];
//        NSColor *charBackgroundColor = attributesDict[NSBackgroundColorAttributeName];
//
////        NSDictionary *improvedAttribsDict = @{
////            NSForegroundColorAttributeName : charForegroundColor,
////            NSBackgroundColorAttributeName : charBackgroundColor,
////            NSFontAttributeName : myFont
////        };
//
//        NSAttributedString *attribStringFromChar = [[NSAttributedString alloc] initWithString:stringFromChar
//                                                                                   attributes:attributesDict]; //improvedAttribsDict];
//
//        CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attribStringFromChar);
//        CFArrayRef runArray = CTLineGetGlyphRuns(line);
//        
//        NSLog(@"zzz %@ %@", substring, NSStringFromRange(substringRange));
//
//        // for each RUN
//        CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
//        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
//        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
//            // get Glyph & Glyph-data
//            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
//            CGGlyph glyph;
//            CGPoint position;
//            CGSize advance;
//            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
//            CTRunGetPositions(run, thisGlyphRange, &position);
//            CTRunGetAdvances(run, thisGlyphRange, &advance);
//            
//            position.x = position.x + totalAdvance.width + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
//            position.y = position.y + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
//
//            CGContextSetFillColorWithColor(context, [charBackgroundColor CGColor]);
//            CGContextFillRect(context, CGRectMake(totalAdvance.width, descender, advance.width, fontHeight));
//
//            CGContextSetFillColorWithColor(context, [charForegroundColor CGColor]);
//            CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
//            
//            
//            totalAdvance.width += advance.width;
//
//        }
//        CFRelease(line);
//    }
//     ];
//    
//    
////    CGSize totalAdvance;
////    totalAdvance.width = 0;
////    for (charIndex = 0; charIndex < stringLength; charIndex++) {
////        unichar theChar = [myString characterAtIndex:charIndex];
////        NSString *stringFromChar = [NSString stringWithFormat:@"%C", theChar];
////        NSDictionary *attributesDict = [_attributedString attributesAtIndex:charIndex effectiveRange:nil];
////        NSAttributedString *attribStringFromChar = [[NSAttributedString alloc] initWithString:stringFromChar
////                                                                                   attributes:attributesDict];
////
////        NSColor *charForegroundColor = attributesDict[NSForegroundColorAttributeName];
////        NSColor *charBackgroundColor = attributesDict[NSBackgroundColorAttributeName];
////
////        CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attribStringFromChar);
////        CFArrayRef runArray = CTLineGetGlyphRuns(line);
////
////        // for each RUN
////        CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
//////        CFIndex numberOfRuns = CFArrayGetCount(runArray);
//////        for (runIndex = 0; runIndex < numberOfRuns; runIndex++) {
////            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
////            for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
////                // get Glyph & Glyph-data
////                CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
////                CGGlyph glyph;
////                CGPoint position;
////                CGSize advance;
////                CTRunGetGlyphs(run, thisGlyphRange, &glyph);
////                CTRunGetPositions(run, thisGlyphRange, &position);
////                CTRunGetAdvances(run, thisGlyphRange, &advance);
////
////                position.x = position.x + totalAdvance.width + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
////                position.y = position.y + 1.0;  // FIXME: For consistency with what MHOldTextualElementNode does (see remark there about where this offset comes from)
////
////                CGContextSetFillColorWithColor(context, [charBackgroundColor CGColor]);
////                CGContextFillRect(context, CGRectMake(totalAdvance.width, descender, advance.width, fontHeight));
////
////                CGContextSetFillColorWithColor(context, [charForegroundColor CGColor]);
////                CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
////
////
////                totalAdvance.width += advance.width;
////
////            }
//////        }
////        CFRelease(line);
////    }
//    
//    
//    CGContextRestoreGState(context);
//}
//
//@end
