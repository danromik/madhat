////
////  MHOldTextualElementNode.h
////  MadHat
////
////  Created by Dan Romik on 7/10/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
////  Class description: an abstract class representing an element of text, such as a string of text or a glyph from a font
////
//
//#import "MadHat.h"
//#import "MHShapeNode.h"
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface MHOldTextualElementNode : MHShapeNode
//{
//@protected
//    MHDimensions _dimensions;       // subclasses can access this
//}
//
//@property (readonly) MHDimensions dimensions;   // subclasses should calculate the dimensions and set this property
//
//// Subclasses should implement this. This is where the node is configured and the dimensions are calculated
//// The default implementation takes care of a colored background, subclasses should call [super configureWithFont:...] at the end of their
//// implementation to use that functionality
//// FIXME: underlining isn't implemented here but in MHTextAtom, make sure all the classes do it correctly and find a way to avoid repetition of code
//- (void)configureWithFont:(NSFont *)font
//                    color:(NSColor *)color
//          backgroundColor:(nullable NSColor *)backgroundColor
//              underlining:(bool)underlining;
//
//
//// This is also implemented, so subclasses do not need to implement unless they add additional subnodes with various graphical decorations
//- (void)renderInCGContext:(CGContextRef)context;
//
//
//@end
//
//NS_ASSUME_NONNULL_END
