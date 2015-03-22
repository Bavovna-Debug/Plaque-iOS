//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#import "AppStore.h"

@interface AppStore () <SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate>

@property (nonatomic, strong) SKProduct *gameUnlockProduct;

@end

@implementation AppStore

+ (AppStore *)sharedAppStore
{
    static dispatch_once_t onceToken;
    static AppStore *appStore;

    dispatch_once(&onceToken, ^{
        appStore = [[AppStore alloc] init];
    });

    return appStore;
}
/*
#define RemoveAdsProductIdentifier  @"Zeppelinium.Plaque.Unlock"

- (void)purchaseUnlock
{
    if ([SKPaymentQueue canMakePayments] == NO)
    {
        NSString *message = NSLocalizedString(@"APP_STORE_ERROR_MESSAGE", nil);
        NSString *okButton = NSLocalizedString(@"ALERT_BUTTON_OK", nil);

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:okButton
                                                  otherButtonTitles:nil];

        [alertView setAlertViewStyle:UIAlertViewStyleDefault];
        [alertView show];

        return;
    }

    NSSet *productIdentifiers = [NSSet setWithObject:RemoveAdsProductIdentifier];

    SKProductsRequest *productsRequest =
    [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];

    [productsRequest setDelegate:self];
    [productsRequest start];
}

- (void)restorePurchasedUnlock
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    if ([response.products count] == 0)
        return;

    self.gameUnlockProduct = [response.products objectAtIndex:0];

    NSLocale *priceLocale = [self.gameUnlockProduct priceLocale];
    NSDecimalNumber *price = [self.gameUnlockProduct price];
    NSString *description = [self.gameUnlockProduct localizedDescription];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:priceLocale];

    NSString *cancelButton = NSLocalizedString(@"APP_STORE_NOT_YET", nil);
    NSString *submitButton = NSLocalizedString(@"APP_STORE_BUY_NOW", nil);
    submitButton = [NSString stringWithFormat:submitButton, [formatter stringFromNumber:price]];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:description
                                                       delegate:self
                                              cancelButtonTitle:cancelButton
                                              otherButtonTitles:submitButton, nil];

    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        if (SKPaymentTransactionStateRestored) {
            [self doUnlock];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Transaction state -> Purchasing");
                break;

            case SKPaymentTransactionStatePurchased:
                NSLog(@"Transaction state -> Purchased");
                [self doUnlock];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;

            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                [self doUnlock];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    NSLog(@"Transaction state -> Cancelled");
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Transaction state -> Deferred");
                break;
        }
    }
}

- (void)doUnlock
{
    [self setGameUnlocked:YES];
    
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(gameWasUnlocked)])
        [self.delegate gameWasUnlocked];
}

#pragma mark - Alert

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:self.gameUnlockProduct];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}
*/

@end
