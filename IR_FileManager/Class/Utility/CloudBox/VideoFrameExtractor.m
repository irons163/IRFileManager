//
//  Video.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//  Copyright 2010 www.codza.com. All rights reserved.
//

#import "VideoFrameExtractor.h"
#import "Utilities.h"


@interface VideoFrameExtractor (private)
-(void)convertFrameToRGB;
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height;
-(void)savePicture:(AVPicture)pFrame width:(int)width height:(int)height index:(int)iFrame;
-(void)setupScaler;
@end



// 20130308 albert.liao modified start

// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

// 20130308 albert.liao modified end


@implementation VideoFrameExtractor
//@synthesize _program;
//@synthesize _positionVBO;
//@synthesize _texcoordVBO;
//@synthesize _indexVBO;
@synthesize pCodecCtx;

@synthesize outputWidth, outputHeight, fps;

-(void)setOutputWidth:(int)newValue {
	if (outputWidth == newValue) return;
	outputWidth = newValue;
	[self setupScaler];
}

-(void)setOutputHeight:(int)newValue {
	if (outputHeight == newValue) return;
	outputHeight = newValue;
	[self setupScaler];
}

-(UIImage *)currentImage {
	if (!pFrame->data[0]) return nil;
	[self convertFrameToRGB];
	return [self imageFromAVPicture:picture width:outputWidth height:outputHeight];
}

-(double)duration {
	return (double)pFormatCtx->duration / AV_TIME_BASE;
}

-(double)currentTime {
    AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
    return packet.pts * (double)timeBase.num / timeBase.den;
}

-(int)sourceWidth {
	return pCodecCtx->width;
}

-(int)sourceHeight {
	return pCodecCtx->height;
}

#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#define STREAM_FRAME_RATE 25 /* 25 images/s */
#define STREAM_PIX_FMT    PIX_FMT_YUV420P /* default pix_fmt */

/*
 00056  * add an audio output stream
 00057  */
static AVStream *add_audio_stream(AVFormatContext *oc, AVCodec **codec,enum AVCodecID codec_id)
{
         AVCodecContext *c;
        AVStream *st;
    
        /* find the audio encoder */
         *codec = avcodec_find_encoder(codec_id);
         if (!(*codec)) {
                 fprintf(stderr, "Could not find codec\n");
                 exit(1);
            }
   
     st = avformat_new_stream(oc, *codec);
   if (!st) {
                fprintf(stderr, "Could not allocate stream\n");
         exit(1);
         }
     st->id = 1;

     c = st->codec;

     /* put sample parameters */
     c->sample_fmt  = AV_SAMPLE_FMT_S16;
     c->bit_rate    = 64000;
     c->sample_rate = 44100;
     c->channels    = 2;

     // some formats want stream headers to be separate
    if (oc->oformat->flags & AVFMT_GLOBALHEADER)
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;
    
    return st;
}

/* Add a video output stream. */
static AVStream *add_video_stream(AVFormatContext *oc, AVCodec **codec,enum AVCodecID codec_id)
{
     AVCodecContext *c;
    AVStream *st;
    
    /* find the video encoder */
    *codec = avcodec_find_encoder(codec_id);
    if (!(*codec)) {
        fprintf(stderr, "codec not found\n");
        exit(1);
        }

     st = avformat_new_stream(oc, *codec);
    if (!st) {
        fprintf(stderr, "Could not alloc stream\n");
         exit(1);
        }
 
    c = st->codec;

    avcodec_get_context_defaults3(c, *codec);

    c->codec_id = codec_id;
    
    /* Put sample parameters. */
    c->bit_rate = 400000;
    /* Resolution must be a multiple of two. */
    c->width    = 352;
    c->height   = 288;
        /* timebase: This is the fundamental unit of time (in seconds) in terms
                * of which frame timestamps are represented. For fixed-fps content,
                * timebase should be 1/framerate and timestamp increments should be
                * identical to 1. */
    c->time_base.den = STREAM_FRAME_RATE;
    c->time_base.num = 1;
    c->gop_size      = 12; /* emit one intra frame every twelve frames at most */
     c->pix_fmt       = STREAM_PIX_FMT;
    if (c->codec_id == AV_CODEC_ID_MPEG2VIDEO) {
        /* just for testing, we also add B frames */
         c->max_b_frames = 2;
        }
    if (c->codec_id == AV_CODEC_ID_MPEG1VIDEO) {
        /* Needed to avoid using macroblocks in which some coeffs overflow.
                        * This does not happen with normal video, it just happens here as
                        * the motion of the chroma plane does not match the luma plane. */
         c->mb_decision = 2;
        }
    /* Some formats want stream headers to be separate. */
    if (oc->oformat->flags & AVFMT_GLOBALHEADER)
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;

     return st;
}

