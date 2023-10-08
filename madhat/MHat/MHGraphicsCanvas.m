//
//  MHGraphicsCanvas.m
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGraphicsCanvas.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"


// Default values for parameters
#define kMHGraphicsCanvasDefaultWidth       200.0
#define kMHGraphicsCanvasDefaultHeight      200.0
#define kMHGraphicsCanvasDefaultMinX        0.0
#define kMHGraphicsCanvasDefaultMaxX        10.0
#define kMHGraphicsCanvasDefaultMinY        0.0
#define kMHGraphicsCanvasDefaultMaxY        10.0


NSString * const kMHGraphicsCanvasCommandName = @"graphics canvas";

NSString * const kMHGraphicsAttributeWidthName = @"width";
//NSString * const kMHGraphicsAttributeDepthName = @"depth";
NSString * const kMHGraphicsAttributeHeightName = @"height";
NSString * const kMHGraphicsAttributeMinXName = @"min x";
NSString * const kMHGraphicsAttributeMaxXName = @"max x";
NSString * const kMHGraphicsAttributeMinYName = @"min y";
NSString * const kMHGraphicsAttributeMaxYName = @"max y";

NSString * const kMHGraphicsAttributeCropName = @"crop";
NSString * const kMHGraphicsAttributeFrameName = @"frame";

NSString * const kMHGraphicsCanvasFrameNodeName = @"frame_node";


@interface MHGraphicsCanvas ()
{
    bool _cropContents;
    bool _frameContents;
    
    // Ranges of x and y coordinates to show
    MHGraphicsRectangle _viewRectangle;
}

@end


@implementation MHGraphicsCanvas


#pragma mark - Constructor methods

+ (instancetype)graphicsCanvasWithDimensions:(MHDimensions)dimensions
                               viewRectangle:(MHGraphicsRectangle)viewRectangle
                                    contents:(MHExpression *)contents
                                cropContents:(bool)cropEnabled
                                   drawFrame:(bool)frameEnabled
{
    return [[self alloc] initWithDimensions:dimensions
                              viewRectangle:viewRectangle
                                   contents:contents
                               cropContents:cropEnabled
                                  drawFrame:frameEnabled];
}

- (instancetype)initWithDimensions:(MHDimensions)dimensions
                     viewRectangle:(MHGraphicsRectangle)viewRectangle
                          contents:(MHExpression *)contents
                      cropContents:(bool)cropEnabled
                         drawFrame:(bool)frameEnabled
{
    if (self = [super initWithContents:contents]) {
        self.dimensions = dimensions;
        _viewRectangle = viewRectangle;
        _cropContents = cropEnabled;
        _frameContents = frameEnabled;
    }
    return self;
}


#pragma mark - Properties

