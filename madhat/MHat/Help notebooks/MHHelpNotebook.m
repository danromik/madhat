//
//  MHHelpNotebook.m
//  MadHat
//
//  Created by Dan Romik on 8/8/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHHelpNotebook.h"
#import "MHNotebookPage.h"

static NSString * const kMHHelpNotebookDocumentType = @"MadHat Help Notebook";  // Note: this string is also specified in the Info.plist file

static NSString * const kMHHelpNotebookToolbarIdentifier = @"HelpNotebookToolbar";

static NSString * const kMHHelpNotebookSearchToolbarItem = @"MHHelpNotebookSearchToolbarItem";
static NSString * const kMHHelpNotebookHomeToolbarItem = @"MHHelpNotebookHomeToolbarItem";
static NSString * const kMHNotebookPageZoomToolbarItem = @"PageZoomToolbarItem";

static NSString * const kMHNotebookSearchDictionaryKeyPage = @"page";
static NSString * const kMHNotebookSearchDictionaryKeyRelevanceScore = @"relevance score";

static NSString * const kMHHelpNotebookHomePageName = @"MadHat Help";

static NSString * const kMHHelpNotebookWindowFrameAutosaveName = @"MHHelpNotebookWindow";

static NSColorName const kMHHelpNotebookWindowBackgroundColorName = @"Help window background color";


static NSComparisonResult compareSearchResultDictionariesByName(NSDictionary *dict1, NSDictionary *dict2, void *ignore)
{
    NSUInteger relevanceScore1 = [(NSNumber *)(dict1[kMHNotebookSearchDictionaryKeyRelevanceScore]) integerValue];
    NSUInteger relevanceScore2 = [(NSNumber *)(dict2[kMHNotebookSearchDictionaryKeyRelevanceScore]) integerValue];
    if (relevanceScore1 == relevanceScore2)
        return NSOrderedSame;
    if (relevanceScore1 < relevanceScore2)
        return NSOrderedDescending;
    return NSOrderedAscending;
}


@interface MHHelpNotebook ()
{
    NSArray <NSToolbarIdentifier> *_toolbarItemIdentifiers;
    NSArray <NSToolbarItem *> *_toolbarItems;
    NSToolbarItem *_searchFieldToolbarItem;
    NSToolbarItem *_homeToolbarItem;
    
    MHHelpNotebookSearchField *_searchField;
}

@end


@implementation MHHelpNotebook

- (NSString *)documentTypeStringThatMatchesInfoPlist
{
    return kMHHelpNotebookDocumentType;
}

- (BOOL)isInViewingMode
{
    // disable saving
    return YES;
}

+ (BOOL)autosavesInPlace
{
    // disable autosaving
    return NO;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing  _Nullable *)outError
{
    // disable saving again (just in case the above disabling doesn't produce the desired effect)
    return nil;
}

- (void)switchToCounterpartWindow:(id)sender
{
    // disable switching to the counterpart window
    return;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    // disable saving and restoring state
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    // disable saving and restoring state
}

- (IBAction)saveDocumentToPDF:(id)sender
{
    // disable exporting to PDF
}

- (IBAction)printDocument:(id)sender
{
    // disable printing
}

- (BOOL)slideTransitionsCanTransitionAcrossPages
{
    return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    NSInteger menuItemTag = menuItem.tag;
    if (menuItemTag == kExportToPDFMenuItemTag || menuItemTag == kPrintMenuItemTag
        || menuItemTag == kNavigationPreviousPageMenuItemTag || menuItemTag == kNavigationNextPageMenuItemTag
        || menuItemTag == kNavigationFirstPageInNotebookMenuItemTag || menuItemTag == kNavigationLastPageInNotebookMenuItemTag
        || menuItemTag == kNavigationGoToPageNumberMenuItemTag)
        return NO;  // disable various actions that are not meant to be possible to do in a help notebook: exporting to PDF, printing, navigating to the previous/next/first/last notebook page, etc

    return [super validateMenuItem:menuItem];
}


