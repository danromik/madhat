////
////  MHSpace.h
////  MadHat
////
////  Created by Dan Romik on 10/20/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//#import "MHExpression.h"
//
//typedef enum {
//    MHSpaceTypeNormal,      // A normal space such as the one between two words
//    MHSpaceTypeWide,        // A wider space used to separate between sentences in a text paragraph
//    MHSpaceTypeQuad,
//    MHSpaceTypeQQuad,
//    MHSpaceTypeHalf,
//    MHSpaceTypeLogical,     // in math mode, an invisible space that signals a semantic separation between different quantities. In certain algebra contexts it will be interpteted as an implicit multiplication operator
//    MHSpaceTypeOther        // can be used by subclasses
//} MHSpaceType;
//NS_ASSUME_NONNULL_BEGIN
//
//@interface MHSpace : MHExpression
//
//@property MHSpaceType type;
//
//+ (instancetype)space;
//+ (instancetype)spaceWithType:(MHSpaceType)type;
//
//- (instancetype)initWithType:(MHSpaceType)type;
//
//- (void)makeWider;
//
//- (CGFloat)widthWithContextManager:(MHTypesettingContextManager *)contextManager;   // can be overridden by subclasses to modify behavior
//
//
//@end
//
//NS_ASSUME_NONNULL_END
