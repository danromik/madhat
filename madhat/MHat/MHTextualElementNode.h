//
//  MHTextualElementNode.h
//  MadHat
//
//  Created by Dan Romik on 8/3/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MadHat.h"
#import "SKNode+MHSomeConvenienceMethods.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTextualElementNode : SKNode
{
@protected
    MHDimensions _dimensions;       // subclasses can access this
}

@property (readonly) MHDimensions dimensions;


// subclasses should call this method on MHTextualElementNode at the end of their implementation of the method to inherit the class's implementation of underlining, strikethrough and background colors
- (void)configureWithFont:(NSFont *)font
                    color:(NSColor *)color
          backgroundColor:(nullable NSColor *)backgroundColor
              underlining:(bool)underlining
            strikethrough:(bool)strikethrough;


// subclasses should call this method on MHTextualElementNode at the beginning of their implementation of the method to inherit the class's implementation of underlining, strikethrough and background colors
- (void)renderInPDFContext:(CGContextRef)pdfContext;


@end

NS_ASSUME_NONNULL_END
