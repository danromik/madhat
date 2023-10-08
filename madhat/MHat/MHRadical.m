//
//  MHRadical.m
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHRadical.h"
#import "MHGlyphNode.h"
#import "MHMathFontSystem+ExtensibleSymbols.h"
#import "MHStyleIncludes.h"


NSString * const kMHRadicalCommandNameRadical = @"squareroot";

NSString * const kMHRadicalDecorationNodeName = @"MHRadicalDecoration";

// FIXME: add reference to the appropriate place in the TeXBook where this is explained
NSUInteger const kMHRadicalContentsNestingLevels[kMHNumberOfNestingLevels] = {
    1, 1, 3, 3, 5, 5, 7, 7
};



@implementation MHRadical


#pragma mark - Constructor methods

+ (instancetype)radicalWithContents:(MHExpression *)contents
{
    return [[self alloc] initWithContents:contents];
}

- (instancetype)initWithContents:(MHExpression *)contents
{
    if (self = [super initWithContents:contents]) {
    }
    return self;
}
 

#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHRadicalCommandNameRadical]) {
        return [self radicalWithContents:argument];
    }
    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHRadicalCommandNameRadical ];
}






#pragma mark - Properties

- (void)setContents:(MHExpression *)contents
{
//    self.contents.parent = nil;
    super.contents = contents;
//    contents.parent = self;
    contents.nestingLevel = kMHRadicalContentsNestingLevels[self.nestingLevel];
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
    return MHTypographyClassCompoundExpression;
}
- (MHTypographyClass)leftTypographyClass
{
    return MHTypographyClassCompoundExpression;
}
- (MHTypographyClass)rightTypographyClass
{
    return MHTypographyClassCompoundExpression;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    self.contents.nestingLevel = kMHRadicalContentsNestingLevels[nestingLevel];
}






