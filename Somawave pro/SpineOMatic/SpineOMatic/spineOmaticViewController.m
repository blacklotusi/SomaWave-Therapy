//
//  spineOmaticViewController.m
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 07/10/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

/*
 playModes
 1 -> Tone
 3 -> Smooth
 4 -> Semi
 5 -> Whole
 6 -> Octave
 */

#import "spineOmaticViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SaveLoad.h"
#import "Settings.h"

@interface spineOmaticViewController ()
{
    int   isChangeModeOnFly;
    BOOL isLoading;
}
@end

#pragma mark------------------Frequency Generation-------------------
#pragma mark Rendering frequency

OSStatus RenderToneStereoMono(
                              void *inRefCon,
                              AudioUnitRenderActionFlags 	*ioActionFlags,
                              const AudioTimeStamp 		*inTimeStamp,
                              UInt32 						inBusNumber,
                              UInt32 						inNumberFrames,
                              AudioBufferList 			*ioData)

{
    // Fixed amplitude is good enough for our purposes
    
    float amplifierValue;
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Amplifier"] floatValue]==0.000000f) {
        amplifierValue=0.25;
    }
    else{
        amplifierValue = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Amplifier"] floatValue];
    }
    const double amplitude=amplifierValue;
    
    float value=[[[NSUserDefaults standardUserDefaults] stringForKey:@"channelFrequency"] floatValue] ;
    
    // Get the tone parameters out of the view controller
    spineOmaticViewController *viewController =
    (__bridge spineOmaticViewController *)inRefCon;
    double theta1 = viewController->theta1;
    double theta1_increment;
    if (viewController->isStereo == YES) {
        theta1_increment = 2.0 * M_PI * (viewController->frequency - (value)) / viewController->sampleRate;
    }
    else{
        theta1_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    }
    
    // This is a mono tone generator so we only need the first buffer
    const int channel1= 0;
    Float32 *buffer1 = (Float32 *)ioData->mBuffers[channel1].mData;
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer1[frame] = sin(theta1) * amplitude;
        
        theta1 += theta1_increment;
        if (theta1 > 2.0 * M_PI)
        {
            theta1 -= 2.0 * M_PI;
        }
    }
    viewController->theta1 = theta1;
    if (viewController->isStereo == YES) {
        double theta2 = viewController->theta2;
        double theta2_increment = 2.0 * M_PI * (viewController->frequency+(value)) / viewController->sampleRate;
        const int channel2 = 1;
        Float32 *buffer2 = (Float32 *)ioData->mBuffers[channel2].mData;
        
        for (UInt32 frame = 0; frame < inNumberFrames; frame++)
        {
            buffer2[frame] = sin(theta2) * amplitude;
            
            theta2 += theta2_increment;
            if (theta2 > 2.0 * M_PI)
            {
                theta2 -= 2.0 * M_PI;
            }
        }
        
        // Store the theta back in the view controller
        viewController->theta2 = theta2;
    }
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    spineOmaticViewController *viewController =
    (__bridge spineOmaticViewController *)inClientData;
    
    [viewController stop];
}

@implementation spineOmaticViewController

- (void)viewDidLoad
{
    
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    isLoading = NO;
    //----modified subhra-----//
    isChangeModeOnFly=0;
    //------end---------//
    
    
    
    
    frequency = [_frequencySlider value];
    sampleRate = 44100;
    isStereo = YES;
    isNote = NO;
    isSavePossible = NO;
    [self setMaximumFrequency];
    [self checkMonoSteroButton];
    _mPopUpImageview.hidden = YES;
    _mPopupLabel.hidden = YES;
    _mSweepMenuView.hidden = YES;
    // Tone Mode Menu
    self.mMenuView.hidden = YES;
    playMode = @"1";
    noteDictionary = [NSMutableDictionary dictionaryWithDictionary:[[[NSUserDefaults standardUserDefaults] objectForKey:@"SharpDictionary"] objectForKey:@"note"]];
    hertzDictionary = [NSMutableDictionary dictionaryWithDictionary:[[[NSUserDefaults standardUserDefaults] objectForKey:@"SharpDictionary"] objectForKey:@"hertz"]];
    totalFrequencyArray=[[NSMutableArray alloc] initWithObjects:@"32.7",@"34.65",@"36.71",@"38.89",@"41.2",@"43.65",@"46.25",@"49",@"51.91",@"55",@"58.27",@"61.74", @"65.41", @"69.3", @"73.42",@"77.78",@"82.41",@"87.31",@"92.5",@"98",@"103.83",@"110",@"116.54",@"123.47",@"130.81",@"138.59",@"146.83",@"155.56",@"164.81",@"174.61",@"185",@"196",@"207.65",@"220",@"233.08",@"246.94", nil];
    semiSweepArray=[[NSMutableArray alloc] initWithObjects:@"32.7",@"34.65",@"36.71",@"38.89",@"41.2",@"43.65",@"46.25",@"49",@"51.91",@"55",@"58.27",@"61.74",@"65.41", nil];
    wholeSweepArray=[[NSMutableArray alloc] initWithObjects:@"32.7",@"36.71",@"41.2",@"46.25",@"51.91",@"58.27",@"65.41", nil];
    //octaveSweepArray=[[NSMutableArray alloc] initWithObjects:@"32.7",@"65.41",@"130.81", nil];
    monoTimeArray=[[NSMutableArray alloc] initWithObjects:@"10 sec",@"20 sec",@"30 sec",@"40 sec",@"50 sec",@"1 min",@"2 min",@"3 min",@"4 min",@"5 min", nil];
    stereoTimeArray=[[NSMutableArray alloc] initWithObjects:@"1 min",@"2 min",@"3 min",@"4 min",@"5 min",@"10 min",@"15 min",@"20 min",@"25 min",@"30 min",@"40 min",@"50 min",@"60 min", nil];
    timeSlot = 4;
    //_mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
    _mTimeLabel.text = [stereoTimeArray objectAtIndex:timeSlot];
    noteArray = [[NSArray alloc] initWithObjects: @"C1",@"C#1",@"D1",@"D#1",@"E1",@"F1",@"F#1",@"G1",@"G#1",@"A1",@"A#1",@"B1",@"C2",@"C#2",@"D2",@"D#2",@"E2",@"F2",@"F#2",@"G2",@"G#2",@"A2",@"A#2",@"B2",@"C3",@"C#3",@"D3",@"D#3",@"E3",@"F3",@"F#3",@"G3",@"G#3",@"A3",@"A#3",@"B3", nil];
    [_frequencySlider setMinimumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    [_frequencySlider setMaximumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    //[_lowerFrequencySlider setMinimumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    //[_lowerFrequencySlider setMaximumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    //[_upperFrequencySlider setMinimumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    //[_upperFrequencySlider setMaximumTrackImage:[UIImage imageNamed:@"sliderblank.png"] forState:UIControlStateNormal];
    [_frequencySlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateNormal];
    [_frequencySlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateSelected];
    [_frequencySlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateHighlighted];
    [_frequencySlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateApplication];
    //[_lowerFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateNormal];
    //[_lowerFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateSelected];
    //[_lowerFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateHighlighted];
    //[_lowerFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateApplication];
    //[_upperFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateNormal];
    //[_upperFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateSelected];
    //[_upperFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateHighlighted];
    //[_upperFrequencySlider setThumbImage:[UIImage imageNamed:@"circle.png"] forState:UIControlStateApplication];
    _frequencySlider.delegate = (id)self;
    //_lowerFrequencySlider.delegate = (id)self;
    //_upperFrequencySlider.delegate = (id)self;
    
    
    
    hertzArray = [[NSMutableArray alloc] initWithCapacity:215];
    
    int stereoCount = 33;
    for (int stereoi=0; stereoi<=214; stereoi++) {
        //NSLog(@"%d %d", stereoi, stereoCount);
        hertzArray[stereoi] = [NSNumber numberWithInt:stereoCount++];
    }
    
    _lowerFrequencyPicker.delegate = (id)self;
    _upperFrequencyPicker.delegate = (id)self;
    
    
    
    _thumbTextField.userInteractionEnabled = NO;
    //_lowerFrequencyTextField.userInteractionEnabled = NO;
    //_upperFrequencyTextField.userInteractionEnabled = NO;
    //_upperFrequencySlider.tag = 999;
    //[self resizeSlider:_lowerFrequencySlider];
    //[self resizeSlider:_upperFrequencySlider];
    
    
    
    //_upperFrequencyPicker
    //[_upperFrequencyPicker selectRow:upperFrequencyValues.count-1 inComponent:0 animated:YES];
    
    //[self setTextFieldPosition:_lowerFrequencyTextField];
    //[self setTextFieldPosition:_upperFrequencyTextField];
    [self setTextFieldPosition:_thumbTextField];
    _thumbTextField.text = [NSString stringWithFormat:@"%0.f",[_frequencySlider value]];
    //_lowerFrequencyTextField.text = [NSString stringWithFormat:@"%0.f",[_lowerFrequencySlider value]];
    //_upperFrequencyTextField.text = [NSString stringWithFormat:@"%0.f",[_upperFrequencySlider value]];
    slot = 1;
    [self loadSlotDetails];
    [self checkPlayMode];
    slaceTimer = 0;
    dateFormatter = [[NSDateFormatter alloc] init] ;
    clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCurrentTime) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view, typically from a nib.
    
    //--------Modified by subhra---------//
    
    self.mNoteHzSwitch.onText=@"";
    self.mNoteHzSwitch.offText=@"";
    
    //maxUpperSliderX = _upperFrequencySlider.frame.origin.x;
    
    //[_upperFrequencyPicker selectRow:[hertzDictionary count]-1 inComponent:0 animated:NO];
    
    [_frequencySlider setValue:33.0];
    _thumbTextField.text = @"33";
    [self setTextFieldPosition:_thumbTextField];
    
    /*
     timeSlot = 9;
     _mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
     */
    
    [_upperFrequencyPicker selectRow:32 inComponent:0 animated:NO];
    
    
    [_frequencySlider setMinimumValue:33.0];
    [_frequencySlider setMaximumValue:65.0];
    
    
    //NSLog(@"%d", [hertzDictionary count]);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark ---------------Slider-------------
#pragma mark slider thumb position detection

- (float)xPositionFromSliderValue:(UISlider *)aSlider;
{
    
    float sliderRange = aSlider.frame.size.width - aSlider.currentThumbImage.size.width;
    float sliderOrigin = aSlider.frame.origin.x + (aSlider.currentThumbImage.size.width / 2.0);
    
    NSLog(@"paddy3 %f %f", aSlider.maximumValue, aSlider.minimumValue);
    NSLog(@"val %f", aSlider.value);
    
    NSLog(@"timeslot %d %@", timeSlot, [stereoTimeArray objectAtIndex:timeSlot]);
    float nanIssueHandler = (aSlider.maximumValue - aSlider.minimumValue); //by Paddy the awesome
    if (nanIssueHandler <= 0.01) {
        NSLog(@"NANNNNNNANANANANAN");
        //        nanIssueHandler = 0.02f;
    }
    
    float sliderValueToPixels = (( (aSlider.value - aSlider.minimumValue) / nanIssueHandler ) * sliderRange) + sliderOrigin;
    
    //NSLog(@"paddy2 %f %f %f %f", sliderRange, sliderOrigin, sliderValueToPixels, (aSlider.maximumValue-aSlider.minimumValue));
    
    return sliderValueToPixels;
    
}




# pragma picker view methods

#pragma mark -
#pragma mark PickerView Delegate


// amt columns
- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

// amt rows
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    
    if (isStereo) {
        if (isNote) {
            return 13;
        } else {
            return 33; //65-33
        }
    } else {
        if (isNote) {
            return [hertzDictionary allValues].count;
        } else {
            return 215; //247-33
        }
        
    }
    
}


// contents
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    NSArray *keys, *sortedArray;
    
    [[pickerView.subviews objectAtIndex:1] setHidden:TRUE];
    [[pickerView.subviews objectAtIndex:2] setHidden:TRUE];
    
    if (isNote) {
        keys = [noteDictionary allValues];
        
        // sort array block
        sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            //NSLog(@"%@ andddd %@",[hertzDictionary valueForKey:obj1], [hertzDictionary valueForKey:obj2]);
            if ([[hertzDictionary valueForKey:obj1]  floatValue] > [[hertzDictionary valueForKey:obj2] floatValue])
                return NSOrderedDescending;
            else if ([[hertzDictionary valueForKey:obj1] floatValue] < [[hertzDictionary valueForKey:obj2] floatValue])
                return NSOrderedAscending;
            return NSOrderedSame;
        }];
        
        return [sortedArray objectAtIndex:row];
        
        
        
    } else {
        return [[hertzArray objectAtIndex:row] stringValue];
        
    }
    
}

