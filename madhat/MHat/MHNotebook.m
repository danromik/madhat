//
//  MHNotebook.m
//  MadHat
//
//  Created by Dan Romik on 12/22/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "BFPageControl.h"
#import "MadHat.h"
#import "MHUserDefaults.h"
#import "MHNotebook.h"
#import "MHNotebookConfiguration.h"
#import "MHNotebookConfigurationPanelController.h"
#import "MHDocumentController.h"
#import "MHProfiler.h"
#import "MHNotebook+AssetLibrary.h"
#import "NSTableViewWithDeleteShortcut.h"
#import "AppDelegate.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeEditorThemeManager.h"



unichar kMHNotebookForbiddenPageFilenamePrefixChar = '_';   // page file names are not allowed to start with this character, as it is used for the index, configuration and other metadata files
static NSString * const kMHNotebookPageIndexFileName = @"_index.txt";
static NSString * const kMHNotebookPageConfigurationFileName = @"_config.txt";
NSString * const kMHNotebookImageIndexFileName = @"_imageindex.txt";
NSString * const kMHNotebookImagesFolderName = @"_images";
NSString * const kMHNotebookVideoIndexFileName = @"_videoindex.txt";
NSString * const kMHNotebookVideoFolderName = @"_videos";

static NSString * const kMHNotebookPageDraggingPasteboardType = @"design.madhat.notebookpage";

static NSString * const kMHNotebookWindowNibName = @"MHNotebook";  // this is the name of the xib file for the windows of a notebook
NSString * const kMHNotebookDocumentType = @"MadHat Notebook";  // Note: this string is also specified in the Info.plist file

static NSString * const kMHNotebookPageListColumnIdentifierPageNumber = @"pagenumber";
static NSString * const kMHNotebookPageListColumnIdentifierFilename = @"filename";


// code templates
static NSString * const kMHNotebookCodeTemplatesPlistFilename = @"codetemplates";
static NSString * const kMHNotebookCodeTemplatesPlistFileExtension = @"plist";
static NSString * const kMHNotebookCodeTemplatesTemplateNameKey = @"name";
static NSString * const kMHNotebookCodeTemplatesSubmenuNameKey = @"submenu";
static NSString * const kMHNotebookCodeTemplatesTemplateCodeKey = @"code";

static NSString * const kMHNotebookDefaultConfigurationCodeFilename = @"defaultconfigurationcode";
static NSString * const kMHNotebookDefaultConfigurationCodeFileExtension = @"txt";

static NSString * const kMHNotebookRestorableStatePageIndex = @"pageindex";
static NSString * const kMHNotebookRestorableStateSlideTransitionIndex = @"slidetransitionindex";
static NSString * const kMHNotebookRestorableStatePageViewerViewZoom = @"pageviewerviewzoom";
static NSString * const kMHNotebookRestorableStatePageViewerAspectRatioLocked = @"pagevieweraspectratiolocked";
static NSString * const kMHNotebookRestorableStateAssetLibraryOpen = @"assetlibraryopen";
static NSString * const kMHNotebookRestorableStateAssetLibraryVisibleTabIndex = @"assetlibraryvisibletab";


static const NSUInteger kMHNotebookMaxNumberOfRecentlyVisitedPages = 50; // FIXME: temporary for debugging, should be increased to some large number like 100



// Note: Make sure that these defines match the ordering of the segments in the segmented control as defined in MHNotebook.xib
#define kMHNotebookActionCreateNewPageSegmentIndex   0
#define kMHNotebookActionDeletePageSegmentIndex      1
#define kMHNotebookActionShowHideAssetLibrarySegmentIndex    3
#define kMHNotebookActionShowConfigurationSheetSegmentIndex   4




// tag for retrieving menu items from the main menu. They are set in Interface Builder in the MainMenu.xib file, make sure to keep the values in that file in sync with the values here
static const NSInteger kNavigateMenuItemTag = 1000;
const NSInteger kNavigationPreviousPageMenuItemTag = 1001;
const NSInteger kNavigationNextPageMenuItemTag = 1002;
const NSInteger kNavigationFirstPageInNotebookMenuItemTag = 1003;
const NSInteger kNavigationLastPageInNotebookMenuItemTag = 1004;
const NSInteger kNavigationGoToPageNumberMenuItemTag = 1005;

const NSInteger kToggleAutomaticQuoteSubstitutionMenuItemTag = 5678;
const NSInteger kToggleAutomaticDashSubstitutionMenuItemTag = 5679;

const NSInteger kViewMenuItemTag = 2000;
static const NSInteger kLockAspectRatioMenuItemTag = 3000;
static const NSInteger kPageMenuItemTag = 4000;
static const NSInteger kDeletePageMenuItemTag = 5000;
static const NSInteger kCreateNewPageMenuItemTag = 6000;
const NSInteger kShowHideAssetLibraryMenuItemTag = 7777;
const NSInteger kExportToPDFMenuItemTag = 8888;
const NSInteger kPrintMenuItemTag = 8900;



static NSMenuItem *templateMenuItemFromPlistEntry(NSDictionary *plistEntry);



#define NO_CURRENT_PAGE_SET_YET         NSIntegerMax


@interface MHNotebook () <NSTableViewDataSource, NSTableViewDelegate, NSTableViewWithDeleteShortcutDelegate>
{
    MHExpressionPresentationMode _presentationMode;
    
    NSArray <MHNotebookPage *> *_pages;
    NSUInteger _currentPageIndex;           // a value of NO_CURRENT_PAGE_SET_YET means there is no current page (happens only at initialization until a current page is set)
    
    MHSourceCodeEditorTheme *_editorTheme;
    
    NSMutableArray <NSString *> *_recentlyVisitedPagesList;
    NSUInteger _recentlyVisitedPagesListCurrentIndex;
    NSUInteger _pagesTableViewProgrammaticSelectionCounter;     // a clunky device to prevent unwanted recursion when switching pages (calling setCurrentPageIndex leads to changing the selection in the pages table view, which leads to a delegate call that again calls setCurrentPageIndex)
    
    NSAutoresizingMaskOptions _sourceCodeEditorAutoresizingMask;
    
    bool _timedSlidePresentationRunning;
    
    MHNotebookConfiguration *_notebookConfiguration;

    NSString *_configurationCode;
    MHNotebookConfigurationPanelController *_configurationSheetController;
    
    NSArray *_codeTemplatesArray;
    
    bool _awake;     // keeps track of whether awakeFromNib has been called
    
    bool _viewerViewLockedToPageAspectRatio;     // defaults to false
    
    NSString *_notebookDisplayName;
}

// IB outlets
@property IBOutlet NSTextView *dummySourceCodeEditorView;   // a xib-defined view used as a prototype for source code editor views
@property IBOutlet NSView *dummyPageViewerView;   // a xib-defined view used as a prototype for document views
@property IBOutlet NSScrollView *sourceCodeEditorEnclosingScrollView;
@property IBOutlet NSTextField *sourceCodeStatusLabel;
@property IBOutlet NSTextField *pageViewerStatusLabel;
@property IBOutlet NSTextField *notebookAuthorLabel;
@property IBOutlet NSTableViewWithDeleteShortcut *pageListTableView;
@property IBOutlet NSSegmentedControl *notebookActionsSegmentedControl;
@property IBOutlet NSSegmentedControl *previousNextPageSegmentedControl;
@property IBOutlet NSSegmentedControl *goBackForwardSegmentedControl;
@property IBOutlet NSSegmentedControl *slideNavigationSegmentedControl;
@property IBOutlet BFPageControl *slideTransitionPageControl;
@property IBOutlet NSProgressIndicator *slideTransitionProgressIndicator;
@property IBOutlet NSPopUpButton *editorThemeSelectionPopupButton;
@property IBOutlet NSMenuItem *pageViewerViewZoomIndicator;
@property IBOutlet NSMenuItem *lockPageViewerAspectRatioMenuItem;
@property IBOutlet NSMenu *codeTemplatesMenu;



// The array of pages in the notebook and a variable keeping track of the current page index
@property NSArray <MHNotebookPage *> *pages;
@property NSUInteger currentPageIndex;

@property MHSourceCodeEditorTheme *editorTheme;

@end


@interface MHNotebook (AssetLibrarySilencingAWarning)
// The methods declared below are implemented in the MHNotebook+AssetLibrary category, but needed in the main file, so I'm declaring them here to avoid making them public. The name of the category AssetLibrarySilencingAWarning is different from AssetLibrary just to silence a compiler warning about a duplicate definition of the same category. Not sure if this is the recommended way to achieve the same combination of effects in Objective-C or if I'm doing something slightly unorthodox, but this seems to work...
- (NSArray <NSString *> *)indexFilenamesByAssetType;
- (NSArray <NSString *> *)assetFolderNamesByAssetType;
@end


@implementation MHNotebook


#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Not much to do here, most of the actual initialization takes place in the awakeFromNib method
        
        _currentPageIndex = NO_CURRENT_PAGE_SET_YET;
        _notebookConfiguration = [[MHNotebookConfiguration alloc] init];
        _recentlyVisitedPagesList = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)awakeFromNib
{
    // Set the notebook author text field to an empty string if it hasn't been set, or whatever was set in the configuration code
    NSString *notebookAuthor = _notebookConfiguration.notebookAuthor;
    self.notebookAuthorLabel.stringValue = (notebookAuthor ? notebookAuthor : @"");
//    self.pageViewerViewWindow.title = (_notebookTitle ? _notebookTitle : self.displayName);
    
    // Register the dragged types for the page list table view (to enable drag and drop interface for reordering pages)
    [self.pageListTableView registerForDraggedTypes:@[kMHNotebookPageDraggingPasteboardType]];
    
    //  This line is needed if we want the MHSpriteKitScene object to accept mouse movement events
    self.pageViewerViewWindow.acceptsMouseMovedEvents = YES;

    // Record the autoresizing mask of the dummy source code editor view, and then discard the view
    _sourceCodeEditorAutoresizingMask = self.dummySourceCodeEditorView.autoresizingMask;
    [self.dummySourceCodeEditorView removeFromSuperview];
    self.dummySourceCodeEditorView = nil;   // we won't ever need this again, so zero out the property to free up the memory
    
    [self adjustUserInterfaceForPageSize];
    
    [self configureCodeTemplatesMenu];
    
    [self configureEditorThemesMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editorThemesChanged:)
                                                 name:kMHSourceCodeEditorThemeManagerThemesChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editorThemeWasRenamed:)
                                                 name:kMHSourceCodeEditorThemeManagerThemeWasRenamedNotification
                                               object:nil];

    // Set the editor theme
    MHSourceCodeEditorTheme *theme = [[MHSourceCodeEditorThemeManager defaultManager] userDefaultTheme];
    if (!theme) {
        theme = [[MHSourceCodeEditorThemeManager defaultManager] defaultTheme];    // a fallback in case the saved default theme doesn't exist
    }
    self.editorTheme = theme;

    // Go to the first page
    self.currentPageIndex = 0;
    self.currentPageIndex = 0;  // FIXME: this is ridiculous but doing the method call twice fixes a bug that causes the editor view to have an incorrect origin inside its parent clip view upon loading.
    
    [self initializeListOfRecentlyVisitedPages];

    // Configure the slide transition page control
    self.slideTransitionPageControl.hidesForSinglePage = true;
    self.slideTransitionPageControl.indicatorDiameterSize = 7;
    self.slideTransitionPageControl.indicatorMargin = 4;
    [self.currentPage updatePageStatusUserInterfaceElements];   // FIXME: not sure this is good OO practice
    self.timedSlidePresentationRunning = NO;
    
    [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus];
    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
    
    [self updateWindowTitles];
    
    _awake = true;
    
    if (!_configurationCode) {
        // this will run only when creating a new notebook
        [self setConfigurationCodeWithoutInvalidatingConfigurationCodeFileWrapper:[self defaultConfigurationCode]];
    }
    
    [self adjustUserInterfaceForPageSize];
}


