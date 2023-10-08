//
//  MHSourceCodeTextView.m
//  MadHat
//
//  Created by Dan Romik on 11/4/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHSourceCodeTextView.h"
#import "MHSourceCodeTextView+Autocomplete.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeEditorThemeManager.h"
#import "MHSourceCodeLayoutManager.h"
#import "MHParser.h"
#import "MadHat.h"
#import "MHSourceCodeTextStorage.h"
#import "MHAssetLibraryController.h"
#import "MHImage.h"     //  for accepting an image drag and drop, need to know about kMHImageCommandName
#import "MHVideo.h"     //  for accepting a video drag and drop, need to know about kMHVideoCommandName
#import "MHSourceCodeAutocompleteSuggestionsView.h"
#import "AppDelegate.h"
#import "NSScroller+KnobStyleExtension.h"


#define MHSourceCodeGutterViewWidth             26.0

NSString * const kMHSourceCodeTextViewSelectionChangedNotification = @"MHSourceCodeTextViewSelectionChangedNotification";
NSString * const kMHSourceCodeTextViewSelectionExpression = @"selectionExpression";

NSString * const kMHSourceCodeTextViewScrolledNotification = @"MHSourceCodeTextViewScrolledNotification";

NSString * const kMHSourceCodeTextViewSelectionCodeRecompiledNotification = @"MHSourceCodeTextViewSelectionCodeRecompiledNotification";




@interface MHSourceCodeTextView ()
{
    NSFont *_currentFont;
    id <MHSourceCodeTextViewDelegate> _codeEditingDelegate;

    MHSourceCodeEditorTheme *_editorTheme;
    NSFont *_boldFont;
    NSFont *_italicFont;
    MHSourceCodeGutterView *_gutter;
    
    NSUInteger _programmaticallyInitiatedScrollCounter;
    
    bool _sourceCodeParsingSynchronized;    // FIXME: temporary solution to facilitate lazy parsing of code only when the view is loaded (so that a document with many pages can be opened quickly). Eventually this logic will need to be redesigned to allow referencing between pages etc
    
    NSWindow *_savedKeyWindowDuringDragAndDrop;  // FIXME: it's annoying that I need to carry an instance variable just to save such a rarely used piece of information. Is there a way to avoid this?
    
    NSUndoManager *_undoManager;
}

@end

@implementation MHSourceCodeTextView

@dynamic textStorage;       // Let the compiler know this property is provided by the superclass


#pragma mark - initializers

- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer * _Nullable)container
{
    // The idea here is to ignore the container and install our own custom container that is set up to use a MHSourceCodeTextStorage object for its text storage
    
    // This method is described in https://www.raywenderlich.com/2644-text-kit-tutorial
    
    // 1. Create the text storage
    MHSourceCodeTextStorage *myTextStorage = [[MHSourceCodeTextStorage alloc] init];
    myTextStorage.smallEditsDelegate = (id <MHSourceCodeTextStorageSmallEditsDelegate>)self;    // Note: I declared the MHSourceCodeTextStorageSmallEditsDelegate protocol in the category file MHSourceCodeTextView+UserEditingHandler.h and implemented the protocol in the associated file MHSourceCodeTextView+UserEditingHandler.m. So the current class does not know that the self variable conforms to it, and without the casting we get a compiler warning. If I try to declare that the class conforms to it in the current file, I get a compiler warning that two different files are trying to implement the protocol, which is not what I'm intending. So, casting seems like the least problematic solution to declare our intent and eliminate compiler warnings, although I'm not sure that there isn't a more correct method

    // 2. Create the layout manager
    MHSourceCodeLayoutManager *myLayoutManager = [[MHSourceCodeLayoutManager alloc] init];

    [myTextStorage addLayoutManager:myLayoutManager];

    // 3. Create the text container
    CGSize containerSize = CGSizeMake(frameRect.size.width,  CGFLOAT_MAX);
    NSTextContainer *myTextContainer = [[NSTextContainer alloc] initWithSize:containerSize];
    myTextContainer.widthTracksTextView = true;
//    myTextContainer.heightTracksTextView = false;
    [myLayoutManager addTextContainer:myTextContainer];

    // We are now ready to actually initialize
    if (self = [super initWithFrame:frameRect textContainer:myTextContainer]) {
        self.currentFont = [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName size:12.0];
        
        self.editorTheme = [[MHSourceCodeEditorThemeManager defaultManager] defaultTheme];
        self.horizontallyResizable = false;
        self.verticallyResizable = true;
        self.maxSize = containerSize;
        
        super.automaticQuoteSubstitutionEnabled = NO;    // disable smart quotes - calling the super method because in the current class the method is overridden to do nothing
        super.automaticDashSubstitutionEnabled = NO;    // disable smart dashes - calling the super method because in the current class the method is overridden to do nothing

        _gutter = [[MHSourceCodeGutterView alloc] initWithFrame:NSMakeRect(0.0, 0.0, MHSourceCodeGutterViewWidth, 0.0)];
        _gutter.delegate = self;
        
        self.delegate = self;
        self.usesFindBar = YES;
        self.incrementalSearchingEnabled = YES;
        
        _sourceCodeParsingSynchronized = false;
        
        
//        NSArray *imageUTITypes = [NSImage imageTypes];
//        NSArray *draggingTypes = [imageUTITypes arrayByAddingObjectsFromArray:@[kMHAssetLibraryImageDraggingPasteboardType]];
        [self registerForDraggedTypes:@[kMHAssetLibraryAssetDraggingPasteboardType]];
//        [self registerForDraggedTypes:draggingTypes];
//        [self registerForDraggedTypes:@[(NSString*)kUTTypeItem]]; // draggingTypes];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    NSAssert(NO, @"Error: an MHSourceCodeTextView object cannot be instantiated through initWithFrame");
//    if (self = [super initWithFrame:(NSRect)frameRect]) {
//    }
    return nil;
}

- (void)setAutomaticQuoteSubstitutionEnabled:(BOOL)automaticQuoteSubstitutionEnabled
{
    // disable smart quote substitution, even if the user tries to enable it
}

- (void)setAutomaticDashSubstitutionEnabled:(BOOL)automaticDashSubstitutionEnabled
{
    // disable smart dash substitution, even if the user tries to enable it
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.tag == kToggleAutomaticQuoteSubstitutionMenuItemTag)
        return NO;
    if (menuItem.tag == kToggleAutomaticDashSubstitutionMenuItemTag)
        return NO;
    return [super validateMenuItem:menuItem];
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    NSAssert(NO, @"Error: an MHSourceCodeTextView object cannot be instantiated through initWithCoder");
    return nil;
}

