//
//  MHGraphicsCanvas.h
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN



@interface MHGraphicsCanvas : MHWrapper <MHCommand>


//@property (readonly) bool cropContents;
//@property (readonly) bool framed;

+ (instancetype)graphicsCanvasWithDimensions:(MHDimensions)dimensions
                               viewRectangle:(MHGraphicsRectangle)viewRectangle
                                    contents:(MHExpression *)contents
                                cropContents:(bool)cropEnabled
                                   drawFrame:(bool)frameEnabled;

@end

@protocol MHGraphicsExpressionWithPath <NSObject>

- (nullable CGPathRef)graphicsPath;

@end


NS_ASSUME_NONNULL_END
