//
//  AUGraphMixerV2.m
//  RecordMixerText
//
//  Created by XingTu on 2019/1/30.
//  Copyright © 2019 IXingTu. All rights reserved.
//

#import "AUGraphMixerV2.h"
#import <AVFoundation/AVFoundation.h>

#define AVPLAYERITEM_STATUS @"status"

const Float64 kGraphSampleRate = 44100.0;


#pragma mark- RenderProc

// audio render procedure, don't allocate memory, don't take any locks, don't waste time, printf statements for debugging only may adversly affect render you have been warned
static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    
      AUGraphMixerV2* aUGraphMixer = (__bridge AUGraphMixerV2 *)(inRefCon);
    
    if(0 == inBusNumber){
        
      
        
        
        SoundBufferPtr sndbuf = aUGraphMixer->mSoundBuffer;
        
        UInt32 sample = sndbuf[inBusNumber].sampleNum;      // frame number to start from
        UInt32 bufSamples = sndbuf[inBusNumber].numFrames;  // total number of frames in the sound buffer
        Float32 *in = sndbuf[inBusNumber].data; // audio data buffer
        
        Float32 *outA = (Float32 *)ioData->mBuffers[0].mData; // output audio buffer for L channel
        Float32 *outB = (Float32 *)ioData->mBuffers[1].mData; // output audio buffer for R channel
        
        // for demonstration purposes we've configured 2 stereo input busses for the mixer unit
        // but only provide a single channel of data from each input bus when asked and silence for the other channel
        // alternating as appropriate when asked to render bus 0 or bus 1's input
        for (UInt32 i = 0; i < inNumberFrames; ++i) {
            
            if (1 == inBusNumber) {
                
                //            outA[i] = 0;
                //            outB[i] = in[sample++];
                //双声道
                outA[i] = in[sample++];
                outB[i] = in[sample++];
            } else {
                
                //            outA[i] = in[sample++];
                //            outB[i] = 0;
                
                //双声道
                outA[i] = in[sample++];
                outB[i] = in[sample++];
            }
            
            if (sample > bufSamples) {
                // start over from the beginning of the data, our audio simply loops
                printf("looping data for bus %d after %ld source frames rendered\n", (unsigned int)inBusNumber, (long)sample-1);
                sample = 0;
            }
        }
        
        sndbuf[inBusNumber].sampleNum = sample; // keep track of where we are in the source data buffer
        
        //printf("bus %d sample %d\n", (unsigned int)inBusNumber, (unsigned int)sample);
    }else{
        
        Float32 *outA = (Float32 *)ioData->mBuffers[0].mData; // output audio buffer for L channel
        Float32 *outB = (Float32 *)ioData->mBuffers[1].mData;



        for (UInt32 i = 0; i < inNumberFrames; ++i) {
        
            
           // 双声道
//            outA[i] = in[i];
//            outB[i] = in[i];
//
//            NSLog(@"in[i]:%f",in[i]);
           
        }
    
        
    }
   
    
    return noErr;
}


static OSStatus XTRecordCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    
     AUGraphMixerV2* aUGraphMixer = (__bridge AUGraphMixerV2 *)(inRefCon);
    

    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    
    OSStatus status = AudioUnitRender(aUGraphMixer->mOutput, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    
    if (status != noErr) {
        NSLog(@"AudioUnitRender error:%d", status);
    }else{
        NSLog(@"AudioUnitRender success");
        
        [aUGraphMixer writePCMData:bufferList.mBuffers[0].mData size:bufferList.mBuffers[0].mDataByteSize];
    }
    
//     UInt32 samples = (UInt32)(aUGraphMixer->mRecordBuffer.numFrames + inNumberFrames) * aUGraphMixer->mRecordBuffer.asbd.mChannelsPerFrame;
//    if(aUGraphMixer->mRecordBuffer.data){
//        aUGraphMixer->mRecordBuffer.data = realloc(aUGraphMixer->mRecordBuffer.data, samples * sizeof(Float32));
//        NSLog(@"动态增加内存");
//    }else{
//        aUGraphMixer->mRecordBuffer.data = calloc(samples, sizeof(Float32));
//        NSLog(@"第一次内存");
//    }
    
    
    
    
   //赋值
   
    return noErr;
}

@interface AUGraphMixerV2 ()

- (void)loadFiles;

@property AVPlayerItem* avPlayerItem;

@property AVPlayer* avPlayer;

@end

@implementation AUGraphMixerV2


@synthesize isPlaying;


- (void)dealloc
{
    printf("MultichannelMixerController dealloc\n");
    
    DisposeAUGraph(mGraph);
    
    free(mSoundBuffer[0].data);
    free(mSoundBuffer[1].data);
    
    CFRelease(sourceURL[0]);
    CFRelease(sourceURL[1]);
    
//    [mAudioFormat release];
    
//    [super dealloc];
}