#pragma mark - Miscellaneous configuration methods

+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    // FIXME: create override for -makeWindowControllers and custom NSWindowControllers to support both the source code editor and page viewer windows being considered document windows
    return kMHNotebookWindowNibName;
}

// Overriding this method since using setDisplayName: results in sometimes incorrect behavior, apparently because the NSDocument class interferes in some circumstances by setting the displayName property itself in ways I don't approve of, for example when saving/autosaving the document
- (NSString *)displayName
{
    if (!_notebookDisplayName)
        return super.displayName;
    return _notebookDisplayName;
}

- (NSString *)documentTypeStringThatMatchesInfoPlist
{
    return kMHNotebookDocumentType;
}


#pragma mark - Saving and loading documents from file


// Saving a notebook-document
- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing  _Nullable *)outError
{
    // Notebooks are saved as a directory file wrapper
        
    // Do we have an existing file wrapper associated with the document? If not, create an empty one
    if (!_notebookFileWrapper) {
        _notebookFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{ }];
    }
    
    // Get the dictionary of file wrappers in the root notebook folder
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;

    // Prepare a string with a list of the filenames separated by newlines to save in an index file
    NSMutableString *pageIndexString = [[NSMutableString alloc] initWithCapacity:0];
    
    // Cycle through the pages, building up the index string and creating file wrappers for any pages for which file wrappers are missing
    NSUInteger pageIndex = 0;
    NSUInteger numberOfPages = _pages.count;
    for (MHNotebookPage *page in _pages) {
        NSString *pagefilenameWithExtension = page.filenameWithExtension;
        [pageIndexString appendFormat:(pageIndex+1 < numberOfPages ? @"%@\n" : @"%@"), pagefilenameWithExtension];
        
        NSData *pageData = [page.code dataUsingEncoding:NSUTF8StringEncoding];
        NSFileWrapper *pageFileWrapper = fileWrappers[pagefilenameWithExtension];
        if (!pageFileWrapper) {
            // the page does not have an associated file wrapper, so create a new one
            pageFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:pageData];
            [_notebookFileWrapper addRegularFileWithContents:pageData preferredFilename:pagefilenameWithExtension];
        }
        pageIndex++;
    }
    
    // Create the file wrapper for the page index if it doesn't yet exist
    NSFileWrapper *pageIndexFileWrapper = fileWrappers[kMHNotebookPageIndexFileName];
    if (!pageIndexFileWrapper) {
        NSData *pageIndexData = [pageIndexString dataUsingEncoding:NSUTF8StringEncoding];
        [_notebookFileWrapper addRegularFileWithContents:pageIndexData preferredFilename:kMHNotebookPageIndexFileName];
    }

    // Create the file wrapper for the configuration code if it doesn't yet exist
    NSFileWrapper *configurationCodeFileWrapper = fileWrappers[kMHNotebookPageConfigurationFileName];
    if (!configurationCodeFileWrapper) {
        NSData *configurationCodeData = [self.configurationCode dataUsingEncoding:NSUTF8StringEncoding];
        [_notebookFileWrapper addRegularFileWithContents:configurationCodeData preferredFilename:kMHNotebookPageConfigurationFileName];
    }
    
    // Create the file wrapper for the image index if we have image assets and the index doesn't yet exist
    NSFileWrapper *imageIndexFileWrapper = fileWrappers[kMHNotebookImageIndexFileName];
    if (!imageIndexFileWrapper) {
        NSArray <NSString *> *imageIndex = [self indexOfAssetsOfType:MHAssetImage];
        if (imageIndex.count > 0) {
            // Build up the image index, which is a text file with the filenames for the image library listed separated by newlines
            NSMutableString *imageIndexString = [[NSMutableString alloc] initWithCapacity:0];
            for (NSString *imageFilename in imageIndex) {
                // Append the image filename to the index string
                [imageIndexString appendFormat:(pageIndex+1 < numberOfPages ? @"%@\n" : @"%@"), imageFilename];
            }
            NSData *imageIndexData = [imageIndexString dataUsingEncoding:NSUTF8StringEncoding];
            [_notebookFileWrapper addRegularFileWithContents:imageIndexData preferredFilename:kMHNotebookImageIndexFileName];
        }
    }
    
    // Note: we don't create the file wrappers for the image files themselves in this method, but assume they have already been created dynamicaly at the time the images were added to the library (and when operations such as file renaming are performed, the file wrappers are updated at the same time). This allows us not to store the images in memory

    // Return the main wrapper
    return _notebookFileWrapper;
}


// Loading a notebook-document
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    if (![typeName isEqualToString:[self documentTypeStringThatMatchesInfoPlist]]) {
        NSLog(@"Error: unknown document type '%@'", typeName);
        return false;
    }
    
    if (![MHDocumentController appConfigurationComplete]) {
        return false;
    }
    
    // Notebooks can be loaded either from a file wrapper representing a regular file (a single-page document)
    // or from a directory (multi-page document)
    
    // FIXME: disabling the single-file option for refactoring, consider restoring this later:
//    if (fileWrapper.regularFile) {
//        // A single page document
//        NSData *pageData = fileWrapper.regularFileContents;
//        NSString *pageCode = [[NSString alloc] initWithData:pageData encoding:NSUTF8StringEncoding];
//        MHNotebookPage *page = [[MHNotebookPage alloc] init];
//        page.notebook = self;
//        page.code = pageCode;
//        self.pages = [NSArray arrayWithObject:page];
//        return true;
//    }
//    else if (fileWrapper.directory) {
//        // code for handling a notebook stored in a directory (the default option)
//        // ....
//    }
//
//    // don't know how to deal with a wrapper that isn't a regular file or a directory
//    NSLog(@"Error: unknown document type");
//    return false;

    
    
    // A multi-page document
    
    // Create an array for the pages
    NSMutableArray *newPages = [[NSMutableArray alloc] initWithCapacity:0];

    
    // First, look for a page index
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = fileWrapper.fileWrappers;
    NSFileWrapper *indexFileWrapper = fileWrappers[kMHNotebookPageIndexFileName];
    
    // Do we have an index?
    if (indexFileWrapper) {
        // Found the index, so read its contents and parse into an array of file names for the pages
        NSData *indexData = [indexFileWrapper regularFileContents];
        NSString *indexString = [[NSString alloc] initWithData:indexData encoding:NSUTF8StringEncoding];
        NSArray <NSString *> *pageFileNames = [indexString componentsSeparatedByString:@"\n"];
                    
        // Cycle through the file names, for each one read the file, create the page and add it to the array
        for (NSString *pageFileName in pageFileNames) {
            NSFileWrapper *pageFileWrapper = fileWrappers[pageFileName];
            NSData *pageData = [pageFileWrapper regularFileContents];
            NSString *pageCode = [[NSString alloc] initWithData:pageData encoding:NSUTF8StringEncoding];
            if (pageCode) {
                MHNotebookPage *page = [[MHNotebookPage alloc] initWithNotebookConfiguration:_notebookConfiguration];
                page.notebook = self;
                page.code = pageCode;
                page.filename = [pageFileName stringByDeletingPathExtension];
                [newPages addObject:page];
            }
        }
    }
    else {
        // Didn't find the index, so read the pages in whatever order the file wrappers come in
        for (NSString *pageFileName in fileWrappers) {
            NSFileWrapper *pageFileWrapper = fileWrappers[pageFileName];
            NSData *pageData = [pageFileWrapper regularFileContents];
            NSString *pageCode = [[NSString alloc] initWithData:pageData encoding:NSUTF8StringEncoding];
            if (pageCode) {
                MHNotebookPage *page = [[MHNotebookPage alloc] initWithNotebookConfiguration:_notebookConfiguration];
                page.notebook = self;
                page.code = pageCode;
                page.filename = [pageFileName stringByDeletingPathExtension];
                [newPages addObject:page];
            }
        }
    }
    
    // Set the pages array
    self.pages = [NSArray arrayWithArray:newPages];

    // Next, try to read the configuration code
    NSFileWrapper *configurationCodeFileWrapper = fileWrappers[kMHNotebookPageConfigurationFileName];
    
    // Do we have a configuration code file?
    if (configurationCodeFileWrapper) {
        // Read the configuration code
        NSData *configurationCodeData = [configurationCodeFileWrapper regularFileContents];
        NSString *configurationCodeString = [[NSString alloc] initWithData:configurationCodeData encoding:NSUTF8StringEncoding];
        if (configurationCodeString) {
            [self setConfigurationCodeWithoutInvalidatingConfigurationCodeFileWrapper:configurationCodeString];
        }
    }
    
    // Save the file wrapper so that we can update it as notebook content is created and modified
    _notebookFileWrapper = fileWrapper;
    
    // Note: the notebook may contain additional data that is only loaded from disk as it's needed (it can be retrieved using the file wrapper we saved). Currently this applies to image assets
    
    // Return true to indicate the document was opened successfully
    return true;
}



#pragma mark - Accessor methods

- (NSArray <MHNotebookPage *> *)pages
{
    // Lazily create the pages array if it hasn't been initialized yet
    if (!_pages) {
        // initialize pages array with a single empty page
        MHNotebookPage *emptyPage = [[MHNotebookPage alloc] initWithNotebookConfiguration:_notebookConfiguration];
        emptyPage.notebook = self;
        self.pages = @[emptyPage];
    }

    return _pages;
}

- (void)setPages:(NSArray<MHNotebookPage *> *)pages
{
    _pages = pages;
    if (_awake) {
        self.currentPageIndex = 0;
    }
    [self initializeListOfRecentlyVisitedPages];
    [self.pageListTableView reloadData];

    [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus];
    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
}

- (MHNotebookPage *)currentPage
{
    if (_currentPageIndex == NO_CURRENT_PAGE_SET_YET)
        return nil;
    return _pages[_currentPageIndex];
}

- (NSUInteger)currentPageIndex
{
    return _currentPageIndex;
}

- (void)setCurrentPageIndex:(NSUInteger)newPageIndex
{
    // This method is separated into two methods in a slightly clunky way:
    // In normal usage the first responder status is transferred to the source code editor view after changing the page,
    // but there is an option to do it without that change of first responder for use when navigating through the page list table view
    [self setCurrentPageIndexWithoutChangingFirstResponder:newPageIndex];
    
    MHNotebookPage *currentPage = [_pages objectAtIndex:newPageIndex];
    MHSourceCodeTextView *editorView = currentPage.sourceCodeEditorView;
    [editorView.window makeFirstResponder:editorView];
}

