//
//  spineOmaticViewController.h
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 07/10/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UiSliderSubClass.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioUnit/AudioUnit.h>
#import "Settings.h"
#import "DCRoundSwitch.h"

#define saveFrequencyTag 100
#define saveTimeTag 200
#define saveCurveImageTag 300
#define saveMonoOrStereoTag 500

@interface spineOmaticViewController : UIViewController<customSliderDelegate,UITextFieldDelegate,settingMenuDelegate>{
    int slot, totaltime, flagIndex, slaceTimer, timeSlot;
    float upperFrequency, lowerFrequency, maximumFrequency, minimumFrequency, slidertapValue;
    double incrementFrequencyMove;
    NSMutableDictionary *noteDictionary, *hertzDictionary;
    NSMutableArray *totalFrequencyArray, *semiSweepArray, *wholeSweepArray, *monoTimeArray, *stereoTimeArray;//, *octaveSweepArray;
    NSString *flagText,*playMode;
    NSTimer *autoTimer, *clockTimer;
    NSDateFormatter *dateFormatter;
	AudioComponentInstance toneUnit;
    UIPopoverController *pop;
    NSMutableArray *hertzArray;
    NSArray *noteArray;
    
    //NSMutableArray *upperFrequencyValues;
    //NSMutableArray *lowerFrequencyValues;
    
@public
    BOOL isStereo, isNote, isSavePossible, isMovingForword;
	double frequency;
	double sampleRate;
	double theta1;
	double theta2;
    
    BOOL isMovingUpperSlider;//paddy
    float maxUpperSliderX;//paddy
}
@property (weak, nonatomic) IBOutlet UiSliderSubClass *frequencySlider;
//@property (weak, nonatomic) IBOutlet UiSliderSubClass *lowerFrequencySlider;
@property (weak, nonatomic) IBOutlet UITextField *thumbTextField;
//@property (weak, nonatomic) IBOutlet UITextField *lowerFrequencyTextField;
@property (weak, nonatomic) IBOutlet UIButton *hertzNoteButton;
//@property (weak, nonatomic) IBOutlet UiSliderSubClass *upperFrequencySlider;
//@property (weak, nonatomic) IBOutlet UITextField *upperFrequencyTextField;
@property (strong, nonatomic) IBOutlet UIView *mPopUpImageview;
@property (strong, nonatomic) IBOutlet UILabel *mPopupLabel;
@property (weak, nonatomic) IBOutlet UIButton *mBankButton;
@property (weak, nonatomic) IBOutlet UIButton *mStoreButton;
@property (weak, nonatomic) IBOutlet UILabel *mTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *mPlayStopButton;
@property (weak, nonatomic) IBOutlet UIButton *mStereoMonoButton;
@property (weak, nonatomic) IBOutlet UIButton *mToneButton;
@property (weak, nonatomic) IBOutlet UIButton *mSweepMenuButton;
@property (weak, nonatomic) IBOutlet UIView *mSweepMenuView;
@property (weak, nonatomic) IBOutlet UIButton *mSmoothButton;
@property (weak, nonatomic) IBOutlet UIButton *mSemiButton;
@property (weak, nonatomic) IBOutlet UIButton *mWholeButton;
@property (weak, nonatomic) IBOutlet UIButton *mOctaveButton;
@property (weak, nonatomic) IBOutlet UILabel *mClockLabel;
@property (weak, nonatomic) IBOutlet UIButton *mSettingButton;
@property (weak, nonatomic) IBOutlet UIView *mMenuView;
@property (weak, nonatomic) IBOutlet UIButton *mGeneralModeButton;
//@property (weak, nonatomic) IBOutlet UISwitch *mNoteHzSwitch;

@property (weak, nonatomic) IBOutlet DCRoundSwitch *mNoteHzSwitch;

@property (weak, nonatomic) IBOutlet UIPickerView *lowerFrequencyPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *upperFrequencyPicker;
@property (weak, nonatomic) IBOutlet UIImageView *hertzNoteToggleImage;

- (void)stop;

- (IBAction)didTapFrequencyChange:(id)sender;
- (IBAction)didTapChangeLowerFrequency:(id)sender;
- (IBAction)didTapChangeHertzNote:(id)sender;
- (IBAction)didTapUpperFrequencyChange:(id)sender;
- (IBAction)didTapDownFrequencySlider:(id)sender;
- (IBAction)didTapFinishSlider:(id)sender;
- (IBAction)didTapToSaveLoadSlot:(id)sender;
- (IBAction)didTapToSelectBank:(id)sender;
- (IBAction)didTapToStoreDetails:(id)sender;
- (IBAction)didTapPlayStopButton:(id)sender;
- (IBAction)didTapToChangeMonoStereo:(id)sender;
- (IBAction)didTapToChangeInToneMode:(id)sender;
- (IBAction)didTapToOPENSWEEPMENU:(id)sender;
- (IBAction)didTapToChangeInSmoothMode:(id)sender;
- (IBAction)didTapToChangeInSemiMode:(id)sender;
- (IBAction)didTaptoChangeInWholeButton:(id)sender;
//- (IBAction)didTapToChangeInOctaveMode:(id)sender;
- (IBAction)didTapUpArrow:(id)sender;
- (IBAction)didTapDownArrow:(id)sender;
- (IBAction)didTapOpenSettingMenu:(id)sender;
- (IBAction)didTapHertzNoteToggle:(id)sender;

//--------Modification By subhra-----//

-(void)stopAndReinitiateSliders;
-(void)loadModeFromMemoryWithDic:(NSDictionary*)_dic;

- (void) addValueToArray:(NSMutableArray *)array value:(float)val;





@end
