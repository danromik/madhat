//
//  MHMathFontsLibraryEditingManager.m
//  MadHat
//
//  Created by Dan Romik on 12/18/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "MHMathFontSystem.h"
#import "MHMathFontsLibraryEditingManager.h"
#import "MHMathFontEditorController.h"
#import "MHMathFontManager.h"

NSString * const kMHMathFontsLibraryNewFontSampleText = @"Pack my box with five dozen liquor jugs";

NSString * const kMHMathFontsLibraryEditingMathFontsTableIdentifier = @"mathfonts";     // separately defined in MathFontEditor.xib
NSString * const kMHMathFontsLibraryEditingAvailableFontsTableIdentifier = @"allfonts"; // separately defined in MathFontEditor.xib

NSString * const kMHMathFontsLibraryEditingAvailableFontsTableColumnNameIdentifier = @"name"; // separately defined in MathFontEditor.xib
NSString * const kMHMathFontsLibraryEditingAvailableFontsTableColumnSampleTextIdentifier = @"sampletext"; // separately defined in MathFontEditor.xib

@interface MHMathFontsLibraryEditingManager ()
{
    NSArray <NSString *> *_mathFontSystems;
    NSArray <NSString *> *_availableFontFamilies;
    NSArray <NSAttributedString *> *_availableFontFamilyAttributedStrings;
    NSArray <NSAttributedString *> *_availableFontFamilySampleTexts;
    
    NSInteger savedIndexOfRowSelectedWhilePresentingModalSheet;
}

// IB Outlets
// FIXME: which of these outlets need to be weak properties to avoid memory leaks?
@property IBOutlet MHMathFontEditorController *mathFontEditorController;
@property IBOutlet NSWindow *mathFontEditorWindow;
@property IBOutlet NSWindow *fontFamilyPickerSheet;
@property IBOutlet NSWindow *selectionChangeWithUnsavedChangesSheet;
@property IBOutlet NSSegmentedControl *createDeleteFontSegmentedControl;
@property IBOutlet NSTableView *listOfAvailableFontsTableView;
@property IBOutlet NSTableView *listOfMathFontsTableView;
@property IBOutlet NSButton *createNewFontAfterSelectingButton;

@property (readonly) NSArray <NSString *> *mathFontSystems;
@property (readonly) NSArray <NSString *> *availableFontFamilies;
@property (readonly) NSArray <NSString *> *availableFontFamilyAttributedStrings;
@property (readonly) NSArray <NSString *> *availableFontFamilySampleTexts;


- (IBAction)createOrDeleteFont:(NSSegmentedControl *)sender;
- (IBAction)cancelNewFontCreationSequence:(id)sender;
- (IBAction)createNewFontAfterSelectingFont:(id)sender;
- (IBAction)abandonChangesAndSwitchSelection:(id)sender;
- (IBAction)cancelSwitchSelectionAndContinueEditing:(id)sender;


// Contextual menu action
- (IBAction)showMathFontSystemInFinder:(id)sender;



- (void)initiateNewFontCreationSequence;
- (void)deleteCurrentFont;

@end

@implementation MHMathFontsLibraryEditingManager


- (instancetype)init
{
    if (self = [super init]) {
        // nothing special we need to do at this point
    }
    return self;
}


#pragma mark - User actions

- (IBAction)createOrDeleteFont:(NSSegmentedControl *)sender
{
    switch (sender.selectedSegment) {
        case 0:
            [self initiateNewFontCreationSequence];
            break;
        case 1:
            [self deleteCurrentFont];
            break;
        default:
            NSLog(@"This shouldn't happen");
    }
}

- (void)initiateNewFontCreationSequence
{
    if (self.mathFontEditorController.hasUnsavedChanges) {
        // FIXME: temporary code to make it impossible to try to create a new font when there are unsaved changes to the currently edited one
        // FIXME: Replace it with a modal sheet?
        NSBeep();
        return;
    }
    
    void (^handler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
        // Do nothing
    };

    [self.listOfAvailableFontsTableView deselectAll:nil];
    [self.listOfAvailableFontsTableView scrollRowToVisible:0];
    [self.mathFontEditorWindow beginSheet:self.fontFamilyPickerSheet completionHandler:handler];
}

- (IBAction)cancelNewFontCreationSequence:(id)sender
{
    [self.mathFontEditorWindow endSheet:self.fontFamilyPickerSheet];
}

