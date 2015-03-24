//
//  TrainingViewController.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import "TrainingViewController.h"

@interface TrainingViewController ()
{
    ViewController *prevController;
}
@end

@implementation TrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    self.gestures = [NSMutableArray array];
    
}

- (IBAction)createNewGesture:(id)sender {
//    [self.gestures addObject:@"dool"];
            prevController.lalala = @"khar";
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"trainingSegue"]){
        prevController = (ViewController *)segue.destinationController;
    }
}


@end