- (void)viewDidMoveToSuperview
{
    if (!self.superview) {
//        [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                        name:NSViewBoundsDidChangeNotification
//                                                      object:scrollView.contentView];
        return;
    }

    NSScrollView *scrollView = self.enclosingScrollView;
    
    if (!scrollView) {
//        NSLog(@"no enclosing scroll view");
        // No enclosing scroll view, so skip configuring the gutter and ruler views
        return;
    }
    NSRulerView *rulerView = [[NSRulerView alloc] initWithScrollView:scrollView
                                                         orientation:NSVerticalRuler];
    rulerView.clientView = self;
    rulerView.accessoryView = _gutter;
    rulerView.ruleThickness = 0.0;
    [scrollView setHasHorizontalRuler:NO];
//    [scrollView setHasVerticalRuler:YES];
    [scrollView setVerticalRulerView:rulerView];
    
    scrollView.contentView.postsBoundsChangedNotifications = NO; // we don't want a notification to be sent because of messing with the rulersVisible property - that would cause unwanted issues with scrolling
    scrollView.rulersVisible = NO;  // a bit silly and illogical to add this before setting the same property to YES, but it resolves a weird bug where in certain cases the area of the NSTextView where text appears overlaps with that of the ruler/accessory view - apparently a bug in AppKit
    
    scrollView.rulersVisible = YES;
    scrollView.contentView.postsBoundsChangedNotifications = YES;

    // moved this to the -viewWasInstalledAsScrollViewDocumentView method below to resolve a bug. Not the most elegant solution, but it works
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(clipViewBoundsChanged:)
//                                                 name:NSViewBoundsDidChangeNotification object:scrollView.contentView];
    
    
    if (!_sourceCodeParsingSynchronized) {
        [self parseCodeIfNeededAndMarkAsSynchronized];
    }
    else
        [self applyParagraphRanges];
}

- (void)parseCodeIfNeededAndMarkAsSynchronized
{
    if (!_sourceCodeParsingSynchronized) {
        _sourceCodeParsingSynchronized = true;
        [self triggerCodeEditingDelegateUpdate];
    }
}

- (void)viewWasInstalledAsScrollViewDocumentView
{
    // this is some configuration code that was originally in the -viewDidMoveToSuperview method, but this called a problem with spurious calls to clipViewBoundsChanged: from getting installed as the document view of the scroll view, which caused unwanted scrolling. So I'm calling this method from MHNotebookPage after the call to NSScrollView's setDocumentView: to avoid this problem. A clunky solution, but seems like it will do for now.
    
    // FIXME: another issue is that I had to add a call to this method from MHNotebookConfigurationPanelController's -windowDidLoad method, otherwise the configuration code editor view was not getting scrolling notifications. Again, this works even though it is clunky and more importantly it does not respect OO programming methodology - improve
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clipViewBoundsChanged:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:self.enclosingScrollView.contentView];
    
    // FIXME: there's also apparently a memory leak since in the configuration view there no matching call to remove ourselves as an observer in the notification center is received when I dismiss the notebook configuration modal window. Also -dealloc doesn't seem to be called. Investigate this and fix it at some point
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    if (!newSuperview) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:self.enclosingScrollView.contentView];
    }
}




#pragma mark - Various methods

- (NSUndoManager *)undoManager
{
    if (!_undoManager) {
        _undoManager = [[NSUndoManager alloc] init];
    }
    return _undoManager;
    
// In the current implementation, the source code editor view for each notebook page has its own undo manager.
// See the method windowWillReturnUndoManager in MHNotebook.h that makes this happen together with the code above.
// If we decide to have a single undo manager for all the pages, this can be achieved by commenting out the code above and
// the windowWillReturnUndoManager method, and uncommenting the next line:
//    return [[self window] undoManager];

// (this might result in bugs or strange behavior when doing edits on multiple pages and then using undo/redo - haven't really
// tested it)
}