- (IBAction)createNewFontAfterSelectingFont:(id)sender
{
    NSInteger selectedRow = self.listOfAvailableFontsTableView.selectedRow;
    if (selectedRow >= 0) {
        NSString *familyName = self.availableFontFamilies[selectedRow];
        [[MHMathFontManager defaultManager] createNewMathFontWithName:familyName];
    }
    else {
        NSLog(@"Error: no font selected");
        NSBeep();
    }
    _mathFontSystems = nil;     // will force the array to be recreated when the table is loaded
    [self.listOfMathFontsTableView deselectAll:nil];    // FIXME: it would be better to select the newly created font
    [self.listOfMathFontsTableView reloadData];
    
    [self.mathFontEditorWindow endSheet:self.fontFamilyPickerSheet];
}

- (void)deleteCurrentFont
{
    NSInteger currentlySelectedFontIndex = self.listOfMathFontsTableView.selectedRow;
        
    if (currentlySelectedFontIndex >= 0) {
        
        [[MHMathFontManager defaultManager] deleteMathFontWithName:_mathFontSystems[currentlySelectedFontIndex]];
        _mathFontSystems = nil;     // will force the array to be recreated when the table is loaded
        self.mathFontEditorController.mathFontSystem = nil;
        [self.listOfMathFontsTableView deselectAll:nil];
        [self.listOfMathFontsTableView reloadData];

//
//        NSError *myError;
//        NSURL *currentlySelectedFontURL = _mathFontSystems[currentlySelectedFontIndex];
//        [[NSFileManager defaultManager] removeItemAtURL:currentlySelectedFontURL
//                                                  error:&myError];
//        if (myError) {
//            NSLog(@"Error: could not delete font file, error=%@", myError);
//            NSBeep();
//        }
//        else {
//            _mathFontSystems = nil;     // will force the array to be recreated when the table is loaded
//            self.mathFontEditorController.mathFontSystem = nil;
//            [self.listOfMathFontsTableView deselectAll:nil];
//            [self.listOfMathFontsTableView reloadData];
//        }
    }
    else {
        NSLog(@"Error: no selected font, can't delete");
        NSBeep();
    }
}

- (void)saveCurrentlyEditingFont
{
    MHMathFontSystem *currentlyEditingMathFontSystem = self.mathFontEditorController.mathFontSystem;
    if (currentlyEditingMathFontSystem) {
        [[MHMathFontManager defaultManager] saveMathFont:currentlyEditingMathFontSystem];
    }
    else {
        NSLog(@"Error: no selected font, can't save");
    }
    
//
//    NSInteger currentlySelectedFontIndex = self.listOfMathFontsTableView.selectedRow;
//    if (currentlySelectedFontIndex >= 0) {
//        MHMathFontSystem *currentlyEditingMathFontSystem = self.mathFontEditorController.mathFontSystem;
//        NSString *serializedStringRepresentation = [currentlyEditingMathFontSystem serializedStringRepresentation];
//        NSURL *currentlySelectedFontURL = _mathFontSystems[currentlySelectedFontIndex];
//        NSError *myError;
//        [serializedStringRepresentation writeToURL:currentlySelectedFontURL
//                                        atomically:NO
//                                          encoding:NSUTF8StringEncoding
//                                             error:&myError];
//        if (myError) {
//            NSLog(@"Error: could not save font to file, error=%@", myError);
//            NSBeep();
//        }
//    }
//    else {
//        NSLog(@"Error: no selected font, can't save");
//    }
}

- (IBAction)abandonChangesAndSwitchSelection:(id)sender
{
    [self.mathFontEditorWindow endSheet:self.selectionChangeWithUnsavedChangesSheet];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:savedIndexOfRowSelectedWhilePresentingModalSheet];
    [self.listOfMathFontsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (IBAction)cancelSwitchSelectionAndContinueEditing:(id)sender
{
    [self.mathFontEditorWindow endSheet:self.selectionChangeWithUnsavedChangesSheet];
}

#pragma mark - Contextual menu

- (IBAction)showMathFontSystemInFinder:(id)sender
{
    NSInteger clickedRowIndex = self.listOfMathFontsTableView.clickedRow;
    if (clickedRowIndex >= 0) {
        NSString *name = _mathFontSystems[clickedRowIndex];
        NSURL *url = [[MHMathFontManager defaultManager] urlForFontWithName:name];
        if (url)
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ url ]];
    }
}

