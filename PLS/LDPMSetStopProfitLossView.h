//
//  LDPMSetStopProfitLossView.h
//  PreciousMetals
//
//  Created by wangchao on 15/10/4.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, stopProfitLossType) {
    stopProfitLossTypeProfit,
    stopProfitLossTypeLoss
};

@interface LDPMSetStopProfitLossView : UIView

@property (assign, nonatomic) double price;
@property (copy, nonatomic, readonly) NSString *profitString;
@property (copy, nonatomic, readonly) NSString *profitInfoString;
@property (strong, nonatomic, readonly) UIColor *profitLableColor;

@property (assign, nonatomic) stopProfitLossType type;
@property (assign, nonatomic) BOOL isEnabled;

@end
