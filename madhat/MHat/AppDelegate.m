//
//  AppDelegate.m
//  MadHat
//
//  Created by Dan Romik on 12/22/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "AppDelegate.h"
#import "MHHelpNotebook.h"
#import "MHPackageManager.h"
#import "MHDocumentController.h"
#import "MHIssueReporterWindowController.h"
#import "MHAppConfigurationWindowController.h"
#import "MHPreferencesWindowController.h"

static NSString * const kMadHatWebsiteURL = @"https://madhat.design";

static NSString * const kMadHatAcknowledgementsFileName = @"acknowledgements";
static NSString * const kMadHatAcknowledgementsFileExtension = @"pdf";

static NSString * const kMadHatLicenseFileName = @"madhat-eula";
static NSString * const kMadHatLicenseFileExtension = @"pdf";

static NSString * const kMHMathFontEditorIBFileName = @"MathFontEditor";
static NSString * const kMHMIssueReporterIBFileName = @"IssueReporter";
static NSString * const kMHMConfigurationWindowIBFileName = @"ConfigurationWindow";
static NSString * const kMHPreferencesWindowIBFileName = @"PreferencesWindow";

static NSString * const kMHHelpFileSpecialSymbolsPageName = @"List of special symbols";
static NSString * const kMHHelpFileNotebookConfigurationPageName = @"Notebook configuration";

NSString * const kMHUserDefaultsEditorThemeKey = @"MHDefaultEditorTheme";        // a string value


@interface AppDelegate ()
{
    NSWindowController *_mathFontEditorWindowController;
    BOOL _mathFontEditorIsOpen;

    MHPreferencesWindowController *_preferencesWindowController;
    BOOL _preferencesWindowIsOpen;

    NSMutableArray <MHIssueReporterWindowController *> *_issueReporterWindowControllers;
    NSUInteger _numberOfIssueReporterWindowsOpen;
    
    MHAppConfigurationWindowController *_configurationWindowController;
    BOOL _configurationWindowOpen;
}

@property IBOutlet NSMenuItem *showHideMathFontEditorMenuItem;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _mathFontEditorIsOpen = NO;
    _configurationWindowOpen = NO;
    _numberOfIssueReporterWindowsOpen = 0;
    
    NSDocumentController *sharedDocController = [NSDocumentController sharedDocumentController];
    sharedDocController.autosavingDelay = 60.0;
    
    if (![MHDocumentController appConfigurationComplete])
        [self showConfigurationWindow:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [MHDocumentController appConfigurationComplete];
}


//- (void)applicationWillTerminate:(NSNotification *)aNotification
//{
//// Insert code here to tear down your application
////
//// Note: this isn't guaranteed to run unless the appropriate Info.plist entry is set to NO,
//// see:
//// https://stackoverflow.com/questions/59760604/applicationwillterminate-and-applicationshouldterminate-dont-get-run-on-macos
//}



//
// the Quit main menu action is rerouted to the method closeHelpWindowAndTerminate: below.
// The idea is to close the help window before starting the usual app termination sequence. In this way the help
// notebook does not get opened automatically by macOS the next time the application is relaunched. (To get this to
// work it was also necessary to change a key in the Info.plist file, see this StackOverflow discussion:
// https://stackoverflow.com/questions/59760604/applicationwillterminate-and-applicationshouldterminate-dont-get-run-on-macos
//
- (IBAction)closeHelpWindowAndTerminate:(id)sender
{
    [self closeHelp];
    [[NSApplication sharedApplication] terminate:nil];
}



