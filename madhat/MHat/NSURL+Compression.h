//
//  NSURL+Compression.h
//  Copied from https://stackoverflow.com/questions/1928162/creating-a-zip-archive-from-a-cocoa-application/32723162#32723162
//  For an alternative approach to zipping/unzipping files in Objective-C, see: https://github.com/ZipArchive/ZipArchive
//

#import <Foundation/Foundation.h>


@interface NSURL (NSURLExtension)

- (NSURL*)zip;

-(NSData *)zippedContents;

@end
