//
//  MHStyle.h
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

// An abstract class that manages the data structures associated with a style for a part or aspect of a notebook
// Concrete examples include a typing style (MHTypingStyle subclass - keeps track of font, font size, text and highlight colors etc),
// paragraph style (MHParagraphStyle subclass - manages line spacings, margins etc)
// list style (MHListStyle subclass)
// graphics style (MHGraphicsStyle subclass)
// box style (MHBoxStyle subclass)

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHStyle : NSObject <NSCopying>

+ (instancetype)defaultStyle;   // Must be implemented by subclasses

@end

NS_ASSUME_NONNULL_END
