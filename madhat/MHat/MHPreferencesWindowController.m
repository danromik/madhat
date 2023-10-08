//
//  MHPreferencesWindowController.m
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHPreferencesWindowController.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeEditorThemeManager.h"


static const NSUInteger kCreateThemeSegmentIndex = 0;
static const NSUInteger kDeleteThemeSegmentIndex = 1;


static const NSUInteger kTextBackgroundColorWellTag = 1000;
static const NSUInteger kMathBackgroundColorWellTag = 1001;
static const NSUInteger kInsertionPointColorWellTag = 1002;
static const NSUInteger kSelectionColorWellTag = 1003;



static NSString * const kMHPreferencesEditorThemeDraggingPasteboardType = @"design.madhat.editortheme";



@interface MHEditorThemesTableView : NSTableViewWithDeleteShortcut
@end

@interface MHEditorThemesTableRowView : NSTableRowView
@property BOOL drawsSeparator;
@end







@interface MHPreferencesWindowController ()
{
    NSArray <MHSourceCodeEditorTheme *> *_themes;
    MHSourceCodeEditorTheme *_currentThemeWorkingCopy;
    NSArray <NSString *> *_colorDescriptions;
    NSUInteger _numberOfPresetThemes;
    
    // we want to know these row indices so we can set the background color to the math mode background color
    NSUInteger _mathModeColorRowIndex;
    NSUInteger _mathKeywordColorRowIndex;
    
    // we want to know these row indices so we can set the font to a bold font
    NSUInteger _commandColorRowIndex;
    NSUInteger _unresolvedCommandColorRowIndex;
    
    // keeping track of color wells being displayed so we can enable and disable them when the window goes in and out of focus
    // this is a workaround to overcome very annoying flaws with the NSColorPanel and NSColorWell API
    NSMutableArray *_colorWells;
    NSColorWell *_activeColorWell;
    
    BOOL _haveUnsavedChanges;
}

@property IBOutlet NSToolbar *preferencePanesToolbar;

@property IBOutlet NSTableViewWithDeleteShortcut *themesTableView;
@property IBOutlet NSTableView *themeForegroundColorEntriesTableView;
@property IBOutlet NSTextField *fontTextField;

@property IBOutlet NSColorWell *textBackgroundColorWell;
@property IBOutlet NSColorWell *mathBackgroundColorWell;
@property IBOutlet NSColorWell *insertionPointColorWell;
@property IBOutlet NSColorWell *selectionColorWell;

@property IBOutlet NSButton *applyAndSaveThemeChangesButton;
@property IBOutlet NSButton *revertToSavedThemeButton;
@property IBOutlet NSButton *changeFontButton;
@property IBOutlet NSTextField *uneditableThemeInfoLabel;
@property IBOutlet NSSegmentedControl *createDeleteThemeSegmentedControl;

@property IBOutlet NSPopUpButton *defaultEditorThemeSelectionPopupButton;

@end

@implementation MHPreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.themesTableView.rowHeight = 24.0;
    _colorDescriptions = [MHSourceCodeEditorTheme localizedThemeEditableForegroundColorDescriptions];
    [self reloadThemes];
    
    // select the editor theme table row corresponding to the user default theme
    MHSourceCodeEditorTheme *userDefaultTheme = [[MHSourceCodeEditorThemeManager defaultManager] userDefaultTheme];
    NSUInteger indexOfUserDefaultTheme = [_themes indexOfObject:userDefaultTheme];
    [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexOfUserDefaultTheme] byExtendingSelection:NO];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
    self.preferencePanesToolbar.selectedItemIdentifier = @"themes";
    
    // Register the dragged types for the page list table view (to enable drag and drop interface for reordering pages)
    [self.themesTableView registerForDraggedTypes:@[kMHPreferencesEditorThemeDraggingPasteboardType]];
    
    // tag some of the color wells to help us keep track of color edit events
    self.textBackgroundColorWell.tag = kTextBackgroundColorWellTag;
    self.mathBackgroundColorWell.tag = kMathBackgroundColorWellTag;
    self.insertionPointColorWell.tag = kInsertionPointColorWellTag;
    self.selectionColorWell.tag = kSelectionColorWellTag;

    // create the array of color wells - we need to keep track of them, see comment above the definition of _colorWells instance variable above
    _colorWells = [[NSMutableArray alloc] initWithCapacity:0];
    [_colorWells addObject:self.textBackgroundColorWell];
    [_colorWells addObject:self.mathBackgroundColorWell];
    [_colorWells addObject:self.insertionPointColorWell];
    [_colorWells addObject:self.selectionColorWell];
}

