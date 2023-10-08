//
//  NSSubordinateWindow.m
//  MadHat
//
//  Created by Dan Romik on 7/29/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "NSSubordinateWindow.h"

@interface NSSubordinateWindow ()

@end

@implementation NSSubordinateWindow

- (void)close
{
    [self.primaryWindow performClose:nil];
}

- (void)actuallyClose
{
    [super close];
}

@end