- (IBAction)showIssueReport:(NSMenuItem *)sender
{
    // Create and show the issue reporter window
    MHIssueReporterWindowController *issueReporterWindowController = [[MHIssueReporterWindowController alloc] initWithWindowNibName:kMHMIssueReporterIBFileName];
    [issueReporterWindowController showWindow:nil];
    if (!_issueReporterWindowControllers) {
        _issueReporterWindowControllers = [[NSMutableArray alloc] initWithCapacity:0];
    }
    [_issueReporterWindowControllers addObject:issueReporterWindowController];
    _numberOfIssueReporterWindowsOpen++;

    NSWindow *issueReporterWindow = issueReporterWindowController.window;
    NSRect issueReporterWindowFrame = issueReporterWindow.frame;
    issueReporterWindowFrame.origin.x += 36.0 * _numberOfIssueReporterWindowsOpen;
    issueReporterWindowFrame.origin.y -= 26.0 * _numberOfIssueReporterWindowsOpen;
    [issueReporterWindow setFrameOrigin:issueReporterWindowFrame.origin];

    // Make self the delegate to keep track of user window-closing action
    issueReporterWindowController.window.delegate = self;

    // Important note: it's critical to set the "file's owner" object's "window" property in Interface Builder to the actual window in the xib file. Otherwise the window property of the window controller will be nil and this messes up notifications, programmatically closing the window etc
}

// called from the "Show Math Font Editor" menu item in MainMenu.xib
// FIXME: disabled for now, might expose it to the user in a later version
- (IBAction)toggleMathFontEditor:(NSMenuItem *)sender
{
    _mathFontEditorIsOpen = !_mathFontEditorIsOpen;
    if (_mathFontEditorIsOpen) {
        
        // Create and show the math font editor window
        _mathFontEditorWindowController = [[NSWindowController alloc] initWithWindowNibName:kMHMathFontEditorIBFileName];
        [_mathFontEditorWindowController showWindow:nil];
        // Important note: it's critical to set the "file's owner" object's "window" property in Interface Builder to the actual window in the xib file. Otherwise the window property of the window controller will be nil and this messes up notifications, programmatically closing the window etc

        
        // Make self the delegate to keep track of user window-closing action
        _mathFontEditorWindowController.window.delegate = self;
        
        // Update the menu item text
        self.showHideMathFontEditorMenuItem.title = NSLocalizedString(@"Hide Math Font Editor", @"");
    }
    else {
        // Programmatically close the math font editor window
        [_mathFontEditorWindowController close];
        _mathFontEditorWindowController = nil;
        
        // Update the menu item text
        self.showHideMathFontEditorMenuItem.title = NSLocalizedString(@"Show Math Font Editor", @"");
    }
}

- (IBAction)showConfigurationWindow:(id)sender
{
    if (_configurationWindowOpen)
        return;
    
    _configurationWindowOpen = YES;
    _configurationWindowController = [[MHAppConfigurationWindowController alloc] initWithWindowNibName:kMHMConfigurationWindowIBFileName];
    [_configurationWindowController showWindow:nil];

    // Make self the delegate to keep track of user window-closing action
    _configurationWindowController.window.delegate = self;

    // Important note: it's critical to set the "file's owner" object's "window" property in Interface Builder to the actual window in the xib file. Otherwise the window property of the window controller will be nil and this messes up notifications, programmatically closing the window etc
}

- (IBAction)showAcknowledgements:(id)sender
{
    NSURL *acknowledgementsFileURL = [[NSBundle mainBundle]
                                      URLForResource:kMadHatAcknowledgementsFileName
                                      withExtension:kMadHatAcknowledgementsFileExtension];
    [[NSWorkspace sharedWorkspace] openURL:acknowledgementsFileURL];
}

- (IBAction)showLicense:(id)sender
{
    NSURL *licenseFileURL = [[NSBundle mainBundle]
                                      URLForResource:kMadHatLicenseFileName
                                      withExtension:kMadHatLicenseFileExtension];
    [[NSWorkspace sharedWorkspace] openURL:licenseFileURL];
}

