//
//  FGalleryViewController.h
//  FGallery
//
//  Created by Grant Davis on 5/19/10.
//  Copyright 2011 Grant Davis Interactive, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FGalleryPhotoView.h"
#import "FGalleryPhoto.h"


typedef enum
{
	FGalleryPhotoSizeThumbnail,
	FGalleryPhotoSizeFullsize
} FGalleryPhotoSize;

typedef enum
{
	FGalleryPhotoSourceTypeNetwork,
	FGalleryPhotoSourceTypeLocal
} FGalleryPhotoSourceType;

@protocol FGalleryViewControllerDelegate;

@interface OfflineFGalleryViewController : UIViewController <UIScrollViewDelegate,FGalleryPhotoDelegate,FGalleryPhotoViewDelegate, UIDocumentInteractionControllerDelegate> {
	
	BOOL _isActive;
	BOOL _isFullscreen;
	BOOL _isScrolling;
	BOOL _isThumbViewShowing;
	
	UIStatusBarStyle _prevStatusStyle;
	CGFloat _prevNextButtonSize;
	CGRect _scrollerRect;
	NSString *galleryID;
	NSInteger _currentIndex;
	
	UIView *_container; // used as view for the controller
	UIView *_innerContainer; // sized and placed to be fullscreen within the container
	UIToolbar *_toolbar;
	UIScrollView *_thumbsView;
    UICollectionView *_collectionView;
	
	NSMutableDictionary *_photoLoaders;
	NSMutableArray *_barItems;
	NSMutableArray *_photoViews;
	
    NSObject <FGalleryViewControllerDelegate> *_photoSource;
    
    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_favoriteButton;
    UIBarButtonItem *_sendButton;
    
    UIActivityIndicatorView *activityIndicator;
}

- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc;
- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc barItems:(NSArray*)items;

- (void)next;
- (void)previous;
- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeImageAtIndex:(NSUInteger)index;
- (void)reloadGallery;
- (void)setSlideEnable:(BOOL)enable;

- (FGalleryPhoto*)currentPhoto;

@property NSInteger currentIndex;
@property NSInteger startingIndex;
@property (nonatomic,assign) NSObject<FGalleryViewControllerDelegate> *photoSource;
@property (nonatomic,readonly) UIToolbar *toolBar;
@property (nonatomic,readonly) UIView* thumbsView;
@property (nonatomic,retain) NSString *galleryID;
@property (nonatomic) BOOL useThumbnailView;
@property (nonatomic) BOOL beginsInThumbnailView;
@property (nonatomic) BOOL hideTitle;
@property (nonatomic) BOOL scrollEnable;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIDocumentInteractionController *fileInteractionController;
@property (nonatomic) UIImageView *preDisplayView;

@end


@protocol FGalleryViewControllerDelegate

@required
- (int)numberOfPhotosForPhotoGallery:(OfflineFGalleryViewController*)gallery;
- (FGalleryPhotoSourceType)photoGallery:(OfflineFGalleryViewController*)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index;

@optional
- (NSString*)photoGallery:(OfflineFGalleryViewController*)gallery captionForPhotoAtIndex:(NSUInteger)index;

// the photosource must implement one of these methods depending on which FGalleryPhotoSourceType is specified 
- (NSString*)photoGallery:(OfflineFGalleryViewController*)gallery filePathForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index;
- (NSString*)photoGallery:(OfflineFGalleryViewController*)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index;
- (bool)photoGallery:(OfflineFGalleryViewController*)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index;
- (void)photoGallery:(OfflineFGalleryViewController*)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index;
- (UIImage*)photoGallery:(OfflineFGalleryViewController*)gallery loadThumbnailFromLocalAtIndex:(NSUInteger)index;

@end