- (void)awakeFromNib
{
    [super awakeFromNib];

    // this doesn't work
//    [self.sourceCodeEditorWindow orderOut:nil];

    // FIXME: temporary hack to hide the source code window, works more or less but might cause problems at some point. Improve
    [self.sourceCodeEditorWindow setFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) display:YES];
    [self.sourceCodeEditorWindow performSelector:@selector(orderOut:) withObject:nil afterDelay:0.0001];

    NSWindow *helpWindow = self.pageViewerViewWindow;

    // Customize the help window appearance and behavior
    NSWindowStyleMask styleMask = helpWindow.styleMask;
    styleMask = styleMask & ~NSWindowStyleMaskMiniaturizable;   // disable the minimize button
    helpWindow.styleMask = styleMask;
    [[helpWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];   // disable the zoom button (this is better than setting the NSWindowStyleMaskResizable bit of the styleMask property to 0, since that disables the button but also prevents any resizing of the window. See this discussion: https://stackoverflow.com/questions/11680480/how-to-enable-disable-the-zoom-button-green-button )
    helpWindow.titlebarAppearsTransparent = YES;
    NSColor *highlightColor = [NSColor colorNamed:kMHHelpNotebookWindowBackgroundColorName]; //[NSColor colorWithRed:0.75 green:0.78 blue:0.72 alpha:1.0];
    helpWindow.backgroundColor = highlightColor;
    helpWindow.contentView.wantsLayer = YES;
    helpWindow.contentView.layer.backgroundColor = [highlightColor CGColor];
    helpWindow.level = NSFloatingWindowLevel;
    helpWindow.excludedFromWindowsMenu = YES;
    [helpWindow setFrameAutosaveName:kMHHelpNotebookWindowFrameAutosaveName];


    // create the search field and the toolbar item containing it
    _searchField = [[MHHelpNotebookSearchField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 240.0, 10.0)];
    _searchField.placeholderString = NSLocalizedString(@"Search Help Pages", @"");
    _searchField.helpNotebookSearchFieldDelegate = self;
    _searchFieldToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:kMHHelpNotebookSearchToolbarItem];
    _searchFieldToolbarItem.view = _searchField;

    NSButton *homeButton = [NSButton buttonWithImage:[NSImage imageNamed:NSImageNameHomeTemplate] target:self action:@selector(goToHomeHelpPage:)];
    _homeToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:kMHHelpNotebookHomeToolbarItem];
    _homeToolbarItem.view = homeButton;
    _homeToolbarItem.toolTip = NSLocalizedString(@"Go to Help home page", @"");

    // Create a new toolbar for the window, a modified version of the one for ordinary notebooks that includes the search field toolbar item and removes some other ones we don't need
    NSToolbar *toolbarFromXib = helpWindow.toolbar;
    NSArray *toolbarFromXibItems = toolbarFromXib.visibleItems;
    NSToolbar *modifiedToolbar = [[NSToolbar alloc] initWithIdentifier:kMHHelpNotebookToolbarIdentifier];
    modifiedToolbar.sizeMode = NSToolbarSizeModeSmall;
    NSMutableArray <NSToolbarIdentifier> *modifiedToolbarItemIdentifiers = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray <NSToolbarItem *> *modifiedToolbarItems = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger itemIndex = 0;
    for (NSToolbarItem *item in toolbarFromXibItems) {
        NSString *itemIdentifier = item.itemIdentifier;
        [modifiedToolbarItems addObject:item];
        [modifiedToolbarItemIdentifiers addObject:itemIdentifier];
        if ([itemIdentifier isEqualToString:kMHNotebookPageZoomToolbarItem]) {
            // Add the home button after the page zoom button
            [modifiedToolbarItems addObject:_homeToolbarItem];
            [modifiedToolbarItemIdentifiers addObject:kMHHelpNotebookHomeToolbarItem];
        }
        itemIndex++;
    }

    // add the search field
    [modifiedToolbarItems addObject:_searchFieldToolbarItem];
    [modifiedToolbarItemIdentifiers addObject:kMHHelpNotebookSearchToolbarItem];

    _toolbarItems = [NSArray arrayWithArray:modifiedToolbarItems];
    _toolbarItemIdentifiers = [NSArray arrayWithArray:modifiedToolbarItemIdentifiers];

    modifiedToolbar.delegate = self;

    // install the modified toolbar
    helpWindow.toolbar = modifiedToolbar;

    [helpWindow makeFirstResponder:_searchField];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidResignActive:)
                                                 name:NSApplicationDidResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:NSApplicationDidBecomeActiveNotification
                                               object:nil];

    // Register for notifications about an interface theme change (change between Light and Dark macOS modes):
    // relevant discussion:
    // https://stackoverflow.com/questions/39048894/how-to-detect-switch-between-macos-default-dark-mode-using-swift-3
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(interfaceThemeChanged:)
                                                            name:@"AppleInterfaceThemeChangedNotification"
                                                          object:nil];
}

