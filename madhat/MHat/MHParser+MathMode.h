//
//  MHParser+MathMode.h
//  MadHat
//
//  Created by Dan Romik on 1/5/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHParser (MathMode)

// The return value is either rootContainer, or, if rootContainer is nil, a new expression created to serve as the root container
- (MHHorizontalLayoutContainer *)parseMathModeCodeInRange:(NSRange)charRange
                               actuallyScannedRange:(NSRange *)scannedRangePointer
                                      rootContainer:(nullable MHHorizontalLayoutContainer *)rootContainer;
@end

NS_ASSUME_NONNULL_END
