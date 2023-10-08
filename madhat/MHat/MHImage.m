//
//  MHImage.m
//  MadHat
//
//  Created by Dan Romik on 10/18/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHImage.h"
#import "MHStyleIncludes.h"

NSString * const kMHImageCommandName = @"image";
NSString * const kMHImageMadHatLogoCommandName = @"madhat logo";

// FIXME: these definitions are for the logo. It's a bit of a hack but I'm scaling down the image and vertically offsetting it - improve
#define kMHImageMadHatLogoScalingFactor 0.14
#define kMHImageMadHatLogoVOffset (0.0)

NSString * const kMHImageMissingImageResourceName = @"missing-image.png";
NSString * const kMHImageMadHatLogoResourceName = @"madhat-logo-small.png";

NSString * const kMHImageScaleAttributeName = @"scale";
NSString * const kMHImageXScaleAttributeName = @"scale width";
NSString * const kMHImageYScaleAttributeName = @"scale height";
NSString * const kMHImageWidthAttributeName = @"width";
NSString * const kMHImageHeightAttributeName = @"height";
NSString * const kMHImageVOffsetAttributeName = @"raise";
NSString * const kMHImageNegativeVOffsetAttributeName = @"lower";   // similar to raise, but with the sign of the offset reversed
NSString * const kMHImageMathCenteringAttributeName = @"mathcenter";


typedef enum {
    MHImageTypeImageWithIdentifier = 0,
    MHImageTypeMadHatLogo = 1
} MHImageType;

@interface MHImage ()
{
    MHImageType _imageType;
    NSString *_imageIdentifier;
    NSImage *_image;
    CGFloat _xScale; // defaults to 1
    CGFloat _yScale; // defaults to 1
    CGFloat _widthOverride;     // defaults to -1 which means a specific width isn't specified
    CGFloat _heightOverride;    // defaults to -1 which means a specific width isn't specified
    CGFloat _vOffset;           // a distance by which the image is raised. Defaults to 0
    BOOL _mathCentering;
    BOOL _scalesWithFont;
}

@property CGFloat xScale;
@property CGFloat yScale;
@property CGFloat widthOverride;
@property CGFloat heightOverride;
@property CGFloat vOffset;
@property BOOL mathCentering;


@end

@implementation MHImage


#pragma mark - Constructors

+ (instancetype)imageWithImageIdentifier:(NSString *)identifier
{
    return [[self alloc] initWithImageType:MHImageTypeImageWithIdentifier imageIdentifier:identifier];
}

+ (instancetype)imageWithMadHatLogo
{
    return [[self alloc] initWithImageType:MHImageTypeMadHatLogo imageIdentifier:nil];
}

- (instancetype)initWithImageType:(MHImageType)imageType imageIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        _imageType = imageType;
        if (_imageType == MHImageTypeImageWithIdentifier) {
            _imageIdentifier = identifier;
            _xScale = 1.0;
            _yScale = 1.0;
            _vOffset = 0.0;
        }
        else {
            _xScale = kMHImageMadHatLogoScalingFactor;
            _yScale = kMHImageMadHatLogoScalingFactor;
            _vOffset = kMHImageMadHatLogoVOffset;
            _scalesWithFont = YES;
        }
        _widthOverride = -1;
        _heightOverride = -1;
    }
    return self;
}

#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHImageCommandName]) {
        NSString *imageIdentifier;
        CGFloat argumentProvidedScale = -1.0; // an initial value less than 0 signifies that no scale was provided
        NSUInteger argNumberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (argNumberOfDelimitedBlocks == 1) {
            imageIdentifier = [argument stringValue];
        }
        else {
            // at least two delimited blocks - in that case the first block will be read for the filename and the second block will provide the scale (defaults to 1 unless some other positive number is provided)
            imageIdentifier = [[argument expressionFromDelimitedBlockAtIndex:0] stringValue];
            argumentProvidedScale = [[argument expressionFromDelimitedBlockAtIndex:1] floatValue];
        }
        
        MHImage *imageExpression = [[self class] imageWithImageIdentifier:imageIdentifier];
        
        if (argumentProvidedScale > 0.0) {
            imageExpression.xScale = argumentProvidedScale;
            imageExpression.yScale = argumentProvidedScale;
        }

        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        if (attributes) {
            MHExpression *scaleExpression = attributes[kMHImageScaleAttributeName];
            if (scaleExpression) {
                CGFloat scale = [scaleExpression floatValue];
                if (scale > 0.0) {
                    imageExpression.xScale = scale;
                    imageExpression.yScale = scale;
                }
            }

            MHExpression *xScaleExpression = attributes[kMHImageXScaleAttributeName];
            if (xScaleExpression) {
                CGFloat xScale = [xScaleExpression floatValue];
                if (xScale >= 0.0) {
                    imageExpression.xScale = xScale;
                }
            }

            MHExpression *yScaleExpression = attributes[kMHImageYScaleAttributeName];
            if (yScaleExpression) {
                CGFloat yScale = [yScaleExpression floatValue];
                if (yScale >= 0.0) {
                    imageExpression.yScale = yScale;
                }
            }

            MHExpression *widthExpression = attributes[kMHImageWidthAttributeName];
            if (widthExpression) {
                CGFloat width = [widthExpression floatValue];
                if (width >= 0.0) {
                    imageExpression.widthOverride = width;
                }
            }

            MHExpression *heightExpression = attributes[kMHImageHeightAttributeName];
            if (heightExpression) {
                CGFloat height = [heightExpression floatValue];
                if (height >= 0.0) {
                    imageExpression.heightOverride = height;
                }
            }

            MHExpression *vOffsetExpression = attributes[kMHImageVOffsetAttributeName];
            if (vOffsetExpression) {
                imageExpression.vOffset = [vOffsetExpression floatValue];
            }

            MHExpression *negativeVOffsetExpression = attributes[kMHImageNegativeVOffsetAttributeName];
            if (negativeVOffsetExpression) {
                imageExpression.vOffset = -[negativeVOffsetExpression floatValue];
            }

            MHExpression *mathCenteringExpression = attributes[kMHImageMathCenteringAttributeName];
            if (mathCenteringExpression) {
                imageExpression.mathCentering = [mathCenteringExpression boolValue];
            }

        }
        return imageExpression;
    }
    if ([name isEqualToString:kMHImageMadHatLogoCommandName]) {
        return [[self class] imageWithMadHatLogo];
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHImageCommandName, kMHImageMadHatLogoCommandName ];
}


