//
//  GTMainViewController.m
//  godtools
//
//  Created by Michael Harrison on 3/13/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import "GTMainViewController.h"
#import "GTDataImporter.h"
#import "GTPackageExtractor.h"
#import "GTInitialSetupTracker.h"
#import "GTSplashScreenView.h"
#import "GTHomeViewController.h"
#import "GTGoogleAnalyticsTracker.h"
#import "FollowUpAPI.h"
#import "GTFollowUpSubscription.h"
//GitHub Issue #43
#import "GTDefaults.h"
#import "GTLanguage.h"
#import "GTStorage.h"

NSString * const GTSplashErrorDomain                                            = @"org.cru.godtools.gtsplashviewcontroller.error.domain";
NSInteger const GTSplashErrorCodeInitialSetupFailed                             = 1;

NSString * const GTSplashNotificationDownloadPhonesLanugageSuccess				= @"org.cru.godtools.gtsplashviewcontroller.notification.downloadphoneslanguagesuccess";
NSString * const GTSplashNotificationDownloadPhonesLanugageProgress				= @"org.cru.godtools.gtsplashviewcontroller.notification.downloadphoneslanguageprogress";
NSString * const GTSplashNotificationDownloadPhonesLanugageFailure				= @"org.cru.godtools.gtsplashviewcontroller.notification.downloadphoneslanguagefailure";

@interface GTMainViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) GTInitialSetupTracker *setupTracker;
@property (nonatomic, strong) GTSplashScreenView *splashScreen;

- (void)persistLocalMetaData;
- (void)persistLocalEnglishPackage;
- (void)downloadPhonesLanguage;

- (void)updateMenu;
- (void)goToHome;

- (void)initialSetupBegan:(NSNotification *)notification;
- (void)initialSetupFinished:(NSNotification *)notification;
- (void)initialSetupFailed:(NSNotification *)notification;

- (void)menuUpdateBegan:(NSNotification *)notification;
- (void)menuUpdateFinished:(NSNotification *)notification;

- (void)registerListenersForInitialSetup;
- (void)removeListenersForInitialSetup;
- (void)registerListenersForMenuUpdate;
- (void)removeListenersForMenuUpdate;

@end

@implementation GTMainViewController

- (void)viewDidLoad {
	
    [super viewDidLoad];

	self.setupTracker = [[GTInitialSetupTracker alloc] init];
	
	//UI config
    [self.navigationController setNavigationBarHidden:YES];
    self.splashScreen = (GTSplashScreenView*) [[[NSBundle mainBundle] loadNibNamed:@"GTSplashScreenView" owner:nil options:nil]objectAtIndex:0];
    self.splashScreen.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.view = self.splashScreen;
    
    [self.splashScreen initDownloadIndicator];
	
	//check to see if the database go reset due to a bad migration. If so rerun the first launch code.
	[[NSNotificationCenter defaultCenter] addObserverForName:CRUStorageNotificationRecoveryCompleted
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification * _Nonnull note) {
													  self.setupTracker.firstLaunch = YES;
												  }];
	[GTDataImporter sharedImporter];

    //check if first launch
    if(self.setupTracker.firstLaunch){
		
		[self registerListenersForInitialSetup];
		[self.setupTracker beganInitialSetup];
		
        //prepare initial content
        [self persistLocalEnglishPackage];
        [self persistLocalMetaData];
		
		//download phone's language
		[self downloadPhonesLanguage];
		
	} else {
        [self leavePreviewMode];
        [self registerListenersForMenuUpdate];
        [self sendCachedFollowupSubscriptions];
		[self updateMenu];
	}
	
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[[GTGoogleAnalyticsTracker sharedInstance] setScreenName:@"SplashScreen"] sendScreenView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
}

#pragma mark - API request methods

- (void)updateMenu {
	[[GTDataImporter sharedImporter] updateMenuInfo];
}

#pragma mark - First Launch methods

- (void)persistLocalMetaData {
	
	NSString* pathOfMeta = [[NSBundle mainBundle] pathForResource:@"meta" ofType:@"xml"];
	RXMLElement *metaXML = [RXMLElement elementFromXMLData:[NSData dataWithContentsOfFile:pathOfMeta]];
	
	if ([[GTDataImporter sharedImporter] importMenuInfoFromXMLElement:metaXML]) {
		
		[self.setupTracker finishedExtractingMetaData];
		
	} else {
		
		[self.setupTracker failedExtractingMetaData];
		
	}
	
}

