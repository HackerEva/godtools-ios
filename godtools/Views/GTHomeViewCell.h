//
//  GTHomeViewCell.h
//  godtools
//
//  Created by Claudin.Bael on 11/6/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTHomeViewCell : UITableViewCell

@property (strong, nonatomic) NSString *sectionIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

-(void) setUpBackground:(int)isEven :(int)isTranslatorMode :(int)isMissingDraft;

@end