//- (bool)cropContents
//{
//    return _cropContents;
//}
//
//- (void)setCropContents:(bool)cropContents
//{
//    _cropContents = cropContents;
//}
//
//- (bool)frameContents
//{
//    return _frameContents;
//}
//
//- (void)setFrameContents:(bool)frameContents
//{
//    _frameContents = frameContents;
//}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHGraphicsCanvasCommandName]) {
        NSDictionary *attributes = argument.attributes;
        
        // Set some default values, which can be modified by specifying attributes
        MHDimensions dimensions;
        dimensions.width = kMHGraphicsCanvasDefaultWidth;
        dimensions.height = kMHGraphicsCanvasDefaultHeight;
        dimensions.depth = 0.0;
        
        MHGraphicsRectangle viewRectangle;
        viewRectangle.minX = kMHGraphicsCanvasDefaultMinX;
        viewRectangle.maxX = kMHGraphicsCanvasDefaultMaxX;
        viewRectangle.minY = kMHGraphicsCanvasDefaultMinY;
        viewRectangle.maxY = kMHGraphicsCanvasDefaultMaxY;

                
        bool cropContents = true;
        bool frameContents = false;
        
        if (attributes) {
            MHExpression *widthExpression = attributes[kMHGraphicsAttributeWidthName];
            if (widthExpression)
                dimensions.width = [widthExpression floatValue];
            
            MHExpression *heightExpression = attributes[kMHGraphicsAttributeHeightName];
            if (heightExpression)
                dimensions.height = [heightExpression floatValue];
            
            // Validate the width and height parameters. If they are invalid, revert to the default values
            if (dimensions.width < 1.0 || dimensions.height < 1.0 || dimensions.width > 10000 | dimensions.height > 10000) {
                dimensions.width = kMHGraphicsCanvasDefaultWidth;
                dimensions.height = kMHGraphicsCanvasDefaultHeight;
            }
            

            MHExpression *minXExpression = attributes[kMHGraphicsAttributeMinXName];
            if (minXExpression)
                viewRectangle.minX = [minXExpression floatValue];

            MHExpression *maxXExpression = attributes[kMHGraphicsAttributeMaxXName];
            if (maxXExpression)
                viewRectangle.maxX = [maxXExpression floatValue];

            MHExpression *minYExpression = attributes[kMHGraphicsAttributeMinYName];
            if (minYExpression)
                viewRectangle.minY = [minYExpression floatValue];

            MHExpression *maxYExpression = attributes[kMHGraphicsAttributeMaxYName];
            if (maxYExpression)
                viewRectangle.maxY = [maxYExpression floatValue];
            
            // Now validate the x and y coordinate range parameters. If they are invalid, revert to the default values
            // Of course the max x coordinate has to be greater than the min, and similarly for the y
            // In fact we'll be a little more strict and forbid the max x from being less than 10^(-8) to the right of the min x, and same for the y
            // We'll also forbid the max x from being greater than the min x by more than 10^8, and same for the y
            // This will prevent some strange/pathological things happening with rounding errors in affine transformation calculations
            // FIXME: these restrictions are sort of ad hoc, maybe think this through some more, and/or add a note in the documentation so that users are aware of the issue
            if (viewRectangle.maxX <= viewRectangle.minX+0.00000001
                || viewRectangle.maxY <= viewRectangle.minY+0.00000001
                || viewRectangle.maxX >= viewRectangle.minX+1000000000
                || viewRectangle.maxY >= viewRectangle.minY+1000000000) {
                viewRectangle.minX = kMHGraphicsCanvasDefaultMinX;
                viewRectangle.maxX = kMHGraphicsCanvasDefaultMaxX;
                viewRectangle.minY = kMHGraphicsCanvasDefaultMinY;
                viewRectangle.maxY = kMHGraphicsCanvasDefaultMaxY;
            }

            MHExpression *cropAttribute = attributes[kMHGraphicsAttributeCropName];
            if (cropAttribute)
                cropContents = [cropAttribute boolValue];
            
            MHExpression *frameAttribute = attributes[kMHGraphicsAttributeFrameName];
            if (frameAttribute)
                frameContents = [frameAttribute boolValue];
        }
        
        MHGraphicsCanvas *canvas = [self graphicsCanvasWithDimensions:dimensions
                                                        viewRectangle:viewRectangle
                                                             contents:argument
                                                         cropContents:cropContents
                                                            drawFrame:frameContents];
        
        return canvas;
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHGraphicsCanvasCommandName ];
}



#pragma mark - SpriteKit Node

- (SKNode *)spriteKitNode
{
    if (!_cropContents)
        return super.spriteKitNode;
    if (!_spriteKitNode) {
        SKNode *superSpriteKitNode = super.spriteKitNode;

        MHDimensions myDimensions = self.dimensions;

        if (myDimensions.depth + myDimensions.height == 0.0 || myDimensions.width == 0.0)
            return superSpriteKitNode;
        
        
        SKShapeNode *maskNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, -myDimensions.depth,
                                                                          myDimensions.width, myDimensions.depth+myDimensions.height)];
        maskNode.fillColor = [NSColor blackColor];
        SKCropNode *cropNode = [SKCropNode node];
        cropNode.maskNode = maskNode;
        _spriteKitNode = cropNode;

        [_spriteKitNode addChild:superSpriteKitNode];
    }
    return _spriteKitNode;
}