- (void)persistLocalEnglishPackage {
	
	//retrieve or create the english language object.
	NSArray *englishArray = [[GTStorage sharedStorage] fetchArrayOfModels:[GTLanguage class] usingKey:@"code" forValues:@[@"en"] inBackground:YES];
	GTLanguage *english;
	if([englishArray count] == 0){
		english = [GTLanguage languageWithCode:@"en" inContext:[GTStorage sharedStorage].backgroundObjectContext];
		english.name = @"English";
	}else{
		english = [englishArray objectAtIndex:0];
		[english removePackages:english.packages];
	}
	
	NSURL* pathOfEnglishZip	= [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"zip"]];
	//unzips english package and moves it to documents folder
	RXMLElement *contents			= [[GTPackageExtractor sharedPackageExtractor] unzipResourcesAtTarget:pathOfEnglishZip forLanguage:english package:nil];
	
	//reads contents.xml and saves meta data to the database about all the packages found in the zip file.
	if ([[GTDataImporter sharedImporter] importPackageContentsFromElement:contents forLanguage:english]) {
		
		[self.setupTracker finishedExtractingEnglishPackage];
		
	} else {
		
		[self.setupTracker failedExtractingEnglishPackage];
		
	}
	
	[GTDefaults sharedDefaults].currentLanguageCode = english.code;
	
}

- (void)downloadPhonesLanguage {
	
	if (![[GTDefaults sharedDefaults].phonesLanguageCode isEqualToString:@"en"]) {
	
		__weak typeof(self)weakSelf = self;
		[[NSNotificationCenter defaultCenter] addObserverForName:GTSplashNotificationDownloadPhonesLanugageSuccess
														  object:nil
														   queue:nil
													  usingBlock:^(NSNotification *note) {
														  
														  [weakSelf.setupTracker finishedDownloadingPhonesLanguage];
														  
													  }];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:GTSplashNotificationDownloadPhonesLanugageFailure
														  object:nil
														   queue:nil
													  usingBlock:^(NSNotification *note) {
														  
														  [weakSelf.setupTracker failedDownloadingPhonesLanguage];
														  
													  }];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:GTDataImporterNotificationMenuUpdateFinished
														  object:nil
														   queue:nil
													  usingBlock:^(NSNotification *note) {
			
														  [self.splashScreen showDownloadIndicatorWithLabel:NSLocalizedString(@"status_downloading_resources", nil)];
														  
														  [GTDefaults sharedDefaults].isChoosingForMainLanguage = YES;
														  GTLanguage *phonesLanguage = [[GTStorage sharedStorage] findClosestLanguageTo:[GTDefaults sharedDefaults].phonesLanguageCode];
														  
                                                          if(phonesLanguage) {

															  [[GTDataImporter sharedImporter] downloadPackagesForLanguage:phonesLanguage
																									  withProgressNotifier:GTSplashNotificationDownloadPhonesLanugageProgress
																									   withSuccessNotifier:GTSplashNotificationDownloadPhonesLanugageSuccess
																									   withFailureNotifier:GTSplashNotificationDownloadPhonesLanugageFailure];
                                                          } else {
                                                              [weakSelf.setupTracker finishedDownloadingPhonesLanguage];
                                                          }
														  
		}];
	
	}
	
	[self updateMenu];
	
}


- (void)sendCachedFollowupSubscriptions {
    NSArray *subscriptions = [GTFollowUpSubscription MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"apiTransmissionSuccess == NIL || apiTransmissionSuccess == NO"]];
    
    [subscriptions enumerateObjectsUsingBlock:^(GTFollowUpSubscription * _Nonnull subscription, NSUInteger idx, BOOL * _Nonnull stop) {
        [[FollowUpAPI sharedAPI] sendNewSubscription:subscription
                                           onSuccess:^(AFHTTPRequestOperation *request, id obj) {
                                               [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                                                   subscription.apiTransmissionSuccess = @YES;
                                                   subscription.apiTransmissionTimestamp = [NSDate date];
                                               } completion:nil];
                                           }
                                           onFailure:^(AFHTTPRequestOperation *request, NSError *error) {
                                               [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                                                   subscription.apiTransmissionSuccess = @NO;
                                                   subscription.apiTransmissionTimestamp = [NSDate date];
                                               } completion:nil];
                                               
                                           }];
        
    }];
}


#pragma mark - memory management methods

- (void)didReceiveMemoryWarning {
	
    [super didReceiveMemoryWarning];
	
}

#pragma mark - UI methods

- (void)goToHome {
	
	[self performSegueWithIdentifier:@"splashToHomeViewSegue" sender:self];
}

- (void)initialSetupBegan:(NSNotification *)notification {
	
	[self.splashScreen showDownloadIndicatorWithLabel:NSLocalizedString(@"status_initial_setup", nil)];
}