-(id)initWithVideoMemory:(NSString *)moviePath
{
    FILE* fd = NULL;
    AVCodec         *pCodec;
    AVCodec         *pAudioCodec;
    int ioBufferSize=0;
    
    tFileX *vpFileX=malloc(sizeof(tFileX));
    memset(vpFileX, 0, sizeof(tFileX));
    // Register all formats and codecs
//    avcodec_register_all();
    av_register_all();
    fps=0.0;
    
    // Get File size and read to the buffer
    if (moviePath)
    {

        fd = fopen(moviePath.UTF8String,"r");
        if(NULL == fd)
        {
            printf("\n fopen() Error!!!\n");
            return nil;
        }
        
        fseek(fd, 0, SEEK_END);
        unsigned long len = (unsigned long)ftell(fd);
        NSLog(@"file size = %ld",len);
        fseek(fd, 0, SEEK_SET);
//        fclose(fd);
        

        
//        NSData *pData = [NSData dataWithContentsOfFile:moviePath];
//        if (pData)
        {
            vpFileX->FilePosition =0 ;
            vpFileX->FileSize = len;
//            vpFileX->pBuffer = (unsigned char*) av_malloc(vpFileX->FileSize);
//            memcpy(vpFileX->pBuffer , [pData bytes], vpFileX->FileSize);
            vpFileX->pBuffer = (unsigned char*)fd;
            NSLog(@"file %@,size =%lld", moviePath, vpFileX->FileSize);

        }  
    }
    
//    ioBufferSize = 10240;//32768;
    ioBufferSize = 32768;//32768;
    

    unsigned char * ioBuffer = (unsigned char *)av_malloc(ioBufferSize + FF_INPUT_BUFFER_PADDING_SIZE); // can get av_free()ed by libav
    
    AVIOContext * avioContext = avio_alloc_context(ioBuffer, ioBufferSize, 0, (void*)vpFileX, &readFunction, NULL, &seekFunction);
    
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = avioContext;
    
//    AVOutputFormat *fmt;
//    AVStream *audio_st, *video_st;
//    AVCodec *audio_codec, *video_codec;
//    AVFormatContext *oc;
//    /* auto detect the output format from the name. default is
//     mpeg. */
//    fmt = av_guess_format(NULL, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], NULL);
//    if (!fmt) {
//        printf("Could not deduce output format from file extension: using MPEG.\n");
//        fmt = av_guess_format("mpeg", NULL, NULL);
//        }
//    if (!fmt) {
//        fprintf(stderr, "Could not find suitable output format\n");
//        goto initError;
//    }
//    
//    /* add the audio and video streams using the default format codecs
//      and initialize the codecs */
//    video_st = NULL;
//    audio_st = NULL;
//    if (fmt->video_codec != AV_CODEC_ID_NONE) {
//        video_st = add_video_stream(oc, &video_codec, fmt->video_codec);
//    }
//    if (fmt->audio_codec != AV_CODEC_ID_NONE) {
//        audio_st = add_audio_stream(oc, &audio_codec, fmt->audio_codec);
//    }
//
//     /* set the output parameters (must be done even if no
//               00477        parameters). */
//    if (av_set_parameters(oc, NULL) < 0) {
//        fprintf(stderr, "Invalid output format parameters\n");
//        goto initError;
//    }
    
    // Open video file
//    if(avformat_open_input(&pFormatCtx, "dummyFileName", NULL, NULL) != 0) {
    const char * s = [moviePath cStringUsingEncoding:NSASCIIStringEncoding];
    if(avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open memory file\n");
        goto initError;
    }
    
	
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        goto initError;
    }
    
    // Find the first video stream
    if ((videoStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
    
    // Find the first audio stream add by robert
    if((audioStream = av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, &pAudioCodec, 0)) < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a audio stream in the input file\n");
//        goto initError;
    }
	
    // Get a pointer to the codec context for the video stream
    pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    if(audioStream > 0)
        pAudioCtx = pFormatCtx->streams[audioStream]->codec;
    
    // Find the decoder for the video stream
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);//avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
    
    //Find the decoder for the audio stream
    if(pAudioCtx)
        pAudioCodec = avcodec_find_decoder(pAudioCtx->codec_id);
	
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
    
    if(pAudioCtx)
    if(avcodec_open2(pAudioCtx, pAudioCodec, NULL) < 0)
    {
    
    }
	
