//
//  MHMathFontEditorController.m
//  MadHat
//
//  Created by Dan Romik on 7/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHMathFontEditorController.h"
#import "NSTableViewWitkKeyPressDelegation.h"
#import "MHMathFontsLibraryEditingManager.h"
#import "MHMathFontSystem.h"
#import "MHMathFontManager.h"


//NSString * const kMHMathFontParametersChangedNotification = @"MHMathFontParametersChangedNotification";

@interface MHMathFontEditorController () {
    NSArray *_shortColumnTitles;
    NSArray *_fullColumnTitles;
    NSInteger _currentlyEditingRow;
    NSInteger _currentlyEditingColumn;
    
    bool _hasUnsavedChanges;
    
    MHMathFontSystem * _Nullable _mathFontSystem;
    MHMathFontSystem * _Nullable _mathFontSystemWorkingCopy;    // Changes are made to the working copy until a save operation, to allow a "revert" option
}

// IB Outlets
// FIXME: which of these outlets need to be weak properties to avoid memory leaks?
@property (weak) IBOutlet MHMathFontsLibraryEditingManager *libraryEditingManager;

@property IBOutlet NSTextField *fontFamilyNameTextField;

@property IBOutlet NSTextField *currentlyEditingKernLabel;
@property IBOutlet NSSlider *kernSlider;

@property IBOutlet NSTextField *leftClassLabel;
@property IBOutlet NSTextField *rightClassLabel;

@property IBOutlet NSTextField *mathAxisLabel;
@property IBOutlet NSSlider *mathAxisSlider;

@property IBOutlet NSTextField *fractionThicknessLabel;
@property IBOutlet NSSlider *fractionThicknessSlider;

@property IBOutlet NSTableView *kerningTable;

@property IBOutlet NSButton *saveChangesButton;
@property IBOutlet NSButton *revertButton;


// IB actions
- (IBAction)tableCellClicked:(id)sender;
- (IBAction)tableCellDoubleClicked:(id)sender;

- (IBAction)kernSliderAction:(NSSlider *)sender;
- (IBAction)mathAxisSliderAction:(NSSlider *)sender;
- (IBAction)fractionThicknessSliderAction:(NSSlider *)sender;

- (IBAction)revertToLastSavedVersion:(id)sender;
- (IBAction)saveChanges:(id)sender;


@end


@implementation MHMathFontEditorController


#pragma mark - Initialization

- (void)awakeFromNib
{
    _shortColumnTitles = @[
        @"L \\ R",
        @"abc",
        @"789",
        @"+- (un)",
        @"!",
        @"+-×/",
        @"=<>",
        @"αβγ",
        @"xyz",
        @"([",
        @"])",
        @",.:;",
        @"(x/y)",
    ];

    _fullColumnTitles = @[
        @"left \\ right",
        @"text",
        @"number",
        @"unary prefix operator",
        @"unary postfix operator",
        @"binary operator",
        @"binary relation",
        @"math roman",
        @"math italic",
        @"left bracket",
        @"right bracket",
        @"punctuation",
        @"compound expression",
    ];
                
    self.mathFontSystem = nil;
}



#pragma mark - Setting and retrieving the math font system property

- (MHMathFontSystem * _Nullable)mathFontSystem
{
    return _mathFontSystem;
}

- (void)setMathFontSystem:(MHMathFontSystem *)mathFontSystem
{
    _mathFontSystem = mathFontSystem;
    if (mathFontSystem) {
        _mathFontSystemWorkingCopy = [mathFontSystem copy];
        [[MHMathFontManager defaultManager] setCurrentlyEditingFont:_mathFontSystemWorkingCopy];
        self.fontFamilyNameTextField.stringValue = mathFontSystem.fontFamilyName;
        self.fontFamilyNameTextField.enabled = true;
        self.fontFamilyNameTextField.editable = false;
        self.kerningTable.enabled = true;
        
        short int mathAxisHeight = mathFontSystem.mathAxisHeight;
        self.mathAxisSlider.intValue = mathAxisHeight;
        self.mathAxisLabel.stringValue = [NSString stringWithFormat:@"%d", mathAxisHeight];
        
        short int fractionLineThickness = mathFontSystem.fractionLineThickness;
        self.fractionThicknessSlider.intValue = fractionLineThickness;
        self.fractionThicknessLabel.stringValue = [NSString stringWithFormat:@"%d", fractionLineThickness];

        self.kernSlider.enabled = true;
        self.mathAxisSlider.enabled = true;
        self.fractionThicknessSlider.enabled = true;
        
        if (_currentlyEditingRow == -1) {
            _currentlyEditingRow = 1;
            _currentlyEditingColumn = 1;
        }
        [self selectedCellChanged];
    }
    else {
        // No math font selected – disable various interface elements
        _mathFontSystemWorkingCopy = nil;
        [[MHMathFontManager defaultManager] setCurrentlyEditingFont:nil];
        self.fontFamilyNameTextField.stringValue = NSLocalizedString(@"No font", @"");
        self.fontFamilyNameTextField.enabled = false;
        self.kerningTable.enabled = false;
        self.kernSlider.intValue = 0;
        self.mathAxisSlider.intValue = 0;
        self.fractionThicknessSlider.intValue = 0;
        self.currentlyEditingKernLabel.stringValue = @"0";
        self.mathAxisLabel.stringValue = @"0";
        self.fractionThicknessLabel.stringValue = @"0";

        self.kernSlider.enabled = false;
        self.mathAxisSlider.enabled = false;
        self.fractionThicknessSlider.enabled = false;
        
        _currentlyEditingRow = -1;
    }
    self.hasUnsavedChanges = false;
    [self.kerningTable reloadData];
}

