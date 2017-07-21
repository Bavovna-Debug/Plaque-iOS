//
//  Plaque'n'Play
//
//  Copyright © 2014-2017 Meine Werke. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#import "AppStore.h"
#import "Definitions.h"

@interface AppStore () <SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate>

@property (nonatomic, assign, readwrite)  BOOL appUnlocked;

@property (nonatomic, strong)             SKProduct *selectedProduct;

@end

@implementation AppStore

+ (AppStore *)sharedAppStore
{
    static dispatch_once_t onceToken;
    static AppStore *appStore;

    dispatch_once(&onceToken, ^
    {
        appStore = [[AppStore alloc] init];
    });

#ifdef DEBUG
    NSDictionary* dict = [appStore getStoreReceipt:YES];
    for (NSString* key in dict)
    {
        id value = [dict objectForKey:key];
        NSLog(@"[AppStore] %@ %@", key, value);
    }
#endif

    return appStore;
}

- (void)purchaseFortification
{
    if ([SKPaymentQueue canMakePayments] == NO)
    {
        NSString *message = NSLocalizedString(@"APP_STORE_ERROR_MESSAGE", nil);
        NSString *okButton = NSLocalizedString(@"ALERT_BUTTON_OK", nil);

        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:nil
                                   message:message
                                  delegate:self
                         cancelButtonTitle:okButton
                         otherButtonTitles:nil];

        [alertView setAlertViewStyle:UIAlertViewStyleDefault];
        [alertView show];

        return;
    }

    NSSet *productIdentifiers = [NSSet setWithObject:ProductIdentifier1DMAQ];

    SKProductsRequest *productsRequest =
    [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];

    [productsRequest setDelegate:self];
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    if ([response.products count] == 0)
    {
        return;
    }

    self.selectedProduct = [response.products objectAtIndex:0];

    NSLocale *priceLocale = [self.selectedProduct priceLocale];

    NSDecimalNumber *price = [self.selectedProduct price];

    NSString *description = [self.selectedProduct localizedDescription];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:priceLocale];

    NSString *cancelButton = NSLocalizedString(@"APP_STORE_NOT_YET", nil);
    NSString *submitButton = NSLocalizedString(@"APP_STORE_BUY_NOW", nil);
    submitButton = [NSString stringWithFormat:submitButton, [formatter stringFromNumber:price]];

    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:nil
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
        if (SKPaymentTransactionStateRestored)
        {
            [self dmaqPurchased];

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
            {
                NSLog(@"[AppStore] Transaction state -> Purchasing");

                break;
            }

            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"[AppStore] Transaction state -> Purchased");

                [self dmaqPurchased];

                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
            }

            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"[AppStore] Transaction state -> Restored");

                [self dmaqPurchased];

                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
            }

            case SKPaymentTransactionStateFailed:
            {
                if ((transaction.error != nil) && (transaction.error.code != SKErrorPaymentCancelled))
                {
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }

                NSLog(@"[AppStore] Transaction state -> Failed (%ld)",
                      (long) transaction.error.code);

                break;
            }

            case SKPaymentTransactionStateDeferred:
            {
                NSLog(@"[AppStore] Transaction state -> Deferred (%ld)",
                      (long) transaction.error.code);

                break;
            }
        }
    }

    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSLog(@"[AppStore] Receipt URL: %@",
          [receiptUrl path]);

    NSData *receiptData = [[NSData alloc] initWithContentsOfURL:receiptUrl];
    NSLog(@"[AppStore] Receipt data: %@",
          [receiptData base64EncodedStringWithOptions:0]);
}

- (void)dmaqPurchased
{
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(dmaqPurchased)])
    {
        [self.delegate dmaqPurchased];
    }
}

#pragma mark - Alert

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:self.selectedProduct];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark - TEST

#ifdef DEBUG

