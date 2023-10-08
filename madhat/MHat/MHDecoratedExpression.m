//
//  MHDecoratedExpression.m
//  MadHat
//
//  Created by Dan Romik on 12/21/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHDecoratedExpression.h"
#import "MHStyleIncludes.h"

//unichar kMHDecorationCaret = 0x0302;    // a caret "◌̂" diacritic

static NSString * const kMHDecorationCommandDecorationStringKey = @"decoration";
static NSString * const kMHDecorationCommandDecorationVOffsetKey = @"voffset";

static NSString * const kMHDecorationNodeName = @"decorationnode";
static NSString * const kMHDecorationOverunderbarNodeName = @"overunderbarnode";

static NSString * const kMHDecorationStringForOverbarType = @"-";
static NSString * const kMHDecorationStringForUnderbarType = @"_";

NSUInteger const kMHDecoratedExpressionContentsNestingLevels[kMHNumberOfNestingLevels] = {
    1, 1, 3, 3, 5, 5, 7, 7
};



@interface MHDecoratedExpression ()
{
    MHDecorationType _type;
    NSString *_decorationString;
    short int _vOffset;
}
@end

@implementation MHDecoratedExpression


#pragma mark - Constructor methods

+ (instancetype)decoratedExpressionWithContents:(MHExpression *)contents
                               decorationString:(NSString *)decorationString
                                 verticalOffset:(short int)offset;
{
    return [[self alloc] initWithContents:contents
                           decorationType:MHDecorationCustomStringOverscript
                         decorationString:decorationString
                           verticalOffset:offset];
}

+ (instancetype)decoratedExpressionWithContents:(MHExpression *)contents
                                 decorationType:(MHDecorationType)decorationType
                                 verticalOffset:(short int)offset
{
    return [[self alloc] initWithContents:contents decorationType:decorationType decorationString:nil verticalOffset:offset];
}

- (instancetype)initWithContents:(MHExpression *)contents
                  decorationType:(MHDecorationType)decorationType
                decorationString:(nullable NSString *)decorationString
                  verticalOffset:(short)offset;
{
    if (self = [super initWithContents:contents]) {
        _type = decorationType;
        _decorationString = decorationString;
        _vOffset = offset;
    }
    return self;
}




#pragma mark - MHCommand protocol


+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(nullable NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    NSString *decorationString = parameters[kMHDecorationCommandDecorationStringKey];
    short int vOffset = [parameters[kMHDecorationCommandDecorationVOffsetKey] shortValue];
    if ([decorationString isEqualToString:kMHDecorationStringForOverbarType]) {
        return [self decoratedExpressionWithContents:argument decorationType:MHDecorationOverbar verticalOffset:vOffset];
    }
    else if ([decorationString isEqualToString:kMHDecorationStringForUnderbarType]) {
        return [self decoratedExpressionWithContents:argument decorationType:MHDecorationUnderbar verticalOffset:vOffset];
    }
    
    if (decorationString)
        return [self decoratedExpressionWithContents:argument decorationString:decorationString verticalOffset:vOffset];
    
    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ @"*" ];
}





#pragma mark - Properties

- (void)setContents:(MHExpression *)contents
{
//    self.contents.parent = nil;
    super.contents = contents;
//    contents.parent = self;
    contents.nestingLevel = kMHDecoratedExpressionContentsNestingLevels[self.nestingLevel];
}

- (bool)splittable
{
    return false;
}

- (bool)atomicForReformatting
{
    return true;
}

- (MHTypographyClass)typographyClass
{
    return self.contents.typographyClass;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    self.contents.nestingLevel = kMHDecoratedExpressionContentsNestingLevels[nestingLevel];
}






- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    NSUInteger nestingLevel = self.nestingLevel;
    NSFont *font = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];

    NSColor *color = contextManager.textForegroundColor;

    MHExpression *myContents = self.contents;
    MHDimensions myDimensions;
    MHDimensions contentDimensions = myContents.dimensions;
    
    myDimensions.depth = contentDimensions.depth;
    myDimensions.width = contentDimensions.width;   // FIXME: adjust width if necessary based on custom decoration width

    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];
    CGFloat topDecorationPositioningOffset = emWidth * (CGFloat)(myContents.topDecorationPositioningOffset)/1000.0;
    
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHDecorationNodeName]];
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHDecorationOverunderbarNodeName]];

    switch (_type) {
        case MHDecorationCustomStringOverscript: {
            NSDictionary *attributesDict = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : color };
            NSAttributedString *attributedDecoration = [[NSAttributedString alloc] initWithString:_decorationString
                                                                                       attributes:attributesDict];
            SKLabelNode *decorationNode = [SKLabelNode labelNodeWithAttributedText:attributedDecoration];
            decorationNode.name = kMHDecorationNodeName;
            decorationNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            
            // FIXME: improve positioning of the decoration node - should take into account italic correction
            CGRect decorationNodeRect = decorationNode.frame;
            CGFloat italicCorrection = emWidth * (CGFloat)(myContents.italicCorrection)/1000.0;
            
            // FIXME: improve formulas for positioning decoration
            decorationNode.position = CGPointMake(contentDimensions.width/2.0 - decorationNodeRect.size.width/2.0 + italicCorrection,
                                                  -contentDimensions.depth + contentDimensions.height
                                                  - emWidth * ((float)_vOffset)/1000.0 - topDecorationPositioningOffset);
            
            [_spriteKitNode addChild:decorationNode];

            // FIXME: the height isn't set correctly at the moment
            myDimensions.height = contentDimensions.height - emWidth * ((float)_vOffset)/1000.0 + decorationNodeRect.size.height;
        }
            break;
        case MHDecorationOverbar:
        case MHDecorationUnderbar: {
            CGFloat lineThickness = [contextManager fractionLineThicknessForNestingLevel:myContents.nestingLevel];
            
            CGMutablePathRef linePath = CGPathCreateMutable();
            if (_type == MHDecorationOverbar) {
                // FIXME: improve positioning of the decoration node - should take into account italic correction
                CGPathMoveToPoint(linePath, nil, 0.0,
                                  contentDimensions.height + 2.0 + lineThickness/2.0 - topDecorationPositioningOffset);
                CGPathAddLineToPoint(linePath, nil, contentDimensions.width,
                                     contentDimensions.height + 2.0 + lineThickness/2.0 - topDecorationPositioningOffset);
            }
            else {
                // FIXME: improve positioning of the decoration node - should take into account italic correction
                CGPathMoveToPoint(linePath, nil, 0.0, -2.0 - lineThickness/2.0);
                CGPathAddLineToPoint(linePath, nil, contentDimensions.width, -2.0 - lineThickness/2.0);
            }
            SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
            CGPathRelease(linePath);
            lineNode.name = kMHDecorationOverunderbarNodeName;
            lineNode.strokeColor = color;
            lineNode.lineWidth = lineThickness;
            lineNode.lineCap = kCGLineCapRound;
            [_spriteKitNode addChild:lineNode];
            
            // FIXME: improve formula for the height
            if (_type == MHDecorationOverbar) {
                myDimensions.height = contentDimensions.height + 3.0 + lineThickness;
            }
            else {
                CGFloat underbarDepth = contentDimensions.depth + 3.0 + lineThickness;
                if (myDimensions.depth < underbarDepth) {
                    myDimensions.depth = underbarDepth;
                }
            }
        }
            break;
    }
    
    self.dimensions = myDimensions;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHDecoratedExpression *myCopy = [[[self class] alloc] initWithContents:[self.contents logicalCopy]
                                                            decorationType:_type
                                                          decorationString:[_decorationString copy]
                                                            verticalOffset:_vOffset];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Rendering in PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;

    CGContextSaveGState(pdfContext);
    
    switch (_type) {
        case MHDecorationOverbar:
        case MHDecorationUnderbar: {
            SKShapeNode *line = (SKShapeNode *)[self.spriteKitNode childNodeWithName:kMHDecorationOverunderbarNodeName];
            if (line) {
                CGContextSetStrokeColorWithColor(pdfContext, [line.strokeColor CGColor]);
                CGContextSetLineWidth(pdfContext, line.lineWidth);
                CGContextSetLineCap(pdfContext, line.lineCap);
                CGContextAddPath(pdfContext, line.path);
                CGContextDrawPath(pdfContext, kCGPathStroke);
            }
        }
            break;
        case MHDecorationCustomStringOverscript: {
            // FIXME: the code below is copy-pasted-and-adapted from MHOldTextNode. A hack, badly needs refactoring.
            SKLabelNode *decorationNode = (SKLabelNode *)[_spriteKitNode childNodeWithName:kMHDecorationNodeName];
            CGPoint decorationNodePosition = decorationNode.position;
            NSAttributedString *attrString = decorationNode.attributedText;
            
            NSFont *myFont = [attrString attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
            NSColor *decorationColor = [attrString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
            
            CGContextSetFillColorWithColor(pdfContext, [decorationColor CGColor]);
            CTFontRef ctFont = (__bridge CTFontRef)myFont;
            CGFontRef cgFont = CTFontCopyGraphicsFont(ctFont, NULL);
            CGContextSetFont(pdfContext, cgFont);
            CGFontRelease(cgFont);
            CGContextSetFontSize(pdfContext, CTFontGetSize(ctFont));
            
            CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
            CFArrayRef runArray = CTLineGetGlyphRuns(line);

            // for each RUN
            CFIndex runIndex = 0;   // there is only one run since the attributed string has the same attributes throughout
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
            for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
                // get Glyph & Glyph-data
                CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
                CGGlyph glyph;
                CGPoint position;
                CGSize advance;
                CTRunGetGlyphs(run, thisGlyphRange, &glyph);
                CTRunGetPositions(run, thisGlyphRange, &position);
                CTRunGetAdvances(run, thisGlyphRange, &advance);
                
                // FIXME: shifting the position by decorationNodePosition doesn't give the correct results, the decoration positioning isn't right - improve
                position.x = position.x + decorationNodePosition.x;
                position.y = position.y + decorationNodePosition.y;
                CGContextShowGlyphsAtPositions(pdfContext, &glyph, &position, 1);
            }
            CFRelease(line);
        }
            break;
    }



    CGContextRestoreGState(pdfContext);
}



