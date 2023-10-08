//
//  MHMathFontManager.h
//  MadHat
//
//  Created by Dan Romik on 7/7/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//
//
//  A singleton class whose singleton instance manages available math fonts

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MHMathFontSystem;

@interface MHMathFontManager : NSObject


@property (readonly) NSArray <NSString *> *availableMathFonts;

@property MHMathFontSystem * _Nullable currentlyEditingFont;   // this property can be set by a client editor object, and reset to nil when editing is finished. The editing font will be returned first by any client asking for the same family name as the one being edited


// Accessing the singleton instance
+ (instancetype)defaultManager;

// Font operations: creating, deleting, saving
- (bool)createNewMathFontWithName:(NSString *)name;
- (bool)deleteMathFontWithName:(NSString *)name;
- (bool)saveMathFont:(MHMathFontSystem *)font;

// Font editing
- (void)currentlyEditingFontUpdated;

// Accessing fonts
- (MHMathFontSystem * _Nullable)mathFontWithName:(NSString *)mathFontName;

// Best if used sparingly by client objects (currently only used for "Show in Finder" contextual menu action)
- (NSURL * _Nullable)urlForFontWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