// select
-(void)pickerView:(UIPickerView *)pickerView
     didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    
    float val;
    
    NSString *pickerStringVal = @"33.0";
    
    if (pickerView == _lowerFrequencyPicker) {
        
        
        int lastrow;
        if (isNote) {
            if (isStereo) {
                lastrow = 12;
            } else {
                lastrow=[[hertzDictionary allKeys] count] - 1;
            }
        } else {
            if (isStereo) {
                lastrow = 32;
            } else {
                lastrow = 214;
            }
        }
        
        NSLog(@"%ld and %d", (long)[_lowerFrequencyPicker selectedRowInComponent:0], lastrow);
        NSLog(@"hiiii");
        if ([_lowerFrequencyPicker selectedRowInComponent:0] >= lastrow) {
            [_lowerFrequencyPicker selectRow:lastrow-1 inComponent:0 animated:YES];
        }
        
        if (row >= [_upperFrequencyPicker selectedRowInComponent:0]) {
            [self fixPickerValues:_upperFrequencyPicker];
            
            //[self fixSliderValue];
            
        }
        
        
        if (isNote) {
            [_frequencySlider setMinimumValue:[[hertzDictionary valueForKey:[noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]]] floatValue]];
        } else {
            float myfloat = (float)[_lowerFrequencyPicker selectedRowInComponent:0] + 33.0;
            [_frequencySlider setMinimumValue:myfloat];
        }
        
        
    } else if (pickerView == _upperFrequencyPicker) {
        
        if (row <= 0) {
            [_upperFrequencyPicker selectRow:1 inComponent:0 animated:YES];
        }
        
        
        if ([_upperFrequencyPicker selectedRowInComponent:0] <= [_lowerFrequencyPicker selectedRowInComponent:0]) {
            [self fixPickerValues:_lowerFrequencyPicker];
        }
        
        if (isNote) {
            [_frequencySlider setMaximumValue:[[hertzDictionary valueForKey:[noteArray objectAtIndex:[_upperFrequencyPicker selectedRowInComponent:0]]] floatValue]];
        } else {
            float myfloat = (float)[_upperFrequencyPicker selectedRowInComponent:0] + 33.0;
            [_frequencySlider setMaximumValue:myfloat];
        }
        
    }
    
    
    // fix slider value when any picker is moved
    [self fixSliderValue];
    
    NSLog(@"got hereee");

    [self setTextFieldPosition:_thumbTextField];
    
}



-(void)movePickerUpOrDown : (UIPickerView *)picker row: (int)row
{
    /*
     
     NSArray *keys = [dict allKeys];
     id aKey = [keys objectAtIndex:0];
     id anObject = [dict objectForKey:aKey];
     */
    
    if (picker == _lowerFrequencyPicker) {
        int lastIndex;
        if (isNote)  {
            if (isStereo) {
                lastIndex = 12;
            } else {
                lastIndex = [noteDictionary allValues].count-1;
            }
        } else {
            if (isStereo) {
                lastIndex = 32;
            } else {
                lastIndex = 214;
            }
        }
        if (row == lastIndex) {
            [picker selectRow:lastIndex-1 inComponent:0 animated:YES];
        }
    } else if (picker == _upperFrequencyPicker) {
        if (row == 0) {
            [picker selectRow:1 inComponent:0 animated:YES];
        }
    }
}

-(NSString *)getHertzValueAtRow : (int)row
{
    NSArray *hertzArray = [hertzDictionary allValues];
    
    // sort array block
    NSArray *sortedArray = [hertzArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 floatValue] > [obj2 floatValue])
            return NSOrderedDescending;
        else if ([obj1 floatValue] < [obj2 floatValue])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    return [sortedArray objectAtIndex:row];
}


-(NSString *)getNoteValueAtRow : (int)row
{
    NSArray *notesArray = [noteDictionary allValues];
    
    // sort array block
    NSArray *sortedArray = [notesArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        //NSLog(@"%@",[noteDictionary valueForKey:obj1]);
        if ([[noteDictionary valueForKey:obj1]  floatValue] > [[noteDictionary valueForKey:obj2] floatValue])
            return NSOrderedDescending;
        else if ([[noteDictionary valueForKey:obj1] floatValue] < [[noteDictionary valueForKey:obj2] floatValue])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    NSLog(@" notes %@", sortedArray);
    
    return [sortedArray objectAtIndex:row];
}

-(int)getHertzIndexFromKey : (NSString *)key
{
    NSArray *hertzArray = [hertzDictionary allValues];
    
    // sort array block
    NSArray *sortedArray = [hertzArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 floatValue] > [obj2 floatValue])
            return NSOrderedDescending;
        else if ([obj1 floatValue] < [obj2 floatValue])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    for (int i=0; i<sortedArray.count; i++) {
        NSLog(@" %d, %@", i, sortedArray[i]);
        if ([key isEqual:sortedArray[i]]) {
            return i;
        }
    }
    return -1;
}

-(int)getNotesIndexFromKey : (NSString *)key
{
    NSArray *floatsArray = [noteDictionary allKeys];
    
    NSLog(@"%@", floatsArray);
    
    // sort array block
    NSArray *sortedArray = [floatsArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 floatValue] > [obj2 floatValue])
            return NSOrderedDescending;
        else if ([obj1 floatValue] < [obj2 floatValue])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    NSLog(@"%@", sortedArray);

    
    
    for (int i=0; i<sortedArray.count; i++) {
        NSLog(@"%@", sortedArray[i]);
        
        NSString *string  = [noteDictionary objectForKey:sortedArray[i]];
        NSLog(@"string = %@", string);
        if ([key isEqualToString:string]) {
            NSLog(@"returning %@, index %d", sortedArray[i], i);
            return i;
        }
    }
    return -1;
}


-(void)fixPickerValues : (UIPickerView *)picker
{
    
    
    NSInteger row = [picker selectedRowInComponent:0];
    
    if (picker == _lowerFrequencyPicker) {
        
        while ([_lowerFrequencyPicker selectedRowInComponent:0] >= [_upperFrequencyPicker selectedRowInComponent:0]) {
            //NSLog(@"lower row = %ld and upper row = %ld", (long)[_lowerFrequencyPicker selectedRowInComponent:0], (long)[_upperFrequencyPicker selectedRowInComponent:0]);
            [picker selectRow:--row inComponent:0 animated:YES];
        }
        
        if (isNote) {
            [_frequencySlider setMinimumValue:[[hertzDictionary valueForKey:[noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]]] floatValue]];
        } else {
            float myfloat = (float)[_lowerFrequencyPicker selectedRowInComponent:0] + 33.0;
            [_frequencySlider setMaximumValue:myfloat];
        }
        
        
    } else if (picker == _upperFrequencyPicker) {
        
        while ([_upperFrequencyPicker selectedRowInComponent:0] <= [_lowerFrequencyPicker selectedRowInComponent:0]) {
            
            
            //NSLog(@"lower row = %ld and upper row = %ld", (long)[_lowerFrequencyPicker selectedRowInComponent:0], (long)[_upperFrequencyPicker selectedRowInComponent:0]);
            
            
            [picker selectRow:++row inComponent:0 animated:YES];
            
            
        }
        
        if (isNote) {
            [_frequencySlider setMaximumValue:[[hertzDictionary valueForKey:[noteArray objectAtIndex:[_upperFrequencyPicker selectedRowInComponent:0]]] floatValue]];
        } else {
            float myfloat = (float)[_upperFrequencyPicker selectedRowInComponent:0] + 33.0;
            [_frequencySlider setMaximumValue:myfloat];
        }
    }
    
    
    
}

-(void)fixSliderValue
{
    
    /*
     if (picker == _lowerFrequencyPicker && pickerValue >= [_frequencySlider value]) {
     [_frequencySlider setValue:pickerValue+1.0 animated:YES];
     
     } else if (picker == _upperFrequencyPicker && pickerValue < [_frequencySlider value]) {
     [_frequencySlider setValue:pickerValue animated:YES];
     
     }
     */
    
    //
    NSString *stringVal = [NSString stringWithFormat:@"%f", [_frequencySlider value]];
    NSNumber *num = [NSNumber numberWithFloat:[_frequencySlider value]];
    
    
    if (isNote) {
        NSString *noteVal = [noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]];
        NSLog(@"noteVal = %@ hertzval = %@", noteVal, [hertzDictionary valueForKey:noteVal]);
        
        [_frequencySlider setValue:[[noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]] floatValue]  animated:YES];
        
        
        _thumbTextField.text = [noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]];
        
        //[self setTextType:_thumbTextField value:[[hertzDictionary valueForKey:noteVal] floatValue]];
        
        [self setTextFieldPosition:_thumbTextField];
    } else {
        
        
        //NSLog(@"slider value: %ld", (long)[[self getHertzValueAtRow:[_lowerFrequencyPicker selectedRowInComponent:0]] integerValue]);
        float lowval = (float)[_lowerFrequencyPicker selectedRowInComponent:0] + 33.0;
        [_frequencySlider setValue:lowval animated:YES];
        float num = lowval +0.5;
        int intnum = (int)num;
        NSLog(@"int %ld float %f", (long)intnum, num);
        _thumbTextField.text = [NSString stringWithFormat:@"%d", (int)intnum];
        //[self setTextType:_thumbTextField value:[[hertzDictionary valueForKey:stringVal] floatValue]];
        
        NSLog(@"wassupppp");

        
        [self setTextFieldPosition:_thumbTextField];
        
        
        // timeslot screwed up here
        //isStereo = YES;
        
        
        
    }
    
    
    
    
    
}

