//
//  MHParagraphStyle.h
//  MadHat
//
//  Created by Dan Romik on 2/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "MHStyle.h"

#import "MadHat.h"


NS_ASSUME_NONNULL_BEGIN




@interface MHParagraphStyle : MHStyle




@property (nullable) NSColor *paragraphBackgroundColor;
@property (nullable) NSColor *paragraphFrameColor;
@property CGFloat paragraphFrameThickness;

@property MHParagraphType paragraphType;
@property BOOL paragraphHasIndentSuppressed;
@property BOOL paragraphForcedAsNewParagraph;

- (void)setParagraphBoxType:(MHParagraphBoxType)boxType;
- (MHParagraphBoxType)readAndResetParagraphBoxType;



@end

NS_ASSUME_NONNULL_END
