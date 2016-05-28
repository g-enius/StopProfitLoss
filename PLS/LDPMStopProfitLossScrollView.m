//
//  LDPMStopProfitLossScrollView.m
//  PreciousMetals
//
//  Created by wangchao on 9/29/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "LDPMStopProfitLossScrollView.h"
#import "LDPMStopProfitLossProductView.h"
#import "UIImage+NPMUtil.h"
#import "LDPMNjsPosition.h"

NSString * const StopProfitLossProductDidChangedNotification = @"StopProfitLossProductDidChangedNotification";
NSString * const StopProfitLossProductIndexKey = @"StopProfitLossProductIndexKey";

@interface LDPMStopProfitLossScrollView()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray *positionArray;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation LDPMStopProfitLossScrollView

- (void)setContentWithPositionArray:(NSArray *)positionArray defaultWareId:(NSString *)wareId
{
    self.positionArray = positionArray;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(self.positionArray.count * CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight(self.frame));
    NSInteger defaultIndex = 0;
    for (int i = 0; i < self.positionArray.count; i++) {
        LDPMStopProfitLossProductView *xibView = [[NSBundle mainBundle] loadNibNamed:@"LDPMStopProfitLossProductView" owner:self options:nil].firstObject;
        xibView.backgroundColor = [UIColor clearColor];
        xibView.frame = CGRectMake(i * CGRectGetWidth([UIScreen mainScreen].bounds), 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight(self.frame));
        xibView.index = i;
        LDPMNjsPosition *hold = positionArray[i];
        if ([hold.WAREID isEqual:wareId]) {
            defaultIndex = i;
        }
        [xibView initContentWithTradeQueryHold:hold];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:xibView.frame];
        imageView.image = [UIImage imageNamed:@"PLS_scrollView_back.jpg"];
        [self.scrollView addSubview:imageView];
        [self.scrollView addSubview:xibView];
    }
    self.scrollView.delegate = self;
    
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.backgroundColor = [UIColor clearColor];
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.6];
    self.pageControl.numberOfPages = self.positionArray.count;
    CGSize pageControlSize = [self.pageControl sizeForNumberOfPages:self.pageControl.numberOfPages];
    self.pageControl.frame = CGRectMake((CGRectGetWidth(self.frame) - pageControlSize.width) / 2., CGRectGetHeight(self.frame) - 16., pageControlSize.width, 6);
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    
    self.currentPage = defaultIndex;
}

#pragma mark - scrollViewDelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.currentPage = scrollView.contentOffset.x / CGRectGetWidth([UIScreen mainScreen].bounds);
}

#pragma mark - setter

-(void)setCurrentPage:(NSInteger)currentPage
{
    if (_currentPage != currentPage) {
        _currentPage  = currentPage;
        self.pageControl.currentPage = _currentPage;
        CGPoint offset = CGPointZero;
        offset.x = currentPage*CGRectGetWidth([UIScreen mainScreen].bounds);
        _scrollView.contentOffset = offset;
        [[NSNotificationCenter defaultCenter] postNotificationName:StopProfitLossProductDidChangedNotification object:self userInfo:@{StopProfitLossProductIndexKey:@(currentPage)}];
    }
}

@end