- (void)scrollRangeToVisibleWithAnimation:(NSRange)range
{
    NSLayoutManager *layoutManager = self.layoutManager;
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:nil];
    NSRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    
    NSScrollView *scrollView = self.enclosingScrollView;
    NSClipView *contentView = scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;

    CGFloat minYOriginForContentView = rect.origin.y + rect.size.height - contentViewBounds.size.height + 20.0;
    CGFloat maxYOriginForContentView = rect.origin.y - 20.0;
    CGFloat actualYOriginForContentView;
    if (minYOriginForContentView < maxYOriginForContentView) {
        // The given range can fit inside the view
        if (contentViewBounds.origin.y < minYOriginForContentView)
            actualYOriginForContentView = minYOriginForContentView;
        else if (contentViewBounds.origin.y > maxYOriginForContentView)
            actualYOriginForContentView = maxYOriginForContentView;
        else {
            // the range is already visible
            return;
        }
    }
    else {
        // The range is bigger than the view can accommodate. So we need to decide which part of it to show. There are various ways in which one can do this, but one motivating guidance that seems good is that if the code range is at the beginning of the text, we want to scroll to the very top of the text window, and if the code range is at the end of the text, we want to scroll to the very bottom, so that we cover the full range of the text. With that in mind, it is easy to work out a linear interpolation scheme that interpolates between these two extremes for code ranges that are somewhere in the middle of the text
        
        NSUInteger codeLength = self.string.length;
        CGFloat a = (CGFloat)range.location / (CGFloat)codeLength;
        CGFloat b = (CGFloat)(range.location + range.length) / (CGFloat)codeLength;
        CGFloat fraction = (b-a > 0.999999 ? 0.0 : a / (1-(b-a)));   // if b-a is very close to 1 then we start getting issues with dividing by a very small number, so make an exception for those cases
        
        actualYOriginForContentView = (1-fraction) * maxYOriginForContentView + fraction * minYOriginForContentView;
        
//        // some experimental stuff, mostly for debugging:
//        NSUInteger index = (NSUInteger)((1-fraction) * (CGFloat)(range.location) + fraction * (CGFloat)(range.location+range.length));
//        NSRange rangeToSelect = [self selectionRangeForProposedRange:NSMakeRange(index, 1) granularity:NSSelectByParagraph];
//        self.selectedRange = rangeToSelect;
    }
    
    _programmaticallyInitiatedScrollCounter++;
    
    contentViewBounds.origin.y = actualYOriginForContentView;
    
    [scrollView flashScrollers];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMHDefaultCoupledScrollingAnimationDuration;
        contentView.animator.bounds = contentViewBounds;
    }
    completionHandler:^{
        if (self->_programmaticallyInitiatedScrollCounter > 0) self->_programmaticallyInitiatedScrollCounter--;
    }];
}