#pragma mark customSliderDelegate

-(void)notifyTouchFinish:(UISlider *)slider{
    _mPopUpImageview.hidden = YES;
    _mPopupLabel.hidden = YES;
    
    
    if (isNote == NO && !toneUnit) {
        switch (slider.tag) {
            case 10:
            {
                float value=[slider value];
                if (fabsf(value-slidertapValue)<1.000000) {
                    _thumbTextField.userInteractionEnabled = NO;
                    [_thumbTextField becomeFirstResponder];
                }
            }
                break;
            case 11:
            {
                float value=[slider value];
                if (fabsf(value-slidertapValue)<1.000000) {
                    //_lowerFrequencyTextField.userInteractionEnabled = YES;
                    //[_lowerFrequencyTextField becomeFirstResponder];
                }
            }
                break;
            case 12:
            {
                float value=[slider value];
                if (fabsf(value-slidertapValue)<1.000000) {
                    //_upperFrequencyTextField.userInteractionEnabled = YES;
                    //[_upperFrequencyTextField becomeFirstResponder];
                }
            }
                break;
                
            default:
                break;
        }
    }
    
    
    
    
    /*
     if (slider == _lowerFrequencySlider && [playMode integerValue] != 6) {
     isMovingUpperSlider = NO;
     [slider setValue:[_lowerFrequencySlider minimumValue] animated:YES];
     [self setTextFieldPosition:_lowerFrequencyTextField];
     if (isNote) {
     [_frequencySlider setMinimumValue:[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]];
     } else {
     [_frequencySlider setMinimumValue:[_lowerFrequencyTextField.text floatValue]];
     }
     [self setTextFieldPosition:_lowerFrequencyTextField];
     [self setTextFieldPosition:_thumbTextField];
     [self resizeSlider:_lowerFrequencySlider];
     [self resizeSlider:_upperFrequencySlider];
     }
     else if(slider == _upperFrequencySlider){
     isMovingUpperSlider = YES;//paddy
     [slider setValue:246.99 animated:YES];
     if ([_upperFrequencySlider value]>=246.5) {
     isMovingUpperSlider = NO;
     }
     NSLog(@"%f",[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]);
     NSLog(@"%f",([_upperFrequencyTextField.text floatValue]-.05));
     
     if (isNote) {
     [_frequencySlider setMaximumValue:[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]];
     } else {
     [_frequencySlider setMaximumValue:[_upperFrequencyTextField.text floatValue]-.05];
     }
     [self setTextFieldPosition:_thumbTextField];
     [self setTextFieldPosition:_upperFrequencyTextField];
     [self resizeSlider:_lowerFrequencySlider];
     [self resizeSlider:_upperFrequencySlider];
     }
     else if (slider == _lowerFrequencySlider && [playMode integerValue] == 6){
     isMovingUpperSlider = NO;
     [_lowerFrequencySlider setValue:[_lowerFrequencySlider minimumValue] animated:YES];
     [_upperFrequencySlider setValue:246.99 animated:YES];
     if ([[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue] >=61.74) {
     [_frequencySlider setMinimumValue:61.74];
     }
     else{
     [_frequencySlider setMinimumValue:[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]];
     }
     [self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
     int length = _lowerFrequencyTextField.text.length;
     
     NSLog(@"%f",[[hertzDictionary valueForKey:[_lowerFrequencyTextField.text stringByReplacingCharactersInRange:NSMakeRange(length-1,1) withString:@"3"]] floatValue]);
     
     [_frequencySlider setMaximumValue:[[hertzDictionary valueForKey:[_lowerFrequencyTextField.text stringByReplacingCharactersInRange:NSMakeRange(length-1,1) withString:@"3"]] floatValue]];
     [_frequencySlider setValue:[_frequencySlider maximumValue]];
     [self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
     [self setTextType:_thumbTextField value:[_frequencySlider value]];
     [self setTextFieldPosition:_lowerFrequencyTextField];
     [self setTextFieldPosition:_thumbTextField];
     [self setTextFieldPosition:_upperFrequencyTextField];
     [self resizeSlider:_lowerFrequencySlider];
     [self resizeSlider:_upperFrequencySlider];
     }else
     */
    if (slider == _frequencySlider){
        
        /*
         * call fix picker values function
         */
        
        //[self fixPickerValues:_upperFrequencyPicker];
        //[self fixPickerValues:_lowerFrequencyPicker];
        
    }
    if (toneUnit) {
        switch ([playMode integerValue]) {
            case 3:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                incrementFrequencyMove = ([_frequencySlider maximumValue] - [_frequencySlider minimumValue]) / (totaltime*50);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
                
            default:
                break;
        }
    }
}

#pragma mark ---------SettingMenu Delegate--------

-(void)updateDictionary{
    NSString *str=[[NSUserDefaults standardUserDefaults] stringForKey:@"sharp/b"];
    if ([str isEqualToString:@"b"]) {
        noteDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"BDictionary"] objectForKey:@"note"];
        hertzDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"BDictionary"] objectForKey:@"hertz"];
    }
    else{
        noteDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SharpDictionary"] objectForKey:@"note"];
        hertzDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SharpDictionary"] objectForKey:@"hertz"];
    }
    //[self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
    [self setTextType:_thumbTextField value:[_frequencySlider value]];
    //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
}


#pragma mark ---------------IBAction-------------
#pragma mark IBAction Methods

- (IBAction)didTapFrequencyChange:(id)sender {
    // [self resizeSlider:_lowerFrequencySlider];
    //[self resizeSlider:_upperFrequencySlider];
    [self setTextType:_thumbTextField value:[_frequencySlider value]];
    [self setTextFieldPosition:_thumbTextField];
    frequency = [_frequencySlider value];
}

- (IBAction)didTapChangeLowerFrequency:(id)sender {
    //[self animatePopup:_lowerFrequencySlider];
    //[self setTextType:_lowerFrequencyTextField value:[_lowerFrequencySlider value]];
    //[self setTextFieldPosition:_lowerFrequencyTextField];
    //_mPopupLabel.text = _lowerFrequencyTextField.text;
}

#pragma mark- Reinitiate sound and sliders
//----modified by subhra-----//
-(void)stopAndReinitiateSliders
{
    if (toneUnit)
    {
        //_lowerFrequencySlider.userInteractionEnabled = YES;
        _frequencySlider.userInteractionEnabled = YES;
        //_upperFrequencySlider.userInteractionEnabled = YES;
        AudioOutputUnitStop(toneUnit);
        AudioUnitUninitialize(toneUnit);
        AudioComponentInstanceDispose(toneUnit);
        toneUnit = nil;
        if (autoTimer) {
            [autoTimer invalidate];
            autoTimer = nil;
        }
        
        
        [_frequencySlider setValue:[_frequencySlider minimumValue]];
        [self setTextFieldPosition:_thumbTextField];
        [self setTextType:_thumbTextField value:[_frequencySlider value]];
        [_mPlayStopButton setImage:[UIImage imageNamed:@"Sound.png"] forState:UIControlStateNormal];
        
    }
}

- (IBAction)didTapChangeHertzNote:(id)sender {
    
    NSLog(@"did tap hertz note");
    
# pragma mark hertz/note bug fix - why was this here?
    /*
     if (isLoading) {
     NSLog(@"is loading");
     isLoading = NO;
     return;
     }
     */
    //----stop previous play----//
    
    
    [self  stopAndReinitiateSliders];//------modified by subhra------//
    /*
     
     if (!toneUnit && [playMode integerValue] != 6) {
     if ([(UISwitch *)sender isOn]) // [_hertzNoteButton.titleLabel.text isEqualToString:@"Hz"]
     {
     
     
     NSLog(@"is on - hertz");
     
     [self.mNoteHzSwitch  setOn:YES animated:YES];
     isMovingUpperSlider = NO;//paddy
     [_hertzNoteButton setTitle:@"♪" forState:UIControlStateNormal];
     isNote = YES;
     [_frequencySlider setMinimumValue:32.7];
     
     NSLog(@"%f",maximumFrequency);
     
     [_frequencySlider setMaximumValue:maximumFrequency];
     [_frequencySlider setValue:138.59];
     [self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
     [self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
     
     [self setTextType:_thumbTextField value:[_frequencySlider value]];
     [self didTapFrequencyChange:_frequencySlider];
     [self setMaximumFrequency];
     
     
     [self modifyPickerValues:_upperFrequencyPicker];
     [self modifyPickerValues:_lowerFrequencyPicker];
     
     }
     else{
     
     NSLog(@"is off - note");
     
     [self.mNoteHzSwitch  setOn:NO animated:YES];
     isMovingUpperSlider = NO;//paddy
     isNote = NO;
     [self setTextType:_lowerFrequencyTextField value:[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]];
     [self setTextType:_upperFrequencyTextField value:[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]];
     [self didTapFrequencyChange:_frequencySlider];
     [_hertzNoteButton setTitle:@"Hz" forState:UIControlStateNormal];
     [self setMaximumFrequency];
     
     
     [self modifyPickerValues:_upperFrequencyPicker];
     [self modifyPickerValues:_lowerFrequencyPicker];
     }
     
     }
     */
}



- (IBAction)didTapUpperFrequencyChange:(id)sender {
    /*
     [self animatePopup:_upperFrequencySlider];
     [self setTextType:_upperFrequencyTextField value:[_upperFrequencySlider value]];
     [self setTextFieldPosition:_upperFrequencyTextField];
     _mPopupLabel.text = _upperFrequencyTextField.text;
     
     isMovingUpperSlider = YES;
     //Paddy
     CGRect frame = _upperFrequencySlider.frame;
     float flag = frame.origin.x;
     frame.origin.x = [self xPositionFromSliderValue:_frequencySlider] + 42; //42
     
     
     frame.size.width += (flag - frame.origin.x);
     
     
     if ([_frequencySlider value]>=maximumFrequency-1.0) {
     [_upperFrequencySlider setMinimumValue:[_frequencySlider value]];
     }
     else{
     [_upperFrequencySlider setMinimumValue:[_frequencySlider value]+1.0];
     }
     
     [_upperFrequencySlider setFrame:frame];
     */
}

- (IBAction)didTapDownFrequencySlider:(id)sender {
    if ([(UISlider *)sender tag] != 10) {
        _mPopUpImageview.hidden = NO;
        _mPopupLabel.hidden = NO;
    }
    slidertapValue = [(UISlider *)sender value];
}

- (IBAction)didTapFinishSlider:(id)sender {
}

- (IBAction)didTapToSaveLoadSlot:(id)sender {
    if (isSavePossible==YES ) {
        [self createAlertToStore:[(UIButton *)sender tag]];
    }
    else if(![[(UILabel *)[self.view viewWithTag:saveTimeTag+[(UIButton *)sender tag]] text] isEqualToString:@""]){
        [self createAlertToLoad:[(UIButton *)sender tag]];
    }
}

