//
//  MHShapeNode.h
//  MadHat
//
//  This version created by Dan Romik on 7/9/20.
//
//  This is a modified version of the SKUShapeNode class that's part of the SKUtilities2 package
//
//  Summary of the changes from the SKUShapeNode class:
//  * converted return type of convenience constructors to instancetype to modernize code and make the class easier to subclass

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <SpriteKit/SpriteKit.h>
#import <CoreGraphics/CoreGraphics.h>


#if TARGET_OS_IPHONE
#define SKUImage UIImage
#define SKUFont UIFont
#else
#define SKUImage NSImage
#define SKUFont NSFont
#define TARGET_OS_OSX_SKU 1
#endif


/*!
 Apple's shape generator for SpriteKit causes performance issues. Shapes are rerendered each frame, despite a lack of change in appearance. You can cheat by parenting it to an SKEffectNode and setting it to rasterize. However, any changes cause it to rerender with high cpu usage. It also has low quality anti aliasing. Instead, you can use this class. MHShapeNode uses CAShapeLayer to render a shape, which is slightly more costly than the rendering of the SKShapeNode, but once it's rendered, is cached as a bitmap and renders very quickly in SpriteKit thereafter. TLDR: SpriteKit's shape node fast redner, slow draw. MHShapeNode is slow render, fast draw.
 */
@interface MHShapeNode : SKNode <NSCopying>

/*! @group MHShapeNode Properties */

/*!
 The CGPath to be drawn (in the Node's coordinate space) (will only redraw the image if the path is non-nil, so it's best to set the path as the last property and save some CPU cycles)
 */
@property (nonatomic) CGPathRef path;

/*!
 The color to draw the path with. (for no stroke use [SKColor clearColor]). Defaults to [SKColor whiteColor].
 */
@property (nonatomic, retain) SKColor *strokeColor;

/*!
 The color to fill the path with. Defaults to [SKColor clearColor] (no fill).
 */
@property (nonatomic, retain) SKColor *fillColor;

/*!
 The width used to stroke the path. Widths larger than 2.0 may result in artifacts. Defaults to 1.0.
 */
@property (nonatomic) CGFloat lineWidth;


/*! The fill rule used when filling the path. Options are `non-zero' and
 * `even-odd'. Defaults to `non-zero'. */
@property (nonatomic, assign) NSString* fillRule;
/*!
 Boolean determining whether to anti-alias the rendered image.
 */
@property (nonatomic, assign) BOOL antiAlias;
/*!
 See CAShapeLayer for information on this.
 */
@property (nonatomic, assign) NSString* lineCap;
/*! Causing exceptions (at least on OSX) - keeping it in there cuz I BELIEVE the error is on Apple's side. Careful using this though. See CAShapeLayer for information. */
@property (nonatomic, assign) NSArray* lineDashPattern;
/*! Causing exceptions (at least on OSX) - keeping it in there cuz I BELIEVE the error is on Apple's side. Careful using this though. See CAShapeLayer for information. */
@property (nonatomic, assign) CGFloat lineDashPhase;
/*!
 See CAShapeLayer for information.
 */
@property (nonatomic, assign) NSString* lineJoin;
/*!
 Miter limit value for stroked paths.
 */
@property (nonatomic, assign) CGFloat miterLimit;
/*!
 Anchor point of the sprite.
 */
@property (nonatomic, assign) CGPoint anchorPoint;
/*!
 Readonly access to the rendered texture. MIGHT not be properly retina-ized.
 */
@property(nonatomic, readonly) SKTexture* texture;

/*! @methodgroup Initialization */

/*!
 Convenience method that creates and returns a new shape object in the shape of a circle.
 @brief circleWithRadius:andColor:
 @param radius radius of circle.
 @param color  Color of circle.
 @return MHShapeNode
 */
+(instancetype)circleWithRadius:(CGFloat)radius andColor:(SKColor*)color NS_SWIFT_NAME(init(circleWithRadius:andColor:));
/*!
 Convenience method that creates and returns a new shape object in the shape of a sqaure.
 @brief squareWithWidth:andColor:
 @param width Value that determines size of square.
 @param color Color of square
 @return MHShapeNode
 */
+(instancetype)squareWithWidth:(CGFloat)width andColor:(SKColor*)color NS_SWIFT_NAME(init(squareWithWidth:andColor:));
/*!
 Convenience method that creates and returns a new shape object in the shape of a rectanlge.
 @brief rectangleWithSize:andColor:
 @param size  CGSize value to make a rectange of.
 @param color Color of rectangle.
 @return MHShapeNode
 */
+(instancetype)rectangleWithSize:(CGSize)size andColor:(SKColor*)color NS_SWIFT_NAME(init(rectangleWithSize:andColor:));
/*!
 Convenience method that creates and returns a new shape object in the shape of a rounded rectangle.
 @brief rectangleRoundedWithSize:andCornerRadius:andColor:
 @param size   CGSize value to make a rectangle of.
 @param radius Radius value for corners
 @param color  Color of shape
 @return MHShapeNode
 */
+(instancetype)rectangleRoundedWithSize:(CGSize)size andCornerRadius:(CGFloat)radius andColor:(SKColor*)color NS_SWIFT_NAME(init(rectangleRoundedWithSize:andCornerRadius:andColor:));
/*!
 Convenience method that creates and returns a new shape object in the shape of the provided path.
 @brief shapeWithPath:andColor:
 @param path  CGPathRef path to make a shape out of. A copy is made, so you are responsible for releasing this reference.
 @param color Color to make shape.
 @return MHShapeNode
 */
+(instancetype)shapeWithPath:(CGPathRef)path andColor:(SKColor*)color NS_SWIFT_NAME(init(shapeWithPath:andColor:));


@end
