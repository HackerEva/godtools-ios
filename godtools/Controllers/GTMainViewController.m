//
//  GTMainViewController.m
//  godtools
//
//  Created by Michael Harrison on 3/13/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import "GTMainViewController.h"
#import "GTDataImporter.h"
#import "RXMLElement.h"
#import "SSZipArchive.h"
#import "GTLanguage+Helper.h"
#import "GTPackage+Helper.h"
#import "TBXML.h"
#import "GTDefaults.h"
#import "GTBaseView.h"
#import "GTSplashScreenView.h"

#import "GTGoogleAnalyticsTracker.h"

@interface GTMainViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) GTSplashScreenView *splashScreen;

- (void)askToUpdate:(NSNotification *)notification;

@end

@implementation GTMainViewController

- (void)viewDidLoad {
	
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES];
    
    self.splashScreen = (GTSplashScreenView*) [[[NSBundle mainBundle] loadNibNamed:@"GTSplashScreenView" owner:nil options:nil]objectAtIndex:0];
    self.splashScreen.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.view = self.splashScreen;

    NSLog(@"SPLASH IS   %@", [self.splashScreen class]);
    
    [self.splashScreen initDownloadIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFinished:)
                                                 name: GTDataImporterNotificationMenuUpdateFinished
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showLoadingIndicator:)
                                                 name: GTDataImporterNotificationMenuUpdateStarted
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(askToUpdate:)
												 name: GTDataImporterNotificationNewVersionsAvailable
											   object:nil];

    //check if first launch
    if([[GTDefaults sharedDefaults]isFirstLaunch] == [NSNumber numberWithBool:YES]){
        //prepare initial content
        [self extractBundle];
        [self extractMetaData];
    }
    
    if(![[GTDefaults sharedDefaults] genericApiToken]) {
        [self requestGenericAuthToken];
    } else {
        [self updateMenu];
        [self goToHome];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[[GTGoogleAnalyticsTracker sharedInstance] setScreenName:@"SplashScreen"] sendScreenView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	
#warning remove observe calls are in the wrong place
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationMenuUpdateFinished
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationMenuUpdateStarted                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:GTDataImporterNotificationNewVersionsAvailable                                              object:nil];
}

-(void)goToHome{
    NSLog(@"go to home");
	[self performSelector:@selector(performSegueToHome) withObject:nil afterDelay:1.0];

}

-(void)performSegueToHome{
     [self performSegueWithIdentifier:@"splashToHomeViewSegue" sender:self];
}

-(void) requestGenericAuthToken {
    [[GTAPI sharedAPI] getAuthTokenForDeviceID:nil
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSString *authToken) {
                                           [[GTDefaults sharedDefaults] setGenericApiToken:authToken];
                                           [[GTAPI sharedAPI] setAuthToken:authToken];
                                           [self updateFromApi];
                                           [self goToHome];
                                       }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                           NSLog(@"generic auth failed!!");
                                           [self goToHome];
                                       }];
}

-(void)updateFromApi {
    [self updateMenu];
    [[GTDefaults sharedDefaults] setIsChoosingForMainLanguage:[NSNumber numberWithBool: YES]];
    [[GTDataImporter sharedImporter] downloadPackagesForLanguage:[[[GTStorage sharedStorage]fetchModel:[GTLanguage class] usingKey:@"code" forValue:[[GTDefaults sharedDefaults]phonesLanguageCode] inBackground:YES]objectAtIndex:0]];
}

-(void)updateMenu{

	[[GTDataImporter sharedImporter] updateMenuInfo];
}

-(void)showLoadingIndicator:(NSNotification *) notification{
    [self.splashScreen showDownloadIndicatorWithLabel:@"Checking for Updates"];
}


-(void)updateFinished:(NSNotification *) notification{
    NSLog(@"notification main: %@",notification.name);
    if([self.splashScreen.activityView isAnimating]){
        [self.splashScreen hideDownloadIndicator];
    }
    
}