- (void)clipViewBoundsChanged:(NSNotification *)notification
{
    // FIXME: this NSLog was to try to diagnose a problem with the view's origin being set incorrectly when the notebook first opens. This issue only affects the first page in the document, and goes away after switching pages. I fixed the issue by duplicating the method call "self.currentPageIndex = 0" in the -awakeFromNib method of MHNotebook. It's a stupid fix, but works. I suspect the bug is one of the weird quirks of the NSScroll class and related class, but the cause remains mysterious at this point.
//    NSLog(@"aaa %lu  %f %f", self.string.length, self.frame.origin.y, self.frame.size.height);
    
    NSClipView *clipView = self.enclosingScrollView.contentView;
    _gutter.scrollOffset = clipView.bounds.origin.y;
    [_gutter setNeedsDisplay:true];

    if (_programmaticallyInitiatedScrollCounter > 0)
        return;
    
    NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:self.enclosingScrollView.documentVisibleRect
                                                       inTextContainer:self.textContainer];
    NSRange textRange = [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    
    NSRange selectedRange = self.selectedRange;
    NSUInteger expressionLookupIndex;
    if (NSLocationInRange(selectedRange.location, textRange)) {
        // If the text insertion point is visible, we choose that as the index for the expression to look up
        expressionLookupIndex = selectedRange.location;
    }
    else {
        // Otherwise, we calculate an index based on the assumption that if the visible text range is at the beginning of the page text, we'll use the expression at the very beginning, and if the visible range is at the end of the page, we'll use the expression at the very end. For ranges that are in between those two values, we interpolate linearly, so that as the range window slides down the full length of the document, we cover all mapped expressions.
        
        NSUInteger codeLength = self.string.length;
        CGFloat a = (CGFloat)textRange.location / (CGFloat)codeLength;
        CGFloat b = (CGFloat)(textRange.location + textRange.length) / (CGFloat)codeLength;
        CGFloat fraction = a / (1-(b-a));
        expressionLookupIndex = (NSUInteger)((CGFloat)codeLength * fraction);
        if (expressionLookupIndex >= codeLength)
            expressionLookupIndex = codeLength;
    }
    
    MHExpression *expression = [self.textStorage expressionMappedAtOrProximateToCodeIndex:expressionLookupIndex];
    
    NSDictionary *userInfo = (expression ? @{ kMHSourceCodeTextViewSelectionExpression : expression } : nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSourceCodeTextViewScrolledNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    NSRange selectedRange = self.selectedRange;
    
    MHExpression *mappedExpressionForSelectedRangeLocation = [self.textStorage expressionMappedAtOrProximateToCodeIndex:selectedRange.location];
    
    NSDictionary *userInfo = (mappedExpressionForSelectedRangeLocation ?
                              @{ kMHSourceCodeTextViewSelectionExpression : mappedExpressionForSelectedRangeLocation } : nil);

    NSNotification *notificationToSend = [NSNotification notificationWithName:kMHSourceCodeTextViewSelectionChangedNotification
                                                                       object:self
                                                                     userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notificationToSend];
    
    
    // Code for highlighting matching brackets
    NSString *myString = self.string;
    if (selectedRange.location > 0 && selectedRange.length == 0) {
        unichar charAtRange = [myString characterAtIndex:selectedRange.location-1];
        if (charAtRange == kMHParserCharOpenBlock || charAtRange == kMHParserCharCloseBlock) {
            unichar matchingBracketChar = (charAtRange == kMHParserCharOpenBlock ? kMHParserCharCloseBlock : kMHParserCharOpenBlock);
            NSUInteger startingLocation = selectedRange.location
                                            + (charAtRange == kMHParserCharOpenBlock ? 0 : -2);
            NSRange matchingBracketRange = [self.textStorage rangeOfBracketChar:matchingBracketChar
                                                      startScanningFromLocation:startingLocation];
            
            if (matchingBracketRange.location != NSNotFound) {
                if (((matchingBracketChar == kMHParserCharCloseBlock) &&
                     (matchingBracketRange.location > selectedRange.location))
                    || ((matchingBracketChar == kMHParserCharOpenBlock) &&
                        (selectedRange.location > matchingBracketRange.location + 2))) {
                    [self showFindIndicatorForRange:matchingBracketRange];
                }
            }
//            else {
//                NSBeep();     // uncomment if we want beeping (disabled it, among other reasons since that causes beeping each time we type an open bracket character, which is clearly not very desirable behavior
//            }
        }
    }
    
    [self dismissAutocompleteSuggestions];
}


- (NSFont *)currentFont
{
    return _currentFont;
}

- (void)setCurrentFont:(NSFont *)font
{
    _currentFont = font;
    self.font = font;

    _boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    if (!_boldFont)
        _boldFont = font;

    // FIXME: the italic font is set to a value that's independent of the provided font, so it's not very logical to put this code here. improve?
    _italicFont = [NSFont fontWithName:MHSourceCodeTextViewDefaultItalicFontName size:MHSourceCodeTextViewDefaultFontSize];
    if (!_italicFont) {
        NSLog(@"couldn't find italic font");
        _italicFont = font;
    }

    [_editorTheme recreateAttributesDictsForFont:self.currentFont italicFont:_italicFont boldFont:_boldFont];
    [_editorTheme createAttributesDictsWithFont:self.currentFont italicFont:_italicFont boldFont:_boldFont];
}


- (void)jumpToEndOfCurrentBlock
{
    NSRange selectedRange = self.selectedRange;
    MHSourceCodeTextStorage *myTextStorage = self.textStorage;
    NSRange openBracketRange = [myTextStorage rangeOfBracketChar:kMHParserCharOpenBlock startScanningFromLocation:selectedRange.location-1];
    NSRange closeBracketRange = [myTextStorage rangeOfBracketChar:kMHParserCharCloseBlock startScanningFromLocation:selectedRange.location];

    // highlight the current block open and close markers
    if ((openBracketRange.location != NSNotFound) &&
        ((openBracketRange.location > selectedRange.location) || (openBracketRange.location < selectedRange.location))) {
//        [self showFindIndicatorForRange:openBracketRange];    // this will happen automatically when we jump to after the close block character because of the code highlighting matching braces in textViewDidChangeSelection:
        if ((closeBracketRange.location != NSNotFound) &&
            ((closeBracketRange.location >= selectedRange.location) || (closeBracketRange.location+2 < selectedRange.location))) {
            [self showFindIndicatorForRange:closeBracketRange];
            [self setSelectedRange:NSMakeRange(closeBracketRange.location+1, 0)];
        }
    }
}


- (void)keyDown:(NSEvent *)event
{
    NSEvent *modifiedEvent;
    unichar keyChar = [event.characters characterAtIndex:0];
    
    NSEventModifierFlags modifierFlags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    
    // In this method we perform keystroke substitutions to make entering source code easier and more efficient
    
    // There are four scenarios:
    // 1. Substitutions where the option modifier key is used
    // 2. Substitutions where the option and shift modifier keys are used
    // 3. Substitutions where the shift modifier key is used
    // 4. Other substitutions
    
    bool moveLeft = false;
    
    bool modifiedByOptionKey = (modifierFlags == NSEventModifierFlagOption);
    bool modifiedByShiftOptionKeys = (modifierFlags == (NSEventModifierFlagShift|NSEventModifierFlagOption));
    bool modifiedByShiftKey = (modifierFlags == NSEventModifierFlagShift);

    if (modifiedByOptionKey) {  // First scenario
        
        // These are characters for which the option modifier will be removed
        static NSString *specialCharsToUnOption = @"[];\\#%";
        
        NSString *charactersIgnoringModifiers = event.charactersIgnoringModifiers;
        if ([specialCharsToUnOption rangeOfString:charactersIgnoringModifiers].location != NSNotFound) {
            
            // The user pressed one of the special characters with the option key. What we will do is remove the option key modifier from the event so the non-optioned character is what gets inserted
            modifiedEvent = [NSEvent keyEventWithType:event.type
                                             location:event.locationInWindow
                                        modifierFlags:0
                                            timestamp:event.timestamp
                                         windowNumber:event.windowNumber
                                              context:[NSGraphicsContext currentContext]
                                           characters:charactersIgnoringModifiers
                          charactersIgnoringModifiers:charactersIgnoringModifiers
                                            isARepeat:event.isARepeat
                                              keyCode:event.keyCode];
        }
        else if ([charactersIgnoringModifiers isEqualToString:@"/"]) {
            // Substitute an assignment symbol for an option-'/' keystroke
            modifiedEvent = [NSEvent keyEventWithType:event.type
                                             location:event.locationInWindow
                                        modifierFlags:0
                                            timestamp:event.timestamp
                                         windowNumber:event.windowNumber
                                              context:[NSGraphicsContext currentContext]
                                           characters:kMHParserCharAssignmentString
                          charactersIgnoringModifiers:kMHParserCharAssignmentString
                                            isARepeat:event.isARepeat
                                              keyCode:event.keyCode];
        }
    }
    else if (modifiedByShiftOptionKeys) {   // Second scenario
        
        // These are the characters for which substitutions will apply in this scenario
        static NSString *specialShiftedCharsToUnOption = @"#$%@";
        
        NSString *charactersIgnoringModifiers = event.charactersIgnoringModifiers;
        if ([specialShiftedCharsToUnOption rangeOfString:charactersIgnoringModifiers].location != NSNotFound) {
            // The user pressed one of the special characters with the shift and option keys. What we will do is remove the option key modifier from the event so the non-optioned (but shifted) character is what gets inserted
            modifiedEvent = [NSEvent keyEventWithType:event.type
                                             location:event.locationInWindow
                                        modifierFlags:NSEventModifierFlagShift
                                            timestamp:event.timestamp
                                         windowNumber:event.windowNumber
                                              context:[NSGraphicsContext currentContext]
                                           characters:charactersIgnoringModifiers
                          charactersIgnoringModifiers:charactersIgnoringModifiers
                                            isARepeat:event.isARepeat
                                              keyCode:event.keyCode];
        }
    }
    else { // Third scenario -- probably the most common and useful one
        
        NSString *modifiedChars = nil;
        switch (keyChar) {
            case '\r':
                if (self.autocompleteSuggestionsViewPresented) {
                    [self selectedSuggestion:self.autocompleteSuggestionsView.suggestions[0]];
                    return;
                }
                if (modifiedByShiftKey)
                    modifiedChars = [NSString stringWithFormat:@"%C\n", kMHParserCharCommentMarker];
                break;
            case '\\':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharStartCommand length:1];
                break;
            case '.': {
                NSRange selection = self.selectedRange;
                char *bytes = (char *)self.textStorage.codeSemanticsData.bytes;

                // check the previous character is marked as part of a command
                if (selection.location > 0
                    && (((bytes[selection.location-1] & (kMHParserSyntaxColoringBitMask
                                                      -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode)) == kMHParserSyntaxColoringCommandName)
                    || ((bytes[selection.location-1] & (kMHParserSyntaxColoringBitMask
                    -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode)) == kMHParserSyntaxColoringUnresolvedCommandName))) {
                    // if so, one more thing to check is that the command in question is not the first char of the shortcut for a numbered list item
                    NSString *myString = self.string;
                    if (([myString characterAtIndex:selection.location-1] != kMHParserCharNumberedListItemFirstChar)
                        || (selection.location == 1 ||
                            (((bytes[selection.location-2] & (kMHParserSyntaxColoringBitMask
                                                              -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode)) == kMHParserSyntaxColoringCommandName)
                            || ((bytes[selection.location-2] & (kMHParserSyntaxColoringBitMask
                                                                -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode)) == kMHParserSyntaxColoringUnresolvedCommandName)))) {
                        modifiedChars = [NSString stringWithCharacters:&kMHParserCharQuickCloseCommand length:1];
                    }
                }
            }
                break;
            case '[':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharOpenBlock length:1];
                break;
            case ']':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharCloseBlock length:1];
                break;
            case ';': {
                if (event.modifierFlags == NSEventModifierFlagOption) {
                    
                }
                else {
                    modifiedChars = [NSString stringWithCharacters:&kMHParserCharListDelimiter length:1];
                }
                break;
            }
            case '#':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharSecondaryListDelimiter length:1];
                break;
            case '$': {
                NSString *myString = self.string;
                NSRange selection = self.selectedRange;
                if (selection.location == 0 ||
                    (selection.location == 1 && [myString characterAtIndex:selection.location-1]=='\n') ||
                    (selection.location >= 2 && [myString characterAtIndex:selection.location-1]=='\n' && [myString characterAtIndex:selection.location-2]=='\n')) {
                    modifiedChars = kMHParserMathParagraphShortcutString;     // The control string for a math paragraph
                }
                else {
                    moveLeft = true;
                    modifiedChars = kMHParserMathShiftControlString;    // A math shift followed by an open/close block pair
                }
            }
                break;
            case '%':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharCommentMarker length:1];
                break;
            case '@':
                modifiedChars = [NSString stringWithCharacters:&kMHParserCharAttributesSymbol length:1];
                break;
            case '\t':
                // note: if we want to add an action for a shift-tab keystroke, this should be handled in the -insertBacktab: method rather than here
                if (self.autocompleteSuggestionsViewPresented) {
                    [self.window makeFirstResponder:self.autocompleteSuggestionsView];
                }
                else {
                    [self jumpToEndOfCurrentBlock];
//                        [self calculateAndPresentAutocompleteSuggestionsAtCurrentInsertionPoint];
                }
                return;
                break;
            case NSDownArrowFunctionKey:
                if (self.autocompleteSuggestionsViewPresented) {
                    [self.window makeFirstResponder:self.autocompleteSuggestionsView];
                    return;
                }
                break;
            case 0x1B:  // the escape key
                if (self.autocompleteSuggestionsViewPresented) {
//                    NSRange selectedRange = self.selectedRange;
//                    [self.window makeFirstResponder:self.autocompleteSuggestionsView];
                    [self dismissAutocompleteSuggestions];
//                    [self setSelectedRange:selectedRange];
                    return;
                }
                else {
                    [self calculateAndPresentAutocompleteSuggestionsAtCurrentInsertionPoint];
                    return;
                }
            default:
                break;
        }
        if (modifiedChars != nil) {
            modifiedEvent = [NSEvent keyEventWithType:event.type
                                             location:event.locationInWindow
                                        modifierFlags:modifierFlags
                                            timestamp:event.timestamp
                                         windowNumber:event.windowNumber
                                              context:[NSGraphicsContext currentContext]
                                           characters:modifiedChars
                          charactersIgnoringModifiers:modifiedChars
                                            isARepeat:event.isARepeat
                                              keyCode:event.keyCode];
        }
    }
        
    // Now that we figured out the substitution and constructed the modified event if applicable, call the super method
    [super keyDown:modifiedEvent ? modifiedEvent : event];

    // For some substitutions we move the cursor to the left (for example after starting a math block)
    if (moveLeft) {
        NSRange selection = self.selectedRange;
        selection.location -= 1;
        self.selectedRange = selection;
    }
}

