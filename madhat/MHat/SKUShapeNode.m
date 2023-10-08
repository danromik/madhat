////
//// SKUShapeNode class - extracted from SKUtilities2 package
////
//
//#import "SKUShapeNode.h"
//
//
//
//
//@interface SKUShapeNode() {
//    
//    CAShapeLayer* shapeLayer;
//    CAShapeLayer* outlineLayer;
//    
//    CGSize boundingSize;
//    
//    SKSpriteNode* drawSprite;
//    CGPoint defaultPosition;
//    
//    SKNode* null;
//}
//
//@end
//
//
//@implementation SKUShapeNode
//
//-(id)copyWithZone:(NSZone *)zone {
//    SKUShapeNode* shape = [SKUShapeNode node];
//    shape.strokeColor = _strokeColor.copy;
//    shape.fillColor = _fillColor.copy;
//    shape.lineWidth = _lineWidth;
//    shape.fillRule = _fillRule;
//    shape.lineCap = _lineCap;
//    shape.lineDashPattern = _lineDashPattern;
//    shape.lineDashPhase = _lineDashPhase;
//    shape.lineJoin = _lineJoin;
//    shape.miterLimit = _miterLimit;
//    shape.anchorPoint = _anchorPoint;
//    shape.path = _path;
//    return shape;
//}
//
//+(SKUShapeNode*)circleWithRadius:(CGFloat)radius andColor:(SKColor*)color{
//    CGRect rect = CGRectMake(-radius, -radius, radius*2.0, radius*2.0);
//    CGPathRef circle = CGPathCreateWithEllipseInRect(rect, NULL);
//    
//    SKUShapeNode* shapeNode = [SKUShapeNode node];
//    shapeNode.fillColor = color;
//    shapeNode.path = circle;
//    
//    CGPathRelease(circle);
//    
//    return shapeNode;
//}
//
//+(SKUShapeNode*)squareWithWidth:(CGFloat)width andColor:(SKColor*)color{
//    CGRect rect = CGRectMake(-width / 2.0, -width / 2.0, width, width);
//    CGPathRef square = CGPathCreateWithRect(rect, NULL);
//    
//    SKUShapeNode* shapeNode = [SKUShapeNode node];
//    shapeNode.fillColor = color;
//    shapeNode.path = square;
//    
//    CGPathRelease(square);
//    
//    return shapeNode;
//}
//
//+(SKUShapeNode*)rectangleWithSize:(CGSize)size andColor:(SKColor*)color{
//    CGRect rect = CGRectMake(-size.width / 2.0, -size.height / 2.0, size.width, size.height);
//    CGPathRef rectPath = CGPathCreateWithRect(rect, NULL);
//    
//    SKUShapeNode* shapeNode = [SKUShapeNode node];
//    shapeNode.fillColor = color;
//    shapeNode.path = rectPath;
//    
//    CGPathRelease(rectPath);
//    
//    return shapeNode;
//}
//
//+(SKUShapeNode*)rectangleRoundedWithSize:(CGSize)size andCornerRadius:(CGFloat)radius andColor:(SKColor*)color{
//    CGRect rect = CGRectMake(-size.width / 2.0, -size.height / 2.0, size.width, size.height);
//    CGPathRef rectPath = CGPathCreateWithRoundedRect(rect, radius, radius, NULL);
//    
//    SKUShapeNode* shapeNode = [SKUShapeNode node];
//    shapeNode.fillColor = color;
//    shapeNode.path = rectPath;
//    
//    CGPathRelease(rectPath);
//    
//    return shapeNode;
//}
//
//+(SKUShapeNode*)shapeWithPath:(CGPathRef)path andColor:(SKColor *)color {
//    SKUShapeNode* shapeNode = [SKUShapeNode node];
//    shapeNode.fillColor = color;
//    shapeNode.path = path;
//    return shapeNode;
//}
//-(id)init {
//    
//    if (self = [super init]) {
//        
//        self.name = @"SKUShapeNode";
//        
//        null = [SKNode node];
//        null.name = @"SKUShapeNodeNULL";
//        [self addChild:null];
//        
//        drawSprite = [SKSpriteNode node];
//        drawSprite.name = @"SKUShapeNodeDrawSprite";
//        [null addChild:drawSprite];
//        _strokeColor = [SKColor whiteColor];
//        _fillColor = [SKColor clearColor];
//        _lineWidth = 0.0;
//        _fillRule = kCAFillRuleNonZero;
//        _lineCap = kCALineCapButt;
//        _lineDashPattern = nil;
//        _lineDashPhase = 0;
//        _lineJoin = kCALineJoinMiter;
//        _miterLimit = 10.0;
//        _antiAlias = YES;
//        
//        _anchorPoint = CGPointMake(0.5, 0.5);
//    }
//    
//    return self;
//}
//
//-(CGLineCap)CGLineCapFromStringEnum:(NSString*)stringEnum {
//    CGLineCap lineCapEnum = kCGLineCapSquare;
//    if ([stringEnum isEqualToString:kCALineCapSquare]) {
//        lineCapEnum = kCGLineCapSquare;
//    } else if ([stringEnum isEqualToString:kCALineCapRound]) {
//        lineCapEnum = kCGLineCapRound;
//    } else if ([stringEnum isEqualToString:kCALineCapButt]) {
//        lineCapEnum = kCGLineCapButt;
//    }
//    return lineCapEnum;
//}
//
//-(CGLineJoin)CGLineJoinFromStringEnum:(NSString*)stringEnum {
//    CGLineJoin lineJoinEnum = kCGLineJoinMiter;
//    if ([stringEnum isEqualToString:kCALineJoinBevel]) {
//        lineJoinEnum = kCGLineJoinBevel;
//    } else if ([stringEnum isEqualToString:kCALineJoinMiter]) {
//        lineJoinEnum = kCGLineJoinMiter;
//    } else if ([stringEnum isEqualToString:kCALineJoinRound]) {
//        lineJoinEnum = kCGLineJoinRound;
//    }
//    return lineJoinEnum;
//}
//
//-(void)redrawTexture {
//    
//    if (!_path) {
//        return;
//    }
//    
//    if (!shapeLayer) {
//        shapeLayer = [CAShapeLayer layer];
//        outlineLayer = [CAShapeLayer layer];
//        [shapeLayer addSublayer:outlineLayer];
//    }
//    
//    shapeLayer.strokeColor = [[SKColor clearColor] CGColor];
//    shapeLayer.fillColor = [_fillColor CGColor];
//    shapeLayer.lineWidth = 0;
//    shapeLayer.fillRule = _fillRule;
//
//
//    
//    CGRect enclosure = CGPathGetPathBoundingBox(_path);
////    SKULog(0,@"bounding: %f %f %f %f", enclosure.origin.x, enclosure.origin.y, enclosure.size.width, enclosure.size.height);
//    CGPoint enclosureOffset;
//    
//    if (![_strokeColor isEqual:[SKColor clearColor]]) {
//        enclosureOffset = CGPointMake(enclosure.origin.x - _lineWidth, enclosure.origin.y - _lineWidth);
//    } else {
//        enclosureOffset = CGPointMake(enclosure.origin.x, enclosure.origin.y);
//    }
//    
//    CGAffineTransform transform = CGAffineTransformMake(1, 0, 0, 1, -enclosureOffset.x, -enclosureOffset.y);
//    CGPathRef newPath = CGPathCreateCopyByTransformingPath(_path, &transform);
//    
//    CGPathRef outlinePath = NULL;
//    if (_lineWidth > 0) {
//        CGLineCap lineCapEnum = [self CGLineCapFromStringEnum:_lineCap];
//        CGLineJoin lineJoinEnum = [self CGLineJoinFromStringEnum:_lineJoin];
//        if (_lineDashPattern.count > 0 && _lineDashPhase > 0) {
//            NSUInteger lengthCount = _lineDashPattern.count;
//            CGFloat lengths[lengthCount];
//            for (uint32_t i = 0; i < _lineDashPattern.count; i++) {
//                lengths[i] = [_lineDashPattern[i] doubleValue];
//            }
//            CGPathRef dashPath = CGPathCreateCopyByDashingPath(newPath, NULL, 0, lengths, lengthCount);
//            outlinePath = CGPathCreateCopyByStrokingPath(dashPath, NULL, _lineWidth, lineCapEnum, lineJoinEnum, _miterLimit);
//            CGPathRelease(dashPath);
//        } else {
//            outlinePath = CGPathCreateCopyByStrokingPath(newPath, NULL, _lineWidth, lineCapEnum, lineJoinEnum, _miterLimit);
//        }
//    }
//    outlineLayer.strokeColor = [[SKColor clearColor] CGColor];
//    outlineLayer.fillColor = [_strokeColor CGColor];
//    outlineLayer.lineWidth = 0;
//    outlineLayer.fillRule = _fillRule;
//    
//    shapeLayer.path = newPath;
//    if (_lineWidth > 0 && outlinePath) {
//        outlineLayer.path = outlinePath;
//    } else {
//        outlineLayer.path = nil;
//    }
//    
//    boundingSize = CGSizeMake(enclosure.size.width + _lineWidth * 2, enclosure.size.height + _lineWidth * 2);
//    
//#if TARGET_OS_IPHONE
//    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
//    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
//    if ([systemVersion floatValue] < 8.0) {
//        scaleFactor = 1.0;
//    }
//#endif
//    
//    CGSize imageSize = boundingSize;
//    imageSize.width = ceil(imageSize.width);
//    imageSize.height = ceil(imageSize.height);
//#if TARGET_OS_OSX_SKU
//    NSImage *image = [[NSImage alloc] initWithSize:imageSize];
//    [image lockFocus];
//    CGContextRef newContext = [NSGraphicsContext currentContext].CGContext;
//    CGContextSetAllowsAntialiasing(newContext, _antiAlias);
//    [shapeLayer renderInContext:newContext];
//    [image unlockFocus];
//
//    SKTexture* tex = [SKTexture textureWithImage:image];
//#else
//    UIGraphicsBeginImageContextWithOptions(imageSize, NO, scaleFactor);
//    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
//    SKTexture* tex = [SKTexture textureWithImage:UIGraphicsGetImageFromCurrentImageContext()];
//    UIGraphicsEndImageContext();
//#endif
//    
//    CGPathRelease(newPath);
//    if (outlinePath) {
//        CGPathRelease(outlinePath);
//    }
//    
//    drawSprite.texture = tex;
//    drawSprite.size = boundingSize;
//    drawSprite.anchorPoint = CGPointZero;
//    defaultPosition = CGPointMake(enclosureOffset.x, enclosureOffset.y);
//    drawSprite.position = defaultPosition;
//    [self setAnchorPoint:_anchorPoint];
//    
//    _texture = tex;
//}
//
//-(void)setPath:(CGPathRef)path {
//    _path = CGPathCreateCopy(path);
//    [self redrawTexture];
//}
//
//-(void)setStrokeColor:(SKColor *)strokeColor {
//    _strokeColor = strokeColor;
//    [self redrawTexture];
//}
//
//-(void)setFillColor:(SKColor *)fillColor {
//    _fillColor = fillColor;
//    [self redrawTexture];
//}
//
//-(void)setLineWidth:(CGFloat)lineWidth {
//    _lineWidth = fmax(0.0, lineWidth);
//    [self redrawTexture];
//}
//
//-(void)setFillRule:(NSString *)fillRule {
//    _fillRule = fillRule;
//    [self redrawTexture];
//}
//
//-(void)setAntiAlias:(BOOL)antiAlias {
//    _antiAlias = antiAlias;
//    [self redrawTexture];
//}
//
//-(void)setLineCap:(NSString *)lineCap {
//    _lineCap = lineCap;
//    [self redrawTexture];
//}
//
//-(void)setLineDashPattern:(NSArray *)lineDashPattern {
//    _lineDashPattern = lineDashPattern;
//    [self redrawTexture];
//}
//
//-(void)setLineJoin:(NSString *)lineJoin {
//    _lineJoin = lineJoin;
//    [self redrawTexture];
//}
//
//-(void)setMiterLimit:(CGFloat)miterLimit {
//    _miterLimit = miterLimit;
//    [self redrawTexture];
//}
//
//-(void)setAnchorPoint:(CGPoint)anchorPoint {
//    _anchorPoint = anchorPoint;
//    null.position = CGPointMake(boundingSize.width * (0.5 - anchorPoint.x), boundingSize.height * (0.5 - anchorPoint.y));
//}
//
//-(void)dealloc {
//    CGPathRelease(_path);
//}
//
//@end
