//
//  Settings.h
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 27/06/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol settingMenuDelegate <NSObject>

@optional
-(void) updateFrequencyValue;
-(void) updateDictionary;
@end


@interface Settings : UIViewController{

}
@property(weak,nonatomic) id <settingMenuDelegate>delegate;

@property (strong, nonatomic) IBOutlet UISegmentedControl *mClockTimerSegmentedControl;
@property (strong, nonatomic) IBOutlet UISlider *mSlider;
@property (strong, nonatomic) IBOutlet UILabel *mFrequencyLabel;
@property (strong, nonatomic) IBOutlet UISlider *mAmpliflierSlider;
@property (strong, nonatomic) IBOutlet UILabel *mAmplificationLevel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *mSharpBSegmentedControl;


- (IBAction)didTapToSelectClockOrTimer:(id)sender;
- (IBAction)sliderChangeValue:(id)sender;
- (IBAction)didTapToChangeAmplification:(id)sender;
- (IBAction)didTapToSelectSharpOrB:(id)sender;

@end
