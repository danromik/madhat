//
//  MHNotebook+PDFAndPrinting.m
//  MadHat
//
//  Created by Dan Romik on 10/9/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHNotebook+ExportingAndPrinting.h"
#import "MHPDFRenderingContextManager.h"
#import <AppKit/AppKit.h>
#import <PDFKit/PDFKit.h>


// uncomment the next line to run the experimental check for dead intralinks during PDF exporting
// FIXME: improve this code and add a way to alert the user to the missing links
//#define CHECK_INTRALINKS


@interface NSFileManager (TemporaryFile)
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix;
@end



@implementation MHNotebook (ExportingAndPrinting)




#pragma mark - PDF exporting


- (IBAction)saveDocumentToPDF:(id)sender
{
    //    // used for random tinkering:
    //    [[MHProfiler defaultProfiler] parseExpressionSubclassesTree];
    //    return;
    
    NSWindow *window = self.sourceCodeEditorWindow;
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.message = NSLocalizedString(@"Export notebook to PDF", @"");
    panel.prompt = NSLocalizedString(@"Export", @"");
    panel.allowedFileTypes = @[ @"pdf" ];
    NSString *filenameForExporting = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
    if (!filenameForExporting)
        filenameForExporting = self.displayName;
    [panel setNameFieldStringValue:[filenameForExporting stringByAppendingPathExtension:@"pdf"]];
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            [self saveDocumentToPDFForExportOrPrintingWithURL:[panel URL] windowForProgressSheet:window];
        }
        else {
            // if any action should be taken if the user cancels the export operation, add it here
        }
    }];
}

