//
//  ViewController.m
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import "ViewController.h"
#import "DataCollector.h"

@interface ViewController () {
    DataCollector *datacollector;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    datacollector = [[DataCollector alloc]init];
    [datacollector initEngines:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction)startClicked:(id)sender {
    
    [datacollector startCollection];
}


@end
