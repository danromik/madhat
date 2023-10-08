//
//  NSURL+Compression.m
//  Copied from https://stackoverflow.com/questions/1928162/creating-a-zip-archive-from-a-cocoa-application/32723162#32723162
//

#import "NSURL+Compression.h"


@implementation NSURL (NSURLExtension)


-(NSURL*)zip
{
  BOOL   isDirectory;
  BOOL   hasTempDirectory = FALSE;
  NSURL* sourceURL;

  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL           fileExists  = [fileManager fileExistsAtPath:self.path isDirectory:&isDirectory];

  NSURL* destinationURL = [self URLByAppendingPathExtension:@"zip"];

  if(fileExists && isDirectory)
  {
    sourceURL = self;
  }

  else
  {
    sourceURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [fileManager createDirectoryAtURL:sourceURL withIntermediateDirectories:TRUE attributes:nil error:nil];

    NSString* pathComponent = self.lastPathComponent ? self.lastPathComponent : @"file";
    [fileManager copyItemAtURL:self toURL:[sourceURL URLByAppendingPathComponent:pathComponent] error:nil];

    hasTempDirectory = TRUE;
  }

  NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] init];

  [fileCoordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL* zippedURL)
   {
    [fileManager copyItemAtURL:zippedURL toURL:destinationURL error:nil];
   }];

  if(hasTempDirectory)
  {
    [fileManager removeItemAtURL:sourceURL error:nil];
  }

  return destinationURL;
}



-(NSData *)zippedContents
{
  BOOL   isDirectory;
  BOOL   hasTempDirectory = FALSE;
  NSURL* sourceURL;

  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL           fileExists  = [fileManager fileExistsAtPath:self.path isDirectory:&isDirectory];

//  NSURL* destinationURL = [self URLByAppendingPathExtension:@"zip"];

  if(fileExists && isDirectory)
  {
    sourceURL = self;
  }

  else
  {
    sourceURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [fileManager createDirectoryAtURL:sourceURL withIntermediateDirectories:TRUE attributes:nil error:nil];

    NSString* pathComponent = self.lastPathComponent ? self.lastPathComponent : @"file";
    [fileManager copyItemAtURL:self toURL:[sourceURL URLByAppendingPathComponent:pathComponent] error:nil];

    hasTempDirectory = TRUE;
  }

  NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] init];
    
  __block NSData *dataToReturn;

  [fileCoordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL* zippedURL)
   {
      dataToReturn = [NSData dataWithContentsOfURL:zippedURL];
   }];

  if(hasTempDirectory)
  {
    [fileManager removeItemAtURL:sourceURL error:nil];
  }

  return dataToReturn;
}




@end