- (IBAction)selectPreferencesPane:(NSToolbarItem *)pane
{
    // at the moment we only have one preferences pane, so no need to do anything
    // once there are two or more preferences pane, we should switch the content of the window to the appropriate set of preference setting controls
    
    // related discussion: https://www.spacevatican.org/2013/8/5/selectable-items-in-nstoolbar/
}

- (void)reloadThemes
{
    _themes = [[MHSourceCodeEditorThemeManager defaultManager] themes];
    _numberOfPresetThemes = [[MHSourceCodeEditorThemeManager defaultManager] numberOfPresetThemes];
    [self configureDefaultEditorThemesPopUpMenu];
    [self.themesTableView reloadData];
}


- (BOOL)windowShouldClose:(NSWindow *)sender
{
    if (_haveUnsavedChanges) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.informativeText = NSLocalizedString(@"The selected editor theme has unsaved changes. Closing the window will discard them.", @"");
        alert.messageText = NSLocalizedString(@"Do you want to close the Preferences window?", @"");
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Close Window", @"")];

        void (^completionHandler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    // the "Cancel" button was clicked - no action needed
                    break;
                    
                case NSAlertSecondButtonReturn:
                default:
                    // the "Close Window" button was clicked
                    [self.window close];
                    break;
            }
        };

        [alert beginSheetModalForWindow:self.window
                      completionHandler:completionHandler];
        return NO;
    }
    return YES;
}

// Keep track of the window going in and out of main status -- needed so we can disable and enable the active color well
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [_activeColorWell activate:YES];
}
- (void)windowDidResignMain:(NSNotification *)notification
{
    if (_activeColorWell.active) {
        [_activeColorWell deactivate];
        
        NSUInteger activeColorWellTag = _activeColorWell.tag;
        switch (activeColorWellTag) {
            case kTextBackgroundColorWellTag:
                _activeColorWell.color = _currentThemeWorkingCopy.backgroundColor;
                break;
            case kMathBackgroundColorWellTag:
                _activeColorWell.color = _currentThemeWorkingCopy.mathModeBackgroundColor;
                break;
            case kInsertionPointColorWellTag:
                _activeColorWell.color = _currentThemeWorkingCopy.insertionPointColor;
                break;
            case kSelectionColorWellTag:
                _activeColorWell.color = _currentThemeWorkingCopy.selectionColor;
                break;
            default:
                _activeColorWell.color = [_currentThemeWorkingCopy colorForEditableForegroundColorWithIndex:activeColorWellTag];
                break;
        }
        return;

    }
    else
        _activeColorWell = nil;
}

// attempt to close window on escape key press
- (void)cancel:(id)sender
{
    // relevant discussion:
    // https://stackoverflow.com/questions/42393336/how-to-close-window-nswindowcontroller-by-hitting-the-esc-key
    [self.window performClose:nil];
}

- (void)setCurrentEditorTheme:(MHSourceCodeEditorTheme *)theme
{
    _currentThemeWorkingCopy = [theme copy];
    [self updateEditorThemeInterface];
    self.haveUnsavedChanges = NO;
}

- (void)setHaveUnsavedChanges:(BOOL)haveUnsavedChanges
{
    _haveUnsavedChanges = haveUnsavedChanges;
    if (_haveUnsavedChanges) {
        self.applyAndSaveThemeChangesButton.enabled = YES;
        self.revertToSavedThemeButton.enabled = YES;
    }
    else {
        self.applyAndSaveThemeChangesButton.enabled = NO;
        self.revertToSavedThemeButton.enabled = NO;
    }
}