-(NSString *)exportedLaTeXValue //RS - FIXME: the logic at the bottom doesn't work, and instead default (???) is returned (for overline,underlines, and vectors).
{
    static NSString *combiningArrowString = @"⃗";
    
    switch (_type) {
        case MHDecorationCustomStringOverscript:
            if ([_decorationString isEqualToString: @"~"])
                return [NSString stringWithFormat: @"\\tilde{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"^"])
                return [NSString stringWithFormat: @"\\hat{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"˙"])
                return [NSString stringWithFormat: @"\\dot{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"¨"])
                return [NSString stringWithFormat: @"\\ddot{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"⋯"])
                return [NSString stringWithFormat: @"\\dddot{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"-"]) //Doesn't work!
                return [NSString stringWithFormat: @"\\overline{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: @"_"]) //Doesn't work!
                return [NSString stringWithFormat: @"\\underline{%@}", self.contents.exportedLaTeXValue];
            else if ([_decorationString isEqualToString: combiningArrowString]) //Doesn't work!
                return [NSString stringWithFormat: @"\\vec{%@}", self.contents.exportedLaTeXValue];
        case MHDecorationOverbar:
            return [NSString stringWithFormat: @"\\overline{%@}", self.contents.exportedLaTeXValue];
        case MHDecorationUnderbar:
            return [NSString stringWithFormat: @"\\underline{%@}", self.contents.exportedLaTeXValue];
    }
    return super.exportedLaTeXValue;
}



@end
