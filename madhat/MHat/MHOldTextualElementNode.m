////
////  MHOldTextualElementNode.m
////  MadHat
////
////  Created by Dan Romik on 7/10/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHOldTextualElementNode.h"
//
//static NSString * const kMHOldTextualElementNodeBackgroundNodeName = @"MHOldTextualElementNodeBackground";
//
//
//@implementation MHOldTextualElementNode
//
//- (void)configureWithFont:(NSFont *)font
//                    color:(NSColor *)color
//          backgroundColor:(nullable NSColor *)backgroundColor
//              underlining:(bool)underlining
//{
//    
//    SKSpriteNode *backgroundNode = (SKSpriteNode *)[self childNodeWithName:kMHOldTextualElementNodeBackgroundNodeName];
//    if (backgroundColor) {
//        if (!backgroundNode) {
//            // Create the background node
//            // FIXME: here, I tried using the MHShapeNode +rectangleWithSize:andColor: method for the background node, but it produced a node with a different color than I expected. This suggests a problem with the MHShapeNode code, investigate it at some point.
//            backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor size:CGSizeMake(_dimensions.width, _dimensions.depth+_dimensions.height)];
//            backgroundNode.name = kMHOldTextualElementNodeBackgroundNodeName;
//            backgroundNode.anchorPoint = CGPointMake(0.0, _dimensions.depth/(_dimensions.depth+_dimensions.height));
//            backgroundNode.zPosition = -100.0;
//            [self addChild:backgroundNode];
//        }
//        else
//            backgroundNode.color = backgroundColor;
//    }
//    else {
//        [backgroundNode removeFromParent];  // no need for a background.
//    }
//}
//
//- (CGRect)frame
//{
//    // Not sure if this will ever be needed, so logging a message to help detect if someone tries to use the method
//    NSLog(@"FIXME: MHTextualElement frame method called");
//    return super.frame;
//}
//
//- (void)renderInCGContext:(CGContextRef)context
//{
////    CGPathRef myPath = self.path;
////    if (myPath) {
//        CGContextSaveGState(context);
//        
//        SKSpriteNode *backgroundNode = (SKSpriteNode *)[self childNodeWithName:kMHOldTextualElementNodeBackgroundNodeName];
//        if (backgroundNode) {
//            CGContextSetFillColorWithColor(context, [backgroundNode.color CGColor]);
//            CGContextAddRect(context, backgroundNode.frame);
//            CGContextDrawPath(context, kCGPathFill);
//        }
//
//    // FIXME: commenting out this code. Now the drawing of the path is only carried out by the subclasses MHOldTextNode and MHOldGlyphNode. Not good OO programming practice at all, so needs to be refactored.
////        CGContextAddPath(context, myPath);
////        CGContextSetLineWidth(context, 0.25);       // FIXME: this is kind of arbitrary but produces nice-looking results
////        CGContextSetFillColorWithColor(context, [self.fillColor CGColor]);
////        CGContextSetStrokeColorWithColor(context, [self.strokeColor CGColor]);
////        CGContextDrawPath(context, kCGPathFillStroke);
//        
//        CGContextRestoreGState(context);
////    }
//}
//
//
//
//@end
