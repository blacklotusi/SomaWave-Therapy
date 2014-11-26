//
//  UiSliderSubClass.h
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 03/05/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UiSliderSubClass;

@protocol customSliderDelegate <NSObject>

@optional

-(void) notifyTouchFinish :(UISlider *)slider;

-(void) enableTextEditing :(UISlider *)slider;

@end

@interface UiSliderSubClass : UISlider

@property(weak, nonatomic) id <customSliderDelegate>delegate;

@property (assign, nonatomic, readonly) float scrubbingSpeed;
@property (strong, nonatomic) NSArray *scrubbingSpeeds;
@property (strong, nonatomic) NSArray *scrubbingSpeedChangePositions;

@end
