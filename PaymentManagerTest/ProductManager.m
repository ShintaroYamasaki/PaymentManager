//
//  Product.m
//  PaymentManagerTest
//
//  Created by user on 2014/10/30.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import "ProductManager.h"

@implementation ProductManager

+ (ProductManager *)sharedInstance {
    static ProductManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[ProductManager alloc] init];
    });
    return _sharedInstance;
}

- (id) init {
    self = [super init];
    
    if (self != nil) {
        // プロダクトID一覧を作成
        _productIds = [[NSMutableSet alloc] init];
        [_productIds addObject:kProductRemoveAd];
        [_productIds addObject:kProductIncreasePoints];
        
        // 購入状況をNSUserDefaultsから読み込む
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _isRemoveAd = [_userDefaults boolForKey:kProductRemoveAd];
        _points = [_userDefaults integerForKey:kProductIncreasePoints];
    }
    
    return self;
}

- (void) setIsRemoveiAd:(BOOL)isRemoveAd {
    _isRemoveAd = isRemoveAd;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setBool:isRemoveAd forKey:kProductRemoveAd];
    [_userDefaults synchronize];
}

- (void) setPoints:(NSInteger)points {
    _points = points;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setInteger:points forKey:kProductIncreasePoints];
    [_userDefaults synchronize];
}

- (void)bought:(NSString *)productIds {
    // 購入されたものをNSUserDefaultsで管理する
    // productIdsでプロダクトを識別
    if ([productIds isEqualToString:kProductRemoveAd]) {
        [self setIsRemoveiAd:YES];
    } else if ([productIds isEqualToString:kProductIncreasePoints]) {
        [self setPoints:_points + 1];
    }
}

@end
