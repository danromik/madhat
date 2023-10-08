//
//  MHMathFontsLibraryEditingManager.h
//  MadHat
//
//  Created by Dan Romik on 12/18/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHMathFontsLibraryEditingManager : NSObject <NSTableViewDelegate, NSTableViewDataSource>

- (void)saveCurrentlyEditingFont;

@end

NS_ASSUME_NONNULL_END
