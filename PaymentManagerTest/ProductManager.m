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
        [_productIds addObject:kProductShowText7days];
        [_productIds addObject:kProductShowText1month];
        
        // 購入状況をNSUserDefaultsから読み込む
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _isRemoveAd = [_userDefaults boolForKey:kProductRemoveAd];
        _points = [_userDefaults integerForKey:kProductIncreasePoints];
        _expiresText = [_userDefaults doubleForKey:kProductShowText];
        
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

- (void) setExpiresText:(double)expiresText {
    _expiresText = expiresText;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setDouble:expiresText forKey:kProductShowText];
    [_userDefaults synchronize];
}

- (BOOL) getIsText {
    // レシート確認
    NSTimeInterval expires = [[PaymentManager sharedInstance] checkReceipt:kProductShowText];
    
    [self setExpiresText:expires];

    
    // 有効期限ログ出し -----------------------------------------------------------------------------------
    // NSTimeIntervalからNSStringへ変換
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    NSString *expiresStr = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:expires]];
    
    NSLog(@"有効期限 : %@", expiresStr);
    // --------------------------------------------------------------------------------------------------
    
    BOOL status;
    // 現在時刻と比較
    if (_expiresText < [[NSDate date] timeIntervalSince1970]) {
        status = NO;
    } else {
        status = YES;
    }
    
    return status;
}

- (void)bought:(NSString *)productIds {
    // 購入されたものをNSUserDefaultsで管理する
    // productIdsでプロダクトを識別
    if ([productIds isEqualToString:kProductRemoveAd]) {
        [self setIsRemoveiAd:YES];
    } else if ([productIds isEqualToString:kProductIncreasePoints]) {
        [self setPoints:_points + 1];
    } else if ([productIds hasPrefix:kProductShowText]) {
        // レシート確認
        NSTimeInterval expires = [[PaymentManager sharedInstance] checkReceipt:kProductShowText];
        
        [self setExpiresText:expires];
        
    }
}

@end
