//
//  NPMStopProfitLossViewController.h
//  PreciousMetals
//
//  Created by ypchen on 11/20/14.
//  Copyright (c) 2014 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NPMServiceResponse;
extern NSString * const StopProfitLossProductUpdatedNotification;
extern NSString * const StopProfitLossProductKey;

@interface NPMStopProfitLossViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL isNeedNetErrorAlert;
@property (strong, nonatomic) NSMutableArray *positionArray;

@property (nonatomic,copy) NSString *defaultWareId;
@property (nonatomic, strong) NSString *partnerId; //必需：交易所id

- (void)showEmptyView:(BOOL)type;
- (void)refreshLimitData;
- (void)alertWithResponse:(NPMServiceResponse *)response;
@end