- (bool)hasUnsavedChanges
{
    return _hasUnsavedChanges;
}

- (void)setHasUnsavedChanges:(bool)newValue
{
    _hasUnsavedChanges = newValue;
    self.saveChangesButton.enabled = newValue;
    self.revertButton.enabled = newValue;
    
    if (newValue) {
        [[MHMathFontManager defaultManager] currentlyEditingFontUpdated];   // FIXME: this should be somewhere else
    }
}


#pragma mark - User actions


- (IBAction)tableCellClicked:(id)sender
{
    NSInteger row = ((NSTableView *)sender).clickedRow;
    NSInteger column = ((NSTableView *)sender).clickedColumn;
    if (row > 0 && column > 0) {
        _currentlyEditingRow = row;
        _currentlyEditingColumn = column;
        [self selectedCellChanged];
    }
}

- (IBAction)tableCellDoubleClicked:(id)sender
{
    NSInteger row = ((NSTableView *)sender).clickedRow;
    NSInteger column = ((NSTableView *)sender).clickedColumn;
    [self.kerningTable editColumn:column row:row withEvent:nil select:NO];
}

- (void)selectedCellChanged
{
    if (!_mathFontSystem)
        return;
    short int *kerningMatrix = _mathFontSystemWorkingCopy.mathKerningMatrix;
    short int kernValue = kerningMatrix[MHTypographyNumberOfClasses*(_currentlyEditingRow-1)+_currentlyEditingColumn-1];
    self.currentlyEditingKernLabel.stringValue = [NSString stringWithFormat:@"%d", kernValue];
    self.kernSlider.intValue = kernValue;
    self.leftClassLabel.stringValue = (_currentlyEditingRow != 0 ? _fullColumnTitles[_currentlyEditingRow] : @"*");
    self.rightClassLabel.stringValue = (_currentlyEditingColumn != 0 ? _fullColumnTitles[_currentlyEditingColumn] : @"*");
    
    [self.kerningTable reloadData];
}

- (BOOL)tableView:(NSTableViewWitkKeyPressDelegation *)tableView keyDown:(NSEvent *)event
{
    // FIXME: this is a bit of a hack, are these codes documented anywhere?
    const unsigned short keyLeftCode = 123;
    const unsigned short keyRightCode = 124;
    const unsigned short keyDownCode = 125;
    const unsigned short keyUpCode = 126;
    const unsigned short returnCode = 36;
    const unsigned short enterCode = 76;

    unsigned short eventKeyCode = event.keyCode;

    switch (eventKeyCode) {
        case keyLeftCode:
            if (_currentlyEditingColumn >= 2) {
                _currentlyEditingColumn--;
                [self selectedCellChanged];
            }
            break;
        case keyRightCode:
            if (_currentlyEditingColumn < MHTypographyNumberOfClasses) {
                _currentlyEditingColumn++;
                [self selectedCellChanged];
            }
            break;
        case keyDownCode:
            if (_currentlyEditingRow < MHTypographyNumberOfClasses) {
                _currentlyEditingRow++;
                [self selectedCellChanged];
            }
            break;
        case keyUpCode:
            if (_currentlyEditingRow >= 2) {
                _currentlyEditingRow--;
                [self selectedCellChanged];
            }
            break;
        case returnCode:
        case enterCode:
            if (_currentlyEditingRow >=1 && _currentlyEditingRow <= MHTypographyNumberOfClasses
                && _currentlyEditingColumn >=1 && _currentlyEditingColumn <= MHTypographyNumberOfClasses) {
                [tableView editColumn:_currentlyEditingColumn row:_currentlyEditingRow withEvent:nil select:NO];
            }
        default:
            return NO;
    }
    return YES;
}