#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
//    SKNode *spriteKitNode = self.spriteKitNode;
//    [spriteKitNode removeAllChildren];        // FIXME: commenting it out, otherwise the contents don't show for obvious reasons. But need to think about removing existing nodes (which may be out of sync with the actual contents) without causing this effect
    
    MHDimensions myDimensions = self.dimensions;
    
    [contextManager beginGraphicsCanvas:myDimensions viewRectangle:_viewRectangle];
    
    [super typesetWithContextManager:contextManager];
    
    // FIXME: this code needs some work
    if (myDimensions.width == 0.0 || myDimensions.depth + myDimensions.height == 0.0) {
        CGRect frame = [_spriteKitNode calculateAccumulatedFrame];
        if (myDimensions.width == 0.0) {
            myDimensions.width = frame.origin.x + frame.size.width;
            if (myDimensions.width < 0.0)
                myDimensions.width = 0.0;
        }
        if (myDimensions.depth + myDimensions.height == 0.0) {
            myDimensions.depth = -frame.origin.y;
            if (myDimensions.depth < 0.0)
                myDimensions.depth = 0.0;
            myDimensions.height = frame.origin.y + frame.size.height;
            if (myDimensions.height < 0.0)
                myDimensions.height = 0.0;
        }
    }
    
    [[_spriteKitNode childNodeWithName:kMHGraphicsCanvasFrameNodeName] removeFromParent];
    if (_frameContents) {
        CGRect frameRect = CGRectMake(0.0, -myDimensions.depth, myDimensions.width, myDimensions.depth+myDimensions.height);
        SKShapeNode *frameNode = [SKShapeNode shapeNodeWithRect:frameRect];
        frameNode.strokeColor = contextManager.strokeColor; // FIXME: setting the color doesn't work since the contents are typeset inside a beginLocalScope/endLocalScope block
        frameNode.lineWidth = contextManager.lineThickness;
        frameNode.name = kMHGraphicsCanvasFrameNodeName;
        [_spriteKitNode addChild:frameNode];
    }

    self.dimensions = myDimensions; // FIXME: this is illogical but at the moment necessary because the superclass MHWrapper's typesetWithContextManager method sets the dimensions to the contents' dimensions, which in the current design we don't want to do. Leaving it here as a temporary workaround - improve
    
    // FIXME: this works but is not very elegant, seems computationally wasteful and may invite other kinds of trouble
    // A better solution may be to create a mechanism in the parser so that when content is parsed inside a graphics canvas environment, it is parsed into
    // an MHLinearContainer instead of into an MHHorizontalLayoutContainer. Then the code block below would be unnecessary, and the typesetting
    // of the contents wouldn't waste resources on horizontal layout that no one needs
    // (Anyway, this actually works well for now so leaving it for the time being to work on other improvements)
    MHExpression *myContents = self.contents;
    SKNode *mySpriteKitNode = self.spriteKitNode;
    if (myContents.splittable) {
        // Since the contents identify themselves as splittable, they can be safely assumed to conform to the MHSplittableExpression protocol
        NSArray <MHExpression *> *flattenedList = [(NSObject <MHSplittableExpression> *)myContents flattenedListOfUnsplittableComponents];
        for (MHExpression *subexpression in flattenedList) {
            CGPoint subexpPosition = [mySpriteKitNode convertPoint:CGPointZero toNode:subexpression.spriteKitNode.parent];
            subexpression.position = subexpPosition;
        }
    }
    
    [contextManager endGraphicsCanvas];
}

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    MHDimensions myDimensions = self.dimensions;
    SKNode *spriteKitNode = self.spriteKitNode;
    
    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);
    
    if (_cropContents) {
        CGContextClipToRect(pdfContext, CGRectMake(0.0, -myDimensions.depth, myDimensions.width, myDimensions.depth+myDimensions.height));
    }
    
    [self.contents renderToPDFWithContextManager:contextManager];

    if (_frameContents) {
        SKShapeNode *shapeNode = (SKShapeNode *)[spriteKitNode childNodeWithName:kMHGraphicsCanvasFrameNodeName];    // FIXME: this makes an assumption that the node is a shape node. Safe?
        CGContextSetStrokeColorWithColor(pdfContext, shapeNode.strokeColor.CGColor);
        CGContextSetLineWidth(pdfContext, shapeNode.lineWidth);
        
        CGContextAddPath(pdfContext, shapeNode.path);
        CGContextDrawPath(pdfContext, kCGPathStroke);
    }

    CGContextRestoreGState(pdfContext);
}


- (bool)splittable
{
    return false;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHGraphicsCanvas *myCopy = [[self class] graphicsCanvasWithDimensions:self.dimensions
                                                            viewRectangle:_viewRectangle
                                                                 contents:[self.contents logicalCopy]
                                                             cropContents:_cropContents
                                                                drawFrame:_frameContents];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


@end