- (IBAction)didTapToSelectBank:(id)sender {
    //Sayak - highlighted title set to get button title when button is still highlighted or else it was gettig the previous title and proceed with that
    if ([_mBankButton.titleLabel.text isEqualToString:@"Bank 1"]) {
        [_mBankButton setTitle:@"Bank 2" forState:UIControlStateNormal];
        [_mBankButton setTitle:@"Bank 2" forState:UIControlStateHighlighted];
    }
    else if ([_mBankButton.titleLabel.text isEqualToString:@"Bank 2"]) {
        [_mBankButton setTitle:@"Bank 3" forState:UIControlStateNormal];
        [_mBankButton setTitle:@"Bank 3" forState:UIControlStateHighlighted];
    }
    else if ([_mBankButton.titleLabel.text isEqualToString:@"Bank 3"]) {
        [_mBankButton setTitle:@"Bank 4" forState:UIControlStateNormal];
        [_mBankButton setTitle:@"Bank 4" forState:UIControlStateHighlighted];
    }
    else if ([_mBankButton.titleLabel.text isEqualToString:@"Bank 4"]) {
        [_mBankButton setTitle:@"Bank 5" forState:UIControlStateNormal];
        [_mBankButton setTitle:@"Bank 5" forState:UIControlStateHighlighted];
    }
    else if ([_mBankButton.titleLabel.text isEqualToString:@"Bank 5"]) {
        [_mBankButton setTitle:@"Bank 1" forState:UIControlStateNormal];
        [_mBankButton setTitle:@"Bank 1" forState:UIControlStateHighlighted];
    }
    [self loadSlotDetails];
    [self checkStatus];
}