// load up audio data from the demo files into mSoundBuffer.data used in the render proc
- (void)loadFiles
{
    
    //单声道伴奏
    AVAudioFormat *clientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                   sampleRate:kGraphSampleRate
                                                                     channels:2
                                                                  interleaved:YES];
    
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++)  {
        printf("loadFiles, %d\n", i);
        
        ExtAudioFileRef xafref = 0;
        
        // open one of the two source files
        OSStatus result = ExtAudioFileOpenURL(sourceURL[i], &xafref);
        if (result || !xafref) { printf("ExtAudioFileOpenURL result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); break; }
        
        // get the file data format, this represents the file's actual data format
        AudioStreamBasicDescription fileFormat;
        UInt32 propSize = sizeof(fileFormat);
        
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
        if (result) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); break; }
        
        // set the client format - this is the format we want back from ExtAudioFile and corresponds to the format
        // we will be providing to the input callback of the mixer, therefore the data type must be the same
        
        // used to account for any sample rate conversion
        double rateRatio = kGraphSampleRate / fileFormat.mSampleRate;
        
        propSize = sizeof(AudioStreamBasicDescription);
        result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, propSize, clientFormat.streamDescription);
        if (result) { printf("ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); break; }
        
        // get the file's length in sample frames
        UInt64 numFrames = 0;
        propSize = sizeof(numFrames);
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
        if (result) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); break; }
        printf("File %d, Number of Sample Frames: %u\n", i, (unsigned int)numFrames);
        
        numFrames = (numFrames * rateRatio); // account for any sample rate conversion
        printf("File %d, Number of Sample Frames after rate conversion (if any): %u\n", i, (unsigned int)numFrames);
        
        // set up our buffer
        mSoundBuffer[i].numFrames = (UInt32)numFrames;
        mSoundBuffer[i].asbd = *(clientFormat.streamDescription);
        
        UInt32 samples = (UInt32)numFrames * mSoundBuffer[i].asbd.mChannelsPerFrame;
        mSoundBuffer[i].data = (Float32 *)calloc(samples, sizeof(Float32));
        mSoundBuffer[i].sampleNum = 0;
        
        // set up a AudioBufferList to read data into
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        
        //单声道伴奏1
        bufList.mBuffers[0].mNumberChannels = 2;
        bufList.mBuffers[0].mData = mSoundBuffer[i].data;
        bufList.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
        
        // perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
        UInt32 numPackets = (UInt32)numFrames;
        result = ExtAudioFileRead(xafref, &numPackets, &bufList);
        if (result) {
            printf("ExtAudioFileRead result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result);
            free(mSoundBuffer[i].data);
            mSoundBuffer[i].data = 0;
        }
        
        // close the file and dispose the ExtAudioFileRef
        ExtAudioFileDispose(xafref);
    }
    
//    [clientFormat release];
}

- (void)initializeAUGraph
{
  
    // audio session
   
    
    isPlaying = false;
    
    memset(&mSoundBuffer, 0, sizeof(mSoundBuffer));
    
    // create the URLs we'll use for source A and B
    NSString *sourceA = [[NSBundle mainBundle] pathForResource:@"123" ofType:@"mp3"];
    NSString *sourceB = [[NSBundle mainBundle] pathForResource:@"1234" ofType:@"mp3"];
    sourceURL[0] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceA, kCFURLPOSIXPathStyle, false);
    sourceURL[1] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceB, kCFURLPOSIXPathStyle, false);
    
    printf("initialize\n");
    
    AUNode outputNode;
    AUNode mixerNode;
    
    // this is the format for the graph
    mAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                    sampleRate:kGraphSampleRate
                                                      channels:2
                                                   interleaved:NO];
    
    OSStatus result = noErr;
    
    // load up the audio data
