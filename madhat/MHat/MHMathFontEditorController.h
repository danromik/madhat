//
//  MHMathFontEditorController.h
//  MadHat
//
//  Created by Dan Romik on 7/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHMathFontSystem.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHMathFontParametersChangedNotification;


@interface MHMathFontEditorController : NSObject <NSTableViewDelegate, NSTableViewDataSource>


@property MHMathFontSystem * _Nullable mathFontSystem;

@property bool hasUnsavedChanges;





@end

NS_ASSUME_NONNULL_END
