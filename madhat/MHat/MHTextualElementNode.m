//
//  MHTextualElementNode.m
//  MadHat
//
//  Created by Dan Romik on 8/3/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHTextualElementNode.h"

NSString * const kMHTextNodeUnderlineNode = @"MHTextNodeUnderlineNode";
NSString * const kMHTextNodeStrikethroughNode = @"MHTextNodeStrikethroughNode";
NSString * const kMHTextNodeHighlightNode = @"MHTextNodeHighlightNode";


@implementation MHTextualElementNode


- (void)configureWithFont:(NSFont *)font
                    color:(NSColor *)color
          backgroundColor:(nullable NSColor *)backgroundColor
              underlining:(bool)underlining
            strikethrough:(bool)strikethrough
{
    [self removeChildrenInArray:[self objectForKeyedSubscript:kMHTextNodeUnderlineNode]];
    [self removeChildrenInArray:[self objectForKeyedSubscript:kMHTextNodeStrikethroughNode]];
    [self removeChildrenInArray:[self objectForKeyedSubscript:kMHTextNodeHighlightNode]];

    if (backgroundColor) {
      // add a rectangle node to serve as background
      SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor size:CGSizeMake(_dimensions.width+2, _dimensions.depth + _dimensions.height)];
      backgroundNode.anchorPoint = CGPointZero;
      backgroundNode.position = CGPointMake(-1,-_dimensions.depth);
      backgroundNode.zPosition = -100.0;
      backgroundNode.name = kMHTextNodeHighlightNode;

      [self addChild:backgroundNode];
    }

    // FIXME: code for underlining is a bit shaky - improve (see also some parallel code in the MHWhitespace class)
    if (underlining) {
      SKSpriteNode *underlineNode = [SKSpriteNode spriteNodeWithColor:color size:CGSizeMake(_dimensions.width+2, 0.5)];

      underlineNode.anchorPoint = CGPointZero;
      underlineNode.position = CGPointMake(-1.0,-2.0);
      underlineNode.zPosition = -50.0;
      underlineNode.name = kMHTextNodeUnderlineNode;

      [self addChild:underlineNode];
    }

    if (strikethrough) {
      SKSpriteNode *strikethroughNode = [SKSpriteNode spriteNodeWithColor:color size:CGSizeMake(_dimensions.width+2, 1.0)];

      strikethroughNode.anchorPoint = CGPointZero;
      strikethroughNode.position = CGPointMake(-1.0,3.5);
      strikethroughNode.zPosition = -50.0;
      strikethroughNode.name = kMHTextNodeStrikethroughNode;

      [self addChild:strikethroughNode];
    }

}


- (void)renderInPDFContext:(CGContextRef)pdfContext
{
    CGContextSaveGState(pdfContext);
    
    void (^nodeRenderingBlock)(SKNode *node, BOOL *stop) = ^(SKNode *node, BOOL *stop) {
                               CGContextSetFillColorWithColor(pdfContext, [((SKSpriteNode *)node).color CGColor]);
                               CGContextAddRect(pdfContext, node.frame);
                               CGContextDrawPath(pdfContext, kCGPathFill);
    };

    // Do we have highlighting? That should be rendered first so it is in the background. Look up highlighting nodes and render them into the document with the appropriate color
    [self enumerateChildNodesWithName:kMHTextNodeHighlightNode usingBlock:nodeRenderingBlock];
    
    // Do we have underlining or strikethrough? Look up those nodes and write them into the document as well
    [self enumerateChildNodesWithName:kMHTextNodeUnderlineNode usingBlock:nodeRenderingBlock];
    [self enumerateChildNodesWithName:kMHTextNodeStrikethroughNode usingBlock:nodeRenderingBlock];

    CGContextRestoreGState(pdfContext);
}

@end
