//
//  AUGraphMixerV2.h
//  RecordMixerText
//
//  Created by XingTu on 2019/1/30.
//  Copyright © 2019 IXingTu. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVAudioFormat.h>

#define MAXBUFS  2
#define NUMFILES 2

typedef struct {
    AudioStreamBasicDescription asbd;
    Float32 *data;
    UInt32 numFrames;
    UInt32 sampleNum;
} SoundBuffer, *SoundBufferPtr;


NS_ASSUME_NONNULL_BEGIN

@interface AUGraphMixerV2 : NSObject
{
    CFURLRef sourceURL[2];
    
    AVAudioFormat *mAudioFormat;
    
    AUGraph   mGraph;
    AudioUnit mMixer;
    AudioUnit mOutput;
    
    SoundBuffer mSoundBuffer[MAXBUFS];
    
    Boolean isPlaying;
}

@property (readonly, nonatomic) Boolean isPlaying;

- (void)initializeAUGraph;

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value;
- (void)setOutputVolume:(AudioUnitParameterValue)value;

- (void)startAUGraph;
- (void)stopAUGraph;

@end

NS_ASSUME_NONNULL_END