- (IBAction)specialSymbolsSegmentedControlPressed:(NSSegmentedControl *)sender
{
    static const NSInteger kSpecialSymbolSegmentIndexMathModeSymbol = 3;
    static const NSInteger kSpecialSymbolSegmentIndexTextModeSymbol = 4;

    // note: the ordering of the symbols in this list must match the order of the segments in the segmented control in the file MHNotebook.xib
    static NSString * const specialSymbolStrings[] = {
      @"⌘", @"⟪", @"⟫", @"M̂⟪⟫", @"T̂⟪⟫", @"；", @"＃", @"＠", @"←", @"．", @"％"
    };

    NSInteger specialSymbolIndex = sender.selectedSegment;
    NSString *specialSymbolString = specialSymbolStrings[specialSymbolIndex];
    NSRange selectedRange = self.selectedRange;
    BOOL moveLeft = NO;
    if (specialSymbolIndex == kSpecialSymbolSegmentIndexTextModeSymbol)
        moveLeft = YES;
    if (specialSymbolIndex == kSpecialSymbolSegmentIndexMathModeSymbol) {
        NSString *myString = self.string;
        NSRange selection = self.selectedRange;
        if (selection.location == 0 ||
            (selection.location == 1 && [myString characterAtIndex:selection.location-1]=='\n') ||
            (selection.location >= 2 && [myString characterAtIndex:selection.location-1]=='\n' && [myString characterAtIndex:selection.location-2]=='\n')) {
            specialSymbolString = kMHParserMathParagraphShortcutString;     // The control string for a math paragraph
        }
        else
            moveLeft = YES;
    }
    if ([self shouldChangeTextInRange:selectedRange replacementString:specialSymbolString]) {
        [self.textStorage replaceCharactersInRange:selectedRange withString:specialSymbolString];
        [self didChangeText];
        if (moveLeft) {
            // move the cursor back by one character so that we are between the open block and close block characters and can immediately start typing text content
            selectedRange = self.selectedRange;
            if (selectedRange.location > 0) {
                selectedRange.location--;
                self.selectedRange = selectedRange;
            }
        }
    }
}

