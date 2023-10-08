//
//  MHPDFRenderingContextManager.h
//  MadHat
//
//  Created by Dan Romik on 12/22/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHNotebookConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class MHTypesettingState, MHTypesettingContextManager, MHExpression, MHNotebookPage;
@interface MHPDFRenderingContextManager : NSObject

@property (readonly) CGContextRef pdfContext;
@property (readonly) MHTypesettingContextManager *typesettingContextManager;
@property (readonly) NSUInteger notebookPageNumber;
@property (readonly) NSUInteger pdfPageNumber;
@property (readonly) NSSize pageSize;
@property (readonly) NSRange headerAndFooterPageRange;
@property (nullable, readonly) MHExpression *PDFPageHeader;
@property (nullable, readonly) MHExpression *PDFPageFooter;

@property (readonly) CGFloat topMargin;
@property (readonly) CGFloat bottomMargin;

@property (readonly) CGFloat filledVerticalSpaceOnCurrentPage;
- (void)incrementFilledVerticalSpaceBy:(CGFloat)increment;  // the value resets to 0 when -beginPDFPage is called


- (instancetype)initWithPDFContext:(CGContextRef)pdfContext
            pageGeometryParameters:(MHPageGeometryParameters)pageGeometryParameters
           defaultTypesettingState:(MHTypesettingState *)defaultTypesettingState
                     PDFPageHeader:(nullable MHExpression *)exportedPageHeader
                     PDFPageFooter:(nullable MHExpression *)exportedPageFooter
          headerAndFooterPageRange:(NSRange)range;


- (void)renderNotebookPage:(MHNotebookPage *)page;  // renders the page and increments the notebookPageNumber counter

- (void)beginPDFPage;   // starts a new PDF page and moves the rendering origin to the top-left corner of the page text rendering area
- (void)endPDFPage;     // adds the header and footer if applicable, and closes the page

- (void)declareDestinationLink:(NSString *)destinationName; // rendering expressions should call this each time they render a PDF document intralink. The context manager collects all this information for later error reporting

@property (readonly) NSDictionary <NSNumber *, NSArray <NSString *> *> *declaredDestinations;    // this is used to query the destinations declared during rendering. the dictionary is indexed by the notebook page number in which destinations are declared. for each notebook page number, the value associated with the key is an array of strings corresponding to the (distinct) destinations declared on that page

@end

NS_ASSUME_NONNULL_END