- (NSDictionary *)getStoreReceipt:(BOOL)sandbox
{

    NSArray *objects;
    NSArray *keys;
    NSDictionary *dictionary;

    BOOL gotreceipt = false;

    @try
    {
        NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[receiptUrl path]])
        {
            NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];

            //NSString *receiptString = [self base64forData:receiptData];
            NSString *receiptString =
            [NSString stringWithContentsOfFile:[receiptUrl path]
                                  usedEncoding:nil
                                         error:NULL];
            if (receiptString != nil)
            {
                objects = [[NSArray alloc] initWithObjects:receiptString, nil];
                keys = [[NSArray alloc] initWithObjects:@"receipt-data", nil];
                dictionary = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];

                //NSString *postData = [self getJsonStringFromDictionary:dictionary];
                NSError *error;
                NSData *ZpostData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:&error];

                NSString *postData = [NSString stringWithUTF8String:ZpostData.bytes];

                NSString *urlSting = @"https://buy.itunes.apple.com/verifyReceipt";
                if (sandbox)
                {
                    urlSting = @"https://sandbox.itunes.apple.com/verifyReceipt";
                }

                dictionary = [self getJsonDictionaryWithPostFromUrlString:urlSting andDataString:postData];

                if ([dictionary objectForKey:@"status"] != nil)
                {
                    if ([[dictionary objectForKey:@"status"] intValue] == 0)
                    {
                        gotreceipt = true;
                    }
                }
            }
        }

    }
    @catch (NSException * e)
    {
        gotreceipt = false;
    }

    if (!gotreceipt)
    {
        objects = [[NSArray alloc] initWithObjects:@"-1", nil];
        keys = [[NSArray alloc] initWithObjects:@"status", nil];

        dictionary = [[NSDictionary alloc] initWithObjects:objects
                                                   forKeys:keys];
    }

    return dictionary;
}



- (NSDictionary *)getJsonDictionaryWithPostFromUrlString:(NSString *)urlString
                                           andDataString:(NSString *)dataString
{
    NSString *jsonString = [self getStringWithPostFromUrlString:urlString
                                                  andDataString:dataString];

    NSLog(@"[AppStore] %@", jsonString); // see what the response looks like

    return [self getDictionaryFromJsonString:jsonString];
}


- (NSDictionary *)getDictionaryFromJsonString:(NSString *)jsonstring
{
    NSError *jsonError;
    NSDictionary *dictionary =
    (NSDictionary *) [NSJSONSerialization JSONObjectWithData:[jsonstring dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:0
                                                       error:&jsonError];

    if (jsonError)
    {
        dictionary = [[NSDictionary alloc] init];
    }

    return dictionary;
}


- (NSString *)getStringWithPostFromUrlString:(NSString *)urlString
                               andDataString:(NSString *)dataString
{
    NSString *s = @"";

    @try
    {
        NSData *postdata = [dataString dataUsingEncoding:NSASCIIStringEncoding
                                    allowLossyConversion:YES];

        NSString *postlength = [NSString stringWithFormat:@"%d",
                                [postdata length]];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setTimeoutInterval:60];
        [request setHTTPMethod:@"POST"];

        [request setValue:postlength
       forHTTPHeaderField:@"Content-Length"];

        [request setValue:@"application/x-www-form-urlencoded"
       forHTTPHeaderField:@"Content-Type"];

        [request setHTTPBody:postdata];

        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:nil
                                                         error:nil];
        if (data != nil)
        {
            s = [[NSString alloc] initWithData:data
                                      encoding:NSUTF8StringEncoding];
        }
    }
    @catch (NSException *exception)
    {
        s = @"";
    }
    return s;
}


// from http://stackoverflow.com/questions/2197362/converting-nsdata-to-base64
- (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*) [theData bytes];

    NSInteger length = [theData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

    uint8_t* output = (uint8_t *) data.mutableBytes;

    NSInteger i;
    for (i = 0; i < length; i += 3)
    {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++)
        {
            value <<= 8;
            
            if (j < length)
            {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

#endif

@end
