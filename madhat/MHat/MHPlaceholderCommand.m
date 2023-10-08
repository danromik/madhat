//
//  MHPlaceholderCommand.m
//  MadHat
//
//  Created by Dan Romik on 7/30/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHPlaceholderCommand.h"

@implementation MHPlaceholderCommand



+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ @"*" ];   // Any command is accepted
}


@end