- (IBAction)kernSliderAction:(NSSlider *)sender
{
    short int newKernValue = (short int)(sender.intValue);
    self.currentlyEditingKernLabel.stringValue = [NSString stringWithFormat:@"%d", newKernValue];
    if (_currentlyEditingRow >= 1 && _currentlyEditingColumn >= 1) {
        short int *kerningMatrix = _mathFontSystemWorkingCopy.mathKerningMatrix;
        kerningMatrix[MHTypographyNumberOfClasses*(_currentlyEditingRow-1)+_currentlyEditingColumn-1] = newKernValue;
        [self.kerningTable reloadData];
        
        self.hasUnsavedChanges = true;
//        NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:self.mathFontSystem];
//        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (IBAction)mathAxisSliderAction:(NSSlider *)sender
{
    short int newMathAxisValue = (short int)(sender.intValue);
    _mathFontSystemWorkingCopy.mathAxisHeight = newMathAxisValue;
    self.mathAxisLabel.stringValue = [NSString stringWithFormat:@"%d", newMathAxisValue];
    
    self.hasUnsavedChanges = true;
//    NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:self.mathFontSystem];
//    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction)fractionThicknessSliderAction:(NSSlider *)sender
{
    short int newFractionThicknessValue = (short int)(sender.intValue);
    _mathFontSystemWorkingCopy.fractionLineThickness = newFractionThicknessValue;
    self.fractionThicknessLabel.stringValue = [NSString stringWithFormat:@"%d", newFractionThicknessValue];
    
    self.hasUnsavedChanges = true;
//    NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:self.mathFontSystem];
//    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


- (IBAction)revertToLastSavedVersion:(id)sender
{
    self.mathFontSystem = _mathFontSystem;  // this will reset the working copy and the hasUnsavedChanges boolean
//    NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:self.mathFontSystem];
//    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction)saveChanges:(id)sender
{
    self.mathFontSystem = _mathFontSystemWorkingCopy;
    [self.libraryEditingManager saveCurrentlyEditingFont];  // FIXME: not very good OO practice, but it works for now
}

//- (IBAction)saveToFile:(id)sender
//{
//    // FIXME: very temporary code for debugging/development purposes
//
//    NSMutableString *dataToSave = [[NSMutableString alloc] initWithCapacity:0];
//    [dataToSave appendFormat:@"\nshort int MHHorizontalLayoutContainerMathKerningMatrix[%d][%d] = { \n", MHTypographyNumberOfClasses, MHTypographyNumberOfClasses];
//    int row, column;
//    for (row = 0; row < MHTypographyNumberOfClasses; row++) {
//        [dataToSave appendString:@"    { "];
//        for (column = 0; column < MHTypographyNumberOfClasses; column++) {
//            [dataToSave appendFormat:@"%d%@", MHMathTypesettingDefaultKerningMatrix[row][column], (column == MHTypographyNumberOfClasses-1 ? @" }" : @", ")];
//        }
//        [dataToSave appendFormat:@"%@\n", (row == MHTypographyNumberOfClasses-1 ? @"" : @",")];
//    }
//    [dataToSave appendString:@"};\n"];
//    
//    NSError *myError;
//    bool success = [dataToSave writeToFile:@"/Users/danromik/Desktop/kern.txt" atomically:false encoding:NSUTF8StringEncoding error:&myError];
//    NSLog(@"writing to file, success=%d, error=%@", success, myError);
//}




#pragma mark - NSTableView data source and delegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return MHTypographyNumberOfClasses+1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    int columnIndex = [aTableColumn.identifier intValue];

    if (columnIndex == 0)
        return _shortColumnTitles[rowIndex];

    if (rowIndex == 0) {
        return _shortColumnTitles[columnIndex];
    }
    
    if (_mathFontSystemWorkingCopy) {
        short int *kerningMatrix = _mathFontSystemWorkingCopy.mathKerningMatrix;
        return [NSString stringWithFormat:@"%d", kerningMatrix[MHTypographyNumberOfClasses*(rowIndex-1)+columnIndex-1]];
    }
    return @"--";
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    int columnIndex = [tableColumn.identifier intValue];
    if (row > 0 && columnIndex > 0) {
        int newKernValue = [(NSString *)object intValue];
        if (newKernValue < 0 || newKernValue > 1000) {
            NSBeep();
            return;
        }
        
        short int *kerningMatrix = _mathFontSystemWorkingCopy.mathKerningMatrix;
        kerningMatrix[MHTypographyNumberOfClasses*(row-1)+columnIndex-1] = newKernValue;

//        MHMathTypesettingDefaultKerningMatrix[row-1][columnIndex-1] = [(NSString *)object intValue];
        [self selectedCellChanged];
        self.hasUnsavedChanges = true;
//        NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:self.mathFontSystem];
//        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}
                    
- (void)tableView:(NSTableView *)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    int column = [tableColumn.identifier intValue];
    if (column == 0 || row == 0) {
        ((NSTextFieldCell *)cell).drawsBackground = true;
        ((NSTextFieldCell *)cell).backgroundColor = [NSColor colorWithWhite:0.9 alpha:1];
    }
    else if (column == _currentlyEditingColumn && row == _currentlyEditingRow) {
        ((NSTextFieldCell *)cell).drawsBackground = true;
        ((NSTextFieldCell *)cell).backgroundColor = [NSColor colorWithRed:1 green:0.6 blue:0.1 alpha:1];
    }
    else {
        ((NSTextFieldCell *)cell).backgroundColor = [NSColor clearColor];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return NO;
}



@end
