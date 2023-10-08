//
//  MHSourceCodeEditorTheme.h
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

extern NSString * _Nonnull const kEditorThemePlistKeyName;

NS_ASSUME_NONNULL_BEGIN

@class MHSourceCodeTextStorage;
@interface MHSourceCodeEditorTheme : NSObject <NSCopying>

@property NSString *name;
@property NSFont *font;

@property NSColor *backgroundColor;
@property NSColor *mathModeBackgroundColor;
@property NSColor *insertionPointColor;
@property NSColor *selectionColor;
@property (readonly) NSColor *textColor;

@property BOOL editable;        // defaults to YES


+ (instancetype)themeWithDictionaryRepresentation:(NSDictionary *)themeDict;

- (void)createAttributesDictsWithFont:(NSFont *)font italicFont:(NSFont *)italicFont boldFont:(NSFont *)boldFont;
- (void)recreateAttributesDictsForFont:(NSFont *)font italicFont:(NSFont *)italicFont boldFont:(NSFont *)boldFont;

- (void)applySyntaxColoringToTextStorage:(MHSourceCodeTextStorage *)sourceCodeTextStorage range:(NSRange)range;     // if range.location of the passed range is NSNotFound, coloring is applied to the entire text

+ (NSArray <NSString *> *)localizedThemeEditableForegroundColorDescriptions;
- (NSColor *)colorForEditableForegroundColorWithIndex:(NSUInteger)index;
- (NSUInteger)indexForMathModeForegroundColor;
- (NSUInteger)indexForMathKeywordColor;
- (NSUInteger)indexForCommandColor;
- (NSUInteger)indexForUnresolvedCommandColor;

- (void)setColorForEditableAttributeWithIndex:(NSUInteger)index toColor:(NSColor *)color;

- (NSDictionary *)dictionaryRepresentation;


@end

NS_ASSUME_NONNULL_END