- (void)setCurrentPageIndexWithoutChangingFirstResponder:(NSUInteger)newPageIndex
{

    NSArray <MHNotebookPage *> *myPages = self.pages;
    NSUInteger numberOfPages  = myPages.count;
    
    if (newPageIndex >= numberOfPages)
        return;     // the requested page doesn't exist - ignore

    if (_currentPageIndex != NO_CURRENT_PAGE_SET_YET && _currentPageIndex < numberOfPages) {
        // If rotating out an existing page, do some relevant housekeeping
        MHNotebookPage *oldPage = [self.pages objectAtIndex:_currentPageIndex];
        [self rotateOutPage:oldPage];
    }
    
    _currentPageIndex = newPageIndex;
    
    // Get the page to set as the current page
    MHNotebookPage *newPage = [self.pages objectAtIndex:newPageIndex];
    
    // Install the page's source code editor view as the document view for the scroll view we got from the nib file
    MHSourceCodeTextView *editorView = newPage.sourceCodeEditorView;
    editorView.editable = !(self.isInViewingMode);
    editorView.autoresizingMask = _sourceCodeEditorAutoresizingMask;
//    NSRect scrollViewFrame = self.sourceCodeEditorEnclosingScrollView.frame;
    NSRect clipViewFrame = self.sourceCodeEditorEnclosingScrollView.contentView.frame;
    editorView.frame = NSMakeRect(0.0, 0.0, clipViewFrame.size.width, 0.0);
    editorView.editorTheme = self.editorTheme;
    
    // Start the cursor at the top
    editorView.selectedRange = NSMakeRange(0, 0);

    // configure the page's viewer view and add it to the page viewer view window
    MHPageViewerView *pageViewerView = newPage.pageViewerView;
    NSView *dummyPageViewerView = self.dummyPageViewerView;
    pageViewerView.frame = dummyPageViewerView.frame;
    pageViewerView.autoresizingMask = dummyPageViewerView.autoresizingMask;
    [self.pageViewerViewWindow.contentView addSubview:pageViewerView];
    [self.pageViewerViewWindow makeFirstResponder:pageViewerView];

    pageViewerView.postsFrameChangedNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageViewerViewResized:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:pageViewerView];

    
    // Let the page know it is about to become active
    [newPage pageWillBecomeActive];
    
    [self.sourceCodeEditorEnclosingScrollView setDocumentView:editorView];
    [newPage pageDidBecomeActive];
    
    // Reset the page's state to the default/initial one
    [newPage moveToFirstSlide];   // FIXME: should this, and other setup below, be done by the page in the pageWillBecomeActive method?
    
    // The status labels are defined in the xib file but the page needs to know about them
    [newPage setPageStatusInterfaceElementsWithCodeStatusLabel:self.sourceCodeStatusLabel
                                         pageViewerStatusLabel:self.pageViewerStatusLabel
                                    slideTransitionPageControl:self.slideTransitionPageControl
                              slideTransitionProgressIndicator:self.slideTransitionProgressIndicator];

    // Set the page's row in the page list table view as the currently selected row
    _pagesTableViewProgrammaticSelectionCounter++;  // this prevents unwanted recursion that could potentially mess things up
    [self.pageListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newPageIndex] byExtendingSelection:NO];
    _pagesTableViewProgrammaticSelectionCounter--;

    // Depending on the index of the page, we want to enable or disable the next page and previous page controls
    [self.previousNextPageSegmentedControl setEnabled:(newPageIndex > 0) forSegment:0];
    [self.previousNextPageSegmentedControl setEnabled:(newPageIndex+1 < _pages.count) forSegment:1];
    
//    // Set the title of the document view window to the page's filename
//    // FIXME: also done in MHNotebookPage.m setFilename method, violates DRY principle
//    self.pageViewerViewWindow.title = newPage.filename;
    [self updateWindowTitles];
    [self invalidateRestorableState];
}

- (void)rotateOutPage:(MHNotebookPage *)pageRotatingOut
{
    // Let the page know it is about to become inactive
    [pageRotatingOut pageWillBecomeInactive];
    
    // FIXME: maybe this should be done by the page itself in the pageWillBecomeInactive method?
    [pageRotatingOut setPageStatusInterfaceElementsWithCodeStatusLabel:nil
                                                 pageViewerStatusLabel:nil
                                            slideTransitionPageControl:nil
                                      slideTransitionProgressIndicator:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewFrameDidChangeNotification
                                                  object:pageRotatingOut.pageViewerView];

    [pageRotatingOut.pageViewerView removeFromSuperview];
}

- (void)updateWindowTitles
{
    NSString *sourceCodeEditorWindowTitle;
    NSString *pageViewerWindowTitle;
    NSString *notebookFilenameWithoutPathExtension = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
    bool usedSuperDisplayName = false;
    if (!notebookFilenameWithoutPathExtension) {
        usedSuperDisplayName = true;
        notebookFilenameWithoutPathExtension = super.displayName;
    }
    
    NSString *notebookTitle = _notebookConfiguration.notebookTitle;
    if (notebookTitle) {
        sourceCodeEditorWindowTitle = [NSString stringWithFormat:@"%@ [%@]", notebookTitle, notebookFilenameWithoutPathExtension];
        pageViewerWindowTitle = notebookTitle;
    }
    else {
        sourceCodeEditorWindowTitle = notebookFilenameWithoutPathExtension;
        pageViewerWindowTitle = notebookFilenameWithoutPathExtension;
    }

    if (!usedSuperDisplayName)
        _notebookDisplayName = sourceCodeEditorWindowTitle;
    self.sourceCodeEditorWindow.title = sourceCodeEditorWindowTitle;  // FIXME: updating the source code editor window title doesn't work in awakeFromNib. Probably I'm trying to override default behavior of a document-based app in the wrong way. The right way to do it would apparently be to create a custom NSWindowController subclass
// see here for a related discussion: https://stackoverflow.com/questions/25385088/cocoa-document-based-app-nswindowcontroller-subclass-as-main-window
    
    if (pageViewerWindowTitle)
        self.pageViewerViewWindow.title = pageViewerWindowTitle;
}


#pragma mark - Properties


- (void)setNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration
{
    _notebookConfiguration = notebookConfiguration;
    
    [self adjustUserInterfaceForPageSize];
    [self updateWindowTitles];
    for (MHNotebookPage *page in self.pages) {
        page.notebookConfiguration = _notebookConfiguration;
    }
}

- (void)adjustUserInterfaceForPageSize
{
    if (!_awake)
        return;     // this method only does things after the user interface has been set up
    
    NSSize pageSize = _notebookConfiguration.pageSize;
    if (pageSize.width < MHPageSizeMinimumWidth)
        pageSize.width = MHPageSizeMinimumWidth;
    if (pageSize.height < MHPageSizeMinimumHeight)
        pageSize.height = MHPageSizeMinimumHeight;

    NSRect oldPageViewerViewWindowFrame = self.pageViewerViewWindow.frame;
    NSRect newPageViewerViewWindowFrame = oldPageViewerViewWindowFrame;
    NSRect pageViewerViewFrame = self.dummyPageViewerView.frame;
    newPageViewerViewWindowFrame.size.width = oldPageViewerViewWindowFrame.size.width
                + pageSize.width - pageViewerViewFrame.size.width;
    newPageViewerViewWindowFrame.size.height = oldPageViewerViewWindowFrame.size.height
                + pageSize.height - pageViewerViewFrame.size.height;
    [self.pageViewerViewWindow setFrame:newPageViewerViewWindowFrame display:YES];
}

- (NSString *)defaultConfigurationCode
{
    // read the default configuration code from file - this is a global string variable that only needs to be loaded once and can be accessed by all MHNotebook instances
    static NSString *defaultConfigurationCode;
    if (!defaultConfigurationCode) {
        NSString *defaultConfigurationCodeFilename = [[NSBundle mainBundle] pathForResource:kMHNotebookDefaultConfigurationCodeFilename
                                                                                     ofType:kMHNotebookDefaultConfigurationCodeFileExtension];

        defaultConfigurationCode = [NSString stringWithContentsOfFile:defaultConfigurationCodeFilename
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
        if (!defaultConfigurationCode) {
            // a fallback string in case we cannot load the default code from the file where it's supposed to be
            defaultConfigurationCode = NSLocalizedString(@"％ Enter the notebook configuration code here\n\n", @"");
        }
    }
    return defaultConfigurationCode;
}

- (NSString *)configurationCode
{
    if (!_configurationCode)
        _configurationCode = [self defaultConfigurationCode];
    return _configurationCode;
}


- (void)setConfigurationCode:(NSString *)configurationCode
{
    [self setConfigurationCodeWithoutInvalidatingConfigurationCodeFileWrapper:configurationCode];
            
    // Invalidate the file wrapper associated with the configuration code so it gets written to file on document save
    [self invalidateConfigurationCodeFileWrapper];
}

// We need a version of this method that sets the configuration code without invalidating the file wrapper
// This gets called during notebook loading
- (void)setConfigurationCodeWithoutInvalidatingConfigurationCodeFileWrapper:(NSString *)configurationCode
{
    _configurationCode = configurationCode;

    // Parse and typeset the configuration code
    // FIXME: this code snippet needs to be refactored - there should be a convenience method for quickly parsing/typesetting a string of code without having to manually create a source code view
    MHParser *parser = [[MHParser alloc] init];
    parser.notebookConfigurationCommandsEnabled = YES;
    MHSourceCodeTextView *sourceCodeView = [[MHSourceCodeTextView alloc] initWithFrame:NSZeroRect
                                                                         textContainer:nil];
    sourceCodeView.codeEditingDelegate = parser;
    sourceCodeView.string = configurationCode;
    [parser parseCode:sourceCodeView.textStorage];
    MHTypesettingContextManager *typesettingContextManager = [[MHTypesettingContextManager alloc] init];
    [parser.compiledExpression typesetWithContextManager:typesettingContextManager];
    
    MHNotebookConfiguration *newNotebookConfig = typesettingContextManager.notebookConfiguration;
    self.notebookConfiguration = newNotebookConfig;
}

- (bool)timedSlidePresentationRunning
{
    return _timedSlidePresentationRunning;
}

- (void)setTimedSlidePresentationRunning:(bool)slidePresentationRunning
{
    _timedSlidePresentationRunning = slidePresentationRunning;
    NSString *playPauseActionString;
    if (_timedSlidePresentationRunning) {
        [self.currentPage startOrResumeSlidePresentation];
        playPauseActionString = NSLocalizedString(@"Pause", @"");
        _slideTransitionProgressIndicator.hidden = NO;
    }
    else {
        [self.currentPage pauseSlidePresentation];
        playPauseActionString = NSLocalizedString(@"Play", @"");
        _slideTransitionProgressIndicator.hidden = YES;
    }
}
         

#pragma mark - User actions


- (IBAction)presentationModeChanged:(NSPopUpButton *)sender
{
    NSUInteger selectedIndex = sender.indexOfSelectedItem;
    for (MHNotebookPage *page in self.pages) {
        page.presentationMode = (MHExpressionPresentationMode)selectedIndex;
    }
}

- (IBAction)goToNextOrPreviousPage:(NSSegmentedControl *)sender
{
    switch (sender.selectedSegment) {
        case 0: // previous page
            [self programmaticallyGoToPreviousPage];
            break;
        case 1: // next page
            [self programmaticallyGoToNextPage];
            break;
    }
}


- (IBAction)notebookActionFromSegmentedControl:(NSSegmentedControl *)sender
{
    // Handling for various actions that appear in the small segmented control in the source code editor window (currently in the bottom left corner)
    switch (sender.selectedSegment) {
        case kMHNotebookActionCreateNewPageSegmentIndex:
            [self addNewPageAfterCurrentPageAndSetItAsCurrentPage:nil];
            break;
        case kMHNotebookActionDeletePageSegmentIndex:
            [self initiateCurrentPageDeletionSequence:nil];
            break;
        case kMHNotebookActionShowHideAssetLibrarySegmentIndex:
            [self toggleAssetLibrary:nil];
            break;
        case kMHNotebookActionShowConfigurationSheetSegmentIndex: {
            void (^handler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
                // Release the modal sheet window controller
                self->_configurationSheetController = nil;
            };

            _configurationSheetController = [[MHNotebookConfigurationPanelController alloc] initWithWindowNibName:@"MHNotebookConfigurationSheet"];
            _configurationSheetController.configurationCode = self.configurationCode;
            
            _configurationSheetController.editorTheme = self.editorTheme;

            _configurationSheetController.parentNotebook = self;
            
            NSWindow *configurationSheetWindow = _configurationSheetController.window;
            configurationSheetWindow.delegate = self;
            
            [self.notebookActionsSegmentedControl.window beginSheet:_configurationSheetController.window completionHandler:handler];
        }
            break;
    }
}

- (IBAction)editorThemeChange:(NSPopUpButton *)selectionPopup
{
    NSString *selectedThemeName = selectionPopup.titleOfSelectedItem;
    MHSourceCodeEditorTheme *newTheme = [[MHSourceCodeEditorThemeManager defaultManager] themeWithName:selectedThemeName];
    if (newTheme) {
        self.editorTheme = newTheme;
    }
}



#pragma mark - NSTableViewDelegate, NSTableViewWithDeleteShortcutDelegate and NSTableViewDataSource methods to manage the page list NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _pages.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // The table has two columns, one showing the page number and the other the filename/short title for the page
    
    // We recognize the columns by their identifier. These are hard-coded above in constant NSString vars and are also
    // defined separately in the xib file (FIXME: small violation of DRY principle - is there a way to avoid this?)
    
    NSString *columnIdentifier = aTableColumn.identifier;
    
    if ([columnIdentifier isEqualToString:kMHNotebookPageListColumnIdentifierPageNumber]) {
        return [NSString stringWithFormat:@"%lu", rowIndex+1];
    }
    if ([columnIdentifier isEqualToString:kMHNotebookPageListColumnIdentifierFilename]) {
        MHNotebookPage *page = _pages[rowIndex];
        return page.filename;
    }
    
    // This code should never run, but fail gracefully if it does
    return @"?";
}