#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    if (_imageType == MHImageTypeImageWithIdentifier)
        _image = [contextManager imageResourceForIdentifier:_imageIdentifier];
    else if (_imageType == MHImageTypeMadHatLogo) {
        _image = [NSImage imageNamed:kMHImageMadHatLogoResourceName];
    }
    
    if (!_image) {
        _image = [NSImage imageNamed:kMHImageMissingImageResourceName];
    }
    
    NSSize imageSize = [_image size];
    MHDimensions myDimensions;
    
    SKTexture *texture = [SKTexture textureWithImage:_image];
    SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithTexture:texture];
    spriteNode.anchorPoint = CGPointZero;
    SKNode *spriteKitNode = self.spriteKitNode;
    
    CGFloat actualXScale;
    CGFloat actualYScale;
        
    if (_widthOverride < 0) {
        if (_heightOverride < 0) {
            myDimensions.width = _xScale * imageSize.width;
            actualXScale = _xScale;
            myDimensions.height = _yScale * imageSize.height;
            actualYScale = _yScale;
        }
        else {
            myDimensions.width = _heightOverride / imageSize.height * imageSize.width;
            actualXScale = _heightOverride / imageSize.height;
            myDimensions.height = _heightOverride;
            actualYScale = _heightOverride / imageSize.height;
        }
    }
    else {
        if (_heightOverride < 0) {
            myDimensions.width = _widthOverride;
            actualXScale = _widthOverride / imageSize.width;
            myDimensions.height = _widthOverride / imageSize.width * imageSize.height;
            actualYScale = _widthOverride / imageSize.width;
        }
        else {
            myDimensions.width = _widthOverride;
            actualXScale = _widthOverride / imageSize.width;
            myDimensions.height = _heightOverride;
            actualYScale = _heightOverride / imageSize.height;
        }
    }
    
    if (_scalesWithFont) {
        static CGFloat defaultFontSizeAssumptionForScaling = 16.0;
        CGFloat fontSize = [contextManager baseFontSize];
        CGFloat scalingFactor = fontSize / defaultFontSizeAssumptionForScaling;
        actualXScale = actualXScale * scalingFactor;
        actualYScale = actualYScale * scalingFactor;
        myDimensions.width = myDimensions.width * scalingFactor;
        myDimensions.height = myDimensions.height * scalingFactor;
        myDimensions.depth = myDimensions.depth * scalingFactor;
    }
    
    spriteKitNode.xScale = actualXScale;
    spriteKitNode.yScale = actualYScale;
    
    [spriteKitNode removeAllChildren];
    [spriteKitNode addChild:spriteNode];
    
    CGFloat mathCenteringVOffset = 0.0;
    
    if (_mathCentering) {
        CGFloat mathAxisHeight = [contextManager mathAxisHeightForNestingLevel:self.nestingLevel];
        mathCenteringVOffset = mathAxisHeight - actualYScale * imageSize.height/2.0;
    }
    
    CGFloat totalVOffset = _vOffset + mathCenteringVOffset;

    spriteNode.position = CGPointMake(0.0, totalVOffset / actualYScale);

    if (totalVOffset >= 0) {
        myDimensions.height += totalVOffset;
    }
    else {
        myDimensions.height = fmax(myDimensions.height + totalVOffset, 0.0);
        myDimensions.depth = -totalVOffset;
    }

    self.dimensions = myDimensions;
    
}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        SKTexture *texture = [SKTexture textureWithImage:_image];
        SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithTexture:texture];
        _spriteKitNode = spriteNode;
    }
    return _spriteKitNode;
}

- (MHTypographyClass)typographyClass
{
    return MHTypographyClassCompoundExpression;     // FIXME: is this the best option?
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHImage *myCopy = [[self class] imageWithImageIdentifier:[_imageIdentifier copy]];
    myCopy.xScale = _xScale;
    myCopy.yScale = _yScale;
    myCopy.widthOverride = _widthOverride;
    myCopy.heightOverride = _heightOverride;
    myCopy.vOffset = _vOffset;
    myCopy.mathCentering = _mathCentering;
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


#pragma mark - Rendering to a PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    // FIXME: still a bit buggy
    CGContextRef pdfContext = contextManager.pdfContext;
    
    MHDimensions myDimensions = self.dimensions;
    CGContextTranslateCTM(pdfContext, 0.0, _vOffset);
    
    CGRect imageRect = CGRectMake(0.0, 0.0, myDimensions.width, myDimensions.height);
    CGImageRef cgImage = [_image CGImageForProposedRect:&imageRect context:[NSGraphicsContext currentContext] hints:nil];
    
    CGContextDrawImage(pdfContext, CGRectMake(0.0, 0.0, myDimensions.width, myDimensions.height), cgImage);
    CGContextTranslateCTM(pdfContext, 0.0, -_vOffset);
}

@end
