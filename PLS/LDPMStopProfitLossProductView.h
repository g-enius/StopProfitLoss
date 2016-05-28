//
//  LDPMStopProfitLossProductView.h
//  PreciousMetals
//
//  Created by wangchao on 9/29/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LDPMNjsPosition;

@interface LDPMStopProfitLossProductView : UIView

@property (assign, nonatomic) int index;

- (void)initContentWithTradeQueryHold:(LDPMNjsPosition *)hold;

@end