- (void)updateEditorThemeInterface
{
    static CGFloat minimumRowHeight = 26.0;
    self.themeForegroundColorEntriesTableView.backgroundColor = _currentThemeWorkingCopy.backgroundColor;
    self.textBackgroundColorWell.color = _currentThemeWorkingCopy.backgroundColor;
    self.mathBackgroundColorWell.color = _currentThemeWorkingCopy.mathModeBackgroundColor;
    self.insertionPointColorWell.color = _currentThemeWorkingCopy.insertionPointColor;
    self.selectionColorWell.color = _currentThemeWorkingCopy.selectionColor;
    NSFont *font = _currentThemeWorkingCopy.font;
    NSString *fontName = font.familyName;
    CGFloat fontSize = font.pointSize;
    NSFont *convertedFont = [[NSFontManager sharedFontManager] convertFont:font toSize:self.fontTextField.font.pointSize];
    NSString *fontDescription = [NSString stringWithFormat:@"%@ — %.1f", fontName, fontSize];
    self.fontTextField.stringValue = fontDescription;
    self.fontTextField.font = convertedFont;
    CGFloat newRowHeight = font.ascender - font.descender + 4.0;
    if (newRowHeight < minimumRowHeight)
        newRowHeight = minimumRowHeight;
    
    _mathModeColorRowIndex = [_currentThemeWorkingCopy indexForMathModeForegroundColor];
    _mathKeywordColorRowIndex = [_currentThemeWorkingCopy indexForMathKeywordColor];
    _commandColorRowIndex = [_currentThemeWorkingCopy indexForCommandColor];
    _unresolvedCommandColorRowIndex = [_currentThemeWorkingCopy indexForUnresolvedCommandColor];
    
    // update the _colorWells array
    [_colorWells removeAllObjects];
    [_colorWells addObject:self.textBackgroundColorWell];
    [_colorWells addObject:self.mathBackgroundColorWell];
    [_colorWells addObject:self.insertionPointColorWell];
    [_colorWells addObject:self.selectionColorWell];
    
    self.themeForegroundColorEntriesTableView.rowHeight = newRowHeight;
    [self.themeForegroundColorEntriesTableView reloadData];
    [self updateMathBackgroundColorRows];
    [self.themeForegroundColorEntriesTableView.enclosingScrollView flashScrollers];
    
    // make adjustments to the interface according to whether the theme is editable
    BOOL editable = _currentThemeWorkingCopy.editable;
    self.textBackgroundColorWell.enabled = editable;
    self.mathBackgroundColorWell.enabled = editable;
    self.insertionPointColorWell.enabled = editable;
    self.selectionColorWell.enabled = editable;
    self.changeFontButton.enabled = editable;
    self.applyAndSaveThemeChangesButton.hidden = !editable;
    self.revertToSavedThemeButton.hidden = !editable;
    self.uneditableThemeInfoLabel.hidden = editable;
    [self.createDeleteThemeSegmentedControl setEnabled:editable forSegment:kDeleteThemeSegmentIndex];
}


- (void)configureDefaultEditorThemesPopUpMenu
{
    NSPopUpButton *themeSelectionPopUp = self.defaultEditorThemeSelectionPopupButton;
    [themeSelectionPopUp removeAllItems];
    for (MHSourceCodeEditorTheme *theme in _themes) {
        [themeSelectionPopUp addItemWithTitle:theme.name];
    }
    
    NSString *userDefaultThemeName = [[MHSourceCodeEditorThemeManager defaultManager] userDefaultThemeName];
    [themeSelectionPopUp selectItemWithTitle:userDefaultThemeName];
}