// Experimental code: trying to convert to a view-based table view with a nice drag-and-drop animation, maybe try making it work later
//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
//{
//    NSString *columnIdentifier = aTableColumn.identifier;
//
//    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
//    textField.backgroundColor = [NSColor clearColor];
//
//    if ([columnIdentifier isEqualToString:kMHNotebookPageListColumnIdentifierPageNumber]) {
//        textField.stringValue = [NSString stringWithFormat:@"%lu", rowIndex+1];
//        textField.editable = false;
//        return textField;
//    }
//    if ([columnIdentifier isEqualToString:kMHNotebookPageListColumnIdentifierFilename]) {
//        textField.stringValue = _pages[rowIndex].filename;
//        textField.editable = true;
//        return textField;
//    }
//
//    // This code should never run, but fail gracefully if it does
//    return nil; //@"?";
//}
//- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
//{
//    [self.pageListTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleGap];
//}
// End of experimental code


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger pageIndex = self.pageListTableView.selectedRow;
    if (pageIndex >= 0) {
        // Transition to the selected page, but keep the focus on the table so the user can use the up/down arrow keys to repeatedly navigate through the pages
        if (_pagesTableViewProgrammaticSelectionCounter == 0) {
            [self setCurrentPageIndexWithoutChangingFirstResponder:pageIndex];
            [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
        }
    }
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(NSString *)newPageFilename
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    // Renaming a page
    if (self.isInViewingMode) {
        NSBeep();
        return;
    }
    
    if (![self renamePageWithIndex:row newPageFilename:newPageFilename]) {
        NSBeep();   // beep!
        // FIXME: maybe add some way to explain to the user why the operation failed
    }
}



- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    // When the user initiates a drag action with a page, we store the row index for the page in a pasteboard item
    // This will be used at the drop action to reorder the pages
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setString:[NSString stringWithFormat:@"%d", (int)row] forType:kMHNotebookPageDraggingPasteboardType];
    return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)toRow
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (self.isInViewingMode)
        return NSDragOperationNone;
    
    bool draggingOperationIsCopy = (info.draggingSourceOperationMask == NSDragOperationCopy);
    
    if (dropOperation == NSTableViewDropAbove) {
        // Recover the index of the row where the page was dragged from
        NSString *pasteboardString = [info.draggingPasteboard stringForType:kMHNotebookPageDraggingPasteboardType];
        NSInteger fromRow = [pasteboardString integerValue];

        // If the operation makes sense for the values of fromRow and toRow, return NSDragOperationMove
        if (draggingOperationIsCopy)
            return NSDragOperationCopy;
        return ((toRow == fromRow || toRow == fromRow+1) ? NSDragOperationNone : NSDragOperationMove);
    }
    
    // We only allow dropping a page between page table entries, not on top of another page
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)toRow
    dropOperation:(NSTableViewDropOperation)dropOperation
{
    bool draggingOperationIsCopy = (info.draggingSourceOperationMask == NSDragOperationCopy);
    
    // Which page were we dragging?
    NSString *pasteboardString = [info.draggingPasteboard stringForType:kMHNotebookPageDraggingPasteboardType];
    NSInteger fromRow = [pasteboardString integerValue];
    
    if (draggingOperationIsCopy) {
        // Copy the page
        [self copyPageWithIndex:fromRow toIndex:toRow];
    }
    else {
        // The page will be moved - perform the reordering operation
        [self movePageWithIndex:fromRow toIndex:toRow];
    }
    
    return YES;
}


- (void)tableViewDeleteRowShortcutInvoked:(NSTableView *)tableView
{
    [self initiateCurrentPageDeletionSequence:nil];
}






#pragma mark - Debugging menu actions

- (IBAction)retypesetCurrentPage:(id)sender
{
    // FIXME: this doesn't work well with slides and outliner/collapsible sections
    [self.currentPage retypeset];
}




#pragma mark - Recently visited pages list

// FIXME: the implementation of this feature works in my testing, but the logic ends up being surprisingly messy and clunky. Perhaps this can be cleaned up and made simpler, with fewer dangerous dependencies that could make things break in the future

- (void)clearRecentlyVisitedPagesList:(id)sender
{
    [self initializeListOfRecentlyVisitedPages];
}

- (void)initializeListOfRecentlyVisitedPages
{
    [_recentlyVisitedPagesList removeAllObjects];

    MHNotebookPage *currentPage = self.currentPage;
    if (currentPage) {
        [_recentlyVisitedPagesList addObject:currentPage.filename];
        [self setRecentlyVisitedPagesListCurrentIndex:0];
    }
}

- (void)markCurrentPageAsRecentlyVisitedAfterNavigatingToIt
{
    NSUInteger numberOfRecentlyVisitedPages = _recentlyVisitedPagesList.count;
    
    // Remove from the list of recently visited pages any pages with an index greater than the current one
    if (_recentlyVisitedPagesListCurrentIndex+1 < numberOfRecentlyVisitedPages) {
        NSRange rangeOfPagesToRemove = NSMakeRange(_recentlyVisitedPagesListCurrentIndex+1, numberOfRecentlyVisitedPages-_recentlyVisitedPagesListCurrentIndex-1);
        [_recentlyVisitedPagesList removeObjectsInRange:rangeOfPagesToRemove];
    }
    
    // Add the current page, but only if it's different from the page currently pointed to on the list
    NSString *currentPageName = self.currentPage.filename;
    if (numberOfRecentlyVisitedPages > _recentlyVisitedPagesListCurrentIndex &&
        ![currentPageName isEqualToString:_recentlyVisitedPagesList[_recentlyVisitedPagesListCurrentIndex]]) {
        [_recentlyVisitedPagesList addObject:self.currentPage.filename];
        [self incrementRecentlyVisitedPagesListCurrentIndex];
    }
    
    // Make sure the number of pages on the list stays at or below the allowed maximum
    if (numberOfRecentlyVisitedPages+1 > kMHNotebookMaxNumberOfRecentlyVisitedPages) {
        [_recentlyVisitedPagesList removeObjectAtIndex:0];
        [self decrementRecentlyVisitedPagesListCurrentIndex];   // FIXME: inefficient to call the increment... method and then immediately after decrement..., duplicating some of the work done as a result of those methods - improve
    }
}

- (void)updateRecentlyVisitedPagesListForPageDeletion:(NSString *)pageFilename
{
    [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];

    NSMutableArray *pagesToRemove = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger numberOfPagesToRemove = 0;
    for (NSString *filename in _recentlyVisitedPagesList) {
        if ([filename isEqualToString:pageFilename]) {
            [pagesToRemove addObject:filename];
            numberOfPagesToRemove++;
        }
    }
    if (numberOfPagesToRemove > 0) {
        [_recentlyVisitedPagesList removeObjectsInArray:pagesToRemove];
        _recentlyVisitedPagesListCurrentIndex -= numberOfPagesToRemove;
    }
    
    // after removing the unwanted page from the list, some of the remaining pages might contain successive duplicates (the same page appearing two or more times in immediate succession), which for page navigation purposes is a pointless thing to have. So scan through the list again to eliminate the duplicates
    NSMutableIndexSet *duplicatesToRemove = [NSMutableIndexSet indexSet];
    NSString *previousName = nil;
    NSUInteger index = 0;
    numberOfPagesToRemove = 0;
    for (NSString *filename in _recentlyVisitedPagesList) {
        if (previousName && [filename isEqualToString:previousName]) {
            [duplicatesToRemove addIndex:index];
            numberOfPagesToRemove++;
        }
        else {
            previousName = filename;
        }
        index++;
    }
    if (numberOfPagesToRemove > 0) {
        [_recentlyVisitedPagesList removeObjectsAtIndexes:duplicatesToRemove];
        _recentlyVisitedPagesListCurrentIndex -= numberOfPagesToRemove;
    }

    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
}

- (void)setRecentlyVisitedPagesListCurrentIndex:(NSUInteger)newIndex
{
    _recentlyVisitedPagesListCurrentIndex = newIndex;
    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
}

