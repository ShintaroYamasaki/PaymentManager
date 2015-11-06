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
        
        // 購入状況をNSUserDefaultsから読み込む
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _isRemoveAd = [_userDefaults boolForKey:kProductRemoveAd];
        _points = [_userDefaults integerForKey:kProductIncreasePoints];
        _isText = [_userDefaults boolForKey:kProductShowText];
        
        // レシートのチェック
        [self checkReceipt];
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

- (void) setIsText:(BOOL)isText {
    _isText = isText;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setInteger:isText forKey:kProductShowText];
    [_userDefaults synchronize];
}


- (void) setIsText {
    // 今現在と有効期限を比較する
    NSDate *datecurrent = [NSDate date];
    double doublecurrent = [datecurrent timeIntervalSince1970];
    NSNumber *current = [[NSNumber alloc] initWithDouble: doublecurrent];
    
    NSNumber *expired = [_userDefaults objectForKey:kProductShowTextExpiresDate];
    
    if (expired && NSOrderedDescending != [current compare:expired]) {
        self.isText = YES;
    } else {
        self.isText = NO;
    }
}

- (int)checkReceipt {
    NSDictionary *dictionary = [[PaymentManager sharedInstance] receiveReceipt];
    
    NSNumber *status = [dictionary objectForKey:@"status"];
    
    // ステータスデータの確認
    if (![status isEqual:[NSNumber numberWithInt:0]] &&
        ![status isEqual:[NSNumber numberWithInt:21006]]) {
        return [status intValue];
    }
    
    // 定期購読の期限の保存と最新のレシートの保存
    NSDictionary *receiptDictionary = [dictionary objectForKey:@"receipt"];
    NSArray *appReceipts = [receiptDictionary objectForKey:@"in_app"];
    NSDictionary *appReceipt = [appReceipts lastObject];
    // 有効期限
    NSString *strExperies = [appReceipt objectForKey:@"expires_date_ms"];
    NSNumber *experiesDate = [NSNumber numberWithLong: [strExperies longLongValue] / 1000];
    NSString *productId = [appReceipt objectForKey:@"product_id"];
    
    if (([productId isEqualToString:kProductShowText7days])) {
        [_userDefaults setObject:experiesDate
                          forKey:kProductShowTextExpiresDate];
    }
    return 0;
}


- (void)bought:(NSString *)productIds {
    // 購入されたものをNSUserDefaultsで管理する
    // productIdsでプロダクトを識別
    if ([productIds isEqualToString:kProductRemoveAd]) {
        [self setIsRemoveiAd:YES];
    } else if ([productIds isEqualToString:kProductIncreasePoints]) {
        [self setPoints:_points + 1];
    } else if ([productIds isEqualToString:kProductShowText7days]) {
        // レシート確認
        [self checkReceipt];
        
        [self setIsText];
    }
}

@end
