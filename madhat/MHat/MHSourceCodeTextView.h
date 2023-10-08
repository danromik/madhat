//
//  MHSourceCodeTextView.h
//  MadHat
//
//  Created by Dan Romik on 11/4/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MadHat.h"
#import "MHSourceCodeTextStorage.h"
#import "MHSourceCodeGutterView.h"


NS_ASSUME_NONNULL_BEGIN


// See https://www.jetbrains.com/lp/mono/ for details on the JetBrains Mono typeface
#define MHSourceCodeTextViewDefaultFontSize         14
#define MHSourceCodeTextViewDefaultFontName         @"Monaco"
//#define MHSourceCodeTextViewDefaultFontName         @"SF Mono Regular"  // not installed in MacOS by default
//#define MHSourceCodeTextViewDefaultFontName         @"JetBrains Mono Regular" // not installed in MacOS by default
//#define MHSourceCodeTextViewDefaultFontName         @"JetBrains Mono NL Regular" // not installed in MacOS by default
#define MHSourceCodeTextViewDefaultItalicFontName   @"Georgia Italic"


extern NSString * const kMHSourceCodeTextViewSelectionChangedNotification;
extern NSString * const kMHSourceCodeTextViewSelectionExpression;
extern NSString * const kMHSourceCodeTextViewScrolledNotification;

extern NSString * const kMHSourceCodeTextViewSelectionCodeRecompiledNotification;

typedef enum {
    MHSourceCodeEditCharsAdditionInExistingParagraph,
    MHSourceCodeEditCharsAdditionInNewParagraph,
    MHSourceCodeEditCharsAdditionMergingParagraphs,
    MHSourceCodeEditNewlineAdditionSplittingParagraphs,
    MHSourceCodeEditNewlineAdditionShiftingParagraphs,
    MHSourceCodeEditDeleteParagraph,
    MHSourceCodeEditDeleteCharactersInParagraph,
    MHSourceCodeEditDeleteLeadingToParagraphsMerging,
    MHSourceCodeEditDeleteShiftingParagraphs,
    MHSourceCodeEditDeleteCharactersSplittingParagraphs
} MHSourceCodeEditType;


@protocol MHSourceCodeTextViewDelegate;
@class MHSourceCodeAutocompleteSuggestionsView, MHSourceCodeEditorTheme;

@interface MHSourceCodeTextView : NSTextView <NSTextViewDelegate, MHSourceCodeGutterViewDelegate>
{
@private
    // These variables are used in the UserEditingHandler category
    NSRange _codeRangeBeingEditedInsideSmallEditsBlock;
    BOOL _userEditIsSingleCharInsertion;
    
    BOOL _notebookConfigurationCommandsEnabled;     // defaults to NO

    // Used by the Autocomplete category
    MHSourceCodeAutocompleteSuggestionsView *_autocompleteSuggestionsView;
    NSRange _rangeOfAutocompletionSubstring;
}

// Designated initializer:
// The container parameter is ignored - the class creates its own standard text container and associates with it a text storage object of class MHSourceCodeTextStorage
- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer * _Nullable)container;

// Do not use this!!! This class cannot be instantiated from a nib file due to limitations in the design of NSTextView and how it relates to NSTextStorage (a nib-instantiated NSTextView object cannot adopt a custom NSTextStorage subclass as its text storage object)
- (instancetype)initWithCoder:(NSCoder *)coder;

@property (readonly) MHSourceCodeTextStorage *textStorage;

@property id <MHSourceCodeTextViewDelegate> codeEditingDelegate;
@property NSDictionary *codeToCompiledExpressionRangesAndExpressions;

@property BOOL notebookConfigurationCommandsEnabled;   // defaults to NO

@property NSFont *currentFont;  // the NSTextView font property (inherited from NSText) behaves strangely, setting the font doesn't always work (the docs say the font property returns "the font of all of the receiver's text", which isn't too helpful, and the setFont method isn't even documented). So, I added a "currentFont" property that's stored in a separate instance variable

@property MHSourceCodeEditorTheme *editorTheme;

// FIXME: these two methods are used in the main class file and by the MHSourceCodeTextView+UserEditingHandler category. Not sure if they should be exposed in the public header, or if doing things this way is good OO coding practice
- (void)applyParagraphRanges;
- (void)applySyntaxColoringToRange:(NSRange)range;      // if range.location of the passed range is NSNotFound, coloring is applied to the entire text
- (void)triggerCodeEditingDelegateUpdate;

- (void)scrollRangeToVisibleWithAnimation:(NSRange)range;

- (void)viewWasInstalledAsScrollViewDocumentView;

- (void)parseCodeIfNeededAndMarkAsSynchronized; // related to the _sourceCodeParsingSynchronized private instance var (see the comment where that's defined. If the page is in an unsynchronized state where the source code is set but not yet parsed, call this method to ensure synchronization (for example, this is used when exporting the notebook to PDF)

@end


@protocol MHSourceCodeString;

@protocol MHSourceCodeTextViewDelegate

- (void)codeDidChangeWithNewCode:(id <MHSourceCodeString>)code
                        editType:(MHSourceCodeEditType)type
      firstAffectedParagraphRange:(NSRange)firstParagraphRange
      firstAffectedParagraphIndex:(NSUInteger)paragraphIndex
     secondAffectedParagraphRange:(NSRange)secondParagraphRange
               newParagraphRange:(NSRange)newParagraphRange;

- (void)parseCode:(id <MHSourceCodeString>)code;

@end



NS_ASSUME_NONNULL_END