- (IBAction)didTapToStoreDetails:(id)sender {
    if (isSavePossible==NO) {
        isSavePossible=YES;
        [_mStoreButton setBackgroundImage:[UIImage imageNamed:@"store_select.png"] forState:UIControlStateNormal];
    }
    else{
        isSavePossible=NO;
        [_mStoreButton setBackgroundImage:[UIImage imageNamed:@"store.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)didTapPlayStopButton:(id)sender {
    isMovingForword = YES;
    NSString *str1=[_mTimeLabel.text substringFromIndex:[_mTimeLabel.text length]-3];
    if ([str1 isEqualToString:@"sec"]) {
        totaltime=1*[_mTimeLabel.text integerValue];
    } else {
        totaltime=60*[_mTimeLabel.text integerValue];
    }
    if (!toneUnit) {
        switch ([playMode integerValue]) {
            case 3:
                //Smooth Mode
            {
                [_frequencySlider setValue:[_frequencySlider minimumValue]];
                [self setTextFieldPosition:_thumbTextField];
                [self setTextType:_thumbTextField value:[_frequencySlider value]];
                //[self resizeSlider:_lowerFrequencySlider];
                //[self resizeSlider:_upperFrequencySlider];
                incrementFrequencyMove = ([_frequencySlider maximumValue] - [_frequencySlider minimumValue]) / (totaltime*50);
                frequency = [_frequencySlider minimumValue];
                _frequencySlider.userInteractionEnabled = NO;
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 4:
                //Semi Mode
            {
                //_lowerFrequencySlider.userInteractionEnabled = NO;
                _frequencySlider.userInteractionEnabled = NO;
                //_upperFrequencySlider.userInteractionEnabled = NO;
                [_frequencySlider setMinimumValue:32.7];
                
                //NSLog(@"%f",_frequencySlider.maximumValue);
                
                [_frequencySlider setMaximumValue:65.41];
                [_frequencySlider setValue:32.7];
                [self setTextFieldPosition:_thumbTextField];
                [self setTextType:_thumbTextField value:[_frequencySlider value]];
                //[self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
                //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
                //[self resizeSlider:_lowerFrequencySlider];
                //[self resizeSlider:_upperFrequencySlider];
                frequency = [_frequencySlider minimumValue];
                float i = (float)totaltime/((semiSweepArray.count*2)-1);
                flagIndex = 1;
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 5:
                //Whole Mode
            {
                //_lowerFrequencySlider.userInteractionEnabled = NO;
                _frequencySlider.userInteractionEnabled = NO;
                //_upperFrequencySlider.userInteractionEnabled = NO;
                [_frequencySlider setMinimumValue:32.7];
                
                //NSLog(@"%f",_frequencySlider.maximumValue);
                
                [_frequencySlider setMaximumValue:65.41];
                [_frequencySlider setValue:32.7];
                [self setTextFieldPosition:_thumbTextField];
                [self setTextType:_thumbTextField value:[_frequencySlider value]];
                //[self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
                //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
                //[self resizeSlider:_lowerFrequencySlider];
                //[self resizeSlider:_upperFrequencySlider];
                frequency = [_frequencySlider minimumValue];
                float i = (float)totaltime/((wholeSweepArray.count*2)-1);
                flagIndex = 1;
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 6:
                //Octave Mode
            {
                /*
                 //_lowerFrequencySlider.userInteractionEnabled = NO;
                 _frequencySlider.userInteractionEnabled = NO;
                 //_upperFrequencySlider.userInteractionEnabled = NO;
                 [_frequencySlider setValue:[_frequencySlider minimumValue]];
                 [self setTextFieldPosition:_thumbTextField];
                 [self setTextType:_thumbTextField value:[_frequencySlider value]];
                 //[self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
                 //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
                 //[self resizeSlider:_lowerFrequencySlider];
                 //[self resizeSlider:_upperFrequencySlider];
                 frequency = [_frequencySlider minimumValue];
                 for (int i=0; i<totalFrequencyArray.count; i++) {
                 if([_frequencySlider minimumValue]==[[totalFrequencyArray objectAtIndex:i] floatValue]){
                 flagIndex=i+12;
                 break;
                 }
                 }
                 float time = (float)totaltime/5;
                 autoTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
                 */
            }
                break;
                
            default:
                break;
        }
    }
    slaceTimer = 0;
    [self CheckToneUnit];
}

- (IBAction)didTapToChangeMonoStereo:(id)sender {
    
    /*
     [self stopAndReinitiateSliders];
     if (toneUnit) {
     [self CheckToneUnit];
     }
     */
    
    
    NSString *alertMessage = @"";
    if(isStereo)
    {
        // pro
        alertMessage = @"Are you sure you want to change the mode from Stereo to Mono?";
        
        // home
        //alertMessage = @"Mono mode will be available in SomaWave PRO.";
        
    }
    else
    {
        alertMessage = @"Are you sure you want to change the mode from Mono to Stereo?";
    }
    
    // home
    //UIAlertView *showAlert =[[UIAlertView alloc] initWithTitle:@"Mode change" message:alertMessage delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil , nil];
    
    
    UIAlertView *showAlert =[[UIAlertView alloc] initWithTitle:@"Confirm mode change" message:alertMessage delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    // pro
    // Change to Stereo / Mono mode?   Please change control panel setting to Stereo / Mono
    
     if (isStereo == YES) {
     [showAlert setTag:40];
     } else {
     [showAlert setTag:50];
     }
     
    
    [showAlert show];
    
}

- (IBAction)didTapToChangeInToneMode:(id)sender {
    [self stopAndReinitiateSliders];
    playMode = @"1";
    [self checkPlayMode];
}

- (IBAction)didTapToOPENSWEEPMENU:(id)sender {
    if (_mSweepMenuView.hidden == YES) {
        _mSweepMenuView.hidden = NO;
    }
    else{
        _mSweepMenuView.hidden = YES;
    }
}

- (IBAction)didTapToChangeInSmoothMode:(id)sender {
    [self stopAndReinitiateSliders];
    playMode = @"3";
    [self checkPlayMode];
}

- (IBAction)didTapToChangeInSemiMode:(id)sender {
    [self stopAndReinitiateSliders];
    playMode = @"4";
    [self checkPlayMode];
}

- (IBAction)didTaptoChangeInWholeButton:(id)sender {
    [self stopAndReinitiateSliders];
    playMode = @"5";
    [self checkPlayMode];
}

/*
 - (IBAction)didTapToChangeInOctaveMode:(id)sender {
 playMode = @"6";
 [_hertzNoteButton setTitle:@"♪" forState:UIControlStateNormal];
 isNote = YES;
 [_frequencySlider setMinimumValue:32.7];
 
 // NSLog(@"%f",_frequencySlider.maximumValue);
 
 [_frequencySlider setMaximumValue:130.81];
 [_frequencySlider setValue:130.81];
 //[self setTextType:_lowerFrequencyTextField value:32.7];
 //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
 [self didTapFrequencyChange:_frequencySlider];
 [self checkPlayMode];
 }
 */

- (IBAction)didTapUpArrow:(id)sender {
    if (isStereo == YES && timeSlot < stereoTimeArray.count-1) {
        NSLog(@"STEREO = YES");
        timeSlot++;
        _mTimeLabel.text = [stereoTimeArray objectAtIndex:timeSlot];
    }
    else if(isStereo == NO &&timeSlot < monoTimeArray.count-1){
        NSLog(@"STEREO = NO");
        timeSlot++;
        _mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
    }
    if (toneUnit) {
        NSString *str1=[_mTimeLabel.text substringFromIndex:[_mTimeLabel.text length]-3];
        if ([str1 isEqualToString:@"sec"]) {
            totaltime=1*[_mTimeLabel.text integerValue];
        } else {
            totaltime=60*[_mTimeLabel.text integerValue];
        }
        switch ([playMode integerValue]) {
            case 3:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                incrementFrequencyMove = ([_frequencySlider maximumValue] - [_frequencySlider minimumValue]) / (totaltime*50);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 4:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float i = (float)totaltime/((semiSweepArray.count*2)-1);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 5:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float i = (float)totaltime/((wholeSweepArray.count*2)-1);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 6:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float time = (float)totaltime/5;
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            default:
                break;
        }
    }
}

- (IBAction)didTapDownArrow:(id)sender {
    if (isStereo == YES && timeSlot > 0) {
        NSLog(@"STEREO = YES");
        
        timeSlot--;
        _mTimeLabel.text = [stereoTimeArray objectAtIndex:timeSlot];
    }
    else if(isStereo == NO &&timeSlot > 0){
        NSLog(@"STEREO = NO");
        timeSlot--;
        _mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
    }
    if (toneUnit) {
        NSString *str1=[_mTimeLabel.text substringFromIndex:[_mTimeLabel.text length]-3];
        if ([str1 isEqualToString:@"sec"]) {
            totaltime=1*[_mTimeLabel.text integerValue];
        } else {
            totaltime=60*[_mTimeLabel.text integerValue];
        }
        switch ([playMode integerValue]) {
            case 3:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                incrementFrequencyMove = ([_frequencySlider maximumValue] - [_frequencySlider minimumValue]) / (totaltime*50);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 4:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float i = (float)totaltime/((semiSweepArray.count*2)-1);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 5:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float i = (float)totaltime/((wholeSweepArray.count*2)-1);
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            case 6:
            {
                [autoTimer invalidate];
                autoTimer = nil;
                float time = (float)totaltime/5;
                autoTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(onTimer) userInfo:Nil repeats:YES];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark----- did click on setting option---------
- (IBAction)didTapOpenSettingMenu:(id)sender {
    Settings *settingVC =[[Settings alloc] initWithNibName:@"Settings" bundle:nil];
    [settingVC setDelegate:(id)self];
    pop = [[UIPopoverController alloc] initWithContentViewController:settingVC];
    [pop presentPopoverFromRect:_mSettingButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)didTapHertzNoteToggle:(id)sender {
    
    
    
    NSLog(@"did tap hertz note");
    
# pragma mark hertz/note bug fix - why was this here?
    /*
     if (isLoading) {
     NSLog(@"is loading");
     isLoading = NO;
     return;
     }
     */
    //----stop previous play----//
    
    NSLog(@"stop and reinitiate sliders");
    
    
    
    
    [self  stopAndReinitiateSliders];
    
    
    
    UIButton *button = (UIButton*)sender;
    
    NSLog(@"\n\n\nbutton title is %@\n\n\n\n", button.titleLabel.text);
    
    if (!toneUnit && [playMode integerValue] != 6) {
        // if on hertz set to note else on note set to hertz
        if ([button.titleLabel.text isEqualToString: @"hertz"]) // hertz
        {
            NSLog(@"is on - hertz");
            
            //[self.mNoteHzSwitch  setOn:YES animated:YES];
            
            [_hertzNoteToggleImage setImage:[UIImage imageNamed:@"switch_up.png"]];
            //[button.titleLabel setText:@"note"];
            [button setTitle:@"note" forState:UIControlStateNormal];
            NSLog(@"new button title... %@", button.titleLabel.text);
            isMovingUpperSlider = NO;//paddy
            //[_hertzNoteButton setTitle:@"♪" forState:UIControlStateNormal];
            isNote = YES;
            [_frequencySlider setMinimumValue:32.7];
            
            //NSLog(@"%f",maximumFrequency);
            
            [_frequencySlider setMaximumValue:maximumFrequency];
            [_frequencySlider setValue:138.59];
            //[self setTextType:_lowerFrequencyTextField value:[_frequencySlider minimumValue]];
            //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
            
            [self setTextType:_thumbTextField value:[_frequencySlider value]];
            [self didTapFrequencyChange:_frequencySlider];
            [self setMaximumFrequency];
        }
        else {
            
            NSLog(@"is off - note");
            
            //[self.mNoteHzSwitch  setOn:NO animated:YES];
            
            [_hertzNoteToggleImage setImage:[UIImage imageNamed:@"switch_down.png"]];
            
            [button setTitle:@"hertz" forState:UIControlStateNormal];
            
            isMovingUpperSlider = NO;//paddy
            isNote = NO;
            //[self setTextType:_lowerFrequencyTextField value:[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]];
            //[self setTextType:_upperFrequencyTextField value:[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]];
            [self didTapFrequencyChange:_frequencySlider];
            [_hertzNoteButton setTitle:@"Hz" forState:UIControlStateNormal];
            [self setMaximumFrequency];
            
            
        }
        
        [_upperFrequencyPicker reloadAllComponents];
        [_lowerFrequencyPicker reloadAllComponents];
        
        [_lowerFrequencyPicker selectRow:0 inComponent:0 animated:YES];
        if (isNote) {
            if (isStereo) {
                [_upperFrequencyPicker selectRow:12 inComponent:0 animated:YES];
            } else {
                [_upperFrequencyPicker selectRow:[[hertzDictionary allKeys] count]-1 inComponent:0 animated:YES];
            }
        } else {
            if (isStereo) {
                [_upperFrequencyPicker selectRow:32 inComponent:0 animated:YES];
            } else {
                [_upperFrequencyPicker selectRow:214 inComponent:0 animated:YES];
            }
        }
        
        
    }
    
    
    
}

#pragma mark ---------------textfield-------------
#pragma mark textfield setposition

-(void)setTextFieldPosition:(UITextField *)txtfld{
    CGRect frame = txtfld.frame;
    if (txtfld == _thumbTextField) {
        frame.origin.x = [self xPositionFromSliderValue:_frequencySlider] - frame.size.width/2;
        [txtfld setFrame:frame];
    }
    /*
     else if (txtfld == _lowerFrequencyTextField) {
     frame.origin.x = [self xPositionFromSliderValue:_lowerFrequencySlider] - frame.size.width/2;
     [txtfld setFrame:frame];
     }
     else if (txtfld == _upperFrequencyTextField) {
     frame.origin.x = [self xPositionFromSliderValue:_upperFrequencySlider] - frame.size.width/2;
     //NSLog(@"Paddy %f", frame.origin.x);
     [txtfld setFrame:frame];
     }
     */
}

#pragma mark textfield delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    flagText = textField.text;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    _thumbTextField.userInteractionEnabled = NO;
    //_lowerFrequencyTextField.userInteractionEnabled = NO;
    // _upperFrequencyTextField.userInteractionEnabled = NO;
    frequency = [_frequencySlider value];
    if ([textField.text floatValue]<maximumFrequency && [textField.text floatValue]>32.71) {
        /*
         if (textField == _lowerFrequencyTextField) {
         [_lowerFrequencySlider setValue:[_lowerFrequencySlider minimumValue] animated:YES];
         [self setTextFieldPosition:_lowerFrequencyTextField];
         if (isNote) {
         [_frequencySlider setMinimumValue:[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]];
         } else {
         [_frequencySlider setMinimumValue:[_lowerFrequencyTextField.text floatValue]];
         }
         [self setTextFieldPosition:_lowerFrequencyTextField];
         [self setTextFieldPosition:_thumbTextField];
         [self resizeSlider:_lowerFrequencySlider];
         [self resizeSlider:_upperFrequencySlider];
         }
         else if(textField == _upperFrequencyTextField){
         [_upperFrequencySlider setValue:maximumFrequency animated:YES];
         
         //NSLog(@"%f",[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]);
         //NSLog(@"%f",([_upperFrequencyTextField.text floatValue]-.05));
         
         if (isNote) {
         [_frequencySlider setMaximumValue:[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]];
         } else {
         [_frequencySlider setMaximumValue:[_upperFrequencyTextField.text floatValue]-.05];
         }
         [self setTextFieldPosition:_thumbTextField];
         [self setTextFieldPosition:_upperFrequencyTextField];
         [self resizeSlider:_lowerFrequencySlider];
         [self resizeSlider:_upperFrequencySlider];
         }
         else
         */
        if(textField == _thumbTextField && [textField.text floatValue]<[_frequencySlider maximumValue] && [textField.text floatValue]>[_frequencySlider minimumValue]){
            [_frequencySlider setValue:[textField.text floatValue] animated:YES];
            [self setTextFieldPosition:_thumbTextField];
            //[self resizeSlider:_lowerFrequencySlider];
            //[self resizeSlider:_upperFrequencySlider];
        }
        else{
            textField.text = flagText;
        }
    }
    else{
        textField.text = flagText;
    }
}

//------Modified by Subhra----------//
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField  resignFirstResponder];
    return YES;
}

#pragma mark setMaxFrequency
-(void)setMaximumFrequency
{
    if(isStereo == YES){
        maximumFrequency = 65.41;
    }
    else{
        maximumFrequency = 246.94;
    }
    upperFrequency = maximumFrequency;
}

#pragma mark setMinFrequency
-(void)setMinimumFrequency
{
    minimumFrequency = 32.7;
    lowerFrequency = minimumFrequency;
}

#pragma mark textchanged

-(void)setTextType : (UITextField *)txtfld value :(float)val{
    if (isNote) {
        for (int i=0; i<noteDictionary.count; i++) {
            if ([[hertzDictionary valueForKey:[noteDictionary valueForKey:[totalFrequencyArray objectAtIndex:i]]] integerValue]==(int)val) {
                txtfld.text = [noteDictionary valueForKey:[totalFrequencyArray objectAtIndex:i]];
                return;
            }
        }
    } else {
        txtfld.text = [NSString stringWithFormat:@"%0.f",val];
    }
    frequency =[_frequencySlider value];
}




#pragma mark ---------------alert function-------------
#pragma mark for Showing alert

-(void)createAlertToStore : (NSInteger)slotNo {
    UIAlertView *showAlert =[[UIAlertView alloc] initWithTitle:@"Confirm Storing Procedure" message:[NSString stringWithFormat:@"Store parameters in %@, Slot %d?",_mBankButton.titleLabel.text,slotNo] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    slot = slotNo;
    [showAlert setTag:10];
    [showAlert show];
}


-(void)createAlertToLoad : (NSInteger)slotNo {
    UIAlertView *showAlert =[[UIAlertView alloc] initWithTitle:@"Confirm Loading Procedure" message:[NSString stringWithFormat:@"Load parameters in %@, Slot %d?",_mBankButton.titleLabel.text,slotNo] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    slot = slotNo;
    [showAlert setTag:20];
    [showAlert show];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==1){
        // store
        if (alertView.tag == 10) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            
            NSString *lowVal, *upVal;
            if (isNote) {
                lowVal = [noteArray objectAtIndex:[_lowerFrequencyPicker selectedRowInComponent:0]];
                upVal = [noteArray objectAtIndex:[_upperFrequencyPicker selectedRowInComponent:0]];
                NSLog(@"lowwww %@ highhhh %@", lowVal, upVal);
            } else {
                lowVal = [NSString stringWithFormat: @"%d", [_lowerFrequencyPicker selectedRowInComponent:0] + 33 ];
                upVal = [NSString stringWithFormat: @"%d", [_upperFrequencyPicker selectedRowInComponent:0] + 33 ];
            }
            
            NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
            [fmt setPositiveFormat:@"0.##"];
            
            NSLog(@"low %@ up %@", [fmt stringFromNumber:[NSNumber numberWithInteger:[lowVal integerValue]]], [fmt stringFromNumber:[NSNumber numberWithFloat:[upVal floatValue]]]);
            [dict setValue:[fmt stringFromNumber:[NSNumber numberWithInteger:[lowVal integerValue]]] forKey:@"LowerRange"];
            [dict setValue:[fmt stringFromNumber:[NSNumber numberWithInteger:[upVal integerValue]]] forKey:@"UpperRange"];
            
            if([playMode integerValue]==1){
                
                [dict setValue:self.thumbTextField.text forKey:@"middleRange"];
                [dict setValue:[NSString stringWithFormat:@"%.0f",[_frequencySlider value]] forKey:@"middleRangeValue"];
                
            }else{
                
            }
            
            if (isStereo == YES) {
                [dict setValue:@"Yes" forKey:@"Stereo/Mono"];
                [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+slot]  setImage:[UIImage  imageNamed:@"stereoIcon.png"]];
                
                
            }
            else{
                [dict setValue:@"No" forKey:@"Stereo/Mono"];
                [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+slot]  setImage:[UIImage  imageNamed:@"monoIcon.png"]];
                
            }
            
            //sayak
            if (isNote == YES) {
                [dict setValue:@"Yes" forKey:@"Note/Hertz"];
                
                [dict setValue:lowVal forKey:@"LowerRangeValue"];
                [dict setValue:upVal forKey:@"UpperRangeValue"];
                
                [dict setValue:lowVal forKey:@"LowerRange"];
                [dict setValue:upVal forKey:@"UpperRange"];
                
                //[dict setValue:[NSString stringWithFormat:@"%f",[[hertzDictionary valueForKey:_lowerFrequencyTextField.text] floatValue]] forKey:@"LowerRangeValue"];
                //[dict setValue:[NSString stringWithFormat:@"%f",[[hertzDictionary valueForKey:_upperFrequencyTextField.text] floatValue]] forKey:@"UpperRangeValue"];
                [dict setValue:[NSString stringWithFormat:@"%f",[[hertzDictionary valueForKey:_thumbTextField.text] floatValue]] forKey:@"middleRangeValue"];
            }
            else{
                [dict setValue:@"No" forKey:@"Note/Hertz"];
                [dict setValue:[NSString stringWithFormat:@"%f",[_frequencySlider minimumValue]] forKey:@"LowerRangeValue"];
                [dict setValue:[NSString stringWithFormat:@"%f",[_frequencySlider maximumValue]] forKey:@"UpperRangeValue"];
                [dict setValue:[NSString stringWithFormat:@"%f",[_frequencySlider value]] forKey:@"middleRangeValue"];
            }
            //[dict setValue:playMode forKey:@"slotType"];
            [dict setValue:playMode forKey:@"PlayStyle"];
            [dict setValue:_mTimeLabel.text forKey:@"Time"];
            [dict setValue:[NSString stringWithFormat:@"%d",timeSlot] forKey:@"TimeSlot"];
            NSString *sharp=[[NSUserDefaults standardUserDefaults] stringForKey:@"sharp/b"];
            [dict setValue:sharp forKey:@"Sharp/b"];
            [dict setValue:[NSNumber numberWithInt: (saveCurveImageTag+slot)] forKey:@"imageView"];
            [dict setValue:[NSNumber numberWithInt:_mGeneralModeButton.tag] forKey:@"buttonTag"];
            
            //[self doCurve:playMode.intValue];
            
            NSString *str=[NSString stringWithFormat:@"%@ - %@",lowVal,upVal ];
            
            //Sayak
            if([playMode integerValue]==1){
                if (!isNote)
                    str = [NSString stringWithFormat:@"%.f",[_frequencySlider value]];
                else
                    str = [NSString stringWithFormat:@"%@",self.thumbTextField.text];
            }
            
            [(UILabel *)[self.view viewWithTag:saveFrequencyTag+slot] setText:str];
            
            
            [(UILabel *)[self.view viewWithTag:saveTimeTag+slot] setText:_mTimeLabel.text];
            [_mStoreButton setBackgroundImage:[UIImage imageNamed:@"store.png"] forState:UIControlStateNormal];
            isSavePossible=NO;
            [self doCurve:playMode.intValue : (saveCurveImageTag+slot)];
            [SaveLoad SaveSlotNo:[NSString stringWithFormat:@"Slot%d",slot] BankNo:_mBankButton.titleLabel.text information:dict];
            
            
            NSLog(@"%@", dict);
        }
        //Load
        else if (alertView.tag == 20){
            NSMutableDictionary *slotDict = [SaveLoad LoadDetailsSlotNo:[NSString stringWithFormat:@"Slot%d",slot] BankNo:_mBankButton.titleLabel.text];
            NSLog(@"slotdict %@",slotDict);
            
            NSLog(@"slotdict stufffff \nis note? %@\nlower value %@\n upper value %@", [slotDict valueForKey:@"Note/Hertz"], [slotDict valueForKey:@"LowerRangeValue"], [slotDict valueForKey:@"UpperRangeValue"]);
            
            //prevent hz/note toggle delegate action
            isLoading = YES;
            
            ////////////////////////////Set Stereo/Mono to load///////////////////////////////////////////////
            if ([[slotDict valueForKey:@"Stereo/Mono"] isEqualToString:@"Yes"]) {
                isStereo = YES;
                [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+slot]  setImage:[UIImage  imageNamed:@"stereoIcon.png"]];
            }
            else {
                isStereo = NO;
                [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+slot]  setImage:[UIImage  imageNamed:@"monoIcon.png"]];
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////
            
            
            [self checkStatus];
            [self checkMonoSteroButton];
            
            
            ////////////////////Set Frequency Type in Hz or in note/////////////////////////////////////////
            
            if ([[slotDict valueForKey:@"Note/Hertz"] isEqualToString:@"Yes"]) {
                isNote = YES;
                [_hertzNoteButton setTitle:@"♪" forState:UIControlStateNormal];
                [self.mNoteHzSwitch  setOn:YES animated:YES]; // Sayak
                [_hertzNoteToggleImage setImage:[UIImage imageNamed:@"switch_up.png"]];
            } else if ([[slotDict valueForKey:@"Note/Hertz"] isEqualToString:@"No"]){
                isNote = NO;
                [_hertzNoteButton setTitle:@"Hz" forState:UIControlStateNormal];
                [self.mNoteHzSwitch  setOn:NO animated:YES]; // Sayak
                [_hertzNoteToggleImage setImage:[UIImage imageNamed:@"switch_down.png"]];
            }
            
            /////////////////////////////////////////////////////////////////////////////////////////////////
            
            
            
            /////////////////Set Lower and Upper Fequency Picker and Set Middle Frequency Slider while Loading////////////////////
            
            
            // pickers
            
            [_upperFrequencyPicker reloadAllComponents];
            [_lowerFrequencyPicker reloadAllComponents];
            
            NSLog(@"low slotdict %@", [slotDict valueForKey:@"LowerRangeValue"]);
            NSLog(@"up slotdict %@", [slotDict valueForKey:@"UpperRangeValue"]);
            
            NSString *upstring = [slotDict valueForKey:@"UpperRangeValue"];
            NSString *lowstring = [slotDict valueForKey:@"LowerRangeValue"];
            
            
            NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
            [fmt setPositiveFormat:@"0.##"];
            
            if (!isNote) {
                // fix loading
                float upfloat = [upstring floatValue];
                float lowfloat = [lowstring floatValue];
                upfloat += 0.5;
                lowfloat += 0.5;
                
                NSLog(@"low float %f up float %f", lowfloat, upfloat);
                
                upstring = [[NSNumber numberWithFloat:upfloat] stringValue];
                lowstring = [[NSNumber numberWithFloat:lowfloat] stringValue];
            }

            
            
            //NSLog(@"low %@ up %@", [fmt stringFromNumber:[NSNumber numberWithFloat:[lowVal floatValue]]], [fmt stringFromNumber:[NSNumber numberWithFloat:[upVal floatValue]]]);
            int lowIndex, upIndex;
            NSNumber *upnum, *lownum;
            
            
            //lownum = [NSNumber numberWithInt:[[slotDict valueForKey:@"LowerRangeValue"] integerValue]];
            //upnum = [NSNumber numberWithInt:[[slotDict valueForKey:@"UpperRangeValue"] integerValue]];
            
            if (isNote) {
                NSLog(@"lows = %@ ups = %@", lowstring, upstring);
                
                lowIndex = [self getNotesIndexFromKey:lowstring];
                upIndex = [self getNotesIndexFromKey:upstring];
                
                _frequencySlider.minimumValue = [[hertzDictionary valueForKey:[slotDict valueForKey:@"LowerRangeValue"]] floatValue];
                _frequencySlider.maximumValue = [[hertzDictionary valueForKey:[slotDict valueForKey:@"UpperRangeValue"]] floatValue];
                
            } else {
                NSLog(@"low = %@ up = %@", lownum, upnum);
                
                upnum = [fmt numberFromString:upstring];
                lownum = [fmt numberFromString:lowstring];
                
                NSLog(@"upper val num = %@ and lower val num = %@", upnum, lownum);
                
                
                lowIndex = [lownum integerValue] - 33;//[self getHertzIndexFromKey:[fmt stringFromNumber:lownum]];
                upIndex = [upnum integerValue] - 33;//[self getHertzIndexFromKey:[fmt stringFromNumber:upnum]];
                
                NSLog(@"low index = %d, up indiex = %d", lowIndex, upIndex);
                
                _frequencySlider.minimumValue = [[slotDict valueForKey:@"LowerRangeValue"] floatValue];
                _frequencySlider.maximumValue = [[slotDict valueForKey:@"UpperRangeValue"] floatValue];
            }
            
            NSLog(@"lowindex = %d upindex = %d", lowIndex, upIndex);
            
            
            [_upperFrequencyPicker selectRow:upIndex inComponent:0 animated:YES];
            [_lowerFrequencyPicker selectRow:lowIndex inComponent:0 animated:YES];
            
            float  middleSliderValue=[[slotDict  valueForKey:@"middleRangeValue"] floatValue];
            NSLog(@"mid val=%f", middleSliderValue);
            
            if (middleSliderValue>0) {
                _frequencySlider.value = middleSliderValue;
            }
            [self setTextType:_thumbTextField value:middleSliderValue];//middle
            
            
            
            //////////////////////////////////////////////////////////////////////////////////////////////////////
            
            
            
            //////////////////////////////final code Previously Written///////////////////////////////////////////
            
            [self didTapFrequencyChange:_frequencySlider];
            //[self resizeSlider:_lowerFrequencySlider];
            //[self resizeSlider:_upperFrequencySlider];
            //            [_lowerFrequencySlider setValue:[_lowerFrequencySlider minimumValue] animated:NO];
            //            [_upperFrequencySlider setValue:[_upperFrequencySlider maximumValue] animated:NO];
            //[self setTextFieldPosition:_lowerFrequencyTextField];
            //[self setTextFieldPosition:_upperFrequencyTextField];
            [self setTextFieldPosition:_thumbTextField];
            //            [self setTextType:_thumbTextField value:[_frequencySlider value]];
            _mTimeLabel.text = [slotDict valueForKey:@"Time"];
            timeSlot = [[slotDict valueForKey:@"TimeSlot"] integerValue];
            frequency = [_frequencySlider value];
            [self  loadModeFromMemoryWithDic:slotDict];
            
            /////////////////////////////////////////////////////////////////////////////////////////////////////
            
            
        }
        else if (alertView.tag == 40){
            isStereo = NO;
            [self checkMonoSteroButton];
            [self checkStatus];
            
            timeSlot = 9;
            _mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
            
            if ([playMode  isEqual: @"4"]) {
                [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"tone_select.png"] forState:UIControlStateNormal];//Modified by subhra
                playMode = @"1";
            }
            
            [_upperFrequencyPicker selectRow:214 inComponent:0 animated:true];
            //[self resizeSlider:_lowerFrequencySlider];
            //[self resizeSlider:_upperFrequencySlider];
        }
        else if (alertView.tag == 50){
            isStereo = YES;
            [self checkMonoSteroButton];
            [self checkStatus];
            
            timeSlot = 4;
            _mTimeLabel.text = [stereoTimeArray objectAtIndex:timeSlot];
            
            [_upperFrequencyPicker selectRow:33 inComponent:0 animated:true];
            
            //[self resizeSlider:_lowerFrequencySlider];
            //[self resizeSlider:_upperFrequencySlider];
        }
    }
}

#pragma mark- Display Mode from memory
//---------modified by subhra---------//

-(void)loadModeFromMemoryWithDic:(NSDictionary*)_dic
{
    //self.mMenuView.hidden = YES;
    
    int buttonTagValue=[[_dic  valueForKey:@"buttonTag"]  integerValue];
    
    UIButton *button = (UIButton *)[self.mMenuView  viewWithTag:buttonTagValue];
    [self.mGeneralModeButton setBackgroundImage:[button backgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
    self.mGeneralModeButton.tag = button.tag;
    switch (button.tag)
    {
        case 11:
            [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"tone_select.png"] forState:UIControlStateNormal];//Modified by subhra
            playMode = @"1";
            break;
            
        case 12:
            [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"smooth_select.png"] forState:UIControlStateNormal];//Modified by suhra
            playMode = @"3";
            break;
            
        case 13:
        {
            if(isStereo)
            {
                [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"semi_select.png"] forState:UIControlStateNormal];//Modified by subhra
                playMode = @"4";
                break;
            }
            else
            {
                /*
                 
                 [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"octave_select.png"] forState:UIControlStateNormal];//Modified by subhra
                 playMode = @"6";
                 [self.mNoteHzSwitch setOn:YES animated:YES];
                 isNote = YES;
                 [_frequencySlider setMinimumValue:32.7];
                 
                 //NSLog(@"%f",_frequencySlider.maximumValue);
                 
                 [_frequencySlider setMaximumValue:130.81];
                 [_frequencySlider setValue:130.81];
                 //[self setTextType:_lowerFrequencyTextField value:32.7];
                 //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
                 [self didTapFrequencyChange:_frequencySlider];
                 break;
                 
                 */
            }
            
        }
            
        default:
            break;
    }
    
}

-(void)loadSlotDetails{
    NSMutableDictionary *storeDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] valueForKey:@"Store"]];
    if(storeDict != nil){
        
        NSLog(@"Bank button title : %@",_mBankButton.titleLabel.text);
        
        NSMutableDictionary *bankDict = [NSMutableDictionary dictionaryWithDictionary:[storeDict objectForKey:_mBankButton.titleLabel.text]];
        if(bankDict != nil){
            for (int i=1; i<=4; i++) {
                NSMutableDictionary *slotDict = [NSMutableDictionary dictionaryWithDictionary:[bankDict objectForKey:[NSString stringWithFormat:@"Slot%d",i]]];
                if (slotDict!=nil) {
                    NSString *str=[NSString stringWithFormat:@"%@ - %@",[slotDict valueForKey:@"LowerRange"] ,[slotDict valueForKey:@"UpperRange"] ];
                    // Sayak
                    if([[slotDict valueForKey:@"PlayStyle"] integerValue]==1){
                        if ([[slotDict valueForKey:@"Note/Hertz"] isEqualToString:@"No"])
                            str = [NSString stringWithFormat:@"%.f",[[slotDict valueForKey:@"middleRangeValue"] floatValue]];
                        else
                            str = [NSString stringWithFormat:@"%@",[slotDict valueForKey:@"middleRange"]];
                    }
                    
                    if([slotDict valueForKey:@"LowerRange"]){
                        [(UILabel *)[self.view viewWithTag:saveFrequencyTag+i] setText:str];
                        [(UILabel *)[self.view viewWithTag:saveTimeTag+i] setText:[slotDict valueForKey:@"Time"]];
                        NSInteger tag = [[slotDict valueForKey:@"imageView"] integerValue];
                        NSInteger propTag = [[slotDict valueForKey:@"PlayStyle"] integerValue];
                        [self doCurve: propTag : tag];
                        
                        if ([[slotDict valueForKey:@"Stereo/Mono"] isEqualToString:@"Yes"]) {
                            //isStereo = YES;
                            
                            [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+i]  setImage:[UIImage  imageNamed:@"stereoIcon.png"]];
                        }
                        else {
                            //isStereo = NO;
                            
                            [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+i]  setImage:[UIImage  imageNamed:@"monoIcon.png"]];
                        }
                        
                    }
                    else{
                        [(UILabel *)[self.view viewWithTag:saveFrequencyTag+i] setText:[NSString stringWithFormat:@"Slot %d",i]];
                        [(UILabel *)[self.view viewWithTag:saveTimeTag+i] setText:@""];
                        [(UIImageView *)[self.view viewWithTag:saveCurveImageTag+i] setImage:nil];
                        //[self doCurve:[[slotDict valueForKey:@"PlayStyle"] intValue] : (saveCurveImageTag+slot)];
                        [(UIImageView*)[self.view  viewWithTag:saveMonoOrStereoTag+i] setImage:nil]; //modified by subhra
                        
                    }
                }
            }
        }
    }
}


