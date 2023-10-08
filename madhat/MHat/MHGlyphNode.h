//
//  MHGlyphNode.h
//  MadHat
//
//  Created by Dan Romik on 8/3/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHTextualElementNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHGlyphNode : MHTextualElementNode

@property (nonatomic, readonly) NSString *glyphName;

+ (instancetype)glyphNodeWithGlyphName:(NSString *)glyphName;




@end

NS_ASSUME_NONNULL_END