#pragma mark - NSTableViewDelegate, NSTableViewDataSource and NSTableViewWithDeleteShortcutDelegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if ([tableView isEqual:self.themesTableView]) {
        return _themes.count;
    }
    else if ([tableView isEqual:self.themeForegroundColorEntriesTableView]) {
        return _colorDescriptions.count;
    }

    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([tableView isEqual:self.themesTableView]) {
        MHSourceCodeEditorTheme *theme = _themes[rowIndex];
        return (theme.editable ? theme.name : [NSString stringWithFormat:@"%@ (preset)", theme.name]);
    }
    else if ([tableView isEqual:self.themeForegroundColorEntriesTableView]) {
        return (rowIndex >= 0 ? _colorDescriptions[rowIndex] : @"");
    }
    
    return @"";
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    if ([tableView isEqual:self.themesTableView]) {
        NSTextField *textField; // = [tableView makeViewWithIdentifier:@"editor theme" owner:self];
        if (textField == nil) {
            textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
            textField.cell.usesSingleLineMode = YES;
            textField.cell.lineBreakMode = NSLineBreakByTruncatingTail;
            textField.drawsBackground = YES;
            textField.backgroundColor = [NSColor clearColor];
            textField.bezeled = NO;
            textField.identifier = @"editor theme";
            textField.delegate = self;
        }
        BOOL editable = [_themes objectAtIndex:row].editable;
        textField.editable = editable;
        return textField;
    }
    
    if ([tableView isEqual:self.themeForegroundColorEntriesTableView]) {
        if ([tableColumn.identifier isEqualToString:@"description"]) {
            NSTextField *textField; // = [tableView makeViewWithIdentifier:@"color description" owner:self];

            // There is no existing cell to reuse so create a new one
            if (textField == nil) {
                textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
                textField.drawsBackground = YES;
                textField.backgroundColor = [NSColor clearColor];
                textField.bezeled = NO;
                textField.editable = NO;
                textField.identifier = @"color description";
            }
            textField.textColor = [_currentThemeWorkingCopy colorForEditableForegroundColorWithIndex:row];
            
            NSFont *font = _currentThemeWorkingCopy.font;
            if (row == _commandColorRowIndex || row == _unresolvedCommandColorRowIndex) {
                font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait];
            }
            textField.font = font;

            return textField;
        }
        if ([tableColumn.identifier isEqualToString:@"well"]) {
            NSView *colorWellContainer;// = [tableView makeViewWithIdentifier:@"color well" owner:self];

            // There is no existing cell to reuse so create a new one
            if (colorWellContainer == nil) {
                colorWellContainer = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 6.0, 6.0)];
                NSColorWell *colorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(3.0, 3.0, 0.0, 0.0)];
                [colorWellContainer addSubview:colorWell];
                colorWell.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
                colorWell.tag = row;
                colorWellContainer.identifier = @"color well";
            }
            NSColorWell *colorWell = [[colorWellContainer subviews] objectAtIndex:0]; //[colorWellContainer viewWithTag:9876];
            colorWell.color = [_currentThemeWorkingCopy colorForEditableForegroundColorWithIndex:row];
            colorWell.enabled = _currentThemeWorkingCopy.editable;
            if (![_colorWells containsObject:colorWell]) {
                // keep the _colorWells array up to date
                [_colorWells addObject:colorWell];
            }
            return colorWellContainer;
        }
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if ([tableView isEqual:self.themesTableView]) {
        if (_haveUnsavedChanges) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedString(@"Do you want to select another editor theme?", @"");
            alert.informativeText = NSLocalizedString(@"The currently selected editor theme has unsaved changes. Selecting another theme will discard them.", @"");
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
            [alert addButtonWithTitle:NSLocalizedString(@"Select", @"")];

            void (^completionHandler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
                switch (returnCode) {
                    case NSAlertFirstButtonReturn:
                        // the "Cancel" button was clicked - no action needed
                        break;
                    case NSAlertSecondButtonReturn:
                    default:
                        // the "Select" button was clicked
                        [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                        break;
                }
            };

            [alert beginSheetModalForWindow:self.window
                          completionHandler:completionHandler];
            return NO;
        }
        return YES;
    }
    if ([tableView isEqual:self.themeForegroundColorEntriesTableView]) {
        return NO;
    }
    
    return NO;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    if ([tableView isEqual:self.themesTableView]) {
        NSInteger selectedRow = tableView.selectedRow;
        self.currentEditorTheme = (selectedRow >= 0 ? _themes[selectedRow] : nil);
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    if ([tableView isEqual:self.themesTableView]) {
        MHEditorThemesTableRowView *rowView = [[MHEditorThemesTableRowView alloc] initWithFrame:NSZeroRect];
        rowView.drawsSeparator = (row+1 == _numberOfPresetThemes ? YES : NO);
        return rowView;
    }
    return nil;
}



// FIXME: some experiments for an improved drag and drop experience - couldn't make it work well so disabling for now
//- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
//{
//    [self.themesTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleGap];
//}


- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    // When the user initiates a drag action with a page, we store the row index for the page in a pasteboard item
    // This will be used at the drop action to reorder the pages
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    MHSourceCodeEditorTheme *theme = _themes[row];
    if (!(theme.editable))
        return nil;
    
    [item setString:[NSString stringWithFormat:@"%lu", row] forType:kMHPreferencesEditorThemeDraggingPasteboardType];
    return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)toRow
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    bool draggingOperationIsCopy = (info.draggingSourceOperationMask == NSDragOperationCopy);

    // FIXME: disabled copy-dragging for now, maybe enable it later (need to fix the code a bit to make it work properly)
    if (draggingOperationIsCopy)
        return NSDragOperationNone;
    
    if (dropOperation == NSTableViewDropAbove) {
        // Recover the index of the row where the page was dragged from
        NSString *pasteboardString = [info.draggingPasteboard stringForType:kMHPreferencesEditorThemeDraggingPasteboardType];
        NSInteger fromRow = [pasteboardString integerValue];
        if (!(_themes[fromRow].editable) || toRow < _numberOfPresetThemes || fromRow+1 == toRow) {
            return NSDragOperationNone; // we only allow dragging editable themes
        }

        // If the operation makes sense for the values of fromRow and toRow, return NSDragOperationMove
        if (draggingOperationIsCopy)
            return NSDragOperationCopy;
        return ((toRow == fromRow) ? NSDragOperationNone : NSDragOperationMove);
    }
    
    // We only allow dropping a page between editor theme table entries, not on top of another theme
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)toRow
    dropOperation:(NSTableViewDropOperation)dropOperation
{
    bool draggingOperationIsCopy = (info.draggingSourceOperationMask == NSDragOperationCopy);
    
    // Which page were we dragging?
    NSString *pasteboardString = [info.draggingPasteboard
                                  stringForType:kMHPreferencesEditorThemeDraggingPasteboardType];
    NSInteger fromRow = [pasteboardString integerValue];
    
    NSString *nameOfSelectedTheme = _currentThemeWorkingCopy.name;
    
    if (draggingOperationIsCopy) {
        // Copy the page
//        NSLog(@"copy from row %lu to row %lu", fromRow, toRow);
        // FIXME: this is disabled for now (see the comment in the validateDrop method above), maybe enable it later
    }
    else {
        // The page will be moved - perform the reordering operation
        if ([[MHSourceCodeEditorThemeManager defaultManager] reorderThemesByMovingThemeWithIndex:fromRow toIndex:toRow]) {
            [self reloadThemes];
            MHSourceCodeEditorTheme *selectedTheme = [[MHSourceCodeEditorThemeManager defaultManager]
                                                      themeWithName:nameOfSelectedTheme];
            NSUInteger indexOfSelectedTheme = [_themes indexOfObject:selectedTheme];
            [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexOfSelectedTheme] byExtendingSelection:NO];
        }
    }
    
    return YES;
}













- (void)tableViewDeleteRowShortcutInvoked:(NSTableView *)tableView
{
    [self deleteCurrentlySelectedTheme];
}


- (void)deleteCurrentlySelectedTheme
{
    if (_currentThemeWorkingCopy.editable) {
        if ([[MHSourceCodeEditorThemeManager defaultManager] deleteThemeWithName:_currentThemeWorkingCopy.name]) {
            NSUInteger currentThemesTableViewRowIndex = [self.themesTableView selectedRow];
            NSUInteger numberOfThemes = _themes.count;
            NSUInteger newSelectedIndex = (currentThemesTableViewRowIndex+1 == numberOfThemes ?
                                           currentThemesTableViewRowIndex-1 : currentThemesTableViewRowIndex);
            [self reloadThemes];
            [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedIndex]
                                    byExtendingSelection:NO];
        }
        else {
            NSBeep();
        }
    }
    else {
        NSBeep();
    }
}


#pragma mark - Editing actions

