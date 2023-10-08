//
//  NSData+Compression.m
//  Copied from https://stackoverflow.com/questions/1928162/creating-a-zip-archive-from-a-cocoa-application/32723162#32723162
//

#import "NSData+Compression.h"
#import "NSURL+Compression.h"


@implementation NSData (NSDataExtension)


// Creates a zip archive of this data via a temporary file and returns the zipped contents
// Swift to objective c from https://stackoverflow.com/a/32723162/
-(NSData*)zip
{
  NSURL* temporaryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
  [self writeToURL:temporaryURL options:NSDataWritingAtomic error:nil];
  NSURL* zipURL = [temporaryURL zip];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSData*        zippedData  = [NSData dataWithContentsOfURL:zipURL options:NSDataReadingMapped error:nil];

  [fileManager removeItemAtURL:temporaryURL error:nil];
  [fileManager removeItemAtURL:zipURL error:nil];
  
  return zippedData;
}


@end
