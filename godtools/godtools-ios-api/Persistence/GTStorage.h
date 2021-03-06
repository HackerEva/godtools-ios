//
//  GTStorage.h
//  godtools
//
//  Created by Michael Harrison on 3/21/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import "CRUStorage.h"
#import "GTStorageErrorHandler.h"
#import "GTLanguage.h"

/**
 *  Core Data Stack configured for God Tools.
 *  Subclass of CRUStorage, a Core Data stack designed for normal use an background importing.
 */
@interface GTStorage : CRUStorage

/**
 *  Singleton of GTStorage.
 *
 *  @return Configured Singleton
 */
+ (instancetype)sharedStorage;

/**
 *  Initializer that configures the Storage stack based on method parameters.
 *
 *  @param storeURL     URL of sqlite file. Usually you put it in the Application Documents folder. This method will create it if it doesn't exist.
 *  @param storeType	the type of store that will back this core data stack. The options are the following constants defined in NSPersistentStoreCoordinator: NSSQLiteStoreType, NSBinaryStoreType or NSInMemoryStoreType. NSSQLiteStoreType is default.
 *  @param modelURL     URL of managed object model file. Usually apart of the main bundle.
 *  @param shared       determines whether each context gets its own store coordinator or whether they share a store coordinator. Refer to CRUStorage initalizer for more details
 *  @param errorHandler Error handler, used by class to display errors that occur in its use.
 *
 *  @return configured storage object
 */
- (id)initWithStoreURL:(NSURL*)storeURL storeType:(NSString *)storeType modelURL:(NSURL*)modelURL contextsSharePersistentStoreCoordinator:(BOOL)shared errorHandler:(GTStorageErrorHandler *)errorHandler;

/**
 *  Error handler, used by class to display errors that occur in its use.
 */
@property (nonatomic, strong, readonly) GTStorageErrorHandler *errorHandler;

/**
 *  Grab array of models from the Persistent Store
    @param modelType  Class of object you want to grab (assumes Class name matches CoreData Entity name)
 *  @param background determines if it will be run on the background context (using its background queue) or the main context (using the main thread)
 *
 *  @example [myStorage fetchArrayOfModels:[Book class] inBackground:YES];
 *  This would search in the background for all the books .
 *
 *  @return array of models
 */
- (NSArray *)fetchArrayOfModels:(Class)modelType inBackground:(BOOL)background ;

/**
 *  Grab a specific object of model from the Persistent Store
 @param modelType  Class of object you want to grab (assumes Class name matches CoreData Entity name)
 *  @param background determines if it will be run on the background context (using its background queue) or the main context (using the main thread)
 *
 *  @example [myStorage fetchModel:[Book class] usingKey:@"title" forValue:@"Narnia" inBackground:(BOOL)backgroundinBackground:YES];
 *  This would search in the background for all the books with a title of Narnia.
 *
 *  @return array of models
 */
- (NSArray *)fetchModel:(Class)modelType usingKey:(NSString *)key forValue:(NSString *)value inBackground:(BOOL)background;

- (GTLanguage *)languageWithCode:(NSString *)languageCode;
- (GTLanguage *)findClosestLanguageTo:(NSString *)languageCode;

@end
