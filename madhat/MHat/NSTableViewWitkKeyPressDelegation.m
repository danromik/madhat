//
//  NSTableViewWitkKeyPressDelegation.m
//  MadHat
//
//  Created by Dan Romik on 7/3/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "NSTableViewWitkKeyPressDelegation.h"

@implementation NSTableViewWitkKeyPressDelegation

@dynamic delegate;

- (void)keyDown:(NSEvent *)event
{
    if (![self.delegate tableView:self keyDown:event])
        [super keyDown:event];
}

@end
