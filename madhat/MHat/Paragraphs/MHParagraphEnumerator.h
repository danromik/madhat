//
//  MHParagraphEnumerator.h
//  MadHat
//
//  Created by Dan Romik on 8/18/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHParagraph.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHParagraphEnumerator : NSObject

- (instancetype)initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *> *)paragraphs;

- (instancetype)initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *> *)paragraphs
                                      startingParagraphIndex:(NSUInteger)index;


- (NSArray <MHParagraph *> *)allParagraphs;
- (nullable MHParagraph *)nextParagraph;

@end

NS_ASSUME_NONNULL_END