//    [self performSelectorInBackground:@selector(loadFiles) withObject:nil];
    
    [self loadFiles];
    
    // create a new AUGraph
    result = NewAUGraph(&mGraph);
    if (result) { printf("NewAUGraph result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    // create two AudioComponentDescriptions for the AUs we want in the graph
    
    // output unit
    
    AudioComponentDescription output_desc;
    output_desc.componentType = kAudioUnitType_Output;
    output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
    //kAudioUnitSubType_VoiceProcessingIO;
    output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    output_desc.componentFlagsMask = 0;
    output_desc.componentFlags = 0;
    
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
//    [session setPreferredIOBufferDuration:0.1 error:nil];
    
    NSError* error;
    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    if(error) {
        NSLog(@"切换到扬声器失败");
    }else{
          NSLog(@"切换到扬声器成功");
    }
    
    [session setActive:YES error:nil];
    
//    CAComponentDescription (kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
//    CAShowComponentDescription(&output_desc);
    
    // multichannel mixer unit
     AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;

    mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    //kAudioUnitSubType_VoiceProcessingIO;
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixer_desc.componentFlagsMask = 0;
    mixer_desc.componentFlags = 0;
    
//    CAComponentDescription (kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer, kAudioUnitManufacturer_Apple);
//    CAShowComponentDescription(&mixer_desc);
    
    printf("new nodes\n");
    
    // create a node in the graph that is an AudioUnit, using the supplied AudioComponentDescription to find and open that unit
    result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
    if (result) { printf("AUGraphNewNode 1 result %ld %4.4s\n", (long)result, (char*)&result); return; }
    
    result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode );
    if (result) { printf("AUGraphNewNode 2 result %ld %4.4s\n", (long)result, (char*)&result); return; }
    
    // connect a node's output to a node's input
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0);
    if (result) { printf("AUGraphConnectNodeInput result %ld %4.4s\n", (long)result, (char*)&result); return; }
    
    
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
    result = AUGraphOpen(mGraph);
    if (result) { printf("AUGraphOpen result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    if (result) { printf("AUGraphNodeInfo result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutput);
    if (result) { printf("AUGraphNodeInfo result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    // set bus count
    UInt32 numbuses = 2;
    
    printf("set input bus count %u\n", (unsigned int)numbuses);
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
    if (result) { printf("AudioUnitSetProperty result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    for (int i = 0; i < numbuses; ++i) {
        // setup render callback struct
        AURenderCallbackStruct rcbs;
        rcbs.inputProc = &renderInput;
        rcbs.inputProcRefCon = (__bridge void * _Nullable)(self);
        
        printf("set kAudioUnitProperty_SetRenderCallback for mixer input bus %d\n", i);
        
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &rcbs);
        // equivalent to AudioUnitSetProperty(mMixer, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &rcbs, sizeof(rcbs));
        if (result) { printf("AUGraphSetNodeInputCallback result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
        
        // set input stream format to what we want
        printf("set mixer input kAudioUnitProperty_StreamFormat for bus %d\n", i);
        
        result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
        if (result) { printf("AudioUnitSetProperty result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    }
    
    
    // audio format
    AudioStreamBasicDescription recordaudioFormat;
    recordaudioFormat.mSampleRate = 44100;
    recordaudioFormat.mFormatID = kAudioFormatLinearPCM;
    recordaudioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;
    recordaudioFormat.mFramesPerPacket = 1;
    recordaudioFormat.mChannelsPerFrame = 1;
    recordaudioFormat.mBytesPerPacket = 2;
    recordaudioFormat.mBytesPerFrame = 2;
    recordaudioFormat.mBitsPerChannel = 16;
    
    
    mRecordBuffer.asbd = recordaudioFormat;
    mRecordBuffer.numFrames = 0;
    mRecordBuffer.sampleNum = 0;
    
     result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &recordaudioFormat, sizeof(AudioStreamBasicDescription));
    
    if(!result){
        NSLog(@"kAudioUnitProperty_StreamFormat成功");
    }else{
        NSLog(@"kAudioUnitProperty_StreamFormat失败");
    }
    
    result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &recordaudioFormat, sizeof(AudioStreamBasicDescription));
    
    if(!result){
        NSLog(@"kAudioUnitProperty_StreamFormat成功");
    }else{
        NSLog(@"kAudioUnitProperty_StreamFormat失败");
    }
    
    //打开录音端口
    UInt32 flag = 1;
    result = AudioUnitSetProperty(mOutput, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    if(!result){
        NSLog(@"录音端口打开成功");
    }else{
        NSLog(@"录音端口打开失败");
    }
    
    
    //录音回调
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = XTRecordCallback;
    recordCallback.inputProcRefCon = (__bridge void *)self;
    
    result = AudioUnitSetProperty(mOutput,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Output,
                         1,
                         &recordCallback,
                         sizeof(recordCallback));
    
    if(!result){
        NSLog(@"录音回调设置成功");
    }else{
        NSLog(@"录音回调设置失败");
    }
    
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    if (result) { printf("AudioUnitSetProperty result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    printf("AUGraphInitialize\n");
    
    // now that we've set everything up we can initialize the graph, this will also validate the connections
    result = AUGraphInitialize(mGraph);
    if (result) { printf("AUGraphInitialize result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    CAShow(mGraph);
    
    [self enableInput:0 isOn:YES];
    [self enableInput:1 isOn:YES];
    [self setInputVolume:0 value:0.5];
    [self setInputVolume:1 value:0.5];
    [self setOutputVolume:0.8];
}


#pragma mark-

// enable or disables a specific bus
- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue
{
    printf("BUS %d isON %f\n", (unsigned int)inputNum, isONValue);
    
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
}

// sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value
{
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

// sets the overall mixer output volume
- (void)setOutputVolume:(AudioUnitParameterValue)value
{
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

// stars render
- (void)startAUGraph
{
    printf("PLAY\n");
    
    OSStatus result = AUGraphStart(mGraph);
    if (result) { printf("AUGraphStart result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    isPlaying = true;
    
    if(inputSteam){
         [inputSteam close];
    }
   
}

// stops render
- (void)stopAUGraph
{
    printf("STOP\n");
    
    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if (result) { printf("AUGraphIsRunning result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    if (isRunning) {
        result = AUGraphStop(mGraph);
        if (result) { printf("AUGraphStop result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
        isPlaying = false;
        
        
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"/record.pcm"];
        
        NSURL *url = [NSURL fileURLWithPath:path];
        
        inputSteam = [NSInputStream inputStreamWithURL:url];
    }
    
    NSLog(@"停止播放");
    [self createPlayableFileFromPcmData];
    
    
}

- (void)writePCMData:(Byte *)buffer size:(int)size {
    static FILE *file = NULL;
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"/record.pcm"];
    if (!file) {
        file = fopen(path.UTF8String, "w");
    }
    fwrite(buffer, size, 1, file);
}

- (void) createPlayableFileFromPcmData {
    
    FILE *fout;
    
    short NumChannels = 1;       //录音通道数
    short BitsPerSample = 16;    //线性采样位数
    int SamplingRate = 44100;     //录音采样率(Hz)
    
    NSString *pcmPath = [NSTemporaryDirectory() stringByAppendingString:@"/record.pcm"];
    
    int numOfSamples = (int)[[NSData dataWithContentsOfFile:pcmPath] length];
    
    int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
    
    short BlockAlign = NumChannels*BitsPerSample/8;
    
    int DataSize = NumChannels*numOfSamples*BitsPerSample/8;
    
    int chunkSize = 16;
    
    int totalSize = 46 + DataSize;
    
    short audioFormat = 1;
    
    NSString* wavPath = [NSTemporaryDirectory() stringByAppendingString:@"/recordwav.wav"];;
    
    if((fout = fopen([wavPath cStringUsingEncoding:NSUTF8StringEncoding], "w")) == NULL) {
        NSLog(@"createPlayableFileFromPcmData打开失败:%@",wavPath);
        return;
    }
    
    fwrite("RIFF", sizeof(char), 4,fout);
    fwrite(&totalSize, sizeof(int), 1, fout);
    fwrite("WAVE", sizeof(char), 4, fout);
    fwrite("fmt ", sizeof(char), 4, fout);
    fwrite(&chunkSize, sizeof(int),1,fout);
    fwrite(&audioFormat, sizeof(short), 1, fout);
    fwrite(&NumChannels, sizeof(short),1,fout);
    fwrite(&SamplingRate, sizeof(int), 1, fout);
    fwrite(&ByteRate, sizeof(int), 1, fout);
    fwrite(&BlockAlign, sizeof(short), 1, fout);
    fwrite(&BitsPerSample, sizeof(short), 1, fout);
    fwrite("data", sizeof(char), 4, fout);
    fwrite(&DataSize, sizeof(int), 1, fout);
    
    fclose(fout);
    
    NSMutableData *pamdata = [NSMutableData dataWithContentsOfFile:pcmPath];
    NSFileHandle* handle = [NSFileHandle fileHandleForUpdatingAtPath:wavPath];
    [handle seekToEndOfFile];
    [handle writeData:pamdata];
    [handle closeFile];
    
    NSLog(@"createPlayableFileFromPcmData成功:%@",wavPath);
    
    [self playWav:wavPath];
}

- (void) playWav:(NSString*) path {
    [self playMusic:[NSURL fileURLWithPath:path]];
}

- (void) playMusic:(NSURL*) url {
    self.avPlayerItem = [[AVPlayerItem alloc] initWithURL:url];
    [self.avPlayerItem addObserver:self forKeyPath:AVPLAYERITEM_STATUS options:NSKeyValueObservingOptionNew context:nil];
    self.avPlayer = [[AVPlayer alloc] init];
    [self.avPlayer replaceCurrentItemWithPlayerItem:self.avPlayerItem];
    
    NSLog(@"playWav");
}

// kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.avPlayerItem) {
        if ([keyPath isEqualToString:AVPLAYERITEM_STATUS]) {
            switch (self.avPlayerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"AVPlayerItemStatusReadyToPlay");
                    //推荐将视频播放放在这里
                    [self.avPlayer play];
                    
                    break;
                    
                case AVPlayerItemStatusUnknown:
                    NSLog(@"AVPlayerItemStatusUnknown");
                    
                    break;
                    
                case AVPlayerItemStatusFailed:
                    NSLog(@"AVPlayerItemStatusFailed");
                    
                    break;
                    
                default:
                    break;
            }
        }
    }
    
}

@end