#pragma mark ---------------class function-------------

-(void)animatePopup : (UISlider *)slider{
    CGRect popImgRect = _mPopUpImageview.frame;
    CGRect popLblRect = _mPopupLabel.frame;
    popImgRect.origin.x = [self xPositionFromSliderValue:slider]-popImgRect.size.width/2;
    popLblRect.origin.x = [self xPositionFromSliderValue:slider]-popLblRect.size.width/2;
    [_mPopUpImageview setFrame:popImgRect];
    [_mPopupLabel setFrame:popLblRect];
}

-(void)doCurve : (NSInteger )tag :(NSInteger)imageViewTag{
    /*UIGraphicsBeginImageContext(imageView.frame.size);
     CGContextRef context=UIGraphicsGetCurrentContext();
     CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
     // Draw them with a 2.0 stroke width so they are a bit more visible.
     CGContextSetLineWidth(context, 2.0);
     CGFloat dashPattern[]= {15, 2};
     // Draw a bezier curve with end points s,e and control points cp1,cp2
     CGPoint s = CGPointMake(16, 140);
     CGPoint e = CGPointMake(149, 140);
     CGPoint cp1 = CGPointMake(30, 60);
     CGPoint cp2 = CGPointMake(135, 60);
     CGContextMoveToPoint(context, s.x, s.y);
     CGContextAddCurveToPoint(context, cp1.x, cp1.y, cp2.x, cp2.y, e.x, e.y);
     CGContextSetRGBStrokeColor(context, 1, 1, 1, 5);//0, 0, 0//-------Modified by subhra---//
     CGContextSetLineDash(context, 50, dashPattern, 2);
     CGContextStrokePath(context);
     imageView.image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();*/
    
    //curvedSaveProp.image = [UIImage imageNamed:@"dot.png"];
    if (imageViewTag >= 301 && imageViewTag <= 304) {
        UIImageView *curvedSaveProp = (UIImageView *)[self.view viewWithTag:imageViewTag];
        
        if (tag == 1) {//11
            //UIImageView *curvedSaveProp = (UIImageView *)[self.view viewWithTag:301];
            curvedSaveProp.image = [UIImage imageNamed:@"line.png"];
        }
        else if (tag == 3)//12
        {
            //UIImageView *curvedSaveProp = (UIImageView *)[self.view viewWithTag:302];
            curvedSaveProp.image = [UIImage imageNamed:@"oval.png"];
        }
        else if (tag == 4)//13
        {
            //UIImageView *curvedSaveProp = (UIImageView *)[self.view viewWithTag:303];
            curvedSaveProp.image = [UIImage imageNamed:@"dot.png"];
        }
        else if (tag == 6)//13
        {
            //UIImageView *curvedSaveProp = (UIImageView *)[self.view viewWithTag:304];
            curvedSaveProp.image = [UIImage imageNamed:@"oval_cut.png"];
        }
    }
    
    
}

