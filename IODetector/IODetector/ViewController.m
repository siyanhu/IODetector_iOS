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
}

@property (nonatomic, strong) IBOutlet UITextView *detailLabel;
@property (nonatomic, strong) IBOutlet UIButton *queryButton;

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
    self.detailLabel.delegate = self;
    datacollector = [[DataCollector alloc]init];
    datacollector.delegate = self;
    [datacollector initEngines:self];
}

- (IBAction)startClicked:(id)sender {
    [self.detailLabel setText:[NSString stringWithFormat:@"%@", @"Start Collection"]];
    [datacollector startCollection];
}

- (IBAction)endClicked:(id)sender {
    [datacollector finishCollection];
    NSString *preText = self.detailLabel.text;
    [self.detailLabel setText:[NSString stringWithFormat:@"%@\n%@",preText, @"End Collection"]];
    
    self.queryButton.hidden = YES;
    self.queryButton.userInteractionEnabled = NO;
}

- (IBAction)queryClicked:(id)sender {
    NSString *id_str = [datacollector phone_App_vendor_ID];
    NSDictionary *paras = [NSDictionary dictionaryWithObjectsAndKeys:
                           id_str, @"userId",
                           id_str, @"devId",
                           nil];
    [[RemoteAccess instance]readFrom:@"http://143.89.145.220:8080/quarloc/client/stateQuery" withParameters:paras success:^(NSData * _Nonnull remoteData) {
        [self showQuery: remoteData];
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

- (void)uploadData:(NSDictionary *)content {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Error msg: %@", error.description);
    } else {
        [[RemoteAccess instance] uploadJSONTo:@"http://143.89.145.220:8080/quarloc/client/report" withContent:jsonData success:^(NSData * _Nonnull response) {
            NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            NSLog(@"Success upload: %@", json_string);
            if ([json_string containsString:@"true"]) {
                [self enableQuery];
            }
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
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Parse Error: %@", error.description);
        } else{
            NSString *preText = self.detailLabel.text;
            [self.detailLabel setText:[NSString stringWithFormat:@"%@\n%@",preText, dict]];
        }
    });
}

#pragma mark - Delegate
- (void)didUpdateData:(NSDictionary *)dataDict {
    if (dataDict) {
        [self uploadData:dataDict];
    }
}

@end