// the method below is used to export a document to PDF. This is used by both the "Export To PDF" and "Print" features, so can be invoked in two ways:
// if fileURL is not nil, we save the PDF to that location and clean up any temporary files that were created. This is invoked after a save panel that lets the user select the location for the exported PDF
// if fileURL is nil, that means we are in a printing scenario. We save the exported PDF to a temporary file and once finished call the method presentPrintPanelWithExportedPDFURL: with a URL pointing to the exported file. The presentPrintPanelWithExportedPDFURL: method takes care of presenting the print panel and upon completion of the print operation, deleting the temporary file
// if we are unable to save the PDF, we issue an error message and return
- (void)saveDocumentToPDFForExportOrPrintingWithURL:(nullable NSURL *)fileURL windowForProgressSheet:(NSWindow *)window
{
    // create a URL for a temporary file to save the PDF to
    NSString *filename = [[fileURL path] lastPathComponent];
    if (!filename)
        filename = [[NSUUID UUID] UUIDString];  // if a filename was not provided, generate one using a UUID
    NSString *temporaryFilePath = [[NSFileManager defaultManager] pathForTemporaryFileWithPrefix:filename]; // a simple auxiliary method defined in a category on NSFileManager at the end of this source file
    __block NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
    if (!temporaryFileURL) {
        NSLog(@"unable to create file for exporting");
        NSBeep();
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = (fileURL ? NSLocalizedString(@"Error: Could not create PDF file", @"") :
                             NSLocalizedString(@"Error: Could not create formatted file to initiate printing", @""));
        [alert setInformativeText:(fileURL ?
                                   NSLocalizedString(@"Check if you have sufficient disk space and the necessary permissions to write to the file", @"") :
                                   NSLocalizedString(@"Check if you are running low on disk space", @""))];
        [alert addButtonWithTitle:NSLocalizedString(@"Ok", @"")];
        [alert runModal];
        return;
    }
    
    
    // ensure that all pages in the notebook are parsed and typeseet
    for (MHNotebookPage *page in self.pages) {
        [page.sourceCodeEditorView parseCodeIfNeededAndMarkAsSynchronized];
    }
    

    __block bool exportOperationCanceledFlag = false;
    void (^exportingProgressWindowCompletionHandler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseStop) {
            // the export ended successfully - no need to do anything
        }
        else if (returnCode == NSAlertFirstButtonReturn) {
            exportOperationCanceledFlag = true;
        }
    };

    NSAlert *exportingProgressWindow = [[NSAlert alloc] init];
    exportingProgressWindow.messageText = (fileURL ?
                                           NSLocalizedString(@"Exporting notebook to PDF", @"") :
                                           NSLocalizedString(@"Formatting notebook content for printing", @""));
    [exportingProgressWindow setInformativeText:(fileURL ?
                                                 NSLocalizedString(@"Preparing to export...", @"") :
                                                 NSLocalizedString(@"Preparing...", @""))];
    [exportingProgressWindow addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 0.0, 240.0, 20.0)];
    progressIndicator.indeterminate = NO;
    progressIndicator.doubleValue = 0.0;
    
    exportingProgressWindow.accessoryView = progressIndicator;

    [exportingProgressWindow beginSheetModalForWindow:window completionHandler:exportingProgressWindowCompletionHandler];

  
    void (^pdfExportingBlock)(void);
    pdfExportingBlock = ^{
        CGContextRef pdfContext;
        CFMutableDictionaryRef exportedPDFInfoDictionary;
        exportedPDFInfoDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
           
        // Set the content creator info dictionary key
        CFDictionarySetValue(exportedPDFInfoDictionary, kCGPDFContextCreator, CFSTR("MadHat"));

        // Set the title and author info dictionary keys
        MHNotebookConfiguration *notebookConfig = self.notebookConfiguration;
        NSString *author = notebookConfig.notebookAuthor;
        NSString *title = notebookConfig.notebookTitle;
        CFDictionarySetValue(exportedPDFInfoDictionary, kCGPDFContextAuthor, author ? (__bridge CFStringRef)author : CFSTR(""));
        CFDictionarySetValue(exportedPDFInfoDictionary, kCGPDFContextTitle, title ? (__bridge CFStringRef)title : CFSTR(""));
        
        // Create the PDF context
        pdfContext = CGPDFContextCreateWithURL((CFURLRef)temporaryFileURL, nil, exportedPDFInfoDictionary);
        
        // FIXME: add appropriate handling when context creation fails (for example if the user lacks permission to write to the file, etc)
           
        CFRelease(exportedPDFInfoDictionary);
        
        MHPDFRenderingContextManager *pdfRenderingContextManager
        = [[MHPDFRenderingContextManager alloc] initWithPDFContext:pdfContext
                                            pageGeometryParameters:notebookConfig.pageGeometryParameters
                                           defaultTypesettingState:notebookConfig.defaultTypesettingState
                                                     PDFPageHeader:notebookConfig.exportedPageHeader
                                                     PDFPageFooter:notebookConfig.exportedPageFooter
                                          headerAndFooterPageRange:notebookConfig.exportedHeaderAndFooterRange];
                                                                    

        NSUInteger notebookPageNumber = 1;
        NSUInteger pdfPageNumber = 1;
        NSUInteger numberOfNotebookPages = self.pages.count;
        
        // as we render each notebook page, compile a list of exported page numbers where each notebook page begins. This will be used to create a PDF outline
        NSMutableArray <NSNumber *> *pageNumbersForOutline = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (MHNotebookPage *page in self.pages) {
            if (exportOperationCanceledFlag) {
                break;
            }
            
            [pageNumbersForOutline addObject:[NSNumber numberWithInteger:pdfPageNumber]];
             
            [pdfRenderingContextManager renderNotebookPage:page];
            pdfPageNumber = pdfRenderingContextManager.pdfPageNumber;

            // NOTE: It is important to let all UI updates occur on the main thread, so we put the following UI updates on the main queue.
            dispatch_async(dispatch_get_main_queue(), ^{
                [exportingProgressWindow setInformativeText:[NSString stringWithFormat:
                                                             (fileURL ?
                                                              NSLocalizedString(@"Notebook page %lu of %lu (PDF pages created: %lu)", @"") :
                                                              NSLocalizedString(@"Notebook page %lu of %lu (formatted pages: %lu)", @"")),
                                                             notebookPageNumber, numberOfNotebookPages, pdfPageNumber-1]];
                progressIndicator.doubleValue = 100.0 * ((double)notebookPageNumber)/((double)(self.pages.count));
            });
            
            notebookPageNumber++;
        }
        CGPDFContextClose(pdfContext);
        CGContextRelease(pdfContext);
        
        
        if (fileURL) {  // for PDF exporting only, not for printing
            // Add a table of contents (aka outline)
            // This uses the PDFKit classes PDFDocument, PDFPage, PDFOutline and PDFAction
            // In the current implementation it requires creating a new PDF file from the already created one
            // FIXME: is there a way to avoid this two-step approach and create a single PDF file with the table of contents already included?
            
#ifdef CHECK_INTRALINKS
            // Some experimental code for gathering information about intralinks in the notebook and checking whether there are any dead links
            // that don't point to actual notebook pages
            NSDictionary <NSNumber *, NSArray <NSString *> *> *declaredDestinations = pdfRenderingContextManager.declaredDestinations;
            NSMutableArray *pageDestinationNames = [[NSMutableArray alloc] initWithCapacity:0];
#endif

            NSString *secondTemporaryFilePath = [temporaryFilePath stringByAppendingString:@"-with-outline"];
            NSURL *secondTemporaryFileURL = [NSURL fileURLWithPath:secondTemporaryFilePath];

            PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:temporaryFileURL];

            PDFOutline *rootOutline = [[PDFOutline alloc] init];

            NSUInteger numberOfPages = pageNumbersForOutline.count;
            for (NSUInteger outlineIndex = 0; outlineIndex < numberOfPages; outlineIndex++) {
                NSUInteger pageNumber = [pageNumbersForOutline[outlineIndex] integerValue];
                PDFPage *page = [pdfDoc pageAtIndex:pageNumber-1];
                NSPoint point = { FLT_MAX, FLT_MAX };
                PDFDestination *destination =  [[PDFDestination alloc] initWithPage:page atPoint:point];
                PDFAction *action = [[PDFActionGoTo alloc] initWithDestination:destination];
                PDFOutline *outline = [[PDFOutline alloc] init];
                MHNotebookPage *notebookPage = self.pages[outlineIndex];
                NSString *pageFilename = notebookPage.filename;
                outline.label = pageFilename;
                outline.action = action;
                [rootOutline insertChild:outline atIndex:outlineIndex];
                
#ifdef CHECK_INTRALINKS
                [pageDestinationNames addObject:pageFilename];
#endif
            }

            pdfDoc.outlineRoot = rootOutline;
            
#ifdef CHECK_INTRALINKS
            // --- More experimental code for intralinks ---
            // check if the destination names that were declared actually exist as page destination names, and report an error for each declared destination name that doesn't exist
            NSArray *pageNumbersWhereDestinationsDeclared = [declaredDestinations allKeys];
            NSArray *pageNumbersWhereDestinationsDeclaredSorted = [pageNumbersWhereDestinationsDeclared sortedArrayUsingSelector:@selector(compare:)];

            BOOL missingDestinationsFound = NO;
            for (NSNumber *pageNum in pageNumbersWhereDestinationsDeclaredSorted) {
                NSUInteger pageNumberWhereDeclared = [pageNum integerValue];
                NSArray <NSString *> *declaredDestinationsInPage = declaredDestinations[pageNum];
                for (NSString *declaredDestinationName in declaredDestinationsInPage) {
                    BOOL destinationExists = [pageDestinationNames containsObject:declaredDestinationName];
                    if (!destinationExists) {
                        NSLog(@"destination \"%@\" was declared on page %lu but does not exist", declaredDestinationName, pageNumberWhereDeclared);
                        missingDestinationsFound = YES;
                    }
                }
            }
            if (!missingDestinationsFound) {
                NSLog(@"no missing destinations found");
            }
            // --- end experimental code ---
#endif

            // now that we added the outline, write the modified PDF to a new temporary file
            if ([pdfDoc writeToURL:secondTemporaryFileURL]) {
                // delete the first temporary file we created, and work with the second one instead
                
                [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];
                temporaryFileURL = secondTemporaryFileURL;
            }
        }

        
        // after finishing the export, clean up or call the print method as appropriate - this should be done on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [window endSheet:exportingProgressWindow.window];
            
            if (fileURL) {
                // we finished exporting the notebook to a PDF file in a temporary file. Now move the file to where the user selected it should be saved to
                NSError *fileMovingError;
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil]; // if there was already a file at the destination, delete it (the user must have authorized this via the file saving panel, so it's okay to do)
                [[NSFileManager defaultManager] moveItemAtURL:temporaryFileURL toURL:fileURL error:&fileMovingError];
                if (fileMovingError) {
                    NSLog(@"could not move the exported file to its destination, error=%@", fileMovingError);

                    // FIXME: I haven't done testing in various failure scenarios to see that this works as intended - do this
                    NSBeep();
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = NSLocalizedString(@"Error: Could not create PDF file", @"");
                    [alert setInformativeText:NSLocalizedString(@"Check if you have sufficient disk space and the necessary permissions to write to the file", @"")];
                    [alert addButtonWithTitle:NSLocalizedString(@"Ok", @"")];
                    [alert runModal];
                }
            }
            else {
                // this is the case of printing. We finished exporting the notebook to a PDF file in a temporary file. now call the relevant method to present a print panel using the PDF document
                [self presentPrintPanelWithExportedPDFURL:temporaryFileURL];
            }
            
            // for debugging, if we want to open the exported file after saving it, uncomment this line:
            //            [[NSWorkspace sharedWorkspace] openFile:fileURL.path];

        });
    }; //end of pdfExportingBlock

    
    // Run the block on a different thread to allow the UI to keep updating
    dispatch_queue_t queue = dispatch_get_global_queue(0,0);
    dispatch_async(queue, pdfExportingBlock);
    
}






