//
//  GTPackageExtractor.m
//  godtools
//
//  Created by Michael Harrison on 8/24/15.
//  Copyright (c) 2015 Michael Harrison. All rights reserved.
//

#import "GTPackageExtractor.h"
#import "SSZipArchive.h"
#import "GTPackage+Helper.h"
#import <GTViewController/GTFileLoader.h>

@implementation GTPackageExtractor

- (RXMLElement *)unzipResourcesAtTarget:(NSURL *)targetPath forLanguage:(GTLanguage *)language package:(GTPackage *)package {
	
	NSParameterAssert(language.code || package.code);
	
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *temporaryFolderName	= [[NSUUID UUID] UUIDString];
	NSString* temporaryDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:temporaryFolderName];
	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:temporaryDirectory]){    //Does directory already exist?
		if (![[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory withIntermediateDirectories:NO attributes:nil error:&error]){
			NSLog(@"Create directory error: %@", error);
		}
	}
	
	if(![SSZipArchive unzipFileAtPath:[targetPath absoluteString]
						toDestination:temporaryDirectory
							overwrite:NO
							 password:nil
								error:&error
							 delegate:nil]) {
		
		[self displayDownloadPackagesUnzippingError:error];
		[[NSNotificationCenter defaultCenter] postNotificationName:GTDataImporterNotificationLanguageDownloadFinished object:self];
	}
	
	if(!error){
		
		RXMLElement *element = [RXMLElement elementFromXMLData:[NSData dataWithContentsOfFile:[temporaryDirectory stringByAppendingPathComponent:@"contents.xml"]]];
		
		//move to Packages folder
		NSString *destinationPath = [[GTFileLoader sharedInstance] pathOfPackagesDirectory];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if (![fm fileExistsAtPath:destinationPath]){ //Create directory
			if (![[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO  attributes:nil error:&error]){
				NSLog(@"Create directory error: %@", error);
			}
		}
		
		for (NSString *file in [fm contentsOfDirectoryAtPath:temporaryDirectory error:&error]) {
			NSString *filepath = [NSString stringWithFormat:@"%@/%@",temporaryDirectory,file];
			NSString *destinationFile = [NSString stringWithFormat:@"%@/%@",destinationPath,file];
			if(![file  isEqual: @"contents.xml"]){ //&& ![fm fileExistsAtPath:destinationFile]){
				if([fm fileExistsAtPath:destinationFile]){
					//NSLog(@"file exist: %@", destinationFile);
					[fm removeItemAtPath:destinationFile error:&error];
				}
				BOOL success = [fm copyItemAtPath:filepath toPath:destinationFile error:&error] ;
				if (!success || error) {
					NSLog(@"Error: %@ file: %@",[error description],file);
				}else{
					[fm removeItemAtPath:filepath error:&error];
				}
			}
		}
		
		if(!error){ //No error moving files
			[fm removeItemAtPath:temporaryDirectory error:&error];
			[fm removeItemAtPath:[targetPath absoluteString] error:&error];
		}
		return element;
		
	}else{
		
		[[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:&error];
		[[NSFileManager defaultManager] removeItemAtPath:[targetPath absoluteString] error:&error];
	}
	
	return nil;
	
	
}

- (NSError *)unzipXMLAtTarget:(NSURL *)targetPath forPage:(NSString *)pageID {
	
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *fileName = [NSString stringWithFormat:@"%@.xml",pageID];
	NSString *fileDownloadDestinationPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:pageID];
	
	if(![SSZipArchive unzipFileAtPath:[targetPath absoluteString]
						toDestination:fileDownloadDestinationPath
							overwrite:NO
							 password:nil
								error:&error
							 delegate:nil]) {
		
		[self displayDownloadPackagesUnzippingError:error];
		[[NSNotificationCenter defaultCenter] postNotificationName:GTDataImporterNotificationLanguageDownloadFinished object:self];
	}
	
	if(!error){
		
		//RXMLElement *element = [RXMLElement elementFromXMLData:[NSData dataWithContentsOfFile:[temporaryDirectory stringByAppendingPathComponent:@"contents.xml"]]];
		
		//move to Packages folder
		NSString *destinationPath = [[GTFileLoader sharedInstance] pathOfPackagesDirectory];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if (![fm fileExistsAtPath:destinationPath]){ //Create directory
			if (![[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO  attributes:nil error:&error]){
				NSLog(@"Create directory error: %@", error);
			}
		}
		for (NSString *file in [fm contentsOfDirectoryAtPath:fileDownloadDestinationPath error:&error]) {
			NSString *filepath = [NSString stringWithFormat:@"%@/%@",fileDownloadDestinationPath,file];
			NSString *destinationFile = [NSString stringWithFormat:@"%@/%@",destinationPath,file];
			if([fm fileExistsAtPath:destinationFile]){
				//NSLog(@"file exist: %@", destinationFile);
				[fm removeItemAtPath:destinationFile error:&error];
			}
			BOOL success = [fm copyItemAtPath:filepath toPath:destinationFile error:&error] ;
			if (!success || error) {
				NSLog(@"Error: %@ file: %@",[error description],file);
				return error;
			}else{
				[fm removeItemAtPath:fileDownloadDestinationPath error:&error];
				return nil;
			}
		}
		
	}else{
		return error;
	}
	
	return nil;
	
	
}

- (void)displayDownloadPackagesUnzippingError:(NSError *)error {
	
	[self.storage.errorHandler displayError:error];
	
	
}

@end
