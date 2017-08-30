//
//  AudioQueue.m
//  TestNESiOS
//
//  Created by arvin on 8/27/17.
//  Copyright © 2017 arvin. All rights reserved.
//

#import "AudioQueue.h"

@implementation AudioQueue

static AudioQueue *_player;

+ (id)sharePalyer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_player == nil) {
            _player = [[AudioQueue alloc] init];
            [_player initOpenAL];
        }
    });
    return _player;
}

-(void)initOpenAL
{
    mDevice=alcOpenDevice(NULL);
    if (mDevice) {
        mContext=alcCreateContext(mDevice, NULL);
        alcMakeContextCurrent(mContext);
    }
    
    alGenSources(1, &outSourceID);
    alSourcei(outSourceID, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(outSourceID, AL_PITCH, 1.0f);
    alSourcef(outSourceID, AL_GAIN, 1.0f);
    
    lock = [[NSLock alloc] init];
}


- (void)openAudio:(short*)data dataSize:(UInt32)dataSize
{
    
    if (data == NULL) {
        return;
    }
    
    [lock lock];
    
    ALint st;

    alGetSourcei(outSourceID, AL_SOURCE_STATE, &st);
    if (st != AL_STOPPED){
        alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &st);
        ALuint buff;
        while (st--) {
            alSourceUnqueueBuffers(outSourceID, 1, &buff);
            alDeleteBuffers(1, &buff);
        }
    }
    
    ALuint bufferID;
    alGenBuffers(1, &bufferID);
    alBufferData(bufferID, AL_FORMAT_MONO16, (const ALvoid*)data, (ALsizei)(dataSize*sizeof(short)), 44100);
    alSourceQueueBuffers(outSourceID, 1, &bufferID);
    
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &st);
    if (st != AL_PLAYING) {
        alSourcePlay(outSourceID);
    }
    
    [lock unlock];
    
}


@end