- (void)changeColor:(NSColorPanel *)colorPanel
{
    for (NSColorWell *colorWell in _colorWells) {
        if (colorWell.active) {
            _activeColorWell = colorWell;
            NSUInteger activeColorWellTag = colorWell.tag;
            switch (activeColorWellTag) {
                case kTextBackgroundColorWellTag:
                    [self textBackgroundColorEdited:colorWell];
                    break;
                case kMathBackgroundColorWellTag:
                    [self mathBackgroundColorEdited:colorWell];
                    break;
                case kInsertionPointColorWellTag:
                    [self insertionPointColorEdited:colorWell];
                    break;
                case kSelectionColorWellTag:
                    [self selectionColorEdited:colorWell];
                    break;
                default:
                    [self colorEdited:colorWell];
                    break;
            }
            return;
        }
    }
}

- (void)colorEdited:(NSColorWell *)colorWell
{
    if (_currentThemeWorkingCopy.editable) {
        NSUInteger editedColorIndex = colorWell.tag;
        NSColor *currentColor = [_currentThemeWorkingCopy colorForEditableForegroundColorWithIndex:editedColorIndex];
        NSColor *newColor = colorWell.color;
        if (![newColor isEqual:currentColor]) {
            [_currentThemeWorkingCopy setColorForEditableAttributeWithIndex:editedColorIndex toColor:newColor];
            NSTextField *textField = [self.themeForegroundColorEntriesTableView viewAtColumn:0 row:editedColorIndex makeIfNecessary:NO];
            textField.textColor = newColor;
            self.haveUnsavedChanges = YES;
        }
    }
}

- (IBAction)textBackgroundColorEdited:(NSColorWell *)colorWell
{
    if (_currentThemeWorkingCopy.editable) {
        NSColor *currentColor = _currentThemeWorkingCopy.backgroundColor;
        NSColor *newColor = colorWell.color;
        if (![newColor isEqual:currentColor]) {
            _currentThemeWorkingCopy.backgroundColor = newColor;
            self.themeForegroundColorEntriesTableView.backgroundColor = _currentThemeWorkingCopy.backgroundColor;
            [self updateMathBackgroundColorRows];
            self.haveUnsavedChanges = YES;
        }
    }
}

- (IBAction)mathBackgroundColorEdited:(NSColorWell *)colorWell
{
    if (_currentThemeWorkingCopy.editable) {
        NSColor *currentColor = _currentThemeWorkingCopy.mathModeBackgroundColor;
        NSColor *newColor = colorWell.color;
        if (![newColor isEqual:currentColor]) {
            _currentThemeWorkingCopy.mathModeBackgroundColor = newColor;
            [self updateMathBackgroundColorRows];
            self.haveUnsavedChanges = YES;
        }
    }
}

- (IBAction)insertionPointColorEdited:(NSColorWell *)colorWell
{
    if (_currentThemeWorkingCopy.editable) {
        NSColor *currentColor = _currentThemeWorkingCopy.insertionPointColor;
        NSColor *newColor = colorWell.color;
        if (![newColor isEqual:currentColor]) {
            _currentThemeWorkingCopy.insertionPointColor = newColor;
            self.haveUnsavedChanges = YES;
        }
    }
}

- (IBAction)selectionColorEdited:(NSColorWell *)colorWell
{
    if (_currentThemeWorkingCopy.editable) {
        NSColor *currentColor = _currentThemeWorkingCopy.selectionColor;
        NSColor *newColor = colorWell.color;
        if (![newColor isEqual:currentColor]) {
            _currentThemeWorkingCopy.selectionColor = newColor;
            self.haveUnsavedChanges = YES;
        }
    }
}

- (void)updateMathBackgroundColorRows
{
    NSTableRowView *tableRowView1 = [self.themeForegroundColorEntriesTableView rowViewAtRow:_mathModeColorRowIndex makeIfNecessary:YES];
    NSTableRowView *tableRowView2 = [self.themeForegroundColorEntriesTableView rowViewAtRow:_mathKeywordColorRowIndex makeIfNecessary:YES];
    tableRowView1.backgroundColor = _currentThemeWorkingCopy.mathModeBackgroundColor;
    tableRowView2.backgroundColor = _currentThemeWorkingCopy.mathModeBackgroundColor;
}

- (IBAction)showFontPanel:(id)sender
{
    if (_currentThemeWorkingCopy.editable) {
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        [fontManager setSelectedFont:_currentThemeWorkingCopy.font isMultiple:NO];
        [fontManager setTarget:self];
//        [fontManager setAction:@selector(changeFont:)];   // this is the default action according to the docs, no need to change
        NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
        [fontPanel makeKeyAndOrderFront:nil];
    }
}

