////
////  MHSpace.m
////  MadHat
////
////  Created by Dan Romik on 10/20/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//#import <SpriteKit/SpriteKit.h>
//#import "MHSpace.h"
//
//
//#define kMHSpaceWideWidthFactor                 1.2
//#define kMHSpaceQuadWidthFactor                 2.0
//#define kMHSpaceQQuadWidthFactor                4.0
//#define kMHSpaceHalfSpaceWidthFactor            0.5     // If I ever change this value, it would make sense to rename the space type and constant
//
//
//@implementation MHSpace
//
//
//#pragma mark - Constructor methods
//
//- (instancetype)initWithType:(MHSpaceType)type
//{
//    if (self = [super init]) {
//        _type = type;
//    }
//    return self;
//}
//
//+ (instancetype)space
//{
//    return [self spaceWithType:MHSpaceTypeNormal];
//}
//
//+ (instancetype)spaceWithType:(MHSpaceType)type
//{
//    return [[self alloc] initWithType:type];
//}
//
//
//
//
//
//
//#pragma mark - Properties
//
//- (NSString *)stringValue
//{
//    return (_type == MHSpaceTypeLogical ? @"" : @" ");
//}
//
//- (MHTypographyClass)typographyClass
//{
//    return (_type == MHSpaceTypeLogical ? MHTypographyClassNone : MHTypographyClassWhiteSpace);
//}
//
//- (CGFloat)widthWithContextManager:(MHTypesettingContextManager *)contextManager
//{
//    MHExpressionPresentationMode myPresentationMode = self.presentationMode;
//    NSFont *font = [contextManager textFontForPresentationMode:myPresentationMode nestingLevel:self.nestingLevel];
//    CGFloat interWordSpace = [@" " sizeWithAttributes:@{NSFontAttributeName : font}].width;
//
//    switch (_type) {
//        case MHSpaceTypeHalf:
//            return interWordSpace * kMHSpaceHalfSpaceWidthFactor;
//        case MHSpaceTypeNormal:
//            return interWordSpace;
//        case MHSpaceTypeWide:
//            return interWordSpace * kMHSpaceWideWidthFactor;
//            break;
//        case MHSpaceTypeQuad:
//            return interWordSpace * kMHSpaceQuadWidthFactor;
//        case MHSpaceTypeQQuad:
//            return interWordSpace * kMHSpaceQQuadWidthFactor;
//        case MHSpaceTypeLogical:
//        case MHSpaceTypeOther:
//            return 0.0;
//    }
//}
//
//
//
//#pragma mark - typeset method
//
//- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
//{
//    [super typesetWithContextManager:contextManager];
//    
//    MHDimensions myDimensions;
//    
//    MHExpressionPresentationMode myPresentationMode = self.presentationMode;
//
//    myDimensions.height = (myPresentationMode == MHExpressionPresentationModePublishing ? 0.0 : 4.0);
//    myDimensions.depth = 0.0;
//
//    // FIXME: this setup makes some redundant method calls, retrieving the font and presentation mode twice - improve?
//    NSFont *font = [contextManager textFontForPresentationMode:myPresentationMode nestingLevel:self.nestingLevel];
//    myDimensions.width = [self widthWithContextManager:contextManager];
////    CGFloat interWordSpace = [@" " sizeWithAttributes:@{NSFontAttributeName : font}].width;
////
////    switch (_type) {
////        case MHSpaceTypeHalf:
////            myDimensions.width = interWordSpace * kMHSpaceHalfSpaceWidthFactor;
////            break;
////        case MHSpaceTypeNormal:
////            myDimensions.width = interWordSpace;
////            break;
////        case MHSpaceTypeWide:
////            myDimensions.width = interWordSpace * kMHSpaceWideWidthFactor;
////            break;
////        case MHSpaceTypeQuad:
////            myDimensions.width = interWordSpace * kMHSpaceQuadWidthFactor;
////            break;
////        case MHSpaceTypeQQuad:
////            myDimensions.width = interWordSpace * kMHSpaceQQuadWidthFactor;
////            break;
////        case MHSpaceTypeLogical:
////        case MHSpaceTypeOther:
////            myDimensions.width = 0.0;
////            break;
////    }
//    
//    NSColor *backgroundColor = contextManager.textHighlightColor;
//    if (backgroundColor) {
////        NSDictionary *attributesDict = @{
////            NSFontAttributeName : font
////        };
////        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@" "
////                                                                               attributes:attributesDict];
////        NSSize textSize = [attributedString size];
////        NSRect textRect = [@" " boundingRectWithSize:textSize options:0 attributes:attributesDict];
//
//        CGFloat ascender = font.ascender;
//        CGFloat descender = font.descender;
//        SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor size:CGSizeMake(myDimensions.width+2, ascender-descender)];
//        backgroundNode.anchorPoint = CGPointZero;
//        backgroundNode.position = CGPointMake(-1,descender);
//        backgroundNode.zPosition = -100.0;
//
////        SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, descender, myDimensions.width, -descender+ascender)];
////        decorationNode.fillColor = backgroundColor;
////        decorationNode.strokeColor = backgroundColor;
////        decorationNode.lineWidth = 0.0;
////        decorationNode.zPosition = -10.0;
//        [_spriteKitNode removeAllChildren];
//        [_spriteKitNode addChild:backgroundNode];
//    }
//
//    
//    self.dimensions = myDimensions;
//}
//
//
//
//#pragma mark - Instance methods
//
//
//- (void)makeWider
//{
//    switch (_type) {
//        case MHSpaceTypeLogical:
//            _type = MHSpaceTypeHalf;
//            break;
//        case MHSpaceTypeHalf:
//            _type = MHSpaceTypeNormal;
//            break;
//        case MHSpaceTypeNormal:
//            _type = MHSpaceTypeWide;
//            break;
//        case MHSpaceTypeWide:
//            _type = MHSpaceTypeQuad;
//            break;
//        case MHSpaceTypeQuad:
//            _type = MHSpaceTypeQQuad;
//            break;
//        case MHSpaceTypeQQuad:
//        case MHSpaceTypeOther:
//            break;
//    }
//}
//
//- (SKNode *)spriteKitNode
//{
//    if (!_spriteKitNode) {
//        switch (self.presentationMode) {
//            case MHExpressionPresentationModePublishing:
//                return super.spriteKitNode;
//            case MHExpressionPresentationModeEditing:
//                _spriteKitNode = [SKSpriteNode spriteNodeWithColor:[NSColor colorWithRed:0 green:1 blue:0 alpha:0.3]
//                                                              size:CGSizeMake(self.dimensions.width, 4.0)];
//                ((SKSpriteNode *)_spriteKitNode).anchorPoint = CGPointZero;
//                _spriteKitNode.ownerExpression = self;
//                return _spriteKitNode;
//        }
//    }
//    return _spriteKitNode;
//}
//
//
//#pragma mark - Expression copying
//
//- (instancetype)logicalCopy
//{
//    MHSpace *myCopy = [[self class] spaceWithType:_type];
//    myCopy.codeRange = self.codeRange;
//    return myCopy;
//}
//
//
//
//
//
//#pragma mark - Debugging
//
//- (NSString *)description
//{
//    NSString *typeString;
//    switch (_type) {
//        case MHSpaceTypeHalf:
//            typeString = @"half";
//            break;
//        case MHSpaceTypeNormal:
//            typeString = @"interword";
//            break;
//        case MHSpaceTypeWide:
//            typeString = @"wide";
//            break;
//        case MHSpaceTypeQuad:
//            typeString = @"quad";
//            break;
//        case MHSpaceTypeQQuad:
//            typeString = @"qquad";
//            break;
//        case MHSpaceTypeLogical:
//            typeString = @"logical";
//            break;
//        case MHSpaceTypeOther:
//            typeString = @"(unknown)";
//            break;
//    }
//
//    return [NSString stringWithFormat:@"<%@ %@>", [self className], typeString];
//}
//
//
//
//@end
