//
//  MHPDFRenderingContextManager.m
//  MadHat
//
//  Created by Dan Romik on 12/22/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHPDFRenderingContextManager.h"
#import "MHTypesettingContextManager.h"
#import "MHTypesettingState.h"
#import "MHNotebookPage.h"

@interface MHPDFRenderingContextManager ()
{
    CGContextRef _pdfContext;
    NSUInteger _notebookPageNumber;
    NSUInteger _pdfPageNumber;
    NSSize _pageSize;
    MHTypesettingContextManager *_typesettingContextManager;    // used to typeset page headers and footers
    MHExpression * _Nullable _PDFPageHeader;
    MHExpression * _Nullable _PDFPageFooter;
    NSRange _headerAndFooterPageRange;
    
    CGFloat _leftMargin;
    CGFloat _topMargin;
    CGFloat _bottomMargin;
    CGFloat _headerOffset;
    CGFloat _footerOffset;

    CGFloat _filledVerticalSpaceOnCurrentPage;
    
    CFMutableDictionaryRef _pageDictionary;
    
    NSMutableDictionary <NSNumber *, NSMutableArray <NSString *> *> *_declaredDestinations;
}

@end

@implementation MHPDFRenderingContextManager


- (instancetype)initWithPDFContext:(CGContextRef)pdfContext
            pageGeometryParameters:(MHPageGeometryParameters)pageGeometryParameters
           defaultTypesettingState:(MHTypesettingState *)defaultTypesettingState
                     PDFPageHeader:(nullable MHExpression *)exportedPageHeader
                     PDFPageFooter:(nullable MHExpression *)exportedPageFooter
          headerAndFooterPageRange:(NSRange)range
{
    if (self = [super init]) {
        _notebookPageNumber = 1;
        _pdfPageNumber = 1;
        _pdfContext = CGContextRetain(pdfContext);
        _pageSize = pageGeometryParameters.pageSize;
        _typesettingContextManager = [[MHTypesettingContextManager alloc] init];
        _typesettingContextManager.defaultState = defaultTypesettingState;
        _PDFPageHeader = exportedPageHeader;
        _PDFPageFooter = exportedPageFooter;
        _headerAndFooterPageRange = range;
        _typesettingContextManager.exportedPageNumber = _pdfPageNumber;

        _leftMargin = pageGeometryParameters.pageLeftMargin;
        _topMargin = pageGeometryParameters.exportedPageTopMargin;
        _bottomMargin = pageGeometryParameters.exportedPageBottomMargin;
        _headerOffset = pageGeometryParameters.exportedPageHeaderOffset;
        _footerOffset = pageGeometryParameters.exportedPageFooterOffset;
        
        // the next code lines are needed to cause the footer and header are typeset with the correct text width
        // FIXME: this works but is confusing and breaks the OO encapsulation philosophy, it might be better if there was an explicit method call to set the text width
        _typesettingContextManager.pageLeftMargin = pageGeometryParameters.pageLeftMargin;
        _typesettingContextManager.pageRightMargin = pageGeometryParameters.pageRightMargin;

        CGRect pageRect = CGRectMake(0.0, 0.0, _pageSize.width, _pageSize.height);
        _pageDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDataRef boxData = CFDataCreate(NULL,(const UInt8 *)&pageRect, sizeof (CGRect));
        CFDictionarySetValue(_pageDictionary, kCGPDFContextMediaBox, boxData);
        CFRelease(boxData);
        
        _declaredDestinations = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    CGContextRelease(_pdfContext);
    CFRelease(_pageDictionary);
}

- (void)renderNotebookPage:(MHNotebookPage *)page
{
    [page renderToPDFWithContextManager:self];
    _notebookPageNumber++;
}

- (void)incrementFilledVerticalSpaceBy:(CGFloat)increment
{
    _filledVerticalSpaceOnCurrentPage += increment;
}

- (void)beginPDFPage
{
    CGPDFContextBeginPage(_pdfContext, _pageDictionary);
    _filledVerticalSpaceOnCurrentPage = 0.0;
    CGContextSaveGState(_pdfContext);
    
    // move the rendering point to the top-left corner of the page
    CGContextTranslateCTM(_pdfContext, 0.0, _pageSize.height-_topMargin);
}

- (void)endPDFPage
{
    CGContextRestoreGState(_pdfContext);
    
    BOOL addHeaderAndFooter = NSLocationInRange(_notebookPageNumber, _headerAndFooterPageRange);
    if (addHeaderAndFooter) {
        CGContextSaveGState(_pdfContext);

        // Render the page header
        if (_PDFPageHeader) {
            CGPoint headerTranslationVector;
            headerTranslationVector.x = _leftMargin;
            headerTranslationVector.y = _pageSize.height - _headerOffset;
            CGContextTranslateCTM(_pdfContext, headerTranslationVector.x, headerTranslationVector.y);    // FIXME: improve
            [_PDFPageHeader typesetWithContextManager:_typesettingContextManager];
            [_PDFPageHeader renderToPDFWithContextManager:self];
            CGContextTranslateCTM(_pdfContext, -headerTranslationVector.x, -headerTranslationVector.y);    // FIXME: improve
        }

        // Render the page footer
        if (_PDFPageFooter) {
            CGPoint footerTranslationVector;
            footerTranslationVector.x = _leftMargin;
            footerTranslationVector.y = _footerOffset;
            CGContextTranslateCTM(_pdfContext, footerTranslationVector.x, footerTranslationVector.y);    // FIXME: improve
            [_PDFPageFooter typesetWithContextManager:_typesettingContextManager];
            [_PDFPageFooter renderToPDFWithContextManager:self];
            CGContextTranslateCTM(_pdfContext, -footerTranslationVector.x, -footerTranslationVector.y);    // FIXME: improve
        }
        CGContextRestoreGState(_pdfContext);
    }
    
    _pdfPageNumber++;
    _typesettingContextManager.exportedPageNumber = _pdfPageNumber;
    
    CGPDFContextEndPage(_pdfContext);
}

- (void)declareDestinationLink:(NSString *)destinationName
{
    NSMutableArray <NSString *> *declaredDestinationsInCurrentPage;
    NSNumber *pageNum = [NSNumber numberWithInteger:_notebookPageNumber];
    declaredDestinationsInCurrentPage = _declaredDestinations[pageNum];
    if (declaredDestinationsInCurrentPage) {
        if ([declaredDestinationsInCurrentPage containsObject:destinationName])
            return; // the destination was already declared on this page so no need to record it again
    }
    else {
        declaredDestinationsInCurrentPage = [[NSMutableArray alloc] initWithCapacity:0];
        _declaredDestinations[pageNum] = declaredDestinationsInCurrentPage;
    }
    [declaredDestinationsInCurrentPage addObject:destinationName];
}

- (NSDictionary <NSNumber *, NSArray <NSString *> *> *)declaredDestinations
{
    return _declaredDestinations;
}

@end