#pragma mark - NSTableViewDelegate and NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingMathFontsTableIdentifier])
        return self.mathFontSystems.count;
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableIdentifier])
        return self.availableFontFamilies.count;
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableView.identifier isEqualToString:kMHMathFontsLibraryEditingMathFontsTableIdentifier]) {
//        if (rowIndex < self.mathFontSystems.count) {
            return self.mathFontSystems[rowIndex];
//            return [[self.mathFontSystems[rowIndex] lastPathComponent] stringByDeletingPathExtension];
//        }
//        return nil;
    }
    if ([aTableView.identifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableIdentifier]) {
        NSString *columnIdentifier = aTableColumn.identifier;
        if ([columnIdentifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableColumnNameIdentifier]) {
            return self.availableFontFamilyAttributedStrings[rowIndex];
        }
        if ([columnIdentifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableColumnSampleTextIdentifier]) {
            return self.availableFontFamilySampleTexts[rowIndex];
        }
        return @"?";
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    NSInteger selectedRowIndex = tableView.selectedRow;
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingMathFontsTableIdentifier]) {
        if (selectedRowIndex < 0) {
            self.mathFontEditorController.mathFontSystem = nil;
            [self.createDeleteFontSegmentedControl setEnabled:false forSegment:1];  // segment 1 is the "delete" action
        }
        else {
            
            // Load the font and assign it as the currently edited font in the math font editor controller
            MHMathFontSystem *mathFontSystem = [[MHMathFontManager defaultManager] mathFontWithName:self.mathFontSystems[selectedRowIndex]];
            self.mathFontEditorController.mathFontSystem = mathFontSystem;
            [self.createDeleteFontSegmentedControl setEnabled:true forSegment:1];  // segment 1 is the "delete" action
            
//            // Load the font from file and assign it as the currently edited font in the math font editor controller
//
//            NSError *myError;
//            NSURL *fontFamilyURL = self.mathFontSystems[selectedRowIndex];
//            NSString *fontFamilySerializedString = [NSString stringWithContentsOfURL:fontFamilyURL
//                                                                            encoding:NSUTF8StringEncoding
//                                                                               error:&myError];
//            if (myError) {
//                NSLog(@"Error: unable to load font file, error=%@", myError);
//                NSString *fontFamilyName = [[self.mathFontSystems[selectedRowIndex] lastPathComponent] stringByDeletingPathExtension];
//                MHMathFontSystem *mathFontSystem = [[MHMathFontSystem alloc] initWithFontFamilyName:fontFamilyName];
//                self.mathFontEditorController.mathFontSystem = mathFontSystem;
//            }
//            else {
//                MHMathFontSystem *mathFontSystem = [MHMathFontSystem fontFamilyFromSerializedStringRepresentation:fontFamilySerializedString];
//                self.mathFontEditorController.mathFontSystem = mathFontSystem;
//            }
//            [self.createDeleteFontSegmentedControl setEnabled:true forSegment:1];  // segment 1 is the "delete" action
        }
    }
    
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableIdentifier]) {
        self.createNewFontAfterSelectingButton.enabled = true;
    }
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingAvailableFontsTableIdentifier]) {
        NSString *fontFamilyName = self.availableFontFamilies[row];
        for (NSString *mathFontSystem in self.mathFontSystems) {
//            NSString *anotherFontFamilyName = [[mathFontSystem lastPathComponent] stringByDeletingPathExtension];
            if ([mathFontSystem isEqualToString:fontFamilyName])
                // the font already has a math font system - do not allow selection
                return NO;
        }
        return YES;
    }
    if ([tableView.identifier isEqualToString:kMHMathFontsLibraryEditingMathFontsTableIdentifier]) {
        if (self.mathFontEditorController.hasUnsavedChanges) {
            // User attempted to select a different math font when there are unsaved changes to the current one
            
            // FIXME: incorrect behavior when creating a new font while having unsaved changes - fix

            // Just beeping for now, commenting out the modal sheet
            NSBeep();

            // Commenting this out for now
//            void (^handler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
//                // Do nothing
//            };
//            savedIndexOfRowSelectedWhilePresentingModalSheet = row;
//            [self.mathFontEditorWindow beginSheet:self.selectionChangeWithUnsavedChangesSheet completionHandler:handler];

                        
            return NO;
        }
        return YES;
    }
    return YES;
}


#pragma mark - Miscellaneous methods

- (NSArray <NSString *> *)availableFontFamilies
{
    if (!_availableFontFamilies)
        _availableFontFamilies = [[NSFontManager sharedFontManager] availableFontFamilies];
    return _availableFontFamilies;
}

- (NSArray <NSAttributedString *> *)availableFontFamilyAttributedStrings
{
    [self lazilyCreateAvailableFontFamilyAndSampleTextAttributedStrings];
    return _availableFontFamilyAttributedStrings;
}