#pragma mark---- Check status for mono/stereo and store button enable or diable---
-(void)checkStatus{
    /*if((([_mBankButton.titleLabel.text isEqualToString:@"Bank 1"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 2"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 3"]) && isStereo == NO )||(([_mBankButton.titleLabel.text isEqualToString:@"Bank 4"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 5"]) && isStereo == YES)){
     _mStoreButton.enabled=YES;
     
     }
     else{
     _mStoreButton.enabled=NO;
     }*/
    
    //Modified by subhra
    
    if(([_mBankButton.titleLabel.text isEqualToString:@"Bank 1"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 2"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 3"])||([_mBankButton.titleLabel.text isEqualToString:@"Bank 4"]||[_mBankButton.titleLabel.text isEqualToString:@"Bank 5"])){
        _mStoreButton.enabled=YES;
        
    }
    else{
        _mStoreButton.enabled=NO;
    }
}


- (void)createToneUnit
{
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
    NSAssert1(toneUnit, @"Error creating unit: %hd", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderToneStereoMono;
    input.inputProcRefCon = (__bridge void *)(self);
    err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    NSAssert1(err == noErr, @"Error setting callback: %hd", err);
    
    if (isStereo == YES) {
        // Set the format to 32 bit, Double channel, floating point, linear PCM
        const int four_bytes_per_float = 4;
        const int eight_bits_per_byte = 8;
        AudioStreamBasicDescription streamFormat;
        streamFormat.mSampleRate = sampleRate;
        streamFormat.mFormatID = kAudioFormatLinearPCM;
        streamFormat.mFormatFlags =
        kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
        streamFormat.mBytesPerPacket = four_bytes_per_float;
        streamFormat.mFramesPerPacket = 1;
        streamFormat.mBytesPerFrame = four_bytes_per_float;
        streamFormat.mChannelsPerFrame = 2;
        streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
        err = AudioUnitSetProperty (toneUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &streamFormat,
                                    sizeof(AudioStreamBasicDescription));
        NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
        
    }
    else {
        // Set the format to 32 bit, single channel, floating point, linear PCM
        const int four_bytes_per_float = 4;
        const int eight_bits_per_byte = 8;
        AudioStreamBasicDescription streamFormat;
        streamFormat.mSampleRate = sampleRate;
        streamFormat.mFormatID = kAudioFormatLinearPCM;
        streamFormat.mFormatFlags =
        kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
        streamFormat.mBytesPerPacket = four_bytes_per_float;
        streamFormat.mFramesPerPacket = 1;
        streamFormat.mBytesPerFrame = four_bytes_per_float;
        streamFormat.mChannelsPerFrame = 1;
        streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
        err = AudioUnitSetProperty (toneUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &streamFormat,
                                    sizeof(AudioStreamBasicDescription));
        NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
    }
}

- (void)stop
{
    if (toneUnit)
    {
        
    }
}

-(void)CheckToneUnit{
    if (toneUnit)
    {
        
        isChangeModeOnFly=0;
        //_lowerFrequencySlider.userInteractionEnabled = YES;
        _frequencySlider.userInteractionEnabled = YES;
        //_upperFrequencySlider.userInteractionEnabled = YES;
        AudioOutputUnitStop(toneUnit);
        AudioUnitUninitialize(toneUnit);
        AudioComponentInstanceDispose(toneUnit);
        toneUnit = nil;
        if (autoTimer) {
            [autoTimer invalidate];
            autoTimer = nil;
        }
        [_mPlayStopButton setImage:[UIImage imageNamed:@"Sound.png"] forState:UIControlStateNormal];
    }
    else
    {
        isChangeModeOnFly=1;
        
        [self createToneUnit];
        
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(toneUnit);
        NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
        
        // Start playback
        err = AudioOutputUnitStart(toneUnit);
        NSAssert1(err == noErr, @"Error starting unit: %hd", err);
        
        [_mPlayStopButton setImage:[UIImage imageNamed:@"Mute.png"] forState:UIControlStateNormal];
    }
}

-(void)checkMonoSteroButton{
    
    
    [_upperFrequencyPicker reloadAllComponents];
    [_lowerFrequencyPicker reloadAllComponents];
    [_lowerFrequencyPicker selectRow:0 inComponent:0 animated:YES];
    
    
    if (isStereo == YES) {
        [(UIButton *)[self.mMenuView viewWithTag:13] setBackgroundImage:[UIImage imageNamed:@"semi_select_dropdown.png"] forState:UIControlStateNormal];
        if(self.mGeneralModeButton.tag == 13)
        {
            [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"semi_select.png"] forState:UIControlStateNormal];//Modified by subhra
            playMode = @"4";
        }
        timeSlot = 0;
        _mTimeLabel.text = [stereoTimeArray objectAtIndex:timeSlot];
        //[_mStereoMonoButton setTitle:@"Stereo" forState:UIControlStateNormal];
        [_mStereoMonoButton setBackgroundImage:[UIImage imageNamed:@"stereo.png"] forState:UIControlStateNormal];
        _mSemiButton.hidden = NO;
        //_mWholeButton.hidden = NO;
        //_mOctaveButton.hidden = YES;
        [(UIButton *)[self.mMenuView viewWithTag:13] setEnabled:YES];
    } else {
        NSLog(@"STEREO = NO");
        //[(UIButton *)[self.mMenuView viewWithTag:13] setBackgroundImage:[UIImage imageNamed:@"octave_select_dropdown.png"] forState:UIControlStateNormal];
        [(UIButton *)[self.mMenuView viewWithTag:13] setBackgroundImage:nil forState:UIControlStateNormal];
        [(UIButton *)[self.mMenuView viewWithTag:13] setEnabled:NO];
        if(self.mGeneralModeButton.tag == 13)
        {
            /*
             [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"octave_select.png"] forState:UIControlStateNormal];//Modified by subhra
             playMode = @"6";
             */
        }
        timeSlot = 0;
        _mTimeLabel.text = [monoTimeArray objectAtIndex:timeSlot];
        //[_mStereoMonoButton setTitle:@"Mono" forState:UIControlStateNormal];
        [_mStereoMonoButton setBackgroundImage:[UIImage imageNamed:@"mono.png"] forState:UIControlStateNormal];
        _mSemiButton.hidden = YES;
        //_mWholeButton.hidden = YES;
        //_mOctaveButton.hidden = NO;
        //[_mOctaveButton setFrame:CGRectMake(_mOctaveButton.frame.origin.x, _mSmoothButton.frame.origin.y+_mSmoothButton.frame.size.height, _mOctaveButton.frame.size.width, _mOctaveButton.frame.size.height)];
    }
    [self setMaximumFrequency];
    
    //NSLog(@"%f",maximumFrequency);
    
    [_frequencySlider setMaximumValue:maximumFrequency];
    //[self resizeSlider:_upperFrequencySlider];
    //[_upperFrequencySlider setMaximumValue:maximumFrequency+.001f];
    //[_upperFrequencySlider setMinimumValue:33.0f];//paddy NAN issue
    //[_upperFrequencySlider setValue:[_upperFrequencySlider maximumValue] animated:NO];
    
    //Sayak
    //    if (_lowerFrequencySlider.value>=65) {
    [self setMinimumFrequency];
    
    //NSLog(@"%f",minimumFrequency);
    
    [_frequencySlider setMinimumValue:minimumFrequency];
    //[self resizeSlider:_lowerFrequencySlider];
    //[_lowerFrequencySlider setMaximumValue:maximumFrequency+.001f];
    //[_lowerFrequencySlider setMinimumValue:33.0f];//paddy NAN issue
    //[_lowerFrequencySlider setValue:[_lowerFrequencySlider minimumValue] animated:NO];
    //[self setTextType:_lowerFrequencyTextField value:[_lowerFrequencySlider value]];
    //    }
    
    //[self setTextFieldPosition:_lowerFrequencyTextField];
    //[self setTextFieldPosition:_upperFrequencyTextField];
    [self setTextFieldPosition:_thumbTextField];
    [self setTextType:_thumbTextField value:[_frequencySlider value]];
    //[self setTextType:_upperFrequencyTextField value:[_upperFrequencySlider value]];
    frequency = [_frequencySlider value];
}