- (id<MHSourceCodeTextViewDelegate>)codeEditingDelegate
{
    return _codeEditingDelegate;
}

- (void)setCodeEditingDelegate:(id<MHSourceCodeTextViewDelegate>)codeEditingDelegate
{
    _codeEditingDelegate = codeEditingDelegate;
    if (_sourceCodeParsingSynchronized) {
        [self triggerCodeEditingDelegateUpdate];
    }
}

- (void)setString:(NSString *)string
{
    MHSourceCodeTextStorage *textStorage = self.textStorage;
    bool previousDecomposesEditsIntoSmallOperations = textStorage.decomposesEditsIntoSmallOperations;
    textStorage.decomposesEditsIntoSmallOperations = NO;
    super.string = string;
    textStorage.decomposesEditsIntoSmallOperations = previousDecomposesEditsIntoSmallOperations;
    if (_sourceCodeParsingSynchronized) {
        [self triggerCodeEditingDelegateUpdate];
    }
}

// FIXME: this method name isn't very informative - improve
- (void)triggerCodeEditingDelegateUpdate
{
    id <MHSourceCodeString> sourceCode = self.textStorage;

    [_codeEditingDelegate parseCode:sourceCode];
    [self applySyntaxColoringToRange:NSMakeRange(NSNotFound, 0)];
    [self applyParagraphRanges];
}



- (void)applySyntaxColoringToRange:(NSRange)range
{
    [_editorTheme applySyntaxColoringToTextStorage:self.textStorage range:range];
}

- (void)applyParagraphRanges
{
    NSLayoutManager *layoutManager = self.layoutManager;
    NSUInteger paragraphIndex = 1;

    NSMutableArray <NSValue *> *codeParagraphRanges = self.textStorage.codeParagraphRanges;
    NSMutableArray <NSValue *> *paragraphRects = [[NSMutableArray alloc] initWithCapacity:codeParagraphRanges.count];

    // Uncomment the next line for debugging for some info on paragraph ranges
//#define MHSourceCodeTextView_DEBUGGING_PARAGRAPHS
    
#ifdef MHSourceCodeTextView_DEBUGGING_PARAGRAPHS
    NSString *myString = self.string;
    NSUInteger cc=0;
#endif
    
    for (NSValue *rangeValue in codeParagraphRanges) {
        NSRange range = [rangeValue rangeValue];

#ifdef MHSourceCodeTextView_DEBUGGING_PARAGRAPHS
        NSString *paragraphString = [[myString substringWithRange:range] stringByReplacingOccurrencesOfString:@"\n" withString:@"/"];
        NSLog(@"paragraph %lu: range=%lu %lu, string='%@'", cc, range.location, range.length, paragraphString);
        cc++;
#endif

// see https://stackoverflow.com/questions/5160094/nspoint-nsrect-from-character-in-nstextview for a relevant discussion
        
        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:nil];
        NSRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
        NSValue *rectValue = [NSValue valueWithRect:glyphRect];
        [paragraphRects addObject:rectValue];
        paragraphIndex++;
    }
    
#ifdef MHSourceCodeTextView_DEBUGGING_PARAGRAPHS
    NSLog(@" ");
#endif
    
    _gutter.paragraphRects = paragraphRects;
}




#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);
    
    if (draggingAssetIdentifier) {
//        NSLog(@"dragging types = %@", draggingPasteboard.types);
        _savedKeyWindowDuringDragAndDrop = [[NSApplication sharedApplication] keyWindow];
        [self.window makeKeyAndOrderFront:nil];
        return NSDragOperationCopy;
    }
    
    
    return [super draggingEntered:sender];
}