- (void)initialSetupFinished:(NSNotification *)notification {
	
	if([self.splashScreen.activityView isAnimating]){
		[self.splashScreen hideDownloadIndicator];
	}
	
	[self removeListenersForInitialSetup];
	[self goToHome];
	self.setupTracker.firstLaunch = NO;
}

- (void)initialSetupFailed:(NSNotification *)notification {
	
	if([self.splashScreen.activityView isAnimating]){
		[self.splashScreen hideDownloadIndicator];
	}
	
	[self removeListenersForInitialSetup];
	
	NSError *error = [NSError errorWithDomain:GTSplashErrorDomain
										 code:GTSplashErrorCodeInitialSetupFailed
									 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"initial_setup_error_message", nil) }];
	
	[[GTErrorHandler sharedErrorHandler] displayError:error];
	
}

- (void)menuUpdateBegan:(NSNotification *)notification {
	
	[self.splashScreen showDownloadIndicatorWithLabel:NSLocalizedString(@"status_checking_for_updates", nil)];
}

- (void)menuUpdateFinished:(NSNotification *)notification {
    
    //GitHub Issue #43 - Once the menu has updated, query CoreData and figure out if there's any updates
    //for the user's current language. If so, just go ahead and get them.
    NSString *lang = [GTDefaults sharedDefaults].currentLanguageCode;
    GTLanguage *language = [[GTStorage sharedStorage] languageWithCode:lang];
    //if there's updates, stay here until they're done
    if (language.hasUpdates == YES) {
        [[GTDataImporter sharedImporter] downloadPackagesForLanguage:language];
    //otherwise, move on
    } else {
        //tell the initialization tracker that there's nothing to do
        [self.setupTracker finishedDownloadingPhonesLanguage];
        
        if([self.splashScreen.activityView isAnimating]){
            [self.splashScreen hideDownloadIndicator];
        }
        [self removeListenersForMenuUpdate];
        [self goToHome];
    }
}

- (void)languageUpdateFailed:(NSNotification *)notification {
    //if it failed, should we just go home, or alert the user and do something else?

    //hide the indicator, remove the listeners
    if([self.splashScreen.activityView isAnimating]){
        [self.splashScreen hideDownloadIndicator];
    }
    [self removeListenersForMenuUpdate];
    [self goToHome];
}

- (void)languageUpdateFinished:(NSNotification *)notification {
    //we successfully updated our language, go to the home page
    
    //hide the indicator, remove the listeners
    if([self.splashScreen.activityView isAnimating]){
        [self.splashScreen hideDownloadIndicator];
    }
    [self removeListenersForMenuUpdate];
    [self goToHome];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	if ([[segue identifier] isEqualToString:@"splashToHomeViewSegue"]) {
		
		// Get reference to the destination view controller
		GTHomeViewController *home = [segue destinationViewController];
		home.shouldShowInstructions = self.setupTracker.firstLaunch;
	}
	
}



#pragma mark - listener methods

- (void)registerListenersForInitialSetup {
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(initialSetupBegan:)
												 name:GTInitialSetupTrackerNotificationDidBegin
											   object:self.setupTracker];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(initialSetupFinished:)
												 name:GTInitialSetupTrackerNotificationDidFinish
											   object:self.setupTracker];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(initialSetupFailed:)
												 name:GTInitialSetupTrackerNotificationDidFail
											   object:self.setupTracker];
	
}

- (void)removeListenersForInitialSetup {

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:GTInitialSetupTrackerNotificationDidBegin
												  object:self.setupTracker];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:GTInitialSetupTrackerNotificationDidFinish
												  object:self.setupTracker];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:GTInitialSetupTrackerNotificationDidFail
												  object:self.setupTracker];
	
}

- (void)registerListenersForMenuUpdate {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuUpdateBegan:)
                                                 name:GTDataImporterNotificationMenuUpdateStarted
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuUpdateFinished:)
                                                 name:GTDataImporterNotificationMenuUpdateFinished
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageUpdateFailed:)
                                                 name:GTDataImporterNotificationLanguageDownloadFailed
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageUpdateFinished:)
                                                 name:GTDataImporterNotificationLanguageDownloadFinished
                                               object:nil];
}

- (void)removeListenersForMenuUpdate {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationMenuUpdateStarted
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationMenuUpdateFinished
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationLanguageDownloadFailed
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTDataImporterNotificationLanguageDownloadFinished
                                                  object:nil];
    
}

- (void)dealloc {
}

#pragma mark - Update languages to new versions

#pragma mark - Helper methods
- (void)leavePreviewMode {
    [[GTDefaults sharedDefaults] setIsInTranslatorMode:[NSNumber numberWithBool:NO]];
}
@end
