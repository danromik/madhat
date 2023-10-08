//
//  MHProfiler.h
//  MadHat
//
//  Created by Dan Romik on 7/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHProfiler : NSObject

+ (instancetype)defaultProfiler;

- (void)parseExpressionSubclassesTree;

@end

NS_ASSUME_NONNULL_END
