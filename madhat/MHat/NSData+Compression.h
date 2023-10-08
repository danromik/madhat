//
//  NSData+Compression.h
//  Copied from https://stackoverflow.com/questions/1928162/creating-a-zip-archive-from-a-cocoa-application/32723162#32723162
//

#import <Foundation/Foundation.h>


@interface NSData (NSDataExtension)

- (NSData*)zip;

@end