-(void)extractBundle{
    //WILL ONLY BE TRIGERRED AT FRESH INSTALL
    [self.splashScreen showDownloadIndicatorWithLabel:[NSString stringWithFormat:(NSLocalizedString(@"GTHome_status_updatingResources", nil)),@"English"]];
   
    NSError *error;
    
    NSString *temporaryFolderName	= [[NSUUID UUID] UUIDString];
    NSString* temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryFolderName];

    
    if (![[NSFileManager defaultManager] fileExistsAtPath:temporaryDirectory]){    //Does directory already exist?
        if (![[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory withIntermediateDirectories:NO attributes:nil error:&error]){
            NSLog(@"Create directory error: %@", error);
        }
    }
    
    NSString* pathOfEnglishBundle = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"zip"];
    
    //unzip to temporary directory
    if(![SSZipArchive unzipFileAtPath:pathOfEnglishBundle
                        toDestination:temporaryDirectory
                            overwrite:NO
                             password:nil
                                error:&error
                             delegate:nil]) {
        
        //[self displayDownloadPackagesUnzippingError:error];
        NSLog(@"error unzipping file");
        #warning error handling
    }
    if(!error){
        RXMLElement *rootXML = [RXMLElement elementFromXMLData:[NSData dataWithContentsOfFile:[temporaryDirectory stringByAppendingPathComponent:@"contents.xml"]]];

        //Update database with config filenames.
        NSArray *englishArray = [[GTStorage sharedStorage]fetchArrayOfModels:[GTLanguage class] usingKey:@"code" forValues:@[@"en"] inBackground:YES];
        GTLanguage *english;
        if([englishArray count]==0){
            english = [GTLanguage languageWithCode:@"en" inContext:[GTStorage sharedStorage].backgroundObjectContext];
            english.name = @"English";
        }else{
            english = [englishArray objectAtIndex:0];
            [english removePackages:english.packages];
        }
        
        [rootXML iterate:@"resource" usingBlock: ^(RXMLElement *resource) {
           
            NSString *existingIdentifier = [GTPackage identifierWithPackageCode:[resource attribute:@"package"] languageCode:english.code];
            
            NSArray *packageArray = [[GTStorage sharedStorage]fetchArrayOfModels:[GTPackage class] usingKey:@"identifier" forValues:@[existingIdentifier] inBackground:YES];
            
            GTPackage *package;
            
            if([packageArray count]==0){
                NSLog(@"create new package");
                package = [GTPackage packageWithCode:[resource attribute:@"package"] language:english inContext:[GTStorage sharedStorage].backgroundObjectContext];
            }else{
                NSLog(@"get old package");
                package = [packageArray objectAtIndex:0];
            }
            
            package.name			= [resource attribute:@"name"];
            package.configFile		= [resource attribute:@"config"];
            package.icon			= [resource attribute:@"icon"];
            package.status			= [resource attribute:@"status"];
            package.localVersion	= [resource attribute:@"version"];
            package.latestVersion	= [resource attribute:@"version"];

            [english addPackagesObject:package];
            
        }];
        
        english.downloaded = [NSNumber numberWithBool: YES];
        if (![[GTStorage sharedStorage].backgroundObjectContext save:&error]) {
            NSLog(@"error saving");
        }
        
        //move to Packages folder
        NSString *destinationPath = [GTFileLoader pathOfPackagesDirectory];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]){
            if (![[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO  attributes:nil error:&error]){
                NSLog(@"Create directory error: %@", error);
            }
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        for (NSString *file in [fm contentsOfDirectoryAtPath:temporaryDirectory error:&error]) {
            if(![file  isEqual: @"contents.xml"]){
                NSString *filepath = [NSString stringWithFormat:@"%@/%@",temporaryDirectory,file];
                BOOL success = [fm copyItemAtPath:filepath toPath:[NSString stringWithFormat:@"%@/%@",destinationPath,file] error:&error] ;
                if (!success || error) {
                    NSLog(@"Error: %@",[error localizedDescription]);
                }else{
                    [fm removeItemAtPath:filepath error:&error];
                }
            }
        }
        
        if(!error){
            [fm removeItemAtPath:temporaryDirectory error:&error];
        }
            
        [[GTDefaults sharedDefaults]setCurrentLanguageCode:english.code];

    }
}

-(void)extractMetaData{

    NSString* pathOfMeta = [[NSBundle mainBundle] pathForResource:@"meta" ofType:@"xml"];
    RXMLElement *metaXML = [RXMLElement elementFromXMLData:[NSData dataWithContentsOfFile:pathOfMeta]];
    
    [[GTDataImporter sharedImporter]persistMenuInfoFromXMLElement:metaXML];

}

#pragma mark - Update languages to new versions

- (void)askToUpdate:(NSNotification *)notification {
	
	NSNumber *numberOfUpdatesAvailable = notification.userInfo[GTDataImporterNotificationNewVersionsAvailableKeyNumberAvailable];
	
	UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"AlertTitle_newUpdatesAvailable", nil), [numberOfUpdatesAvailable integerValue]]
														 message:NSLocalizedString(@"AlertMessage_newUpdatesAvailable", nil)
														delegate:self
											   cancelButtonTitle:NSLocalizedString(@"No", nil)
											   otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
	[confirmationAlert show];
	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		
		[[GTDataImporter sharedImporter] updatePackagesWithNewVersions];
		
	}
	
}


- (void)didReceiveMemoryWarning {
	
    [super didReceiveMemoryWarning];
	
}

@end
