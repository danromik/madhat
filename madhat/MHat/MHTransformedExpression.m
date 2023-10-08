//
//  MHTransformedExpression.m
//  MadHat
//
//  Created by Dan Romik on 7/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTransformedExpression.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"

NSString * const kMHTransformedExpressionTranslationCommandName = @"annotation";
NSString * const kMHTransformedExpressionTranslationRelativeToCenterCommandName = @"centered annotation";



@interface MHTransformedExpression ()
{
    CGPoint _translationPoint;
    MHExpressionTranslationCenteringType _centeringType;
}
@end



@implementation MHTransformedExpression



#pragma mark - Constructors

+ (instancetype)transformedExpressionWithContents:(MHExpression *)contents
                                 translationPoint:(CGPoint)point
                                    centeringType:(MHExpressionTranslationCenteringType)centeringType
{
    return [[self alloc] initWithContents:contents translationPoint:point centeringType:centeringType];
}

- (instancetype)initWithContents:(MHExpression *)contents
               translationPoint:(CGPoint)point
                   centeringType:(MHExpressionTranslationCenteringType)centeringType
{
    if (self = [super initWithContents:contents]) {
        _translationPoint = point;
        _centeringType = centeringType;
    }
    return self;
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    // FIXME: it would be better to have just one command for put and centeredput but have a way of passing the centering option inside the command argument
    bool isTranslationRelativeToCorner;
    bool isTranslationRelativeToCenter;
    if ((isTranslationRelativeToCorner = [name isEqualToString:kMHTransformedExpressionTranslationCommandName])
        || (isTranslationRelativeToCenter = [name isEqualToString:kMHTransformedExpressionTranslationRelativeToCenterCommandName])) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *positionExpression = delimitedBlockTable[0];
        NSUInteger numberOfCoordinates = positionExpression.count;
        MHExpression *xCoordinateExpression = (numberOfCoordinates > 0 ? positionExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfCoordinates > 1 ? positionExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        CGPoint point = CGPointMake(xCoord, yCoord);
        MHExpression *contents = (delimitedBlockTable.count <= 1 ? [MHExpression expression] : delimitedBlockTable[1][0]);
        return [self transformedExpressionWithContents:contents
                                      translationPoint:point
                                         centeringType:(isTranslationRelativeToCorner ? MHExpressionTranslationRelativeToCorner
                                                        : MHExpressionTranslationRelativeToCenter)];
    }
    
    return nil;
}



#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    CGPoint translationPointInNodeCoordinates = [contextManager convertPointFromCanvasToNodeCoordinates:_translationPoint];
    CGPoint myContentsPosition = translationPointInNodeCoordinates;

    MHExpression *myContents = self.contents;

    switch (_centeringType) {
        case MHExpressionTranslationRelativeToCenter: {
            MHDimensions contentDimensions = myContents.dimensions;
            myContentsPosition.x -= contentDimensions.width/2.0;
            myContentsPosition.y -= contentDimensions.height/2.0;
            break;
        }
        case MHExpressionTranslationRelativeToCorner:
            // do nothing
            break;
    }
    myContents.position = myContentsPosition;

    // set our dimensions to 0
    MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;
    self.dimensions = myDimensions;
    
}

- (bool)splittable
{
    return false;
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHTransformedExpression *myCopy = [[self class] transformedExpressionWithContents:[self.contents logicalCopy]
                                                                     translationPoint:_translationPoint
                                                                        centeringType:_centeringType];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHTransformedExpressionTranslationCommandName,
        kMHTransformedExpressionTranslationRelativeToCenterCommandName
    ];
}




@end