// it's not clear why this is needed since I am returning NO from wantsPeriodicDraggingUpdates, but if I don't include it, prepareForDragOperation and performDragOperation don't get called
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);
    
    if (draggingAssetIdentifier) {
        NSPoint draggingPointInWindowCoordinates = [sender draggingLocation];
        NSPoint draggingPointInViewCoordinates = [self convertPoint:draggingPointInWindowCoordinates
                                                           fromView:nil];
        NSUInteger characterIndexForDraggingPoint = [self characterIndexForInsertionAtPoint:draggingPointInViewCoordinates];
        self.selectedRange = NSMakeRange(characterIndexForDraggingPoint, 0);
        return NSDragOperationCopy;
    }

    return [super draggingUpdated:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);
    if (draggingAssetIdentifier) {
        // clean up
        if (_savedKeyWindowDuringDragAndDrop) {
            [_savedKeyWindowDuringDragAndDrop makeKeyAndOrderFront:nil];
            _savedKeyWindowDuringDragAndDrop = nil;
        }
        return;
    }
    [super draggingExited:sender];
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return NO;  // FIXME: maybe makes more sense to call the super method?
}

// Not necessary for now
- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);
    
    if (draggingAssetIdentifier) {
        // clean up
        if (_savedKeyWindowDuringDragAndDrop) {
            [_savedKeyWindowDuringDragAndDrop makeKeyAndOrderFront:nil];
            _savedKeyWindowDuringDragAndDrop = nil;
        }
        return;
    }

    // the next command seems like a logical necessity to avoid problems and ensure we don't mess up other types of drag and drop operations implemented by NSTextView, but amazingly, this causes an "unrecognized selector" crash despite the respondsToSelector validation test. So, commenting this out...
//    if ([super respondsToSelector:@selector(draggingEnded:)])
//        [super draggingEnded:sender];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);

    return (draggingAssetIdentifier ? YES : [super prepareForDragOperation:sender]);
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *draggingPasteboard = sender.draggingPasteboard;
    NSDictionary *assetIdentifierDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    bool draggingAssetIdentifier = (assetIdentifierDict != nil);

    if (draggingAssetIdentifier) {
        NSString *assetFilename = assetIdentifierDict[kMHAssetLibraryAssetDraggingPasteboardTypeFilenameKey];
        MHAssetType assetType = (MHAssetType)[(NSNumber *)(assetIdentifierDict[kMHAssetLibraryAssetDraggingPasteboardTypeAssetTypeKey]) integerValue];
        NSString *assetCommandString = [NSString stringWithFormat:@"%C%@%C%@%C1%C", kMHParserCharStartCommand,
                                        (assetType == MHAssetImage ? kMHImageCommandName : kMHVideoCommandName),
                                        kMHParserCharOpenBlock, assetFilename, kMHParserCharListDelimiter, kMHParserCharCloseBlock];
        
        NSRange selectedRange = self.selectedRange;
        if ([self shouldChangeTextInRange:selectedRange replacementString:assetCommandString]) {
            [self.textStorage replaceCharactersInRange:selectedRange withString:assetCommandString];
            [self didChangeText];
        }
        
        return YES;
    }

    return [super performDragOperation:sender];
}




#pragma mark - Code actions

