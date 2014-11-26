//
//  Settings.m
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 27/06/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import "Settings.h"

@interface Settings ()

@end

@implementation Settings

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setContentSizeForViewInPopover:CGSizeMake(320, self.view.frame.size.height)];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    NSString *str=[[NSUserDefaults standardUserDefaults] stringForKey:@"clock/timer"];
    if ([str isEqualToString:@"timer"]) {
        [_mClockTimerSegmentedControl setSelectedSegmentIndex:1];
    }
    else{
        [_mClockTimerSegmentedControl setSelectedSegmentIndex:0];
    }
    int value=[[NSUserDefaults standardUserDefaults] integerForKey:@"channelFrequency"] ;
    NSLog(@"%d",value);
    if (value < 0 || value > 5) {
        [_mSlider setValue:0];
    }
    else{
        [_mSlider setValue:value];
    }
    _mFrequencyLabel.text=[NSString stringWithFormat:@"%d hz",value]; // [NSString stringWithFormat:@"%d %%",value]
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Amplifier"] floatValue]==0.000000f) {
        [_mAmpliflierSlider setValue:0.25];
        _mAmplificationLevel.text=@"1.00";
    }
    else{
        [_mAmpliflierSlider setValue:[[[NSUserDefaults standardUserDefaults] stringForKey:@"Amplifier"] floatValue]];
        _mAmplificationLevel.text=[NSString stringWithFormat:@"%0.02f",[_mAmpliflierSlider value]+.75];
    }
    str=[[NSUserDefaults standardUserDefaults] stringForKey:@"sharp/b"];
    if ([str isEqualToString:@"b"]) {
        [_mSharpBSegmentedControl setSelectedSegmentIndex:1];
    }
    else{
        [_mSharpBSegmentedControl setSelectedSegmentIndex:0];
    }

    [super viewWillAppear:animated];
}


- (IBAction)didTapToSelectClockOrTimer:(id)sender {
    NSLog(@" segment value %d",[sender selectedSegmentIndex]);
    if([(UISegmentedControl *)sender selectedSegmentIndex]==0){
        [[NSUserDefaults standardUserDefaults] setObject:@"clock" forKey:@"clock/timer"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:@"timer" forKey:@"clock/timer"];
    }
}


- (IBAction)sliderChangeValue:(id)sender {
    int val = [(UISlider *)sender value]; //-sliderValue;

    [(UISlider *)sender setValue:val];
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"channelFrequency"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _mFrequencyLabel.text=[NSString stringWithFormat:@"%d hz",val]; // [NSString stringWithFormat:@"%d %%",val]
}

- (IBAction)didTapToChangeAmplification:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",[(UISlider *)sender value]] forKey:@"Amplifier"];
    _mAmplificationLevel.text=[NSString stringWithFormat:@"%0.2f",[_mAmpliflierSlider value]+.75];
}

- (IBAction)didTapToSelectSharpOrB:(id)sender {
    if([(UISegmentedControl *)sender selectedSegmentIndex]==0){
        [[NSUserDefaults standardUserDefaults] setObject:@"sharp" forKey:@"sharp/b"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:@"b" forKey:@"sharp/b"];
    }
    if (_delegate) {
        [self.delegate updateDictionary];
    }
}

- (void)viewDidUnload {
    [self setMClockTimerSegmentedControl:nil];
    [self setMSlider:nil];
    [self setMFrequencyLabel:nil];
    [self setMAmpliflierSlider:nil];
    [self setMAmplificationLevel:nil];
    [self setMSharpBSegmentedControl:nil];
    [super viewDidUnload];
}
@end
