//
//  AudioQueue.h
//  TestNESiOS
//
//  Created by arvin on 8/27/17.
//  Copyright © 2017 arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenAL/OpenAL.h>

@interface AudioQueue : NSObject
{
    ALCdevice* mDevice;
    ALCcontext* mContext;
    ALuint outSourceID;
    
    NSLock* lock;
}

+ (id)sharePalyer;
- (void)openAudio:(short*)data dataSize:(UInt32)dataSize;

@end