- (NSArray <NSAttributedString *> *)availableFontFamilySampleTexts
{
    [self lazilyCreateAvailableFontFamilyAndSampleTextAttributedStrings];
    return _availableFontFamilySampleTexts;
}

- (void)lazilyCreateAvailableFontFamilyAndSampleTextAttributedStrings
{
    if (!_availableFontFamilyAttributedStrings || _availableFontFamilySampleTexts) {
        NSArray <NSString *> *availableFontFamilies = self.availableFontFamilies;
        NSMutableArray *mutableAttributedStringsArrayForFamilies = [[NSMutableArray alloc] initWithCapacity:availableFontFamilies.count];
        NSMutableArray *mutableAttributedStringsArrayForSampleTexts = [[NSMutableArray alloc] initWithCapacity:availableFontFamilies.count];

        NSColor *selectableColor = [NSColor blackColor];
        NSColor *unselectableColor = [NSColor grayColor];
        
        NSDictionary *familiesAttribsDictFontAlreadyExistsAsMathFont = @{ NSForegroundColorAttributeName : unselectableColor };
        NSDictionary *familiesattribsDictFontDoesNotExistAsMathFont = @{ NSForegroundColorAttributeName : selectableColor };

        for (NSString *family in availableFontFamilies) {
            NSAttributedString *attribStringForFamily = nil;
            NSAttributedString *attribStringForSampleText = nil;
            NSFont *font = [NSFont fontWithName:family size:14.0];
            NSDictionary *attribsDictForSampleTextUnselectable = @{
                NSForegroundColorAttributeName : unselectableColor,
                NSFontAttributeName : font
            };
            NSDictionary *attribsDictForSampleTextSelectable = @{
                NSForegroundColorAttributeName : selectableColor,
                NSFontAttributeName : font
            };
            for (NSURL *mathFontSystem in self.mathFontSystems) {
                NSString *mathFontSystemString = [[mathFontSystem lastPathComponent] stringByDeletingPathExtension];
                if ([family isEqualToString:mathFontSystemString]) {
                    // the font already has a math font system - do not allow selection
                    attribStringForFamily = [[NSAttributedString alloc] initWithString:family
                                                                            attributes:familiesAttribsDictFontAlreadyExistsAsMathFont];
                    
                    attribStringForFamily = [[NSAttributedString alloc] initWithString:family
                                                                            attributes:familiesAttribsDictFontAlreadyExistsAsMathFont];
                    attribStringForSampleText = [[NSAttributedString alloc] initWithString:NSLocalizedString(kMHMathFontsLibraryNewFontSampleText, @"")
                                                                            attributes:attribsDictForSampleTextUnselectable];
                    break;
                }
            }
            if (!attribStringForFamily) {
                attribStringForFamily = [[NSAttributedString alloc] initWithString:family
                                                                        attributes:familiesattribsDictFontDoesNotExistAsMathFont];
                attribStringForSampleText = [[NSAttributedString alloc] initWithString:NSLocalizedString(kMHMathFontsLibraryNewFontSampleText, @"")
                                                                        attributes:attribsDictForSampleTextSelectable];
            }
            [mutableAttributedStringsArrayForFamilies addObject:attribStringForFamily];
            [mutableAttributedStringsArrayForSampleTexts addObject:attribStringForSampleText];
        }
        
        _availableFontFamilyAttributedStrings = [NSArray arrayWithArray:mutableAttributedStringsArrayForFamilies];
        _availableFontFamilySampleTexts = [NSArray arrayWithArray:mutableAttributedStringsArrayForSampleTexts];
    }
}

- (NSArray <NSString *> *)mathFontSystems
{
    if (!_mathFontSystems) {
        _mathFontSystems = [[MHMathFontManager defaultManager] availableMathFonts];
//        NSArray <NSURL *> *fontFolders = [AppDelegate fontFolders];
//        NSMutableArray <NSURL *> *fontFiles = [[NSMutableArray alloc] initWithCapacity:0];
//
//        for (NSURL *folderUrl in fontFolders) {
//            NSError *directoryLoadingError = nil;
//            NSArray <NSURL *> * filesInFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderUrl
//                                                                              includingPropertiesForKeys:@[ NSURLIsRegularFileKey ]
//                                                                                                 options:0
//                                                                                                   error:&directoryLoadingError];
//            if (!directoryLoadingError) {
//                [fontFiles addObjectsFromArray:filesInFolder];
//            }
//            else {
//                // FIXME: should we NSLog the error? Do something else with it?
//            }
//        }
//        _mathFontSystems = [NSArray arrayWithArray:fontFiles];
    }
    return _mathFontSystems;
}

@end