#pragma mark - Print feature

//- (void)printDocumentWithSettings:(NSDictionary<NSPrintInfoAttributeKey, id> *)printSettings
//                   showPrintPanel:(BOOL)showPrintPanel
//                         delegate:(id)delegate
//                 didPrintSelector:(SEL)didPrintSelector
//                      contextInfo:(void *)contextInfo
//{
//    // according to the documentation this is called from the printDocument: method, but I don't really need all the parameters here so I'll just initiate the print operation directly from the printDocument: method and skip calling this method
//}

- (void)printDocument:(id)sender
{
    [self saveDocumentToPDFForExportOrPrintingWithURL:nil windowForProgressSheet:self.sourceCodeEditorWindow];
}

- (void)presentPrintPanelWithExportedPDFURL:(NSURL *)exportedPDFURL
{
    PDFDocument *exportedPDF = [[PDFDocument alloc] initWithURL:exportedPDFURL];
    
    // create a print operation
    NSPrintOperation *printOperation = [exportedPDF printOperationForPrintInfo:[NSPrintInfo sharedPrintInfo]
                                                                   scalingMode:kPDFPrintPageScaleDownToFit
                                                                    autoRotate:YES];
    
    // add some useful options to the print panel
    NSPrintPanel *printPanel = printOperation.printPanel;
    [printPanel setOptions:printPanel.options | NSPrintPanelShowsPageSetupAccessory];

    // run the operation
    [printOperation runOperationModalForWindow:self.sourceCodeEditorWindow
                                      delegate:self
                                didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
                                   contextInfo:(void *)(CFBridgingRetain(exportedPDFURL))]; // pass the URL so we can delete the file after printing is complete
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)contextInfo
{
    NSURL *fileURLToDelete = CFBridgingRelease(contextInfo);
//    NSLog(@"deleting file %@", fileURLToDelete.path);
    [[NSFileManager defaultManager] removeItemAtURL:fileURLToDelete error:nil]; // if there was already a file at the destination, delete it (the user must have authorized this via the file saving panel, so it's okay to do)
}








