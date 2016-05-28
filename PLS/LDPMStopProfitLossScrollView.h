//
//  LDPMStopProfitLossScrollView.h
//  PreciousMetals
//
//  Created by wangchao on 9/29/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const StopProfitLossProductDidChangedNotification;
extern NSString * const StopProfitLossProductIndexKey;

@interface LDPMStopProfitLossScrollView : UIView

- (void)setContentWithPositionArray:(NSArray *)positionArray defaultWareId:(NSString *)wareId;

@end
