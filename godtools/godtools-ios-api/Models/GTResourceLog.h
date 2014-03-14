//
//  GTResourceLog.h
//  godtools
//
//  Created by Michael Harrison on 3/14/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GTPackage;

@interface GTResourceLog : NSManagedObject

@property (nonatomic, retain) NSNumber * currentInterpreterVersion;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSManagedObject *currentLanguage;
@property (nonatomic, retain) GTPackage *currentPackage;
@property (nonatomic, retain) NSManagedObject *currentParallelLanguage;
@property (nonatomic, retain) NSSet *languages;
@property (nonatomic, retain) NSSet *packages;
@end

@interface GTResourceLog (CoreDataGeneratedAccessors)

- (void)addLanguagesObject:(NSManagedObject *)value;
- (void)removeLanguagesObject:(NSManagedObject *)value;
- (void)addLanguages:(NSSet *)values;
- (void)removeLanguages:(NSSet *)values;

- (void)addPackagesObject:(GTPackage *)value;
- (void)removePackagesObject:(GTPackage *)value;
- (void)addPackages:(NSSet *)values;
- (void)removePackages:(NSSet *)values;

@end