- (void)interfaceThemeChanged:(NSNotification *)notification
{
    // need to update the background color of the help window backing layer
    // since this involves a CGColor and CGColors don't automatically respond to system appearance changes,
    // need to do this manually
    // We'll do it after a short delay to work around an apparent system bug/limitation that causes the appearance
    // reported by NSAppearance not to update immediately
    [self performSelector:@selector(updateAppearanceAfterDelay) withObject:nil afterDelay:0.1];
}

- (void)updateAppearanceAfterDelay
{
    NSAppearanceName appearanceName = [[[NSApplication sharedApplication] effectiveAppearance] name];

    // FIXME: the code below uses hard-coded RGB values for the light mode and dark mode versions of the highlight color
    // it would be conceptually more correct, and more defensive against future bugs, to load the color as
    // "highlightColor = [NSColor colorNamed:kMHHelpNotebookWindowBackgroundColorName]"
    // but since I'm querying the CGColor version of the color, this doesn't produce the correct result.
    // Alternatively, find a way to load the RGB values for the version of the color I want to use from the asset catalog
    // (there doesn't seem to be a documented way of doing this)

    NSColor *highlightColor;
    if ([appearanceName isEqualToString:NSAppearanceNameAqua]) {
        highlightColor = [NSColor colorWithRed:0.75 green:0.78 blue:0.72 alpha:1.0];
    }
    else {
        highlightColor = [NSColor colorWithRed:0.25 green:0.22 blue:0.28 alpha:1.0];
    }
    
    NSWindow *helpWindow = self.pageViewerViewWindow;
    helpWindow.contentView.layer.backgroundColor = [highlightColor CGColor];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [super windowWillClose:notification];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)goToHomeHelpPage:(id)sender
{
    [self goToPageNamed:kMHHelpNotebookHomePageName];
}



#pragma mark - NSToolbarItemDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return _toolbarItemIdentifiers;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return _toolbarItemIdentifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSUInteger scanningIndex = 0;
    for (NSToolbarIdentifier scanningIdentifier in _toolbarItemIdentifiers) {
        if ([scanningIdentifier isEqualToString:itemIdentifier])
            return _toolbarItems[scanningIndex];
        scanningIndex++;
    }
    return nil;     // this should never happen, if we set things up correctly
}



#pragma mark - Search field delegate and action methods

- (NSArray <NSString *> *)searchResultsForSearchString:(NSString *)searchString
{
    NSArray <NSDictionary *> *searchResults = [self relevanceSortedSearchResultsForSearchString:searchString];
    
    if (searchResults.count > 0) {
        NSMutableArray <NSString *> *searchResultStrings = [[NSMutableArray alloc] initWithCapacity:0];
        for (NSDictionary *searchResultDictionary in searchResults) {
            MHNotebookPage *page = searchResultDictionary[kMHNotebookSearchDictionaryKeyPage];
            NSString *searchResultString = page.filename;
            [searchResultStrings addObject:searchResultString];
        }
        return searchResultStrings;
    }
    return nil;
}

- (void)searchResultSelected:(NSString *)searchResult
{
    [self goToPageNamed:searchResult];
}



#pragma mark - Compiling the search results

- (NSArray <NSDictionary *> *)relevanceSortedSearchResultsForSearchString:(NSString *)searchString
{
    NSMutableArray <NSDictionary *> *results;
    for (MHNotebookPage *page in self.pages) {
        NSUInteger relevanceScore = [page relevanceScoreForSearchString:searchString];
        if (relevanceScore > 0) {
            if (!results) {
                results = [[NSMutableArray alloc] initWithCapacity:0];
            }
            NSDictionary *resultDictionary = @{
                kMHNotebookSearchDictionaryKeyRelevanceScore : [NSNumber numberWithInteger:relevanceScore],
                kMHNotebookSearchDictionaryKeyPage : page
            };
            [results addObject:resultDictionary];
        }
    }
    
    [results sortUsingFunction:compareSearchResultDictionariesByName context:nil];

    return results;
}




- (void)applicationDidResignActive:(NSNotification *)notification
{
    // hide the window when the application resigns active status (per the Apple Human Interface Guidelines, panel-style windows should do this, see https://developer.apple.com/design/human-interface-guidelines/macos/windows-and-views/panels/ )
    
    [self.pageViewerViewWindow setIsVisible:NO];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // show the window when the application becomes active
    [self.pageViewerViewWindow setIsVisible:YES];
}



@end
