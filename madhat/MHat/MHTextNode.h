//
//  MHTextNode.h
//  MadHat
//
//  Created by Dan Romik on 7/31/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHTextualElementNode.h"


NS_ASSUME_NONNULL_BEGIN

@interface MHTextNode : MHTextualElementNode

@property (nonatomic, readonly) NSString *text;

+ (instancetype)textNodeWithString:(NSString *)string;


- (NSArray <SKShapeNode *> *)createTextNodesForIndividualGlyphs;

@end

NS_ASSUME_NONNULL_END