//    av_dump_format(pFormatCtx, 0, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], 0);
    
    if(fps==0)
    {
        
        fps = 1.0/ av_q2d(pCodecCtx->time_base)/ FFMAX(pCodecCtx->ticks_per_frame, 1);
        NSLog(@"num=%d den=%d ,av_q2d=%f ,max=%d",pCodecCtx->time_base.num, pCodecCtx->time_base.den, av_q2d(pCodecCtx->time_base),FFMAX(pCodecCtx->ticks_per_frame, 1));
//        NSLog(@"fps_method(tbc): 1/av_q2d()=%g",fps);
        fps = 30;
        NSLog(@"num=%d den=%d fps=%f", pFormatCtx->streams[0]->avg_frame_rate.num, pFormatCtx->streams[0]->avg_frame_rate.den, av_q2d(pFormatCtx->streams[0]->avg_frame_rate));
    }
    
    // Allocate video frame
    pFrame = avcodec_alloc_frame();
    
	outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
    
//    NSLog(@"extraSize=%d",pCodecCtx->extradata_size);
//    for (int i = 0 ; i < pCodecCtx->extradata_size; i++)
//    {
//        printf("%02X",pCodecCtx->extradata[i]);
//    }
//    printf("\n");
    
//    if(pAudioCtx)
//    {
//        NSLog(@"audio extra=%d",pAudioCtx->extradata_size);
//        for (int i = 0 ; i < pAudioCtx->extradata_size; i++)
//        {
//            printf("%02X",pAudioCtx->extradata[i]);
//        }
//        printf("\n");
//    }
    // 20130311 albert.liao modified start
#if 0
    {
        AVHWAccel *vHwAccel = NULL;
        vHwAccel  = ff_find_hwaccel( AV_CODEC_ID_H264 ,  AV_PIX_FMT_YUV420P ); // 7h800.mp4 is YUV420P
        if(vHwAccel  != NULL)
        {
            NSLog(@"Find vHwAccel  for H264");
        }
        else
        {
            NSLog(@"Cannot Find vHwAccel  for H264");
        }
    }
#endif
    // 20130311 albert.liao modified end
	return self;
	
initError:
	;
	return nil;
    
}