#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{    
    [super typesetWithContextManager:contextManager];
    
    NSColor *foregroundColor = contextManager.textForegroundColor;
    NSColor *backgroundColor = (contextManager.textHighlighting ? contextManager.textHighlightColor : nil);
    bool underlining = contextManager.textUnderlining;
    
    NSUInteger nestingLevel = self.nestingLevel;
    
    MHExpression *myContents = self.contents;
    MHDimensions myDimensions;
    MHDimensions contentDimensions = myContents.dimensions;
    
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHRadicalDecorationNodeName]];

    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];
    CGFloat radicalOverlineThickness = [contextManager radicalOverlineThicknessForNestingLevel:nestingLevel];
    
    
    MHMathFontSystem *mathFontSystem = contextManager.mathFontSystem;
    NSFont *mathFont = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];
    MHDimensions glyphDimensions;
    NSString *glyphName = [mathFontSystem glyphNameForRadicalSignEnclosingTotalHeight:contentDimensions.depth + contentDimensions.height
                                                                        withPointSize:emWidth getDimensions:&glyphDimensions];

    
    if (glyphName) {
        // The contents are small enough to fit under a radical constructed with one of the standard glyph variants
        MHGlyphNode *radicalNode = [MHGlyphNode glyphNodeWithGlyphName:glyphName];
        [radicalNode configureWithFont:mathFont
                                 color:foregroundColor
                       backgroundColor:backgroundColor
                           underlining:underlining
                         strikethrough:false];
        radicalNode.name = kMHRadicalDecorationNodeName;
        [_spriteKitNode addChild:radicalNode];
//        CGRect radicalNodeFrame = radicalNode.calculateAccumulatedFrame;    // FIXME: doesn't seem like such a great idea to use this, but trying it for now
        radicalNode.position = CGPointZero; // CGPointMake(-radicalNodeFrame.origin.x, 1.0);
        
        
        
        // Now draw the horizontal line over the radical content

        // FIXME: there are some manually tweaked parameters here, test to make sure this is robust for different font sizes etc
        
        CGMutablePathRef linePath = CGPathCreateMutable();
        CGPathMoveToPoint(linePath, nil, glyphDimensions.width, // -3*emWidth/80,
                          glyphDimensions.height);
        CGPathAddLineToPoint(linePath, nil, glyphDimensions.width + contentDimensions.width, // -3*emWidth/80,
                             glyphDimensions.height);

        // NOTE: in the renderInContext method below we assume that this node is of class SKShapeNode!!!
        SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
        CGPathRelease(linePath);
        
        lineNode.strokeColor = foregroundColor;
        lineNode.lineWidth = radicalOverlineThickness;
        lineNode.lineCap = kCGLineCapRound;
        lineNode.name = kMHRadicalDecorationNodeName;

        [_spriteKitNode addChild:lineNode];

        // Position the contents and set the dimensions
        myContents.position = NSMakePoint(glyphDimensions.width, 0.0);

        myDimensions.height = glyphDimensions.height + radicalOverlineThickness;
        myDimensions.depth = glyphDimensions.depth;
        myDimensions.width = glyphDimensions.width + contentDimensions.width; // - 3*emWidth/80;
        
        self.dimensions = myDimensions;

    }
    else {
        // We construct the radical symbol with a base glyph and a repeated extension glyph

        NSString *mainPartGlyphName;
        NSString *extensionGlyphName;
        MHDimensions mainPartDimensions;
        MHDimensions extensionDimensions;
        [mathFontSystem getExtensibleRadicalPartsWithPointSize:emWidth
                                          getMainPartGlyphName:&mainPartGlyphName
                                         getMainPartDimensions:&mainPartDimensions
                                 getVerticalExtensionGlyphName:&extensionGlyphName
                                getVerticalExtensionDimensions:&extensionDimensions];
        
        // Add the main part
        MHGlyphNode *radicalNode = [MHGlyphNode glyphNodeWithGlyphName:mainPartGlyphName];
        [radicalNode configureWithFont:mathFont
                                 color:foregroundColor
                       backgroundColor:backgroundColor
                           underlining:underlining
                         strikethrough:false];
        radicalNode.name = kMHRadicalDecorationNodeName;
        [_spriteKitNode addChild:radicalNode];
//        CGRect radicalNodeFrame = radicalNode.calculateAccumulatedFrame;    // FIXME: doesn't seem like such a great idea to use this, but trying it for now
        radicalNode.position = CGPointMake(0.0, -mainPartDimensions.depth-contentDimensions.depth + 1.0);
        
        
        // Add the horizontal line over the contents
        // FIXME: there are some manually tweaked parameters here, test to make sure this is robust for different font sizes, different fonts etc
        // FIXME: add these parameters to the MHMathFontSystem class and add an interface to edit them in the math font editor
        
        short int radicalLineHorizontalOffset = 25;
        short int radicalLineVerticalOffset = 300;
        short int rightSideBearing = 314;
        
        CGMutablePathRef linePath = CGPathCreateMutable();
        CGPathMoveToPoint(linePath, nil, mainPartDimensions.width - emWidth*(float)(rightSideBearing+radicalLineHorizontalOffset)/1000.0,
                          contentDimensions.height + emWidth*(float)radicalLineVerticalOffset/1000.0);
        CGPathAddLineToPoint(linePath, nil, mainPartDimensions.width
                             - emWidth*(float)(rightSideBearing+radicalLineHorizontalOffset)/1000.0 + contentDimensions.width
                             + 0.32 * emWidth,
                             contentDimensions.height + emWidth*(float)radicalLineVerticalOffset/1000.0);

        // NOTE: in the renderInContext method below we assume that this node is of class SKShapeNode!!!
        SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
        CGPathRelease(linePath);
        
        lineNode.strokeColor = foregroundColor;
        lineNode.lineWidth = radicalOverlineThickness;
        lineNode.lineCap = kCGLineCapRound;
        lineNode.name = kMHRadicalDecorationNodeName;
        
        [_spriteKitNode addChild:lineNode];

        myContents.position = NSMakePoint(mainPartDimensions.width, 0.0);

        myDimensions.height = contentDimensions.height + 1.0 + 6.0*emWidth/24 + radicalOverlineThickness;
        myDimensions.depth = contentDimensions.depth;
        myDimensions.width = mainPartDimensions.width + contentDimensions.width;

        self.dimensions = myDimensions;
        
        // now add the extension pieces
        
        NSInteger numberOfExtensionGlyphs = (myDimensions.height + myDimensions.depth - mainPartDimensions.height - mainPartDimensions.depth) / (extensionDimensions.height+extensionDimensions.depth);
        
        MHGlyphNode *extensionGlyphNode;
        NSInteger ind;
        for (ind = 0; ind < numberOfExtensionGlyphs; ind++) {
            extensionGlyphNode = [MHGlyphNode glyphNodeWithGlyphName:extensionGlyphName];
            extensionGlyphNode.name = kMHRadicalDecorationNodeName;
            [extensionGlyphNode configureWithFont:mathFont
                                            color:foregroundColor
                                  backgroundColor:backgroundColor
                                      underlining:underlining
                                    strikethrough:false];
            [_spriteKitNode addChild:extensionGlyphNode];
            extensionGlyphNode.position = CGPointMake(0.0,
                                                      -contentDimensions.depth - mainPartDimensions.depth + mainPartDimensions.height + ind*(extensionDimensions.height+extensionDimensions.depth) + 1.0);
        }
        
        // Now add one final extension piece that is aligned to the rule line at the top
        extensionGlyphNode = [MHGlyphNode glyphNodeWithGlyphName:extensionGlyphName];
        extensionGlyphNode.name = kMHRadicalDecorationNodeName;
        [extensionGlyphNode configureWithFont:mathFont
                                        color:foregroundColor
                              backgroundColor:backgroundColor
                                  underlining:underlining
                                strikethrough:false];
        [_spriteKitNode addChild:extensionGlyphNode];
        extensionGlyphNode.position = CGPointMake(0.0,
                                                  contentDimensions.height + emWidth*(float)radicalLineVerticalOffset/1000.0
                                                  - extensionDimensions.depth - extensionDimensions.height);
    }
}