- (void)updateRecentlyVisitedPagesListMenuAndUserInterface
{
    if (!_awake)
        return;
    
    static const NSInteger kGoBackSegmentIndex = 0;
    static const NSInteger kGoForwardSegmentIndex = 1;

    BOOL enableGoBackButton = (_recentlyVisitedPagesListCurrentIndex > 0);
    BOOL enableGoForwardButton = (_recentlyVisitedPagesListCurrentIndex+1 < _recentlyVisitedPagesList.count);
    NSSegmentedControl *goBackForwardSegmentedControl = self.goBackForwardSegmentedControl;
    [goBackForwardSegmentedControl setEnabled:enableGoBackButton forSegment:kGoBackSegmentIndex];
    [goBackForwardSegmentedControl setEnabled:enableGoForwardButton forSegment:kGoForwardSegmentIndex];


    NSMenu *recentlyVisitedPagesMenu = [[NSMenu alloc] initWithTitle:@"Recently Visited"];
    
    NSMenuItem *headerMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Recently visited pages", @"")
                                                            action:nil
                                                     keyEquivalent:@""];

    // adding a header item and a separator item before adding the list of menu items for the recently visited pages
    // note: in the -goToRecentlyVisitedPageMenuItemAction: method call below, the "-2" in the index calculation
    // accounts for the these two leading menu items. If the code here changes, don't forget to update that -2
    [recentlyVisitedPagesMenu addItem:headerMenuItem];
    [recentlyVisitedPagesMenu addItem:[NSMenuItem separatorItem]];

    if (enableGoBackButton || enableGoForwardButton) {
        NSUInteger numberOfRecentlyVisitedPages = _recentlyVisitedPagesList.count;
        for (NSInteger index = numberOfRecentlyVisitedPages-1; index >= 0; index--) {
            NSString *pageName = _recentlyVisitedPagesList[index];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:pageName
                                                              action:@selector(goToRecentlyVisitedPageMenuItemAction:)
                                                       keyEquivalent:@""];
            [recentlyVisitedPagesMenu addItem:menuItem];
            if (index == _recentlyVisitedPagesListCurrentIndex) {
                menuItem.state = NSControlStateValueOn;
                NSImage *bulletImage = [NSImage imageNamed:@"bullet"];
                menuItem.onStateImage = bulletImage;
                menuItem.enabled = NO;
            }
            else {
                menuItem.state = NSControlStateValueOff;
                menuItem.enabled = YES;
            }
        }
        
        NSMenuItem *clearItemsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear Menu", @"")
                                                                    action:@selector(clearRecentlyVisitedPagesList:)
                                                             keyEquivalent:@""];
        [recentlyVisitedPagesMenu addItem:[NSMenuItem separatorItem]];
        [recentlyVisitedPagesMenu addItem:clearItemsMenuItem];
    }

    
    [goBackForwardSegmentedControl setMenu:(enableGoBackButton ? recentlyVisitedPagesMenu : nil) forSegment:kGoBackSegmentIndex];
    [goBackForwardSegmentedControl setMenu:(enableGoForwardButton ? recentlyVisitedPagesMenu : nil) forSegment:kGoForwardSegmentIndex];
}

- (void)updateRecentlyVisitedPagesListForPageRenamingFrom:(NSString *)oldPageFilename to:(NSString *)newPageFilename
{
    NSUInteger numberOfRecentlyVisitedPages = _recentlyVisitedPagesList.count;
    for (NSUInteger index = 0; index < numberOfRecentlyVisitedPages; index++) {
        NSString *pageName = _recentlyVisitedPagesList[index];
        if ([pageName isEqualToString:oldPageFilename]) {
            [_recentlyVisitedPagesList replaceObjectAtIndex:index withObject:newPageFilename];
        }
    }
    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
}

- (void)goToRecentlyVisitedPageMenuItemAction:(NSMenuItem *)menuItem
{
    NSString *pageName = menuItem.title;
    [self goProgrammaticallyToPageNamed:pageName];
    _recentlyVisitedPagesListCurrentIndex = _recentlyVisitedPagesList.count - 1 - ([menuItem.menu indexOfItem:menuItem]-2); // the -2 is needed to account for the header and separator menu items at the beginning of the menu items array
    [self updateRecentlyVisitedPagesListMenuAndUserInterface];
}

- (void)incrementRecentlyVisitedPagesListCurrentIndex
{
    [self setRecentlyVisitedPagesListCurrentIndex:_recentlyVisitedPagesListCurrentIndex+1];
}

- (void)decrementRecentlyVisitedPagesListCurrentIndex
{
    [self setRecentlyVisitedPagesListCurrentIndex:_recentlyVisitedPagesListCurrentIndex-1];
}



#pragma mark - Page navigation

// FIXME: make method names in this section more descriptive

- (IBAction)goBackOrForwardSegmentedControlAction:(NSSegmentedControl *)sender
{
    switch (sender.selectedSegment) {
        case 0: // go back to the previous visited page
            [self goBack:nil];
            break;
        case 1: // go forward to the next visited page
            [self goForward:nil];
            break;
    }
}

- (IBAction)goBack:(id)sender
{
    if (_recentlyVisitedPagesListCurrentIndex > 0) {
        NSString *previousPageVisited = _recentlyVisitedPagesList[_recentlyVisitedPagesListCurrentIndex-1];
        if ([self goProgrammaticallyToPageNamed:previousPageVisited])
            [self decrementRecentlyVisitedPagesListCurrentIndex];
    }
    else {
        NSBeep();
    }
}

- (IBAction)goForward:(id)sender
{
    if (_recentlyVisitedPagesListCurrentIndex+1 < _recentlyVisitedPagesList.count) {
        NSString *pageVisitedAfterThisOne = _recentlyVisitedPagesList[_recentlyVisitedPagesListCurrentIndex+1];
        if ([self goProgrammaticallyToPageNamed:pageVisitedAfterThisOne]) {
            [self incrementRecentlyVisitedPagesListCurrentIndex];
        }
    }
    else {
        NSBeep();
    }
}

