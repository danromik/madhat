//
//  NSAttributedString+QuickLineBreaking.h
//  MadHat
//
//  Created by Dan Romik on 8/18/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (QuickLineBreaking)

- (NSArray <NSAttributedString *> *)layoutLinesWithWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
