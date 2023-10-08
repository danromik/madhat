//
//  MHStyle.m
//  MadHat
//
//  Created by Dan Romik on 9/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHStyle.h"

@implementation MHStyle

+ (instancetype)defaultStyle
{
    NSAssert(false, @"%@: Abstract class cannot be instantiated", self);
    return nil;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    NSAssert(false, @"%@: Abstract class cannot be copied", [self class]);
    return nil;
}

@end
