//
//  SCScrollableWaveformView.h
//  SCWaveformView
//
//  Created by Simon CORSIN on 24/02/15.
//  Copyright (c) 2015 Simon CORSIN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCWaveformView.h"



@class SCWaveformView;

@protocol CmTimeDelegate <NSObject>

@required
- (void)currentlySelectedPlaybackRange:(CMTimeRange)startRange end:(CMTime)endTime;

@end

@interface SCScrollableWaveformView : UIScrollView

/**
 The managed waveformView.
 */
@property (readonly, nonatomic) SCWaveformView *waveformView;
@property (nonatomic, weak) id <CmTimeDelegate> cmDelegate;

@end