#pragma mark - LaTeX exporting

- (IBAction)saveDocumentToLaTeX:(id)sender
{
    NSWindow *window = self.sourceCodeEditorWindow;
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.message = NSLocalizedString(@"Export notebook to LaTeX", @"");
    panel.prompt = NSLocalizedString(@"Export", @"");
    panel.allowedFileTypes = @[ @"tex" ];
    NSString *filenameForExporting = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
    if (!filenameForExporting)
        filenameForExporting = self.displayName;
    [panel setNameFieldStringValue:[filenameForExporting stringByAppendingPathExtension:@"tex"]];
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            [self saveDocumentToLaTeXWithURL:[panel URL] windowForProgressSheet:window];
        }
        else {
            // if any action should be taken if the user cancels the export operation, add it here
        }
    }];
}


// Note: unlike the analogous method saveDocumentToPDFForExportOrPrintingWithURL:: for PDF exporting defined above, in the case of LaTeX exporting we assume that fileURL is non-nil and contains a valid URL for saving the file to
- (void)saveDocumentToLaTeXWithURL:(NSURL *)fileURL windowForProgressSheet:(NSWindow *)window
{
     // ensure that all pages in the notebook are parsed and typeseet
    for (MHNotebookPage *page in self.pages) {
        [page.sourceCodeEditorView parseCodeIfNeededAndMarkAsSynchronized];
    }

     __block bool exportOperationCanceledFlag = false;
     void (^exportingProgressWindowCompletionHandler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
         if (returnCode == NSModalResponseStop) {
             // the export ended successfully - no need to do anything
         }
         else if (returnCode == NSAlertFirstButtonReturn) {
             exportOperationCanceledFlag = true;
         }
     };

    NSAlert *exportingProgressWindow = [[NSAlert alloc] init];
    exportingProgressWindow.messageText = NSLocalizedString(@"Exporting notebook to LaTeX", @"");
    [exportingProgressWindow setInformativeText:NSLocalizedString(@"Preparing to export...", @"")];
    [exportingProgressWindow addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];

    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 0.0, 240.0, 20.0)];
    progressIndicator.indeterminate = NO;
    progressIndicator.doubleValue = 0.0;
    
    exportingProgressWindow.accessoryView = progressIndicator;

    [exportingProgressWindow beginSheetModalForWindow:window completionHandler:exportingProgressWindowCompletionHandler];
    
    static NSString *exportedLaTeXInfoHeader = @"\
%\n\
% Exported from MadHat\n\
%\n";
    