#pragma mark - Rendering in graphics contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);
    NSArray <SKNode *> *children = self.spriteKitNode.children;
    for (SKNode *child in children) {
        // FIXME: very ad hoc implementation. Need to refactor to get something more logical and consistent
        if ([child.name isEqualToString:kMHRadicalDecorationNodeName]) { // && [child isKindOfClass:[MHGlyphNode class]]) {
            if ([child isKindOfClass:[MHGlyphNode class]]) {
                MHGlyphNode *glyphChild = (MHGlyphNode *)child;     // to let the compiler know we know this object is an instance of MHGlyphNode
                CGPoint childPosition = glyphChild.position;
                CGContextTranslateCTM(pdfContext, childPosition.x, childPosition.y);
                [glyphChild renderInPDFContext:pdfContext];
                CGContextTranslateCTM(pdfContext, -childPosition.x, -childPosition.y);
            }
            else if ([child isKindOfClass:[SKShapeNode class]]) {
                SKShapeNode *shapeChild = (SKShapeNode *)child;     // to let the compiler know we know this object is an instance of SKShapeNode
                CGContextSetStrokeColorWithColor(pdfContext, [shapeChild.strokeColor CGColor]);
                CGContextSetLineWidth(pdfContext, shapeChild.lineWidth);
                CGContextSetLineCap(pdfContext, shapeChild.lineCap);
                CGContextAddPath(pdfContext, shapeChild.path);
                CGContextDrawPath(pdfContext, kCGPathStroke);
            }
        }
    }
    CGContextRestoreGState(pdfContext);
    [super renderToPDFWithContextManager:contextManager];
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHRadical *myCopy = [[self class] radicalWithContents:[self.contents logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ contents=%@>", [self className], (self.contents ? self.contents.description : @"[none]")];
}


- (NSString *) exportedLaTeXValue //RS
{
    return [NSString stringWithFormat: @"\\sqrt{%@}", self.contents.exportedLaTeXValue];
}


@end
