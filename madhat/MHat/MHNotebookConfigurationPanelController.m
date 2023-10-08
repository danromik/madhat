//
//  MHNotebookConfigurationPanelController.m
//  MadHat
//
//  Created by Dan Romik on 8/28/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHNotebookConfigurationPanelController.h"
#import "MHSourceCodeTextView.h"
#import "MHParser.h"
#import "AppDelegate.h"

@interface MHNotebookConfigurationPanelController ()
{
    NSString *_fallbackConfigurationCode;
    NSString *_lastSavedConfigurationCode;
    MHSourceCodeEditorTheme *_editorTheme;
    MHTypesettingContextManager *_typesettingContextManager;
}

@property IBOutlet NSTextView *dummyConfigurationCodeEditorView;
@property IBOutlet NSScrollView *configurationCodeEditorEnclosingScrollView;

@property IBOutlet NSButton *cancelButton;
@property IBOutlet NSButton *revertButton;
@property IBOutlet NSButton *applyButton;
@property IBOutlet NSButton *doneButton;


@property bool haveUnappliedChanges;

@end

@implementation MHNotebookConfigurationPanelController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Install the configuration code editor view as the document view for the scroll view we got from the nib file
    MHSourceCodeTextView *configurationCodeEditorView = [[MHSourceCodeTextView alloc] initWithFrame:NSZeroRect
                                                                                      textContainer:nil];
    configurationCodeEditorView.notebookConfigurationCommandsEnabled = YES;
    configurationCodeEditorView.autoresizingMask = self.dummyConfigurationCodeEditorView.autoresizingMask;
    NSRect scrollViewFrame = self.configurationCodeEditorEnclosingScrollView.frame;
    configurationCodeEditorView.frame = NSMakeRect(0, 0.0, scrollViewFrame.size.width, scrollViewFrame.size.height);
    [self.configurationCodeEditorEnclosingScrollView setDocumentView:configurationCodeEditorView];
    [configurationCodeEditorView viewWasInstalledAsScrollViewDocumentView];
    
    // Start the cursor at the top
    configurationCodeEditorView.selectedRange = NSMakeRange(0, 0);
    
    configurationCodeEditorView.editorTheme = _editorTheme;

    // Create a parser that would be assigned as a code editing delegate of the source code editor view, and for which the Sprite Kit scene would act as a delegate
    // FIXME: is this a logical structure? Re-examine the relationship between these classes and think if the setup can be improved
    MHParser *parser = [[MHParser alloc] init];
    parser.notebookConfigurationCommandsEnabled = YES;
    parser.delegate = self;
    _typesettingContextManager = [[MHTypesettingContextManager alloc] init];
    configurationCodeEditorView.codeEditingDelegate = parser;

    // If some code has been stored in the _fallbackConfigurationCode variable, set that as the source code string and release the string stored in the fallback storage variable
    if (_fallbackConfigurationCode) {
        configurationCodeEditorView.string = _fallbackConfigurationCode;
        _fallbackConfigurationCode = nil;
    }
    
    // Save the view in a property for later use
    self.configurationCodeEditorView = configurationCodeEditorView;
    
    self.applyButton.enabled = false;     // no changes to apply yet
    self.revertButton.enabled = false;   // no changes to revert yet
    self.cancelButton.enabled = false;   // no changes to cancel yet
    self.doneButton.enabled = true;   // it is possible to dismiss the sheet

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationCodeChanged:)
                                                 name:NSTextDidChangeNotification
                                               object:configurationCodeEditorView];
}


#pragma mark - User actions

- (IBAction)getHelp:(id)sender
{
    [((AppDelegate *)[[NSApplication sharedApplication] delegate]) openHelpPagesForNotebookConfiguration];
}

- (IBAction)doneButtonClicked:(id)sender
{
    NSWindow *myWindow = self.window;
    [myWindow.sheetParent endSheet:myWindow];
}

- (IBAction)applyChanges:(id)sender
{
    NSString *configurationCodeToSave = self.configurationCode;
    self.parentNotebook.configurationCode = configurationCodeToSave;
    
    self.haveUnappliedChanges = false;

    _lastSavedConfigurationCode = [configurationCodeToSave copy];
}

- (IBAction)revert:(id)sender
{
    self.configurationCode = _lastSavedConfigurationCode;
    self.haveUnappliedChanges = false;
}

- (IBAction)cancel:(id)sender
{
    NSWindow *myWindow = self.window;
    [myWindow.sheetParent endSheet:myWindow];
}

- (void)configurationCodeChanged:(NSNotification *)notification
{
    self.haveUnappliedChanges = true;
}


#pragma mark - MHParserDelegate


- (void)compiledExpressionChangedTo:(MHVerticalLayoutContainer *)newExpression
                         changeType:(MHExpressionCompiledExpressionUpdateType)changeType
             firstAffectedParagraph:(MHParagraph * _Nullable)firstParagraph
                     paragraphIndex:(NSUInteger)paragraphIndex
            secondAffectedParagraph:(MHParagraph * _Nullable)secondParagraph
{
    [newExpression typesetWithContextManager:_typesettingContextManager];
}



#pragma mark - Properties

- (NSString *)configurationCode
{
    MHSourceCodeTextView *editorView = self.configurationCodeEditorView;
    if (editorView) {
        return editorView.string;
    }
    return _fallbackConfigurationCode;
}

- (void)setConfigurationCode:(NSString *)newConfigurationCode
{
    MHSourceCodeTextView *editorView = self.configurationCodeEditorView;
    if (editorView) {
        editorView.string = newConfigurationCode;
    }
    else {
        _fallbackConfigurationCode = newConfigurationCode;
    }
    _lastSavedConfigurationCode = [newConfigurationCode copy];  // save a copy of the code the user can revert to later
}

- (MHSourceCodeEditorTheme *)editorTheme
{
    return _editorTheme;
}

- (void)setEditorTheme:(MHSourceCodeEditorTheme *)newEditorTheme
{
    _editorTheme = newEditorTheme;
    MHSourceCodeTextView *editorView = self.configurationCodeEditorView;
    if (editorView) {
        editorView.editorTheme = newEditorTheme;
    }
}


- (bool)haveUnappliedChanges
{
    return self.applyButton.enabled;
}

- (void)setHaveUnappliedChanges:(bool)newValue
{
    self.applyButton.enabled = newValue;
    self.revertButton.enabled = newValue;
    self.cancelButton.enabled = newValue;
    self.doneButton.enabled = !newValue;
}

@end