- (void)changeFont:(NSFontManager *)sender
{
// Relevant explanation on how to handle font change actions from the font panel:
// https://developer.apple.com/library/archive/documentation/TextFonts/Conceptual/CocoaTextArchitecture/FontHandling/FontHandling.html
//
    if (_currentThemeWorkingCopy.editable) {
        _currentThemeWorkingCopy.font = [sender convertFont:_currentThemeWorkingCopy.font];
        [self updateEditorThemeInterface];
        self.haveUnsavedChanges = YES;
    }
}


#pragma mark - Creating, deleting, rearranging, and renaming themes

- (IBAction)createDeleteTheme:(NSSegmentedControl *)segmentedControl
{
    switch (segmentedControl.selectedSegment) {
        case kCreateThemeSegmentIndex: {

            [self duplicateSelectedTheme:nil];
            
            // alternative option: don't do the duplicate action immediately but suggest it via a popup menu:
//            NSMenu *menu = [[NSMenu alloc] init];
//            NSString *menuItemTitle = [NSString stringWithFormat:NSLocalizedString(@"Duplicate theme \"%@\"", @""), _currentThemeWorkingCopy.name];
//            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle
//                                                              action:@selector(duplicateSelectedTheme:)
//                                                       keyEquivalent:@""];
//            [menu addItem:menuItem];
//            [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:segmentedControl];
        }
            break;
        case kDeleteThemeSegmentIndex:
            [self deleteCurrentlySelectedTheme];
            break;
        default:
            break;
    }
}

- (void)duplicateSelectedTheme:(id)sender
{
    MHSourceCodeEditorTheme *newTheme =
    [[MHSourceCodeEditorThemeManager defaultManager]
     duplicateEditorThemeAndReturnNewThemeName:_currentThemeWorkingCopy.name];
    if (newTheme) {
        [self reloadThemes];
        [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_themes.count-1]
                                byExtendingSelection:NO];
    }
    else {
        NSBeep();
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    NSTextField *textField = notification.object;
    NSInteger rowIndex = [self.themesTableView rowForView:textField];
    
    MHSourceCodeEditorTheme *theme = _themes[rowIndex];
    NSString *oldName = theme.name;
    NSString *newName = textField.stringValue;
    if (newName.length == 0) {
        // the empty string is not allowed as a theme name
        textField.stringValue = oldName;
        return;
    }
    if (![newName isEqualToString:oldName]) {
        if ([[MHSourceCodeEditorThemeManager defaultManager] renameThemeWithName:oldName toName:newName]) {
            _currentThemeWorkingCopy.name = newName;
            [self configureDefaultEditorThemesPopUpMenu];
        }
        else {
            textField.stringValue = oldName;
            NSBeep();
        }
    }
}


#pragma mark - Saving or reverting changes

- (IBAction)revertToSavedTheme:(id)sender
{
    NSUInteger selectedRowIndex = self.themesTableView.selectedRow;
    self.currentEditorTheme = _themes[selectedRowIndex];
}

- (IBAction)applyAndSaveThemeChanges:(id)sender
{
    if ([[MHSourceCodeEditorThemeManager defaultManager] applyAndSaveTheme:_currentThemeWorkingCopy]) {
        self.haveUnsavedChanges = NO;
        NSUInteger currentThemesTableViewRowIndex = [self.themesTableView selectedRow];
        [self reloadThemes];
        [self.themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentThemesTableViewRowIndex]
                                byExtendingSelection:NO];
    }
}


#pragma mark - Changing the default theme

- (IBAction)defaultThemeSelectionPopupAction:(NSPopUpButton *)themeSelectionPopup
{
    NSString *themeName = [themeSelectionPopup titleOfSelectedItem];
    [[MHSourceCodeEditorThemeManager defaultManager] setUserDefaultThemeName:themeName];
}




@end






@implementation MHEditorThemesTableRowView : NSTableRowView
@end

@implementation MHEditorThemesTableView : NSTableViewWithDeleteShortcut
- (void)drawGridInClipRect:(NSRect)clipRect {
    // do nothing
}
@end
