//
//  ViewController.m
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import "ViewController.h"
#import "DataCollector.h"
#import "RemoteAccess.h"

@interface ViewController () <DataCollectionDelegate, UITextViewDelegate> {
    DataCollector *datacollector;
    NSString *apiSwitch;
}

@property (nonatomic, strong) IBOutlet UITextView *detailLabel;
@property (nonatomic, strong) IBOutlet UIButton *queryButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;

@property (nonatomic, strong) IBOutlet UITextView *bleDetail;
@property (nonatomic, strong) IBOutlet UIButton *bleButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    apiSwitch = @"init";
    self.detailLabel.delegate = self;
    datacollector = [[DataCollector alloc]init];
    datacollector.delegate = self;
    [datacollector initEngines:self];
    [datacollector inputProfile:54287123 globalAddr:@"22.312711,114.1691448"]; //Tel + the longitude latitude of your home addr
    
}

- (IBAction)profileClicked:(id)sender {
    [self submitProfile];
}

- (IBAction)startClicked:(id)sender {
    [self.detailLabel setText:[NSString stringWithFormat:@"%@", @"Start Collection"]];
    [datacollector startCollection];
}

- (IBAction)endClicked:(id)sender {
    [datacollector finishCollection];
    NSString *preText = self.detailLabel.text;
    [self.detailLabel setText:[NSString stringWithFormat:@"%@\n%@",preText, @"End Collection"]];
    
//    self.queryButton.hidden = YES;
//    self.queryButton.userInteractionEnabled = NO;
}

- (IBAction)queryClicked:(id)sender {
    NSString *id_str = [datacollector phone_App_vendor_ID];
    NSDictionary *paras = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:1234567], @"userId",
                           id_str, @"devId",
                           nil];
    [[RemoteAccess instance]readFrom:@"http://143.89.145.220:8080/quarloc/client/stateQuery" withParameters:paras success:^(NSData * _Nonnull remoteData) {
        [self showQuery: remoteData];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Query Error:%@", error.description);
    }];
}

- (void)uploadData:(NSDictionary *)content {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Error msg: %@", error.description);
    } else {
        NSString *url_str = [NSString stringWithFormat:@"%@/%@", @"http://143.89.145.220:8080/quarloc/client", apiSwitch];
        if ([apiSwitch isEqualToString:@"init"]) {
            apiSwitch = @"report";
        }
        [[RemoteAccess instance] uploadJSONTo:url_str withContent:jsonData success:^(NSData * _Nonnull response) {
            NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            NSLog(@"Success upload: %@", json_string);
            if ([json_string containsString:@"true"]) {
                [self enableQuery];
            }
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (void)submitProfile {
    NSError *error = nil;
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"542871235", @"userId",
                          [datacollector phone_App_vendor_ID], @"devId",
                          [NSNumber numberWithDouble: 22.335498], @"spotLatitude",
                          [NSNumber numberWithDouble: 114.263797], @"spotLongitude",
//                          [NSNumber numberWithInteger: 0], @"spotAltitude",
                          nil];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Error msg: %@", error.description);
    } else {
        NSString *url_str = @"http://143.89.145.220:8080/quarloc/api/user/register";
        [[RemoteAccess instance] uploadJSONTo:url_str withContent:jsonData success:^(NSData * _Nonnull response) {
            NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            NSLog(@"Success upload: %@", json_string);
//            if ([json_string containsString:@"true"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.startButton setHidden:NO];
                [self.startButton setUserInteractionEnabled:YES];
            });
//            }
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (void)enableQuery {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.queryButton.hidden) {
            return;
        }
        NSString *preText = self.detailLabel.text;
        [self.detailLabel setText:[NSString stringWithFormat:@"%@\n%@",preText, @"Query Enabled"]];
        [self.queryButton setUserInteractionEnabled:YES];
        [self.queryButton setHidden:NO];
    });
}

- (void)showQuery:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:&error];
    if (error) {
            NSLog(@"Parse Error: %@", error.description);
        } else{
            NSString *preText = self.detailLabel.text;
            [self.detailLabel setText:[NSString stringWithFormat:@"%@\n%@",preText, dict]];
        }
    });
}

- (IBAction)bleClicked:(id)sender {
    [datacollector registerWristBand];
}

#pragma mark - Delegate
- (void)didUpdateData:(NSDictionary *)dataDict {
    if (dataDict) {
//        NSLog(@"%@", dataDict);
        [self uploadData:dataDict];
    }
}

- (void)didUpdateBLE:(NSString *)bleDetail {
    if (bleDetail) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.bleDetail setText:bleDetail];
        });
    }
}

@end