-(id)initWithVideo:(NSString *)moviePath {
	if (!(self=[super init])) return nil;
 
    AVCodec         *pCodec;

    // Register all formats and codecs
//    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    fps=0.0;
    // Open video file
    AVDictionary *opts = 0;
    //int ret = av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    
    if(avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], NULL, &opts) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file %s\n", [moviePath cStringUsingEncoding:NSASCIIStringEncoding]);
        goto initError;
    }
	av_dict_free(&opts);
    
	   
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        goto initError;
    }
    
    // Find the first video stream
    if ((videoStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
	
    // Get a pointer to the codec context for the video stream
    pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    
    // Find the decoder for the video stream
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
	
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
	
    // Allocate video frame
    pFrame = avcodec_alloc_frame();
			
//    av_dump_format(pFormatCtx, 0, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], 0);
    
    if(fps==0)
    {
        fps = 1.0/ av_q2d(pCodecCtx->time_base)/ FFMAX(pCodecCtx->ticks_per_frame, 1);
        NSLog(@"fps_method(tbc): 1/av_q2d()=%g",fps);
    }
    
	outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
			
	return self;
	
initError:
	;
	return nil;
}


-(void)setupScaler {

	// Release old picture and scaler
	avpicture_free(&picture);
	sws_freeContext(img_convert_ctx);	
	
	// Allocate RGB picture
	avpicture_alloc(&picture, PIX_FMT_RGB24, outputWidth, outputHeight);
	
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	img_convert_ctx = sws_getContext(pCodecCtx->width, 
									 pCodecCtx->height,
									 pCodecCtx->pix_fmt,
									 outputWidth, 
									 outputHeight,
									 PIX_FMT_RGB24,
									 sws_flags, NULL, NULL, NULL);
	
}

-(void)seekTime:(double)seconds {
	AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(pFormatCtx, videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(pCodecCtx);
}

-(void)dealloc {
	// Free scaler
	sws_freeContext(img_convert_ctx);
    
	// Free RGB picture
	avpicture_free(&picture);

    // Free the packet that was allocated by av_read_frame
    av_free_packet(&packet);

    // Free the YUV frame
    av_free(pFrame);

    // Close the codec
    if (pCodecCtx) avcodec_close(pCodecCtx);

    // Close the video file
    if (pFormatCtx) avformat_close_input(&pFormatCtx);
    
}

-(AVStream *) getVideoStream
{
    AVStream *objRtn = NULL;
    
    objRtn = pFormatCtx->streams[videoStream];
    
    return objRtn;
}

-(AVStream *) getAudioStream
{
    AVStream *objRtn = NULL;

    if(audioStream >=0)
        objRtn = pFormatCtx->streams[audioStream];

    return objRtn;
}
-(BOOL)stepFrame {

    int vRet, frameFinished=0;

    while(!frameFinished && (vRet = av_read_frame(pFormatCtx, &packet))>=0) {
        // Is this a packet from the video stream?
        if(packet.stream_index==videoStream)
        {
            NSLog(@"video:flag type = %d,%d",packet.flags, vRet);
            // Decode video frame
//            if(packet.flags==1)
//                NSLog(@"got 1");
//            NSLog(@"extraSize=%d",pCodecCtx->extradata_size);
//            for (int i = 0 ; i < pCodecCtx->extradata_size; i++)
//            {
//                printf("%02X",pCodecCtx->extradata[i]);
//            }
//            printf("\n");
            
//            double decodeS = [NSDate timeIntervalSinceReferenceDate] * 1000;

//            NSLog(@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",packet.data[0],packet.data[1],packet.data[2],packet.data[3],packet.data[4],packet.data[5],packet.data[6],packet.data[7],packet.data[8],packet.data[9],packet.data[10],packet.data[11],packet.data[12],packet.data[13],packet.data[14],packet.data[15]);
//            vRet = avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
//            double decodeE = [NSDate timeIntervalSinceReferenceDate] * 1000;
            
//            NSLog(@"Decode Time = %f",decodeE - decodeS);
//            if(vRet<=0) NSLog(@"avcodec_decode_video2 error");
        }
        else if(packet.stream_index == audioStream)
        {
//            NSLog(@"audio data");
        }

        av_free_packet(&packet);
		
	}
    
    if(packet.size > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }

}

-(BOOL) getAVPacket:(AVPacket *) _packet frameType:(int*) _frameType
{
    int vRet=0;

    while(av_read_frame(pFormatCtx, _packet)>=0)
    {
        if(_packet->stream_index==videoStream)
        {
            if (_packet->flags == 1)
            {
                *_frameType = RECORD_VIDEO_IFRAME;
            }
            else
            {
                *_frameType = RECORD_VIDEO_PFRAME;
            }
        }
        else if(_packet->stream_index == audioStream)
        {
            *_frameType = RECORD_AUDIO_FRAME;
        }
        break;
    }

    vRet = _packet->size > 0 ? 1 : 0;
	return vRet;
}

-(int64_t)getDuration{
    if (pFormatCtx) {
        return pFormatCtx->duration;
    }
    return 0;
}

-(void)convertFrameToRGB {	
	sws_scale (img_convert_ctx, pFrame->data, pFrame->linesize,
			   0, pCodecCtx->height,
			   picture.data, picture.linesize);	
}

-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, 
									   height, 
									   8, 
									   24, 
									   pict.linesize[0], 
									   colorSpace, 
									   bitmapInfo, 
									   provider, 
									   NULL, 
									   NO, 
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}

-(void)savePPMPicture:(AVPicture)pict width:(int)width height:(int)height index:(int)iFrame {
    FILE *pFile;
	NSString *fileName;
    int  y;
	
	fileName = [Utilities documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    // Open file
    NSLog(@"write image file: %@",fileName);
    pFile=fopen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    if(pFile==NULL)
        return;
	
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
	
    // Write pixel data
    for(y=0; y<height; y++)
        fwrite(pict.data[0]+y*pict.linesize[0], 1, width*3, pFile);
	
    // Close file
    fclose(pFile);
}


-(AVCodecContext *) getVideoCodecContext
{
    return pFormatCtx->streams[videoStream]->codec;
}
-(AVCodecContext *) getAudioCodecContext
{
    return pFormatCtx->streams[audioStream]->codec;
}
@end
