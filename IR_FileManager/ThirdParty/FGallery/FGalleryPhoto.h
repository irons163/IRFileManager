//
//  FGalleryPhoto.h
//  FGallery
//
//  Created by Grant Davis on 5/20/10.
//  Copyright 2011 Grant Davis Interactive, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol FGalleryPhotoDelegate;

@interface FGalleryPhoto : NSObject {
	
	// value which determines if the photo was initialized with local file paths or network paths.
	BOOL _useNetwork;
	
	BOOL _isThumbLoading;
	BOOL _hasThumbLoaded;
	
	BOOL _isFullsizeLoading;
	BOOL _hasFullsizeLoaded;
	
	NSMutableData *_thumbData;
	NSMutableData *_fullsizeData;
	
	NSURLConnection *_thumbConnection;
	NSURLConnection *_fullsizeConnection;
	
	UIImage *_thumbnail;
	UIImage *_fullsize;
	
	NSObject <FGalleryPhotoDelegate> *_delegate;
	
	NSUInteger tag;
}


- (id)initWithThumbnailUrl:(NSString*)thumb fullsizeUrl:(NSString*)fullsize delegate:(NSObject<FGalleryPhotoDelegate>*)delegate;
- (id)initWithThumbnailPath:(NSString*)thumb fullsizePath:(NSString*)fullsize delegate:(NSObject<FGalleryPhotoDelegate>*)delegate;

- (void)loadThumbnail;
- (void)loadFullsize;

- (void)unloadFullsize;
- (void)unloadThumbnail;

@property NSUInteger tag;

@property (nonatomic,readonly) NSString *thumbUrl;
@property (nonatomic,readonly) NSString *fullsizeUrl;

@property (readonly) BOOL isThumbLoading;
@property (readonly) BOOL hasThumbLoaded;

@property (readonly) BOOL isFullsizeLoading;
@property (readonly) BOOL hasFullsizeLoaded;

@property (nonatomic,readonly) UIImage *thumbnail;
@property (nonatomic,readonly) UIImage *fullsize;

@property (nonatomic,assign) NSObject<FGalleryPhotoDelegate> *delegate;

#pragma mark - Progressive behavior messages
/// Launch the image download
-(void)loadImageAtURL:(NSURL*)url isThumbSize:(BOOL)isThumbSize;
/// This will remove all cached images managed by any NYXProgressiveImageView instances
+(void)resetImageCache;

+(NSUInteger)getCacheSize;

#pragma mark - Progressive behavior properties
/// Delegate
//@property (nonatomic, weak) IBOutlet id <NYXProgressiveImageViewDelegate> delegate;
/// Enable / Disable caching
@property (nonatomic, getter = isCaching) BOOL caching;
/// Cache time in seconds
@property (nonatomic) NSTimeInterval cacheTime;

@property (nonatomic) BOOL enableProgressive;

@property (nonatomic) UIImageOrientation imageOrientation;

@end


@protocol FGalleryPhotoDelegate

@required
- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadThumbnail:(UIImage*)image;
- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadFullsize:(UIImage*)image;

@optional
- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromUrl:(NSString*)url;
- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromUrl:(NSString*)url;

- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromPath:(NSString*)path;
- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromPath:(NSString*)path;

- (void)galleryPhoto:(FGalleryPhoto*)photo loadingFullsize:(UIImage*)image;
- (void)galleryPhoto:(FGalleryPhoto*)photo loadingThumbnail:(UIImage*)image;

- (void)galleryPhoto:(FGalleryPhoto*)photo showThumbnail:(BOOL)show;

- (UIImage*)galleryPhotoLoadThumbnailFromLocal:(FGalleryPhoto*)photo;

@end