//    static NSString *exportedLaTeXPreamble = @"\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{amsfonts}\n\%For the MadHat command nedots, use:\n\%\\usepackage{mathdots}\n\n\\begin{document}\n";  // Robert's version
    
    // a slightly cleaned-up version of the preamble text for use in the MadHat Version 1.1 release
    static NSString *exportedLaTeXPreamble = @"\\documentclass{article}\n\\usepackage{amsmath}\n\\usepackage{amsfonts}\n\n\\begin{document}\n";
    static NSString *exportedLaTeXClosing = @"\n\n\\end{document}\n";

    void (^latexExportingBlock)(void);
    latexExportingBlock = ^{
        NSMutableString *latexFileString = [[NSMutableString alloc] initWithCapacity:0];
        
        [latexFileString appendString:exportedLaTeXInfoHeader];
        [latexFileString appendString:exportedLaTeXPreamble];

        NSUInteger notebookPageNumber = 1;
        NSUInteger numberOfNotebookPages = self.pages.count;
        for (MHNotebookPage *page in self.pages) {
            NSString *pageLaTeXString = page.exportedLaTeXValue;
            [latexFileString appendFormat:@"\n\n\n%% ------------------------------------------------------------\n%% MadHat notebook page %lu: %@\n%% ------------------------------------------------------------\n\n",
             notebookPageNumber, page.filename];
            [latexFileString appendString:pageLaTeXString];
            
            // NOTE: It is important to let all UI updates occur on the main thread, so we put the following UI updates on the main queue.
            dispatch_async(dispatch_get_main_queue(), ^{
                [exportingProgressWindow setInformativeText:[NSString stringWithFormat:
                                                             NSLocalizedString(@"Notebook page %lu of %lu", @""),
                                                             notebookPageNumber, numberOfNotebookPages]];
                progressIndicator.doubleValue = 100.0 * ((double)notebookPageNumber)/((double)(numberOfNotebookPages));
            });

            notebookPageNumber++;
        }
        
        [latexFileString appendString:exportedLaTeXClosing];
        
        // FIXME: add some error panel in case we don't have success
//        BOOL success =
            [latexFileString writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // after finishing the export, clean up -- this should be done on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [window endSheet:exportingProgressWindow.window];
        });
    };
    
    // Run the block on a different thread to allow the UI to keep updating
    dispatch_queue_t queue = dispatch_get_global_queue(0,0);
    dispatch_async(queue, latexExportingBlock);
}


@end





@implementation NSFileManager (TemporaryFile)

// an auxiliary method to create a temporary file (used by the saveDocumentToPDFForExportOrPrintingWithURL: method above)
// taken from this thread: https://stackoverflow.com/questions/215820/how-do-i-create-a-temporary-file-with-cocoa
// (the thread offers several other methods for generating a temporary file name that are potentially more robust than the current one, so might be worth looking at them at some point)
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;

    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);

    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);

    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidStr]];
    assert(result != nil);

    CFRelease(uuidStr);
    CFRelease(uuid);

    return result;
}





@end

