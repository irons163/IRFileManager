//
//  Video.h
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//
//  Copyright 2010 Lajos Kamocsay
//
//  lajos at codza dot com
//
//  iFrameExtractor is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
// 
//  iFrameExtractor is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//

#define RECORD_VIDEO_IFRAME 0x01
#define RECORD_VIDEO_PFRAME 0x02
#define RECORD_AUDIO_FRAME  0x03


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

//@interface VideoFrameExtractor : NSObject {
@interface VideoFrameExtractor : NSObject {
    
	AVFormatContext *pFormatCtx;
//	AVCodecContext *pCodecCtx;
//    AVFrame *pFrame;
    AVPacket packet;
	AVPicture picture;
	int videoStream;
    int audioStream;
	struct SwsContext *img_convert_ctx;
	int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
	UIImage *currentImage;
	double duration;
    double currentTime;
    
    GLuint _program;
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
@public
    AVCodecContext *pCodecCtx;
    AVCodecContext  *pAudioCtx;
    AVFrame *pFrame;
}

/* Last decoded picture as UIImage */
@property (weak, nonatomic, readonly) UIImage *currentImage;

/* Size of video frame */
@property (nonatomic, readonly) int sourceWidth, sourceHeight;
@property (nonatomic, readonly) AVCodecContext *pCodecCtx;

/* Output image size. Set to the source size by default. */
@property (nonatomic) int outputWidth, outputHeight;

/* Length of video in seconds */
@property (nonatomic, readonly) double duration;

/* Current time of video in seconds */
@property (nonatomic, readonly) double currentTime;
@property (nonatomic, readonly) double fps;
//@property (nonatomic, readonly)   GLuint _program;
//@property (nonatomic, readonly)   GLuint _positionVBO;
//@property (nonatomic, readonly)   GLuint _texcoordVBO;
//@property (nonatomic, readonly)   GLuint _indexVBO;

/* Initialize with movie at moviePath. Output dimensions are set to source dimensions. */
-(id)initWithVideo:(NSString *)moviePath;
-(id)initWithVideoMemory:(NSString *)moviePath;
/* Read the next frame from the video stream. Returns false if no frame read (video over). */
-(BOOL)stepFrame;
-(BOOL) getAVPacket:(AVPacket *) _packet frameType:(int*) _frameType;
-(int64_t) getDuration;
/* Seek to closest keyframe near specified time */
-(void)seekTime:(double)seconds;

-(AVCodecContext *) getVideoCodecContext;
-(AVCodecContext *) getAudioCodecContext;

-(AVStream *) getVideoStream;
-(AVStream *) getAudioStream;
@end
