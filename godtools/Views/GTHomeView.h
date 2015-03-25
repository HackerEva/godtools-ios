//
//  GTHomeView.h
//  godtools
//
//  Created by Claudine Bael on 11/14/14.
//  Copyright (c) 2014 Michael Harrison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTBaseView.h"
@protocol GTHomeViewDelegate <NSObject>
@required
-(void)settingsButtonPressed;
-(void)refreshDraftsButtonDragged;
@end


@interface GTHomeView : GTBaseView

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) id<GTHomeViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *translatorModeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UILabel *refreshDraftsLabel;
@property (weak, nonatomic) IBOutlet UIButton *refreshDraftsButton;

- (IBAction)settingsButtonPressed:(id)sender;
- (IBAction)refreshDraftsButtonDragged:(id)sender;
@end