- (IBAction)goToFirstPage:(id)sender
{
    if (self.currentPageIndex > 0) {
        self.currentPageIndex = 0;
        [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
    }
}

- (IBAction)goToLastPage:(id)sender
{
    NSUInteger currentPageIndex = self.currentPageIndex;
    if (currentPageIndex+1 < _pages.count) {
        self.currentPageIndex = _pages.count-1;
        [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
    }
}

- (IBAction)goToPreviousPage:(id)sender
{
    [self programmaticallyGoToPreviousPage];
}

- (IBAction)goToNextPage:(id)sender
{
    [self programmaticallyGoToNextPage];
}

- (bool)programmaticallyGoToNextPage        // FIXME: not a very informative name, and it may be a bit confusing why I also have a goToNextPage: method
{
    NSUInteger currentPageIndex = self.currentPageIndex;
    if (currentPageIndex+1 < _pages.count) {
        self.currentPageIndex = currentPageIndex+1;
        [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
        return true;
    }
    return false;
}

- (bool)programmaticallyGoToPreviousPage
{
    NSUInteger currentPageIndex = self.currentPageIndex;
    if (currentPageIndex > 0) {
        self.currentPageIndex = currentPageIndex-1;
        [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
        return true;
    }
    return false;
}

- (BOOL)slideTransitionsCanTransitionAcrossPages
{
    return YES;
}

- (IBAction)goToNextTransition:(id)sender
{
    MHNotebookPage *currentPage = _pages[self.currentPageIndex];
    if (![currentPage moveToNextSlide] && self.slideTransitionsCanTransitionAcrossPages) {
        [self programmaticallyGoToNextPage];
    }
}

- (IBAction)goToPreviousTransition:(id)sender
{
    MHNotebookPage *currentPage = _pages[self.currentPageIndex];
    if (![currentPage moveToPreviousSlide] && self.slideTransitionsCanTransitionAcrossPages) {
        if (self.currentPageIndex > 0) {
            [self programmaticallyGoToPreviousPage];
            currentPage = _pages[self.currentPageIndex];
            [currentPage moveToLastSlide];
        }
    }
}

- (IBAction)goToFirstTransitionOfCurrentPage:(id)sender
{
    MHNotebookPage *currentPage = _pages[self.currentPageIndex];
    [currentPage moveToFirstSlide];
}

- (IBAction)goToLastTransitionOfCurrentPage:(id)sender
{
    MHNotebookPage *currentPage = _pages[self.currentPageIndex];
    [currentPage moveToLastSlide];
}

- (void)goToPageNamed:(NSString *)pageFilename slideNumber:(NSInteger)slideNumber
{
    if ([self goToPageNamed:pageFilename]) {
        if (slideNumber != NSNotFound)
            self.currentPage.slideTransitionIndex = slideNumber;
    }
}

- (bool)goToPageNamed:(NSString *)pageFilename
{
    if ([self goProgrammaticallyToPageNamed:pageFilename]) {
        [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
        return true;
    }
    NSBeep();
    return false;
}

- (bool)goProgrammaticallyToPageNamed:(NSString *)pageFilename
{
    NSUInteger pageIndex = 0;
    for (MHNotebookPage *page in _pages) {
        if ([page.filename caseInsensitiveCompare:pageFilename] == NSOrderedSame) {
            self.currentPageIndex = pageIndex;
            return true;
        }
        pageIndex++;
    }
    return false;
}

- (IBAction)goToPageNumber:(id)sender
{
    if (_pages.count <= 1) {
        NSBeep();       // no page to go to other than where we already  are
        return;
    }
    
    NSView *accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0,0,240,25)];
    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Go to page:", @"")
                                                                    attributes:textAttributes];
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
    label.attributedStringValue = labelText;
    label.bezeled = NO;
    label.editable = NO;
    label.drawsBackground = NO;
    [label sizeToFit];
    [accessoryView addSubview:label];
    NSRect labelFrame = label.frame;
    labelFrame.origin.y += 3.0;
    label.frame = labelFrame;
    
    NSTextField *pageNumberTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    pageNumberTextField.editable = YES;
    pageNumberTextField.drawsBackground = YES;
    pageNumberTextField.stringValue = @"999999";
    [pageNumberTextField sizeToFit];
    pageNumberTextField.stringValue = @"";
    NSRect pageNumberTextFieldFrame = pageNumberTextField.frame;
    pageNumberTextFieldFrame.origin = NSMakePoint(labelFrame.origin.x + labelFrame.size.width + 10.0, 0.0);
    pageNumberTextField.frame = pageNumberTextFieldFrame;
    [accessoryView addSubview:pageNumberTextField];

     
    NSAlert *alert = [[NSAlert alloc] init];
    NSString *notebookTitle = _notebookConfiguration.notebookTitle;
    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Notebook '%@' (%lu pages)", @""),
                         notebookTitle ? notebookTitle : self.displayName, self.pages.count];
//    [alert setInformativeText:@"informative text will go here"];
    alert.accessoryView = accessoryView;
    
    [alert addButtonWithTitle:NSLocalizedString(@"Ok", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    
    [[alert window] setInitialFirstResponder:pageNumberTextField];
    
    NSModalResponse modalResponse = [alert runModal];
    if (modalResponse == NSAlertFirstButtonReturn) {
        NSUInteger pageNumberToGoTo = [pageNumberTextField integerValue];
        if (pageNumberToGoTo >= 1 && pageNumberToGoTo <= _pages.count) {
            if (pageNumberToGoTo - 1 != self.currentPageIndex) {
                self.currentPageIndex = pageNumberToGoTo - 1;
                [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
            }
        }
        else {
            NSBeep();
        }
    }
}


- (IBAction)scrollToTopOfCurrentPage:(id)sender
{
    [self.currentPage scrollToTop];
}

- (IBAction)scrollToBottomOfCurrentPage:(id)sender
{
    [self.currentPage scrollToBottom];
}

- (IBAction)scrollDownOneScreen:(id)sender
{
    [self.currentPage.pageViewerView scrollPageDown:nil];
}

- (IBAction)scrollUpOneScreen:(id)sender
{
    [self.currentPage.pageViewerView scrollPageUp:nil];
}

- (IBAction)togglePlayPause:(id)sender
{
    self.timedSlidePresentationRunning = !self.timedSlidePresentationRunning;
}

- (IBAction)expandPageContentAndStopAnimations:(id)sender
{
    [self.currentPage expandContentAndStopAnimations];
}

- (IBAction)showHelpForSpecialSymbolsSegmentedControl:(id)sender
{
    [((AppDelegate *)[[NSApplication sharedApplication] delegate]) openHelpPagesForSpecialSymbols];
}



#pragma mark - Window navigation

- (IBAction)switchToCounterpartWindow:(id)sender
{
    NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
    if ([keyWindow isEqual:self.pageViewerViewWindow]) {
        [self.sourceCodeEditorWindow makeKeyAndOrderFront:nil];
    }
    else {
        [self.pageViewerViewWindow makeKeyAndOrderFront:nil];
    }
}







#pragma mark - Resizing of page viewer view

- (IBAction)pageViewerResizingPullDownAction:(NSPopUpButton *)pageViewerResizingPullDown
{
    NSInteger selectedItemIndex = pageViewerResizingPullDown.indexOfSelectedItem;
    static const NSInteger kPageViewerZoomPullDown100Percent = 1;
    static const NSInteger kPageViewerZoomPullDown125Percent = 2;
    static const NSInteger kPageViewerZoomPullDown150Percent = 3;
    static const NSInteger kPageViewerZoomPullDown200Percent = 4;
    static const NSInteger kPageViewerZoomPullDown100ToggleLockViewToAspectRatio = 6;
    switch (selectedItemIndex) {
        case kPageViewerZoomPullDown100Percent:
            [self setPageViewerZoomTo100Percent:nil];
            break;
        case kPageViewerZoomPullDown125Percent:
            [self setPageViewerZoomTo125Percent:nil];
            break;
        case kPageViewerZoomPullDown150Percent:
            [self setPageViewerZoomTo150Percent:nil];
            break;
        case kPageViewerZoomPullDown200Percent:
            [self setPageViewerZoomTo200Percent:nil];
            break;
        case kPageViewerZoomPullDown100ToggleLockViewToAspectRatio:
            [self toggleLockPageViewerViewToPageAspectRatio:nil];
            break;
        default:
            break;
    }
}

- (IBAction)setPageViewerZoomTo100Percent:(id)sender
{
    [self setPageViewerViewZoom:1.0];
}

- (IBAction)setPageViewerZoomTo125Percent:(id)sender
{
    [self setPageViewerViewZoom:1.25];
}

- (IBAction)setPageViewerZoomTo150Percent:(id)sender
{
    [self setPageViewerViewZoom:1.5];
}

- (IBAction)setPageViewerZoomTo200Percent:(id)sender
{
    [self setPageViewerViewZoom:2.0];
}

- (IBAction)toggleLockPageViewerViewToPageAspectRatio:(id)sender
{
    self.viewerViewLockedToPageAspectRatio = !self.viewerViewLockedToPageAspectRatio;
}

- (bool)viewerViewLockedToPageAspectRatio
{
    return _viewerViewLockedToPageAspectRatio;
}

- (void)setViewerViewLockedToPageAspectRatio:(bool)newState;
{
    _viewerViewLockedToPageAspectRatio = newState;
    
    // There are two menu items that display the state of the _viewerViewLockedToPageAspectRatio boolean, so update them
    NSControlStateValue newControlStateValue = (_viewerViewLockedToPageAspectRatio ? NSControlStateValueOn : NSControlStateValueOff);
    [self.lockPageViewerAspectRatioMenuItem
     setState:newControlStateValue];
        
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *viewMenuItem = [mainMenu itemWithTag:kViewMenuItemTag];
    NSMenu *viewMenu = viewMenuItem.submenu;
    NSMenuItem *lockAspectRationMenuItem = [viewMenu itemWithTag:kLockAspectRatioMenuItemTag];
    [lockAspectRationMenuItem setState:newControlStateValue];

    
    if (_viewerViewLockedToPageAspectRatio) {
        // resize the window to ensure the view satisfies the aspect ratio constraint
        NSWindow *pageViewerViewWindow = self.pageViewerViewWindow;
        NSRect currentWindowFrame = pageViewerViewWindow.frame;
        NSRect newWindowFrame;
        newWindowFrame.origin = currentWindowFrame.origin;
        newWindowFrame.size = [self windowWillResize:pageViewerViewWindow toSize:currentWindowFrame.size];
        [pageViewerViewWindow setFrame:newWindowFrame display:YES animate:YES];
    }

}


- (CGFloat)pageViewerViewZoom
{
    NSRect pageViewerViewFrame = self.currentPage.pageViewerView.frame;
    return pageViewerViewFrame.size.width / _notebookConfiguration.pageSize.width;
}

- (void)setPageViewerViewZoom:(CGFloat)zoomScalingFactor        // a value of 1 corresponds to the page size
{
    static CGFloat minZoom = 0.25;
    static CGFloat maxZoom = 4.0;
    CGFloat actualZoomScalingFactor;
    if (zoomScalingFactor < minZoom)
        actualZoomScalingFactor = minZoom;
    else if (zoomScalingFactor > maxZoom)
        actualZoomScalingFactor = maxZoom;
    else
        actualZoomScalingFactor = zoomScalingFactor;
    NSWindow *pageViewerViewWindow = self.pageViewerViewWindow;
    NSRect pageViewerViewWindowFrame = pageViewerViewWindow.frame;
    MHPageViewerView *pageViewerView = self.currentPage.pageViewerView;
    NSRect pageViewerViewFrame = pageViewerView.frame;
    NSRect newPageViewerViewWindowFrame = pageViewerViewWindowFrame;
    
    NSSize pageSize = _notebookConfiguration.pageSize;
    newPageViewerViewWindowFrame.size.width = pageViewerViewWindowFrame.size.width + actualZoomScalingFactor * pageSize.width - pageViewerViewFrame.size.width;
    
    // The window height either stays the same or is resized to maintain the correct contant aspect ratio for the page viewer view if we are in locked aspect ratio mode
    newPageViewerViewWindowFrame.size.height = (_viewerViewLockedToPageAspectRatio ?
                                                pageViewerViewWindowFrame.size.height + actualZoomScalingFactor * pageSize.height - pageViewerViewFrame.size.height : pageViewerViewWindowFrame.size.height);
    
    [pageViewerViewWindow setFrame:newPageViewerViewWindowFrame display:YES animate:YES];
}

- (void)pageViewerViewResized:(NSNotification *)notification
{
    MHPageViewerView *pageViewerView = notification.object;
    self.pageViewerViewZoomIndicator.title = [NSString stringWithFormat:NSLocalizedString(@"Zoom (%d%%)", @""), (int)(100.0 * pageViewerView.bounds.size.width / _notebookConfiguration.pageSize.width)];
}










#pragma mark - Page creation, deletion, reordering and renaming



- (IBAction)addNewPageAfterCurrentPageAndSetItAsCurrentPage:(id)sender
{
    if (self.isInViewingMode) {
        NSBeep();
        return;
    }
    
    NSUInteger currentPageIndex = self.currentPageIndex;
    NSUInteger newPageIndex = currentPageIndex+1;
    NSMutableArray <MHNotebookPage *> *newMutablePagesArray = [[NSMutableArray alloc] initWithArray:_pages];
    MHNotebookPage *newPage = [[MHNotebookPage alloc] initWithNotebookConfiguration:_notebookConfiguration];
    newPage.notebook = self;
    [newMutablePagesArray insertObject:newPage atIndex:newPageIndex];
    _pages = [NSArray arrayWithArray:newMutablePagesArray];
    
    // Check if the filename is a duplicate of an existing page. If so, rename it by appending a number
    NSString *defaultFilename = newPage.filename;
    NSString *newPageFilename;
    int counter = 1;
    bool duplicateFlag = true;
    while (duplicateFlag) {
        duplicateFlag = false;
        NSUInteger otherPageIndex = 0;
        for (MHNotebookPage *otherPage in _pages) {
            if (otherPageIndex != newPageIndex &&
                [otherPage.filename isEqualToString:
                 (counter == 1 ? defaultFilename : (newPageFilename = [defaultFilename stringByAppendingFormat:@" %u", counter]))]) {
                duplicateFlag = true;
                break;
            }
            otherPageIndex++;
        }
        counter++;
    }
    if (counter > 2)
        newPage.filename = newPageFilename;
    
    [self.pageListTableView reloadData];
    [self.pageListTableView scrollRowToVisible:newPageIndex];
    
    [self invalidatePageIndexFileWrapper];
    
    // page deletion should now be enabled since we are sure there is more than one page
    [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus];
    
    self.currentPageIndex = newPageIndex;   // go to the new page
    [self markCurrentPageAsRecentlyVisitedAfterNavigatingToIt];
}

- (void)deleteCurrentPageWithoutAskingForUserConfirmation
{
    // FIXME: add graceful handling for errors (can't delete/read-only file etc)
    
    NSUInteger numberOfPages = _pages.count;
    if (numberOfPages == 1) {
        // This code should never run, but fail gracefully if it does
        NSLog(@"there is only one page, cannot delete it");
        NSBeep();
        return;
    }
    
    
    NSUInteger currentPageIndex = self.currentPageIndex;
    MHNotebookPage *currentPage = _pages[_currentPageIndex];
    NSString *currentPageFilename = currentPage.filename;
    NSString *currentPageFilenameWithExtension = currentPage.filenameWithExtension;

    NSMutableArray <MHNotebookPage *> *newMutablePagesArray = [[NSMutableArray alloc] initWithArray:_pages];
    [newMutablePagesArray removeObjectAtIndex:currentPageIndex];
    _pages = [NSArray arrayWithArray:newMutablePagesArray];
    
    [self rotateOutPage:currentPage];   // this normally gets done as part of the setCurrentPageIndexWithoutChangingFirstResponder: method call, called below. The one exception is when deleting a page, when we are doing some delicate tweaking of the _pages array that would be hard to take into account in the setCurrentPageIndexWithoutChangingFirstResponder: method, so that rotating out logic was refactored to a separate method and we invoke it explicitly here before calling setCurrentPageIndexWithoutChangingFirstResponder:
    _currentPageIndex = NO_CURRENT_PAGE_SET_YET;    // this will prevent a spurious call to rotateOutPage: from the setCurrentPageIndexWithoutChangingFirstResponder: method in the next line
    
    [self setCurrentPageIndexWithoutChangingFirstResponder:(currentPageIndex+1 == numberOfPages ? currentPageIndex-1 : currentPageIndex)];
    [self updateRecentlyVisitedPagesListForPageDeletion:currentPageFilename];
    [self.pageListTableView reloadData];
    
    [self invalidatePageIndexFileWrapper];
    [self invalidateFileWrapperWithName:currentPageFilenameWithExtension];
    
    [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus];
    
    [self.pageListTableView.window makeFirstResponder:self.pageListTableView];  // after deleting a page, the focus should go to the page list table view (to allow the user to navigate the pages, delete more pages etc)
}

- (IBAction)initiateCurrentPageDeletionSequence:(id)sender
{
    if (self.isInViewingMode) {
        NSBeep();
        return;
    }
    NSUInteger numberOfPages = _pages.count;
    if (numberOfPages == 1) {
        // we cannot delete a page if it's the only one
        NSLog(@"there is only one page, cannot delete it");
        NSBeep();
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    alert.messageText = NSLocalizedString(@"Delete the page?", @"");
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to delete the page \"%@\"?",@""),
                             self.currentPage.filename];
    alert.alertStyle = NSAlertStyleWarning;

    NSModalResponse result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        [self deleteCurrentPageWithoutAskingForUserConfirmation];
    }
    else {
        // if any action should be taken if the user cancels the deletion, add it here
    }
    
    // the above code shows the confirmation panel as a modal window. An alternative is to present it as a sheet for the source code editor window, using the code below. This is not so good as with this method of presentation the user can still navigate to a different page of the notebook from the page viewer window while the confirmation panel is waiting for a decision.
//    [alert beginSheetModalForWindow:self.sourceCodeEditorWindow completionHandler:^(NSInteger result){
//        if (result == NSAlertFirstButtonReturn) {
//            [self deleteCurrentPageWithoutAskingForUserConfirmation];
//        }
//        else {
//            // if any action should be taken if the user cancels the deletion, add it here
//        }
//    }];

}

- (void)updateUserInterfaceForPageCreationAndDeletionEnabledStatus
{
    BOOL inViewingMode = self.isInViewingMode;
    BOOL pageDeletionEnabled = (!inViewingMode && _pages.count > 1);
    BOOL pageCreationEnabled = !inViewingMode;
    [self.notebookActionsSegmentedControl setEnabled:pageDeletionEnabled forSegment:kMHNotebookActionDeletePageSegmentIndex];
    [self.notebookActionsSegmentedControl setEnabled:pageCreationEnabled forSegment:kMHNotebookActionCreateNewPageSegmentIndex];
    
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *pageMenuItem = [mainMenu itemWithTag:kPageMenuItemTag];
    NSMenu *pageMenu = pageMenuItem.submenu;
    NSMenuItem *deletePageMenuItem = [pageMenu itemWithTag:kDeletePageMenuItemTag];
    [deletePageMenuItem setEnabled:pageDeletionEnabled];
    NSMenuItem *createPageMenuItem = [pageMenu itemWithTag:kCreateNewPageMenuItemTag];
    [createPageMenuItem setEnabled:pageCreationEnabled];
}

- (void)movePageWithIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    NSUInteger currentPageIndex = self.currentPageIndex;
    
    NSMutableArray <MHNotebookPage *> *newMutablePagesArray = [[NSMutableArray alloc] initWithArray:_pages];
    MHNotebookPage *pageToMove = [newMutablePagesArray objectAtIndex:oldIndex];
    [newMutablePagesArray removeObjectAtIndex:oldIndex];
    [newMutablePagesArray insertObject:pageToMove atIndex:(newIndex > oldIndex ? newIndex-1 : newIndex)];
    _pages = [NSArray arrayWithArray:newMutablePagesArray];
    
    [self.pageListTableView reloadData];
    
    if (currentPageIndex == oldIndex && oldIndex > newIndex) {
        self.currentPageIndex = newIndex;

        // no need to update the recently visited pages list - it keeps track of pages by filename so rearranging the page order will not interfere with that
    }
    else if (currentPageIndex == oldIndex && oldIndex < newIndex) {
        self.currentPageIndex = newIndex-1;

        // no need to update the recently visited pages list - it keeps track of pages by filename so rearranging the page order will not interfere with that
    }
    else if (oldIndex < currentPageIndex && currentPageIndex < newIndex) {
        self.currentPageIndex = currentPageIndex-1;

        // no need to update the recently visited pages list - it keeps track of pages by filename so rearranging the page order will not interfere with that
    }
    else if (oldIndex > currentPageIndex && currentPageIndex > newIndex) {
        self.currentPageIndex = currentPageIndex+1;

        // no need to update the recently visited pages list - it keeps track of pages by filename so rearranging the page order will not interfere with that
    }
    
    [self invalidatePageIndexFileWrapper];
}

- (void)copyPageWithIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    NSUInteger currentPageIndex = self.currentPageIndex;
    NSMutableArray <MHNotebookPage *> *newMutablePagesArray = [[NSMutableArray alloc] initWithArray:_pages];
    MHNotebookPage *pageToCopy = _pages[oldIndex];
    MHNotebookPage *newPage = [[MHNotebookPage alloc] initWithNotebookConfiguration:_notebookConfiguration];
    newPage.notebook = self;
    [newMutablePagesArray insertObject:newPage atIndex:newIndex];
    newPage.code = pageToCopy.code;
    
    // Check if the filename is a duplicate of an existing page. If so, rename it by appending a number
    NSString *defaultFilename = pageToCopy.filename;
    NSString *newPageFilename;
    int counter = 1;
    bool duplicateFlag = true;
    while (duplicateFlag) {
        duplicateFlag = false;
        NSUInteger otherPageIndex = 0;
        for (MHNotebookPage *otherPage in _pages) {
            if ([otherPage.filename isEqualToString:
                 (counter == 1 ? defaultFilename : (newPageFilename = [defaultFilename stringByAppendingFormat:@" %u", counter]))]) {
                duplicateFlag = true;
                break;
            }
            otherPageIndex++;
        }
        counter++;
    }
    newPage.filename = newPageFilename;
    
    _pages = [NSArray arrayWithArray:newMutablePagesArray];
    
    // FIXME: I think this doesn't work in the best way. Currently the focus stays on the page we copied. Shouldn't we switch to the new copy instead? And update the list of recently visited pages?
    self.currentPageIndex = (newIndex > currentPageIndex ? currentPageIndex : currentPageIndex+1);
    
    [self.pageListTableView reloadData];
    [self.pageListTableView scrollRowToVisible:newIndex];
    
    [self invalidatePageIndexFileWrapper];
    
    [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus]; // page deletion should now be enabled in the user interface
}