- (IBAction)goToAppWebsite:(id)sender
{
    NSURL *goToAppWebsite = [NSURL URLWithString:kMadHatWebsiteURL];
    [[NSWorkspace sharedWorkspace] openURL:goToAppWebsite];
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closingWindow = notification.object;
    if (_mathFontEditorWindowController && [closingWindow isEqualTo:_mathFontEditorWindowController.window]) {
        // The user clicked the close button on the math font editor window
        _mathFontEditorWindowController = nil;
        
        // Update the menu item text
        self.showHideMathFontEditorMenuItem.title = NSLocalizedString(@"Show Math Font Editor", @"");
        
        // Update the boolean var keeping track of whether the math font editor is open
        _mathFontEditorIsOpen = NO;
    }
    else if (_configurationWindowController && [closingWindow isEqualTo:_configurationWindowController.window]) {
        // The user clicked the close button on the configuration window
        _configurationWindowController = nil;

        // Update the boolean var keeping track of whether the configuration window is open
        _configurationWindowOpen = NO;
    }
    else if (_preferencesWindowController && [closingWindow isEqualTo:_preferencesWindowController.window]) {
        // The user clicked the close button on the configuration window
        _preferencesWindowController = nil;

        // Update the boolean var keeping track of whether the configuration window is open
        _preferencesWindowIsOpen = NO;
    }
    else {
        MHIssueReporterWindowController *closingWindowController = closingWindow.windowController;
        if ([_issueReporterWindowControllers indexOfObject:closingWindowController] != NSNotFound) {
            // an issue reporter window is being closed, but make sure
            _numberOfIssueReporterWindowsOpen--;
            [_issueReporterWindowControllers removeObject:closingWindowController];
        }
        else {
            NSLog(@"error 537");    // an unknown window is closing. This should never happen
        }
    }
}


#pragma mark - Preferences window

- (IBAction)showPreferences:(id)sender
{
    if (_preferencesWindowIsOpen) {
        [_preferencesWindowController.window makeKeyAndOrderFront:nil];
        return;
    }
        
    // Create and show the preferences window
    _preferencesWindowController = [[MHPreferencesWindowController alloc] initWithWindowNibName:kMHPreferencesWindowIBFileName];
    [_preferencesWindowController showWindow:nil];
    [_preferencesWindowController.window makeKeyAndOrderFront:nil];
    // Important note: it's critical to set the "file's owner" object's "window" property in Interface Builder to the actual window in the xib file. Otherwise the window property of the window controller will be nil and this messes up notifications, programmatically closing the window etc
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:_preferencesWindowController.window];
    
    _preferencesWindowIsOpen = YES;
}



#pragma mark - Help feature

- (IBAction)showHelp:(id)sender
{
    [self openHelpPagesWithStartingPage:nil];
}

- (void)openHelpPagesWithStartingPage:(NSString *)helpPageName
{
    MHDocumentController *sharedDocumentController = [NSDocumentController sharedDocumentController];
    NSURL *helpPagesURL = [sharedDocumentController urlForHelpPagesNotebook];
    
    void (^completionHandler)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) = ^void(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
        // code to configure the opened help notebook
        MHHelpNotebook *helpNotebook = (MHHelpNotebook *)document;
        [helpNotebook.pageViewerViewWindow makeKeyAndOrderFront:nil];
        if (helpPageName) {
            [helpNotebook goToPageNamed:helpPageName];
        }
        else if (!documentWasAlreadyOpen) {
            [helpNotebook goToHomeHelpPage:nil];    // go to the home page, but only if the help window was not already open
            [helpNotebook clearRecentlyVisitedPagesList:nil];
        }
    };

    [sharedDocumentController openDocumentWithContentsOfURL:helpPagesURL display:YES completionHandler:completionHandler];
}

- (void)openHelpPagesForSpecialSymbols
{
    [self openHelpPagesWithStartingPage:kMHHelpFileSpecialSymbolsPageName];
}

- (void)openHelpPagesForNotebookConfiguration
{
    [self openHelpPagesWithStartingPage:kMHHelpFileNotebookConfigurationPageName];
}

- (void)openHelpPage:(NSString *)pageName
{
    [self openHelpPagesWithStartingPage:pageName];
}

- (void)openHelpPageForCommandName:(NSString *)commandName
{
    NSString *helpPageName = [[MHPackageManager sharedPackageManager] helpPageNameForCommandName:commandName];
    [self openHelpPagesWithStartingPage:helpPageName];
}

- (void)closeHelp
{
    NSArray <MHNotebook *> *openNotebooks = [[NSDocumentController sharedDocumentController] documents];
    for (MHNotebook *notebook in openNotebooks) {
        if ([notebook isKindOfClass:[MHHelpNotebook class]]) {
            [notebook close];
            return;
        }
    }
}



@end
