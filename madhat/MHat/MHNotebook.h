//
//  MHNotebook.h
//  MadHat
//
//  Created by Dan Romik on 12/22/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//
//  The base NSDocument subclass for the MadHat document-based app
//

#import <Cocoa/Cocoa.h>
#import "MHNotebookPage.h"
#import "MHTypesettingContextManager.h"
#import "BFPageControl.h"
#import "MHAssetLibraryController.h"
#import "NSSubordinateWindow.h"

NS_ASSUME_NONNULL_BEGIN

extern unichar kMHNotebookForbiddenPageFilenamePrefixChar;   // page file names are not allowed to start with this character
extern NSString * const kMHNotebookImageIndexFileName;
extern NSString * const kMHNotebookImagesFolderName;
extern NSString * const kMHNotebookVideoIndexFileName;
extern NSString * const kMHNotebookVideoFolderName;
extern NSString * const kMHNotebookDocumentType;



@class MHNotebookPage, MHNotebookConfiguration;

@interface MHNotebook : NSDocument <NSWindowDelegate, BFPageControlDelegate>
{
@private
    NSFileWrapper *_notebookFileWrapper;    // a directory file wrapper where the notebook data is stored
    BOOL _assetLibraryVisible;                                  // used in the category file MHNotebook+AssetLibrary.m
    MHAssetLibraryController *_assetLibraryWindowController;    // used in the category file MHNotebook+AssetLibrary.m
    MHAssetType _currentAssetTypeSublibrary;                    // used in the category file MHNotebook+AssetLibrary.m
}

@property IBOutlet NSWindow *sourceCodeEditorWindow;
@property IBOutlet NSSubordinateWindow *pageViewerViewWindow;
@property IBOutlet NSView *pageViewerStatusArea;

// The array of pages in the notebook and a variable keeping track of the current page index
@property (readonly) NSArray <MHNotebookPage *> *pages;

@property NSString *configurationCode;
@property (readonly) MHNotebookConfiguration *notebookConfiguration;

@property (nullable, readonly) MHNotebookPage *currentPage;

@property bool timedSlidePresentationRunning;

@property (readonly) BOOL slideTransitionsCanTransitionAcrossPages;    // defaults to YES, subclasses can override

- (bool)programmaticallyGoToPreviousPage;
- (bool)programmaticallyGoToNextPage;
- (bool)goToPageNamed:(NSString *)pageFilename;     // returns true if a page with that name was found
- (void)goToPageNamed:(NSString *)pageFilename slideNumber:(NSInteger)slideNumber;  // navigate to the specified slide number after switching to the page, unless the slide number given was NSNotFound

- (void)contentsChangedForPage:(MHNotebookPage *)page;


- (void)invalidateAssetIndexFileWrapperForAssetType:(MHAssetType)assetType;
- (void)invalidateAssetFolderFileWrapperForAssetType:(MHAssetType)assetType;

- (void)clearRecentlyVisitedPagesList:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