// Returns true if the operation was successful
- (bool)renamePageWithIndex:(NSUInteger)pageIndex newPageFilename:(NSString *)newPageFilename
{
    // Validate filename
    NSArray *pathComponents = [newPageFilename pathComponents];
    if (pathComponents.count != 1 ||
        [newPageFilename characterAtIndex:0] == kMHNotebookForbiddenPageFilenamePrefixChar ||
        [newPageFilename isEqualToString:[kMHNotebookPageIndexFileName stringByDeletingPathExtension]] ||
        [newPageFilename isEqualToString:[kMHNotebookImageIndexFileName stringByDeletingPathExtension]] ||
        [newPageFilename isEqualToString:[kMHNotebookImagesFolderName stringByDeletingPathExtension]]) {
        // Invalid filename (either has multiple paths or matches the index filename or begins with the forbidden prefix char), return false to indicate that the operation failed
        
        // Technical note: We disallow page filenames from starting with an underscore, reserving underscore-prefixed filenames for metadata files such as the index file _index.txt
        
        return false;
    }
    
    // Check for duplicates
    NSUInteger ind = 0;
    for (MHNotebookPage *otherPage in _pages) {
        if (ind != pageIndex && [newPageFilename isEqualToString:otherPage.filename]) {
            // Duplicate filename, return false to indicate that the renaming failed
            return false;
        }
        ind++;
    }
    
    // The new filename is valid - change the page's filename to the new value
    MHNotebookPage *page = _pages[pageIndex];
    NSString *oldPageFilename = page.filename;
    NSString *oldPageFilenameWithExtension = page.filenameWithExtension;
    page.filename = newPageFilename;

    // Invalidate the page index and the old page filename to keep the NSFileWrapper data consistent with our data model
    [self invalidatePageIndexFileWrapper];
    [self invalidateFileWrapperWithName:oldPageFilenameWithExtension];
    
    // update the recently visited pages list
    [self updateRecentlyVisitedPagesListForPageRenamingFrom:oldPageFilename to:newPageFilename];
    
    return true;    // success
}



#pragma mark - Being notified by notebook pages when their contents change

- (void)contentsChangedForPage:(MHNotebookPage *)page
{
    [self invalidateFileWrapperWithName:page.filenameWithExtension];
}



#pragma mark - Managing file wrappers

// These methods allow us to update any file wrappers included within the root notebook file wrappers to keep things consistent with our data model

- (void)invalidateFileWrapperWithName:(NSString *)filename
{
    // Invalidate a file wrapper if it exists - will be called whenever the data model changes, as explained in Apple's documentation
    // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileWrappers/FileWrappers.html
    //
    
    if (_notebookFileWrapper) {
        NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
        NSFileWrapper *fileWrapperToInvalidate = fileWrappers[filename];
        if (fileWrapperToInvalidate) {
            [_notebookFileWrapper removeFileWrapper:fileWrapperToInvalidate];
        }
    }
    [self updateChangeCount:NSChangeDone];      // to facilitate autosaving
}

- (void)invalidatePageIndexFileWrapper
{
    [self invalidateFileWrapperWithName:kMHNotebookPageIndexFileName];
}

- (void)invalidateConfigurationCodeFileWrapper
{
    [self invalidateFileWrapperWithName:kMHNotebookPageConfigurationFileName];
}

- (void)invalidateAssetIndexFileWrapperForAssetType:(MHAssetType)assetType
{
    [self invalidateFileWrapperWithName:[self.indexFilenamesByAssetType objectAtIndex:assetType]]; // FIXME: the file that gets invalidated should be the correct one for the asset type
}

- (void)invalidateAssetFolderFileWrapperForAssetType:(MHAssetType)assetType
{
    [self invalidateFileWrapperWithName:[self.assetFolderNamesByAssetType objectAtIndex:assetType]]; // FIXME: the file that gets invalidated should be the correct one for the asset type
}



