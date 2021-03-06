//
//  MHConfig.m
//  MissionHub
//
//  Created by Michael Harrison on 10/28/13.
//  Copyright (c) 2013 Cru. All rights reserved.
//

#import "GTConfig.h"

@implementation GTConfig

+ (GTConfig *)sharedConfig {
	
	static GTConfig *_sharedConfig;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		_sharedConfig					= [[GTConfig alloc] init];
		
	});
	
	return _sharedConfig;
	
}

- (id)init {
	
    self = [super init];
    
	if (self) {
        
		//read config file
		NSString *configFilePath		= [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
		NSDictionary *configDictionary	= [NSDictionary dictionaryWithContentsOfFile:configFilePath];
		
		//set urls base on mode
		NSString *baseUrlString			= ( [configDictionary valueForKey:@"base_url"] ? [configDictionary valueForKey:@"base_url"] : @"" );
		_baseUrl						= [NSURL URLWithString:baseUrlString];
		
		//set urls base on mode
		NSString *baseShareUrlString	= ( [configDictionary valueForKey:@"base_share_url"] ? [configDictionary valueForKey:@"base_share_url"] : @"" );
		_baseShareUrl					= [NSURL URLWithString:baseShareUrlString];
		
		//set interpreter version
		_interpreterVersion				= ( [configDictionary valueForKey:@"interpreter_version"] ? [configDictionary valueForKey:@"interpreter_version"] : @0 );
		
		//set api keys
		_apiKeyGodTools					= ( [configDictionary valueForKey:@"godtools_api_key"] ? [configDictionary valueForKey:@"godtools_api_key"] : @"" );
		_apiKeyRollbar					= ( [configDictionary valueForKey:@"rollbar_client_api_key"] ? [configDictionary valueForKey:@"rollbar_client_api_key"] : @"" );
		_apiKeyGoogleAnalytics			= ( [configDictionary valueForKey:@"google_analytics_api_key"] ? [configDictionary valueForKey:@"google_analytics_api_key"] : @"" );
		_apiKeyNewRelic					= ( [configDictionary valueForKey:@"newrelic_api_key"] ? [configDictionary valueForKey:@"newrelic_api_key"] : @"" );

		//set follow api values
        _followUpApiUrl = ([configDictionary valueForKey:@"follow_up_api_url_base"] ? [NSURL URLWithString:[configDictionary valueForKey:@"follow_up_api_url_base"]] : [NSURL URLWithString:@""]);
        
        _followUpApiSharedKey = ([configDictionary valueForKey:@"follow_up_api_shared_key"] ?: @"");

        _followUpApiSecretKey = ([configDictionary valueForKey:@"follow_up_api_secret_key"] ?: @"");
        
        _followUpApiDefaultRouteId = ([configDictionary valueForKey:@"follow_up_api_default_route_id"] ?: @"");

    }
	
    return self;
}

@end
