//
//  NSString+TextSubstitution.h
//  MadHat
//
//  Created by Dan Romik on 8/5/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Foundation/Foundation.h>
#import "MadHat.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (TextSubstitution)

- (NSString *)stringByApplyingSubstitution:(MHTextSubstitutionType)substitutionType;

@end

NS_ASSUME_NONNULL_END
