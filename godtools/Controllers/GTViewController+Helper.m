//
//  GTViewController+Helper.m
//  godtools
//
//  Created by Claudine Bael on 12/3/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import "GTViewController+Helper.h"
#import <objc/runtime.h>

#import "GTDataImporter.h"

@implementation GTViewController (Helper)

@dynamic currentPackage;

NSString const *currentPackageKey = @"com.godtools.gtviewcontroller.currentpackage";
NSString const *refreshDraftAlertKey = @"com.godtools.gtviewcontroller.refreshDraftAlert";


-(void)refreshCurrentPage:(NSString *)currentPage{
    NSLog(@"current page:%@",currentPage);
    NSString *pageID = [[currentPage componentsSeparatedByString:@"."]objectAtIndex:0];
    NSLog(@"page ID: %@",pageID);
    NSLog(@"current package: %@",self.currentPackage);
    NSLog(@"current language: %@",self.currentPackage.language);
    [[GTDataImporter sharedImporter]downloadPageForLanguage:self.currentPackage.language package:self.currentPackage pageID:pageID];
}

-(void)addNotificationObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideRefreshAlert:)
                                                 name: GTDataImporterNotificationDownloadPageStarted
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideRefreshAlert:)
                                                 name: GTDataImporterNotificationDownloadPageSuccessful
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideRefreshAlert:)
                                                 name: GTDataImporterNotificationDownloadPageFail
                                               object:nil];
}

-(void)showHideRefreshAlert:(NSNotification *)notification{
    NSLog(@"notif: %@",notification.name);
    if([notification.name isEqualToString:GTDataImporterNotificationDownloadPageStarted]){
        //if(!self.refreshDraftAlert){
            self.refreshDraftAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Refreshing draft..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        //}
        NSLog(@"refresh alert view, show yourself!");
        [self.refreshDraftAlert show];
    }else if([notification.name isEqualToString:GTDataImporterNotificationDownloadPageSuccessful]){
        [self.refreshDraftAlert dismissWithClickedButtonIndex:0 animated:YES];
    }else if([notification.name isEqualToString:GTDataImporterNotificationDownloadPageFail]){
        [self.refreshDraftAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
}


- (GTPackage*) currentPackage {
    return  objc_getAssociatedObject(self, &currentPackageKey);
}

- (void)setCurrentPackage:(GTPackage *)currentPackage{
    objc_setAssociatedObject(self, &currentPackageKey, currentPackage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIAlertView *)refreshDraftAlert{
    return  objc_getAssociatedObject(self, &refreshDraftAlertKey);
}

-(void)setRefreshDraftAlert:(UIAlertView *)refreshDraftAlert{
    objc_setAssociatedObject(self, &refreshDraftAlertKey, refreshDraftAlert, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