#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closingWindow = notification.object;
    if ([closingWindow isEqualTo:self.sourceCodeEditorWindow]) {
        [self closeAssetLibrary:nil];
        [self.pageViewerViewWindow actuallyClose];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    if ([_configurationSheetController isEqualTo:window.windowController]) {
        return _configurationSheetController.configurationCodeEditorView.undoManager;
    }
    return [[self.currentPage sourceCodeEditorView] undoManager];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self updateUserInterfaceForAssetLibraryVisibilityState];
    
    NSWindow *newKeyWindow = notification.object;
    
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *navigateMenu = [mainMenu itemWithTag:kNavigateMenuItemTag];
    
    // Enable the navigate menu items or disable them, depending on whether the page viewer window is the key window
    navigateMenu.enabled = [newKeyWindow isEqualTo:self.pageViewerViewWindow];
    
    if ([newKeyWindow isEqualTo:self.pageViewerViewWindow] || [newKeyWindow isEqualTo:self.sourceCodeEditorWindow]) {
        // FIXME: the condition to test if one of the document windows is key is not correct, because the notebook could occasionally have other windows visible (for example the asset library) - improve
        [self updateUserInterfaceForPageCreationAndDeletionEnabledStatus];
    }
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    MHPageViewerView *pageViewerView = self.currentPage.pageViewerView;
    MHSpriteKitScene *scene = pageViewerView.scene;
    
    // Hide any hovering auxiliary text that happens to be displayed before the window resigned key status
    scene.mouseHoveringAuxiliaryText = nil;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedNewFrameSize
{
    NSWindow *pageViewerViewWindow = self.pageViewerViewWindow;
    if (!_viewerViewLockedToPageAspectRatio || ![sender isEqualTo:pageViewerViewWindow]) {
        // the window size isn't constrained by locking the aspect ratio of the page viewer view, or we are resizing a different window
        return proposedNewFrameSize;
    }
    
    NSSize pageViewerViewWindowCurrentSize = pageViewerViewWindow.frame.size;
    MHPageViewerView *pageViewerView = self.currentPage.pageViewerView;
    NSSize pageViewerViewCurrentSize = pageViewerView.frame.size;
    NSSize pageViewerViewNewSize;
    
    NSSize actualNewFrameSize;
    
    NSSize pageSize = _notebookConfiguration.pageSize;
    
    if (proposedNewFrameSize.height == pageViewerViewWindowCurrentSize.height) {
        pageViewerViewNewSize.width = pageViewerViewCurrentSize.width + proposedNewFrameSize.width - pageViewerViewWindowCurrentSize.width;
        pageViewerViewNewSize.height = pageViewerViewNewSize.width * pageSize.height / pageSize.width;

        actualNewFrameSize.width // = proposedNewFrameSize.width
        = pageViewerViewNewSize.width + pageViewerViewWindowCurrentSize.width - pageViewerViewCurrentSize.width;

        actualNewFrameSize.height
        = pageViewerViewNewSize.height + pageViewerViewWindowCurrentSize.height - pageViewerViewCurrentSize.height;
    }
    else {
        pageViewerViewNewSize.height = pageViewerViewCurrentSize.height + proposedNewFrameSize.height - pageViewerViewWindowCurrentSize.height;
        pageViewerViewNewSize.width = pageViewerViewNewSize.height * pageSize.width / pageSize.height;

        actualNewFrameSize.height // = proposedNewFrameSize.height
        = pageViewerViewNewSize.height + pageViewerViewWindowCurrentSize.height - pageViewerViewCurrentSize.height;

        actualNewFrameSize.width
        = pageViewerViewNewSize.width + pageViewerViewWindowCurrentSize.width - pageViewerViewCurrentSize.width;
    }
    
    return actualNewFrameSize;
}





#pragma mark - Restoring notebook user interface state

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.currentPageIndex forKey:kMHNotebookRestorableStatePageIndex];
    [coder encodeInteger:self.currentPage.slideTransitionIndex forKey:kMHNotebookRestorableStateSlideTransitionIndex];
    [coder encodeBool:_viewerViewLockedToPageAspectRatio forKey:kMHNotebookRestorableStatePageViewerAspectRatioLocked];
    [coder encodeDouble:self.pageViewerViewZoom forKey:kMHNotebookRestorableStatePageViewerViewZoom];
    [coder encodeBool:_assetLibraryVisible forKey:kMHNotebookRestorableStateAssetLibraryOpen];
    [coder encodeInteger:(NSUInteger)(self.currentAssetTypeSublibrary) forKey:kMHNotebookRestorableStateAssetLibraryVisibleTabIndex];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];
    
    NSUInteger pageIndex = [coder decodeIntegerForKey:kMHNotebookRestorableStatePageIndex];
    self.currentPageIndex = pageIndex;
    [self initializeListOfRecentlyVisitedPages];
    
    NSUInteger slideTransitionIndex = [coder decodeIntegerForKey:kMHNotebookRestorableStateSlideTransitionIndex];
    self.currentPage.slideTransitionIndex = slideTransitionIndex;
    
    bool aspectRatioLocked = [coder decodeBoolForKey:kMHNotebookRestorableStatePageViewerAspectRatioLocked];
    self.viewerViewLockedToPageAspectRatio = aspectRatioLocked;
    
    CGFloat zoom = [coder decodeDoubleForKey:kMHNotebookRestorableStatePageViewerViewZoom];
    [self setPageViewerViewZoom:zoom];
    
    BOOL assetLibraryOpen = [coder decodeBoolForKey:kMHNotebookRestorableStateAssetLibraryOpen];
    if (assetLibraryOpen) {
        [self openAssetLibrary:nil];
    }
    MHAssetType currentAssetTypeLibrary = (MHAssetType)[coder decodeIntegerForKey:kMHNotebookRestorableStateAssetLibraryVisibleTabIndex];
    [self setCurrentAssetTypeSublibrary:currentAssetTypeLibrary];
}



#pragma mark - Code templates

- (void)configureCodeTemplatesMenu
{
    NSMenu *menu = self.codeTemplatesMenu;
    NSString *codeTemplatesFilename = [[NSBundle mainBundle] pathForResource:kMHNotebookCodeTemplatesPlistFilename
                                                                     ofType:kMHNotebookCodeTemplatesPlistFileExtension];
    _codeTemplatesArray = [NSArray arrayWithContentsOfFile:codeTemplatesFilename];
    for (NSDictionary *codeTemplateDict in _codeTemplatesArray) {
        NSMenuItem *templateMenuItem = templateMenuItemFromPlistEntry(codeTemplateDict);
        [menu addItem:templateMenuItem];
    }
}

- (void)codeTemplateAction:(NSMenuItem *)codeTemplateMenuItem
{
    NSString *templateCode = (NSString *)(codeTemplateMenuItem.representedObject);
    MHSourceCodeTextView *sourceCodeEditorView = self.currentPage.sourceCodeEditorView;
    NSRange selectedRange = sourceCodeEditorView.selectedRange;
    if ([sourceCodeEditorView shouldChangeTextInRange:selectedRange replacementString:templateCode]) {
        [sourceCodeEditorView.textStorage replaceCharactersInRange:selectedRange withString:templateCode];
        [sourceCodeEditorView didChangeText];
    }
}

#pragma mark - Editor themes

- (MHSourceCodeEditorTheme *)editorTheme
{
    return _editorTheme;
}

- (void)setEditorTheme:(MHSourceCodeEditorTheme *)editorTheme
{
    _editorTheme = editorTheme;
    [self.editorThemeSelectionPopupButton selectItemWithTitle:_editorTheme.name];
    self.currentPage.sourceCodeEditorView.editorTheme = _editorTheme;
}

- (void)configureEditorThemesMenu
{
    NSPopUpButton *themeSelectionPopUp = self.editorThemeSelectionPopupButton;
    [themeSelectionPopUp removeAllItems];
    NSArray <MHSourceCodeEditorTheme *> *editorThemes = [[MHSourceCodeEditorThemeManager defaultManager] themes];
    for (MHSourceCodeEditorTheme *theme in editorThemes) {
        [themeSelectionPopUp addItemWithTitle:theme.name];
    }
    
    // now resize the theme selection popup, but also reposition it so we keep the same spacing to right edge of the superview
    // (I thought this should happen automatically by setting the autoresizing mask, but couldn't make it work that way)
    NSRect originalPopUpFrame = themeSelectionPopUp.frame;
    [themeSelectionPopUp sizeToFit];
    NSRect popUpFrameAfterResizing = themeSelectionPopUp.frame;
    popUpFrameAfterResizing.origin.x = originalPopUpFrame.origin.x + originalPopUpFrame.size.width - popUpFrameAfterResizing.size.width;
    themeSelectionPopUp.frame = popUpFrameAfterResizing;
}

- (void)editorThemesChanged:(NSNotification *)notification
{
    [self configureEditorThemesMenu];
    
    NSString *currentThemeName = _editorTheme.name;
    MHSourceCodeEditorTheme *themeWithCurrentThemeName = [[MHSourceCodeEditorThemeManager defaultManager] themeWithName:currentThemeName];
    
    if (themeWithCurrentThemeName) {
        // the theme we were using still exists, so select it in the theme selection popup button
        NSDictionary *userInfo = notification.userInfo;
        NSString *affectedThemeName = userInfo[kMHSourceCodeEditorEditorThemeChangeAffectedThemeName];
        if ([affectedThemeName isEqualToString:currentThemeName]) {
            // the current theme was affected, need to reload it
            self.editorTheme = themeWithCurrentThemeName;
        }
        else {
            // the current theme was not affected, so just need to reselect the item in the theme selection popup button
            [self.editorThemeSelectionPopupButton selectItemWithTitle:_editorTheme.name];
        }
    }
    else {
        // the theme we were using no longer exists, so select an arbitrary existing theme
        MHSourceCodeEditorTheme *newTheme = [[[MHSourceCodeEditorThemeManager defaultManager] themes] objectAtIndex:0];
        self.editorTheme = newTheme;
    }
}

- (void)editorThemeWasRenamed:(NSNotification *)notification
{
    [self configureEditorThemesMenu];
    
    NSDictionary *notificationInfo = notification.userInfo;
    NSString *oldThemeName = notificationInfo[kMHSourceCodeEditorEditorThemeChangeAffectedThemeName];
    NSString *newThemeName = notificationInfo[kMHSourceCodeEditorEditorThemeRenamingNewNameKey];
    
    if ([_editorTheme.name isEqualToString:oldThemeName]) {
        // the theme that was renamed was the one we are currently using
        [self.editorThemeSelectionPopupButton selectItemWithTitle:newThemeName];
    }
    else {
        // the theme that was renamed was not the one we are currently using
        [self.editorThemeSelectionPopupButton selectItemWithTitle:_editorTheme.name];
    }
}
















@end


// A C function to recursively generate an NSMenu for code templates from an entry in the Plist file where code templates are stored
// the Plist entry is an NSDictionary encoding either a single menu item, or an NSArray representing a menu with multiple submenu items, which are generated recursively
static NSMenuItem *templateMenuItemFromPlistEntry(NSDictionary *plistEntry)
{
    NSString *templateName = plistEntry[kMHNotebookCodeTemplatesTemplateNameKey];
    NSString *templateCode = plistEntry[kMHNotebookCodeTemplatesTemplateCodeKey];
    
    if (templateCode) {
        // a menu item representing a single template
        NSMenuItem *templateMenuItem = [[NSMenuItem alloc] initWithTitle:templateName
                                                                  action:@selector(codeTemplateAction:)
                                                           keyEquivalent:@""];
        templateMenuItem.representedObject = templateCode;
        return templateMenuItem;
    }
    else {
        // a submenu of templates
        NSArray *templateSubmenuArray = plistEntry[kMHNotebookCodeTemplatesSubmenuNameKey];
        NSMenu *submenu = [[NSMenu alloc] init];
        for (NSDictionary *submenuTemplate in templateSubmenuArray) {
            NSMenuItem *submenuItem = templateMenuItemFromPlistEntry(submenuTemplate);
            [submenu addItem:submenuItem];
        }
        NSMenuItem *menuItemForSubmenu = [[NSMenuItem alloc] initWithTitle:templateName action:nil keyEquivalent:@""];
        menuItemForSubmenu.submenu = submenu;
        return menuItemForSubmenu;
    }
}
