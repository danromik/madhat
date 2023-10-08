//
//  MHVerticalLayoutContainer.h
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHLinearContainer.h"

NS_ASSUME_NONNULL_BEGIN

@class MHPDFRenderingContextManager;
@interface MHVerticalLayoutContainer : MHLinearContainer <MHIncrementalTypesetting>

@property (readonly) NSUInteger numberOfSlideTransitions;




- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager;



- (void)replaceParagraphAtIndex:(NSUInteger)index withParagraph:(MHParagraph *)newParagraph;
- (void)removeParagraphAtIndex:(NSUInteger)index;
- (void)insertParagraph:(MHParagraph *)paragraph atIndex:(NSUInteger)index;



@end

NS_ASSUME_NONNULL_END