- (IBAction)commentUncommentSelection:(NSMenuItem *)sender
{
    NSRange selectedRange = self.selectedRange;
    NSString *myString = self.string;
    NSUInteger myStringLength = myString.length;
    NSString *newlineString = @"\n";
    NSString *commentSymbolString = [NSString stringWithFormat:@"%C", kMHParserCharCommentMarker];

    bool selectedRangeEndsWithNewline = (selectedRange.length > 0)
                                        && [myString characterAtIndex:selectedRange.location + selectedRange.length - 1] == '\n';
    
    // First, let's find the range of the code string that will be affected by the commenting/uncommenting operation
    NSInteger beginningOfSectionToCommentIndex;
    NSRange backwardsSearchRange = [myString rangeOfString:newlineString
                                                   options:NSBackwardsSearch
                                                     range:NSMakeRange(0, selectedRange.location)];
    beginningOfSectionToCommentIndex = (backwardsSearchRange.location == NSNotFound ? 0 : backwardsSearchRange.location+1);

    NSInteger endOfSectionToCommentIndex;
    
    if (selectedRangeEndsWithNewline) {
        endOfSectionToCommentIndex = selectedRange.location + selectedRange.length;
    }
    else {
        NSRange rangeToSearch;
        rangeToSearch.location = selectedRange.location+selectedRange.length;
        rangeToSearch.length = myStringLength - rangeToSearch.location;
        NSRange forwardSearchRange = [myString rangeOfString:newlineString
                                                     options:0
                                                       range:rangeToSearch];
        endOfSectionToCommentIndex = (forwardSearchRange.location == NSNotFound ? myStringLength : forwardSearchRange.location);
        if ((endOfSectionToCommentIndex > beginningOfSectionToCommentIndex)
            && (endOfSectionToCommentIndex < myStringLength-1)
            && [myString characterAtIndex:endOfSectionToCommentIndex-1] == '\n'
            && [myString characterAtIndex:endOfSectionToCommentIndex] != '\n') {
            endOfSectionToCommentIndex--;
        }
    }
    
    NSUInteger sectionToCommentLength = endOfSectionToCommentIndex-beginningOfSectionToCommentIndex;
    NSString *sectionToComment = [myString substringWithRange:NSMakeRange(beginningOfSectionToCommentIndex, sectionToCommentLength)];
    
    // Now, let's determine if the operation to do is commenting or uncommenting
    // This is decided by whether there is a line that does not start with a comment symbol
    bool commentingOperation;
    
    NSUInteger beginningOfLineIndex = 0;
    if (sectionToCommentLength == 0) {
        commentingOperation = true;
    }
    else {
        commentingOperation = false;
        while (beginningOfLineIndex < sectionToCommentLength) {
            if ([sectionToComment characterAtIndex:beginningOfLineIndex] != kMHParserCharCommentMarker) {
                commentingOperation = true;
                break;
            }
            NSRange searchRange = [sectionToComment rangeOfString:newlineString options:0
                                                            range:NSMakeRange(beginningOfLineIndex+1, sectionToCommentLength-beginningOfLineIndex-1)];
            
            beginningOfLineIndex = (searchRange.location != NSNotFound ? searchRange.location+1 : sectionToCommentLength);
        }
    }
    
//    NSLog(@"%lu %lu '%@'", beginningOfSectionToCommentIndex, endOfSectionToCommentIndex, [sectionToComment stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]);
    
    BOOL textChanged = NO;
        
    // Now perform the appropriate operation
    if (commentingOperation) {
        // A commenting operation: add a comment symbol at the beginning of every line in the operation range
        NSUInteger beginningOfLineToCommentIndex = 0;
        NSRange commentInsertionRange;
        NSUInteger numberOfInsertions = 0;
        if (sectionToCommentLength == 0) {
            NSRange range = NSMakeRange(beginningOfSectionToCommentIndex, 0);
            if ([self shouldChangeTextInRange:range replacementString:commentSymbolString]) {
                [self.textStorage replaceCharactersInRange:range withString:commentSymbolString];
                textChanged = YES;
            }
        }
        else {
            while (beginningOfLineToCommentIndex < sectionToCommentLength) {
                commentInsertionRange = NSMakeRange(beginningOfSectionToCommentIndex + numberOfInsertions + beginningOfLineToCommentIndex, 0);
                if ([self shouldChangeTextInRange:commentInsertionRange replacementString:commentSymbolString]) {
                    [self.textStorage replaceCharactersInRange:commentInsertionRange withString:commentSymbolString];
                    textChanged = YES;
                }
                numberOfInsertions++;
                NSRange searchRange = [sectionToComment rangeOfString:newlineString
                                                              options:0
                                                                range:NSMakeRange(beginningOfLineToCommentIndex,
                                                                                  sectionToCommentLength-beginningOfLineToCommentIndex-1)];
                beginningOfLineToCommentIndex = (searchRange.location != NSNotFound ? searchRange.location + 1 : sectionToCommentLength);
            }
            
            if (textChanged) {
                // Modify the selection so the same text that was selected before is now selected
                self.selectedRange = NSMakeRange(selectedRange.location+1, selectedRange.length-1+numberOfInsertions);
            }
        }
        
        if (textChanged) {
            [self.undoManager setActionName:NSLocalizedString(@"Comment", @"")];
            [self didChangeText];
        }
    }
    else {
        // An uncommenting operation: delete the comment symbol at the beginning of every line in the operation range
        NSUInteger beginningOfLineToUncommentIndex = 0;
        NSRange commentDeletionRange;
        NSUInteger numberOfDeletions = 0;
        while (beginningOfLineToUncommentIndex < sectionToCommentLength) {
            commentDeletionRange = NSMakeRange(beginningOfSectionToCommentIndex - numberOfDeletions + beginningOfLineToUncommentIndex, 1);
            if ([self shouldChangeTextInRange:commentDeletionRange replacementString:@""]) {
                [self.textStorage replaceCharactersInRange:commentDeletionRange withString:@""];
                textChanged = YES;
            }
            numberOfDeletions++;

            NSRange searchRange = [sectionToComment rangeOfString:newlineString
                                                          options:0
                                                            range:NSMakeRange(beginningOfLineToUncommentIndex,
                                                                sectionToCommentLength-beginningOfLineToUncommentIndex-1)];

            beginningOfLineToUncommentIndex = (searchRange.location != NSNotFound ? searchRange.location+1 : sectionToCommentLength);
        }
                
        if (textChanged) {
            // Modify the selection so the same text that was selected before is now selected
            NSRange newRange;
            if (selectedRange.location == beginningOfSectionToCommentIndex)
                newRange = NSMakeRange(selectedRange.location, selectedRange.length-numberOfDeletions);
            else
                newRange = NSMakeRange(selectedRange.location-1, selectedRange.length+1-numberOfDeletions);
            self.selectedRange = newRange;
            [self.undoManager setActionName:NSLocalizedString(@"Uncomment", @"")];
            [self didChangeText];
        }
    }

}



- (void)paragraphClicked:(NSUInteger)paragraphIndex
{
    NSMutableArray <NSValue *> *codeParagraphRanges = self.textStorage.codeParagraphRanges;
    NSRange clickedParagraphRange = [codeParagraphRanges[paragraphIndex] rangeValue];
    self.selectedRange = clickedParagraphRange;
}



#pragma mark - Editor themes


- (MHSourceCodeEditorTheme *)editorTheme
{
    return _editorTheme;
}

- (void)setEditorTheme:(MHSourceCodeEditorTheme *)editorTheme
{
    _editorTheme = editorTheme;
    NSColor *backgroundColor = _editorTheme.backgroundColor;
    self.backgroundColor = backgroundColor;
    NSColor *selectionColor = _editorTheme.selectionColor;
    ((MHSourceCodeLayoutManager *)(self.layoutManager)).textSelectionColor = selectionColor;
    self.selectedTextAttributes = @{ NSBackgroundColorAttributeName : selectionColor };
    _gutter.backgroundColor = backgroundColor;
    self.enclosingScrollView.scrollerKnobStyle = [NSScroller knobStyleAdaptedToBackgroundColor:backgroundColor];
    self.insertionPointColor = _editorTheme.insertionPointColor;
    _gutter.markerColor = _editorTheme.textColor;

    self.currentFont = _editorTheme.font;

    [_editorTheme createAttributesDictsWithFont:self.currentFont italicFont:_italicFont boldFont:_boldFont];
    [self applySyntaxColoringToRange:NSMakeRange(NSNotFound, 0)];
}


@end

