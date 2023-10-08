////
////  MHTextAtom.m
////  MadHat
////
////  Created by Dan Romik on 10/20/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//
//// If this #define is in effect, the code will use the new experimental SKSimpleTextNode class I'm developing to render the text
//// Otherwise the older code is used based on SKLabelNode
//#define USE_SKSimpleTextNode
//
//
//
//
//#import <SpriteKit/SpriteKit.h>
//#import "MHTextAtom.h"
//#import "MHTypesettingContextManager.h"
//
//#ifdef USE_SKSimpleTextNode
//#import "SKSimpleTextNode.h"
//#endif
//
//
//
//@implementation MHTextAtom
//
//
//#pragma mark - Constructor methods
//
//- (instancetype)initWithString:(NSString *)string
//{
//    if (self = [super init]) {
//        _text = string;
//    }
//    return self;
//}
//
//+ (instancetype)atomWithString:(NSString *)string
//{
//    return [[self alloc] initWithString:string];
//}
//
//
//#pragma mark - Properties
//
//- (MHTypographyClass)typographyClass
//{
//    return MHTypographyClassText;
//}
//
//- (bool)usesGlyphEncoding
//{
//    return false;
//}
//
//- (NSString *)stringValue
//{
//    return self.text;
//}
//
//
//
//
//
//
//
//
//#pragma mark - typeset and spriteKitNode methods
//
//
//- (SKNode *)spriteKitNode
//{
//    if (!_spriteKitNode) {
//#ifndef USE_SKSimpleTextNode
//        _spriteKitNode = [SKLabelNode node];
//        ((SKLabelNode *)_spriteKitNode).horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
//#endif
//
//#ifdef USE_SKSimpleTextNode
////        _spriteKitNode = [SKSimpleTextNode textNodeWithString:_text]; // original code before adding MHMultiformMathAtom class
//        
//        _spriteKitNode = [SKSimpleTextNode textNodeWithString:self.text];   // new code, makes things work since MHMultiformMathAtom class dynamically figures out the value of the text property based on the nesting level. FIXME: this is very bad, non-OO coding. Also inefficient since most of the time it's fine to use a static variable property. NEEDS IMPROVEMENT!!!
//#endif
//
//        _spriteKitNode.ownerExpression = self;
//    }
//    return _spriteKitNode;
//}
//
//
//- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
//{
//    NSFont *font;
//    
//    MHTypographyClass typographyClass = self.typographyClass;
//
//    if (typographyClass == MHTypographyClassText) {
//        font = [contextManager textFontForPresentationMode:self.presentationMode nestingLevel:self.nestingLevel];
//    }
//    else if (typographyClass == MHTypographyClassItalicMathVariable) {
//        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitItalic];
//    }
//    else {
//        font = [contextManager mathFontForNestingLevel:self.nestingLevel traits:MHMathFontTraitRoman];
//    }
//    
//    
//#ifndef USE_SKSimpleTextNode
//    // old code (commenting out for experimentation with new SKSimpleTextNode class)
//    NSDictionary *attributesDict = @{
//        NSFontAttributeName : font,
//        NSForegroundColorAttributeName : contextManager.textForegroundColor
//    };
//    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:_text
//                                                                           attributes:attributesDict];
//    NSSize textSize = [attributedString size];
//
//    ((SKLabelNode *)_spriteKitNode).attributedText = attributedString;
//
//    MHDimensions myDimensions;
//
////    NSRect textRect = [_text boundingRectWithSize:textSize options:0 attributes:attributesDict];
//    NSRect textRect = [attributedString boundingRectWithSize:textSize options:0];
//
//    myDimensions.width = textSize.width;
//    myDimensions.height = textSize.height+textRect.origin.y;
//    myDimensions.depth = -textRect.origin.y;
//
//    self.dimensions = myDimensions;
//
//    NSColor *backgroundColor = contextManager.textHighlightColor;
//    if (backgroundColor) {
//        SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, -myDimensions.depth, myDimensions.width, myDimensions.height+myDimensions.depth)];
////        SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, _spriteKitNode.frame.size.width, _spriteKitNode.frame.size.height)];
//        decorationNode.fillColor = backgroundColor;
//        decorationNode.strokeColor = [NSColor clearColor];
//        decorationNode.zPosition = -10.0;
//        [_spriteKitNode removeAllChildren];
//        [_spriteKitNode addChild:decorationNode];
//    }
//#endif
//
//    
//    
//    
//#ifdef USE_SKSimpleTextNode
//    
//    
////  new code:
//    MHDimensions myDimensions;
//    
//    NSColor *color = contextManager.textForegroundColor;
//    NSColor *backgroundColor = contextManager.textHighlightColor;
//    
//    SKSimpleTextNode *textNode = (SKSimpleTextNode *)(self.spriteKitNode);
//    MHDimensions dims =
//            [textNode configureWithFont:font color:color backgroundColor:backgroundColor textIsGlyphName:self.usesGlyphEncoding];
//
//    // FIXME: this case division is an ugly hack, improve
//    if (dims.width > 0.0) {
//        myDimensions = dims;
//    }
//    else {
//        CGRect textRect = textNode.frame;
//        myDimensions.width =  textRect.size.width;
//        myDimensions.height = font.ascender; // textRect.size.height;
//        myDimensions.depth = -font.descender; // 0;
//    }
//
////    myDimensions.height = textRect.origin.y + textRect.size.height;
////    myDimensions.depth = -textRect.origin.y;
//
//    self.dimensions = myDimensions;
//    
//#endif
//    
////    if (wasNotItalic) {
////        self.contextManager.italic = false;
////    }
//}
//
//
//
//
//
//
//#pragma mark - Debugging
//
//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@ text='%@'>", [self className], (self.text ? self.text : @"")];
//}
//
//
//@end