-(void)checkPlayMode{
    [_mToneButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    [_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    [_mSmoothButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    [_mSemiButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    //[_mWholeButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    //[_mOctaveButton setBackgroundImage:[UIImage imageNamed:@"plain.png"] forState:UIControlStateNormal];
    [_mSweepMenuView setHidden:YES];
    //_upperFrequencySlider.userInteractionEnabled = YES;
    switch ([playMode integerValue]) {
        case 1:
        {
            [_mToneButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setTitle:@"Sweep" forState:UIControlStateNormal];
        }
            break;
        case 2:
        {
            [_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
        }
            break;
        case 3:
        {
            [_mSmoothButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setTitle:@"Smooth" forState:UIControlStateNormal];
        }
            break;
        case 4:
        {
            [_mSemiButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setTitle:@"Semi" forState:UIControlStateNormal];
        }
            break;
        case 5:
        {
            //[_mWholeButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            //[_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            //[_mSweepMenuButton setTitle:@"Whole" forState:UIControlStateNormal];
        }
            break;
        case 6:
        {
            //[_mOctaveButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            [_mSweepMenuButton setBackgroundImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
            //[_mSweepMenuButton setTitle:@"Octave" forState:UIControlStateNormal];
            //_upperFrequencySlider.userInteractionEnabled = NO;
        }
            break;
            
        default:
            break;
    }
    if (toneUnit) {
        [self CheckToneUnit];
    }
}

-(void)onTimer{
    switch ([playMode integerValue]) {
        case 3:
        {
            if (isMovingForword == YES) {
                frequency+=incrementFrequencyMove;
            }
            else{
                frequency-=incrementFrequencyMove;
            }
            if (frequency>=[_frequencySlider maximumValue] && isMovingForword == YES) {
                isMovingForword = NO;
            }
            else if(frequency<=[_frequencySlider minimumValue]){
                isMovingForword = YES;
            }
        }
            break;
        case 4:
        {
            if (flagIndex == semiSweepArray.count && isMovingForword == YES) {
                flagIndex-=2;
                isMovingForword = NO;
            }
            else if(flagIndex<0){
                [autoTimer invalidate];
                autoTimer = nil;
                [self CheckToneUnit];
                return;
            }
            frequency = [[semiSweepArray objectAtIndex:flagIndex] floatValue];
            if (isMovingForword == YES) {
                flagIndex++;
            }
            else{
                flagIndex--;
            }
        }
            break;
        case 5:
        {
            if (flagIndex == wholeSweepArray.count && isMovingForword == YES) {
                flagIndex-=2;
                isMovingForword = NO;
            }
            else if(flagIndex<0){
                [autoTimer invalidate];
                autoTimer = nil;
                [self CheckToneUnit];
                return;
            }
            frequency = [[wholeSweepArray objectAtIndex:flagIndex] floatValue];
            if (isMovingForword == YES) {
                flagIndex++;
            }
            else{
                flagIndex--;
            }
        }
            break;
        case 6:
        {
            if (flagIndex+12>= totalFrequencyArray.count && isMovingForword == YES) {
                isMovingForword = NO;
            }
            else if(flagIndex<0){
                //-----Modified by subhra------//
                // [autoTimer invalidate];
                // autoTimer = nil;
                // [self CheckToneUnit];
                
                frequency = [_frequencySlider minimumValue];
                for (int i=0; i<totalFrequencyArray.count; i++) {
                    if([_frequencySlider minimumValue]==[[totalFrequencyArray objectAtIndex:i] floatValue]){
                        flagIndex=i+12;
                        break;
                    }
                }
                isMovingForword=YES;
                
                //return;
                
                //------End of modification----//
            }
            frequency = [[totalFrequencyArray objectAtIndex:flagIndex] floatValue];
            if (isMovingForword == YES) {
                flagIndex+=12;
            }
            else{
                flagIndex-=12;
            }
            
        }
            break;
            
        default:
            break;
    }
    [_frequencySlider setValue:frequency];
    [self setTextFieldPosition:_thumbTextField];
    [self setTextType:_thumbTextField value:[_frequencySlider value]];
    //[self resizeSlider:_lowerFrequencySlider];
    //[self resizeSlider:_upperFrequencySlider];
}

-(void)updateCurrentTime{
    NSString *str=[[NSUserDefaults standardUserDefaults] stringForKey:@"clock/timer"];
    if ([str isEqualToString:@"timer"]) {
        if (!toneUnit) {
            _mClockLabel.text=@"00:00:00";
        }
        else{
            slaceTimer++;
            _mClockLabel.text=[NSString stringWithFormat:@"%02d:%02d:%02d",(slaceTimer/60)/60,slaceTimer/60,slaceTimer%60];
        }
    }
    else{
        [dateFormatter setDateFormat:@"hh:mm a"];
        NSString *currentTime=[dateFormatter stringFromDate:[NSDate date]];
        
        if ([currentTime hasPrefix:@"0"]) {
            currentTime = [currentTime substringFromIndex:1];
        }
        
        _mClockLabel.text=currentTime;
    }
}


- (IBAction)didTapMenuButton:(id)sender
{
    if(self.mMenuView.hidden)
    {
        self.mMenuView.hidden = NO;
    }
    else
    {
        self.mMenuView.hidden = YES;
    }
}


- (IBAction)didTapModeButtons:(id)sender
{
    [self stopAndReinitiateSliders];
    
    self.mMenuView.hidden = YES;
    UIButton *button = (UIButton *)sender;
    [self.mGeneralModeButton setBackgroundImage:[button backgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
    self.mGeneralModeButton.tag = button.tag;
    switch (button.tag)
    {
        case 11:
            [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"tone_select.png"] forState:UIControlStateNormal];//Modified by subhra
            playMode = @"1";
            break;
            
        case 12:
            [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"smooth_select.png"] forState:UIControlStateNormal];//Modified by suhra
            playMode = @"3";
            break;
            
        case 13:
        {
            if(isStereo)
            {
                [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"semi_select.png"] forState:UIControlStateNormal];//Modified by subhra
                playMode = @"4";
                break;
            }
            else
            {
                /*
                 [self.mGeneralModeButton setBackgroundImage:[UIImage imageNamed:@"octave_select.png"] forState:UIControlStateNormal];//Modified by subhra
                 playMode = @"6";
                 [self.mNoteHzSwitch setOn:YES animated:YES];
                 isNote = YES;
                 [_frequencySlider setMinimumValue:32.7];
                 
                 //NSLog(@"%f",_frequencySlider.maximumValue);
                 
                 [_frequencySlider setMaximumValue:130.81];
                 [_frequencySlider setValue:130.81];
                 //[self setTextType:_lowerFrequencyTextField value:32.7];
                 //[self setTextType:_upperFrequencyTextField value:[_frequencySlider maximumValue]];
                 [self didTapFrequencyChange:_frequencySlider];
                 break;
                 */
            }
            
        }
            
        default:
            break;
    }
}

@end
