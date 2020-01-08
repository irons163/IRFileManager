    //
//  FGalleryViewController.m
//  FGallery
//
//  Created by Grant Davis on 5/19/10.
//  Copyright 2011 Grant Davis Interactive, LLC. All rights reserved.
//

#import "OfflineFGalleryViewController.h"
#import "StorageDeleteView.h"
#import "KGModal.h"
#import "CommonTools.h"
#import "SuccessView.h"
#import "Masonry.h"
#import "IR_Tools.h"
#import "DataManager.h"

#define kThumbnailSize 75
#define kThumbnailSpacing 4
#define kCaptionPadding 3
#define kToolbarHeight 45


@interface MyCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *filenameLabel;
@property (strong, nonatomic) IBOutlet FGalleryPhotoView *imageView;


@end

@implementation MyCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        CGRect imageFrame = frame;
        imageFrame.origin = CGPointZero;
        
//        self.thumbView = [[UIImageView alloc] initWithFrame:imageFrame];
//        [self.thumbView setContentMode:UIViewContentModeScaleAspectFill];
//        [self.thumbView setClipsToBounds:YES];
//        [self.contentView addSubview:self.thumbView];
//        self.thumbView.scrollEnabled = NO;
//        self.thumbView.hidden = YES;
        
        self.imageView = [[FGalleryPhotoView alloc] initWithFrame:imageFrame];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.autoresizesSubviews = YES;
//        self.imageView.photoDelegate = self;
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];
        

        
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

@end

@interface MyUICollectionViewFlowLayout : UICollectionViewFlowLayout
@end

@implementation MyUICollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *newAttributes = [NSMutableArray arrayWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if ((attribute.frame.origin.x + attribute.frame.size.width <= self.collectionViewContentSize.width) &&
            (attribute.frame.origin.y + attribute.frame.size.height <= self.collectionViewContentSize.height)) {
            [newAttributes addObject:attribute];
        }
    }
    return newAttributes;
}

//-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
//{
//    return YES;
//}

@end

@interface OfflineFGalleryViewController (Private) <UICollectionViewDelegate, UICollectionViewDataSource>

// general
- (void)destroyViews;
- (void)layoutViews;
- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation;
- (void)updateTitle;
- (void)updateButtons;
- (void)layoutButtons;
- (void)updateScrollSize;
- (void)updateCaption;
- (void)resizeImageViewsWithRect:(CGRect)rect;
- (void)resetImageViewZoomLevels;

- (void)enterFullscreen;
- (void)exitFullscreen;
- (void)enableApp;
- (void)disableApp;

- (void)positionInnerContainer;
- (void)positionToolbar;

// thumbnails
- (void)toggleThumbnailViewWithAnimation:(BOOL)animation;
- (void)showThumbnailViewWithAnimation:(BOOL)animation;
- (void)hideThumbnailViewWithAnimation:(BOOL)animation;

- (void)preloadThumbnailImages;
- (void)unloadFullsizeImageWithIndex:(NSUInteger)index;

- (void)scrollingHasEnded;

- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index;

- (void)loadThumbnailImageWithIndex:(NSUInteger)index;
- (void)loadFullsizeImageWithIndex:(NSUInteger)index;

- (void)shareClk:(id)sender;
- (void)shareByFileURLStringWithPath:(NSString*)fileURLStringWithPath;

@end



@implementation OfflineFGalleryViewController
@synthesize galleryID;
@synthesize photoSource = _photoSource;
@synthesize currentIndex = _currentIndex;
@synthesize thumbsView = _thumbsView;
@synthesize toolBar = _toolbar;
@synthesize useThumbnailView = _useThumbnailView;
@synthesize startingIndex = _startingIndex;
@synthesize beginsInThumbnailView = _beginsInThumbnailView;
@synthesize hideTitle = _hideTitle;
@synthesize delegate;

#pragma mark - Public Methods
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
	if((self = [super initWithNibName:nil bundle:nil])) {
	
		// init gallery id with our memory address
		self.galleryID						= [NSString stringWithFormat:@"%p", self];

        // configure view controller
		self.hidesBottomBarWhenPushed		= YES;
        
        // set defaults
        _useThumbnailView                   = YES;
		_prevStatusStyle					= [[UIApplication sharedApplication] statusBarStyle];
        _hideTitle                          = NO;
		
		// create storage objects
		_currentIndex						= 0;
        _startingIndex                      = 0;
		_photoLoaders						= [[NSMutableDictionary alloc] init];
		_photoViews							= [[NSMutableArray alloc] init];
//		_photoThumbnailViews				= [[NSMutableArray alloc] init];
		_barItems							= [[NSMutableArray alloc] init];
        
        /*
         // debugging: 
         _container.layer.borderColor = [[UIColor yellowColor] CGColor];
         _container.layer.borderWidth = 1.0;
         
         _innerContainer.layer.borderColor = [[UIColor greenColor] CGColor];
         _innerContainer.layer.borderWidth = 1.0;
         
         _scroller.layer.borderColor = [[UIColor redColor] CGColor];
         _scroller.layer.borderWidth = 2.0;
         */
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self != nil) {
		self.galleryID						= [NSString stringWithFormat:@"%p", self];
		
        // configure view controller
		self.hidesBottomBarWhenPushed		= YES;
        
        // set defaults
        _useThumbnailView                   = YES;
		_prevStatusStyle					= [[UIApplication sharedApplication] statusBarStyle];
        _hideTitle                          = NO;
		
		// create storage objects
		_currentIndex						= 0;
        _startingIndex                      = 0;
		_photoLoaders						= [[NSMutableDictionary alloc] init];
		_photoViews							= [[NSMutableArray alloc] init];
//		_photoThumbnailViews				= [[NSMutableArray alloc] init];
		_barItems							= [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc
{
	if((self = [self initWithNibName:nil bundle:nil])) {
		
		_photoSource = photoSrc;
        
        // create public objects first so they're available for custom configuration right away. positioning comes later.
        _container							= [[UIView alloc] initWithFrame:CGRectZero];
        _innerContainer						= [[UIView alloc] initWithFrame:CGRectZero];
        MyUICollectionViewFlowLayout *flowLayout =[[MyUICollectionViewFlowLayout alloc]init];
        _collectionView  = [[UICollectionView alloc]initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:flowLayout];
        _thumbsView							= [[UIScrollView alloc] initWithFrame:CGRectZero];
        _toolbar							= [[UIToolbar alloc] initWithFrame:CGRectZero];
        _toolbar.barStyle					= UIBarStyleDefault;
        _toolbar.barTintColor               = [UIColor whiteColor];
        _container.backgroundColor			= [UIColor whiteColor];
        
        // listen for container frame changes so we can properly update the layout during auto-rotation or going in and out of fullscreen
//        [_container addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        _collectionView.delegate							= self;
        _collectionView.dataSource                         = self;
        _collectionView.pagingEnabled						= YES;
        _collectionView.showsVerticalScrollIndicator		= NO;
        _collectionView.showsHorizontalScrollIndicator	= NO;
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        // make things flexible
        _container.autoresizesSubviews				= NO;
        _innerContainer.autoresizesSubviews			= NO;
        _collectionView.autoresizesSubviews         = NO;
        _container.autoresizingMask					= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // set view
        self.view                                   = _container;
        
        _preDisplayView                              = [[UIImageView alloc] initWithFrame:CGRectZero];
        _preDisplayView.backgroundColor				= [UIColor whiteColor];
        _preDisplayView.hidden						= NO;
        _preDisplayView.contentMode = UIViewContentModeScaleAspectFit;
        
        // add items to their containers
        [_container addSubview:_innerContainer];
        [_innerContainer addSubview:_collectionView];
        [_innerContainer addSubview:_toolbar];
        
        [self createToolbarItems];
        _prevNextButtonSize = 30;
        
        // set buttons on the toolbar.
        NSMutableArray *items = [NSMutableArray arrayWithArray:_barItems];
        for(int i = 1; i < items.count; i+=2){
            UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [items insertObject:space atIndex:i];
        }
        [_toolbar setItems:items animated:NO];
        [self initMyFavorites];
        [self reloadGallery];
//        dispatch_async(dispatch_get_main_queue(), ^{
            // init with next on first run.
            if( _currentIndex == -1 ) [self next];
            
            [activityIndicator stopAnimating];
            [activityIndicator release];
            activityIndicator = nil;
//        });
        //    [self reloadGallery];
        //    [self enterFullscreen];
        
        

	}
	return self;
}


- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc barItems:(NSArray*)items
{
	if((self = [self initWithPhotoSource:photoSrc])) {
		
		[_barItems addObjectsFromArray:items];
	}
	return self;
}

- (void)viewDidUnload {
    
    [self destroyViews];
    
    [_barItems release], _barItems = nil;
    [_deleteButton release], _deleteButton = nil;
    [_favoriteButton release], _favoriteButton = nil;
    [_sendButton release], _sendButton = nil;
    [_container release], _container = nil;
    [_innerContainer release], _innerContainer = nil;
    [_collectionView release], _collectionView = nil;
    [_toolbar release], _toolbar = nil;
    
    [super viewDidUnload];
}


- (void)destroyViews {
    // remove previous photo views
    for (UIView *view in _photoViews) {
        [view removeFromSuperview];
    }
    [_photoViews removeAllObjects];
    
    // remove photo loaders
    NSArray *photoKeys = [_photoLoaders allKeys];
    for (int i=0; i<[photoKeys count]; i++) {
        FGalleryPhoto *photoLoader = [_photoLoaders objectForKey:[photoKeys objectAtIndex:i]];
        photoLoader.delegate = nil;
        [photoLoader unloadFullsize];
        [photoLoader unloadThumbnail];
    }
    [_photoLoaders removeAllObjects];
}


- (void)reloadGallery
{
    _currentIndex = _startingIndex;
    _isThumbViewShowing = NO;
    
    // remove the old
    [self destroyViews];
    
    NSLog(@"Load start");
    // build the new
    if ([_photoSource numberOfPhotosForPhotoGallery:self] > 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
            [self layoutViews];
//        });
    }
}

- (void)buildGalleryViews
{
    NSLog(@"Load start");
    // build the new
    if ([_photoSource numberOfPhotosForPhotoGallery:self] > 0) {
        
        NSLog(@"buildView Finish");
        
        // layout
        [self layoutViews];
        
        NSLog(@"reloadGallery Finish");
    }
}

-(void)createToolbarItems{
    // create buttons for toolbar
    UIButton* doDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    
#ifdef MESSHUDrive
    UIImage *image = [UIImage imageNamed:@"btn_video_delete"];
#else
    UIImage *image = [UIImage imageNamed:@"btn_trash"];
#endif
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateNormal];
#ifdef MESSHUDrive
    image = [UIImage imageNamed:@"btn_video_delete"];
#else
    image = [UIImage imageNamed:@"btn_trash"];
#endif
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateHighlighted];
    [doDeleteButton addTarget:self action:@selector(deleteClk:) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton = [[UIBarButtonItem alloc] initWithCustomView:doDeleteButton];
    
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:doDeleteButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:33];
//    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:doDeleteButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:33];
//    [heightConstraint setActive:TRUE];
//    [widthConstraint setActive:TRUE];

//    NSLayoutConstraint * widthConstraint = [doDeleteButton.widthAnchor constraintEqualToConstant:40];
//    NSLayoutConstraint * HeightConstraint =[doDeleteButton.heightAnchor constraintEqualToConstant:40];
//    [widthConstraint setActive:YES];
//    [HeightConstraint setActive:YES];
    
    UIButton* doFavoriteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    image = [UIImage imageNamed:@"btn_video_heart"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_video_heart"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateHighlighted];
    image = [UIImage imageNamed:@"btn_heart_h"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateSelected];
    [doFavoriteButton addTarget:self action:@selector(addToMyFavoritesClk:) forControlEvents:UIControlEventTouchUpInside];
    _favoriteButton = [[UIBarButtonItem alloc] initWithCustomView:doFavoriteButton];
    
//    heightConstraint = [NSLayoutConstraint constraintWithItem:doFavoriteButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:33];
//    widthConstraint = [NSLayoutConstraint constraintWithItem:doFavoriteButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:33];
//    [heightConstraint setActive:TRUE];
//    [widthConstraint setActive:TRUE];

//    widthConstraint = [doFavoriteButton.widthAnchor constraintEqualToConstant:40];
//    HeightConstraint =[doFavoriteButton.heightAnchor constraintEqualToConstant:40];
//    [widthConstraint setActive:YES];
//    [HeightConstraint setActive:YES];
    
    UIButton* doSendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    image = [UIImage imageNamed:@"btn_video_send"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [doSendButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_video_send"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [doSendButton setImage:image forState:UIControlStateHighlighted];
    [doSendButton addTarget:self action:@selector(shareClk:) forControlEvents:UIControlEventTouchUpInside];
    _sendButton = [[UIBarButtonItem alloc] initWithCustomView:doSendButton];
    
//    widthConstraint = [doSendButton.widthAnchor constraintEqualToConstant:40];
//    HeightConstraint =[doSendButton.heightAnchor constraintEqualToConstant:40];
//    [widthConstraint setActive:YES];
//    [HeightConstraint setActive:YES];
    
    // add prev next to front of the array
    //	[_barItems insertObject:_nextButton atIndex:0];
    //	[_barItems insertObject:_prevButton atIndex:0];
    
    [_barItems insertObject:_sendButton atIndex:0];
    [_barItems insertObject:_favoriteButton atIndex:0];
    [_barItems insertObject:_deleteButton atIndex:0];
}

- (FGalleryPhoto*)currentPhoto
{
    return [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", _currentIndex]];
}

-(void)viewDidLoad{

    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear Start");
    [super viewWillAppear:animated];
	
    _isActive = YES;
    
    self.useThumbnailView = _useThumbnailView;
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self layoutViews];
        [self positionInnerContainer];
        [self positionToolbar];
//        [self updateScrollSize];
//        [self updateCaption];
        //	[self resizeImageViewsWithRect:_scroller.frame];
//        [self resizeImageViewsWithRect:_collectionView.frame];
//        [self layoutButtons];
//        [self moveScrollerToCurrentIndexWithAnimation:NO];
    });
    
	// update status bar to be see-through
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
//    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
	_isActive = NO;

	[[UIApplication sharedApplication] setStatusBarStyle:_prevStatusStyle animated:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    _preDisplayView.hidden = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [_collectionView.collectionViewLayout invalidateLayout];
}

-(void)viewDidLayoutSubviews{
    CGRect newFrame = _collectionView.frame;
    newFrame.origin.y = self.view.bounds.origin.y + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    newFrame.size.height = self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - kToolbarHeight;
    _collectionView.frame = newFrame;
    newFrame.size.height = newFrame.size.height - 2;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize = newFrame.size;
}


- (void)resizeImageViewsWithRect:(CGRect)rect
{
    int imageviewOffsetY = 0;
	// resize all the image views
	NSUInteger i, count = [_photoViews count];
	float dx = 0;
	for (i = 0; i < count; i++) {
		FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
		photoView.frame = CGRectMake(dx, imageviewOffsetY, rect.size.width, rect.size.height  - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
		dx += rect.size.width;
	}
    
//    _preDisplayView.frame = CGRectMake(0, imageviewOffsetY  + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, rect.size.width, rect.size.height  - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
    
    _preDisplayView.frame = rect;
}


- (void)resetImageViewZoomLevels
{
	// resize all the image views
	NSUInteger i, count = [_photoViews count];
	for (i = 0; i < count; i++) {
		FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
		[photoView resetZoom];
	}
}


- (void)removeImageAtIndex:(NSUInteger)index
{
	// remove the image and thumbnail at the specified index.
	FGalleryPhotoView *imgView = [_photoViews objectAtIndex:index];
// 	FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:index];
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i",index]];
	
	[photo unloadFullsize];
	[photo unloadThumbnail];
	
	[imgView removeFromSuperview];
//	[thumbView removeFromSuperview];
	
	[_photoViews removeObjectAtIndex:index];
//	[_photoThumbnailViews removeObjectAtIndex:index];
	[_photoLoaders removeObjectForKey:[NSString stringWithFormat:@"%i",index]];
	
	[self layoutViews];
	[self updateButtons];
    [self updateTitle];
}


- (void)next
{
	NSUInteger numberOfPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
	NSUInteger nextIndex = _currentIndex+1;
	
	// don't continue if we're out of images.
	if( nextIndex <= numberOfPhotos )
	{
		[self gotoImageByIndex:nextIndex animated:NO];
	}
}



- (void)previous
{
	NSUInteger prevIndex = _currentIndex-1;
	[self gotoImageByIndex:prevIndex animated:NO];
}



- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated
{
	NSUInteger numPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
	
	// constrain index within our limits
    if( index >= numPhotos ) index = numPhotos - 1;
	
	
	if( numPhotos == 0 ) {
		// no photos!
		_currentIndex = -1;
	}
	else {
		
		// clear the fullsize image in the old photo
		[self unloadFullsizeImageWithIndex:_currentIndex];
		
		_currentIndex = index;
		[self moveScrollerToCurrentIndexWithAnimation:animated];
		[self updateTitle];
		
		if( !animated )	{
			[self preloadThumbnailImages];
			[self loadFullsizeImageWithIndex:index];
		}
	}
	[self updateButtons];
	[self updateCaption];
}


- (void)layoutViews
{
    NSLog(@"layoutViews go");
	[self positionInnerContainer];
	[self positionToolbar];
	[self updateScrollSize];
	[self updateCaption];
//	[self resizeImageViewsWithRect:_scroller.frame];
    [self resizeImageViewsWithRect:_collectionView.frame];
	[self layoutButtons];
	[self moveScrollerToCurrentIndexWithAnimation:NO];
    NSLog(@"layoutViews end");
}


- (void)setUseThumbnailView:(BOOL)useThumbnailView
{
    [self setNavigatinItem];
    
    _useThumbnailView = useThumbnailView;
}

-(void)setNavigatinItem{
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage* backImage = [UIImage imageNamed:@"btn_nav_back.png"];
    UIImage* iBackImage = [UIImage imageNamed:@"ibtn_nav_back"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (iBackImage) {
        [backButton setImage:iBackImage forState:UIControlStateHighlighted];
    }
    [backButton setImage:backImage forState:UIControlStateNormal];
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0 ;
    backButtonFrame.origin.y = 5 ;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(closeClk:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

#pragma mark - Private Methods

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//	if([keyPath isEqualToString:@"frame"]) 
//	{
//		[self layoutViews];
//	}
//}


- (void)positionInnerContainer
{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	CGRect innerContainerRect;
	
	if( self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
	{//portrait
        innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.height , _container.frame.size.width, screenFrame.size.height);
	}
	else 
	{// landscape
		innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.width, _container.frame.size.width, screenFrame.size.width );
	}
	
	_innerContainer.frame = innerContainerRect;
}

- (void)positionToolbar
{
//	_toolbar.frame = CGRectMake( 0, _scroller.frame.size.height-kToolbarHeight, _scroller.frame.size.width, kToolbarHeight );
//    _toolbar.frame = CGRectMake( 0, _scroller.frame.size.height, _scroller.frame.size.width, kToolbarHeight );
//    _toolbar.frame = CGRectMake( 0, _collectionView.frame.origin.y + _collectionView.frame.size.height, _collectionView.frame.size.width, kToolbarHeight );
    [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.and.left.and.right.equalTo(_toolbar.superview);
        make.top.equalTo(self.view.mas_bottomMargin).offset(-44);
    }];
}

- (void)enterFullscreen
{
    if (!_isThumbViewShowing)
    {
        _isFullscreen = YES;
        
        [self disableApp];
        
        UIApplication* application = [UIApplication sharedApplication];
        if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
            [[UIApplication sharedApplication] setStatusBarHidden: YES withAnimation: UIStatusBarAnimationFade]; // 3.2+
        } else {
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] setStatusBarHidden: YES animated:YES]; // 2.0 - 3.2
    #pragma GCC diagnostic warning "-Wdeprecated-declarations"
        }
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [UIView beginAnimations:@"galleryOut" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(enableApp)];
        _toolbar.alpha = 0.0;
//        _captionContainer.alpha = 0.0;
        [UIView commitAnimations];
    }
}



- (void)exitFullscreen
{
	_isFullscreen = NO;
    
	[self disableApp];
    
	UIApplication* application = [UIApplication sharedApplication];
	if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade]; // 3.2+
	} else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; // 2.0 - 3.2
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
	}
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    
	[UIView beginAnimations:@"galleryIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(enableApp)];
	_toolbar.alpha = 1.0;
//	_captionContainer.alpha = 1.0;
	[UIView commitAnimations];
}



- (void)enableApp
{
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}


- (void)disableApp
{
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (void)setSlideEnable:(BOOL)enable{
    _collectionView.scrollEnabled = enable;
}

- (void)updateCaption
{
    /*
	if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
	{
		if([_photoSource respondsToSelector:@selector(photoGallery:captionForPhotoAtIndex:)])
		{
			NSString *caption = [_photoSource photoGallery:self captionForPhotoAtIndex:_currentIndex];
			
			if([caption length] > 0 )
			{
				float captionWidth = _container.frame.size.width-kCaptionPadding*2;
				CGSize textSize = [caption sizeWithFont:_caption.font];
				NSUInteger numLines = ceilf( textSize.width / captionWidth );
				NSInteger height = ( textSize.height + kCaptionPadding ) * numLines;
				
				_caption.numberOfLines = numLines;
				_caption.text = caption;
				
				NSInteger containerHeight = height+kCaptionPadding*2;
				_captionContainer.frame = CGRectMake(0, -containerHeight, _container.frame.size.width, containerHeight );
				_caption.frame = CGRectMake(kCaptionPadding, kCaptionPadding, captionWidth, height );
				
				// show caption bar
				_captionContainer.hidden = NO;
			}
			else {
				
				// hide it if we don't have a caption.
				_captionContainer.hidden = YES;
			}
		}
	}*/
    
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:captionForPhotoAtIndex:)])
        {
            NSString *caption = [_photoSource photoGallery:self captionForPhotoAtIndex:_currentIndex];
            self.navigationItem.title = caption;
//            [caption release];
//            caption = nil;
        }
    }
}


- (void)updateScrollSize
{
//	float contentWidth = _scroller.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
//	[_scroller setContentSize:CGSizeMake(contentWidth, _scroller.frame.size.height - 80)];
    float contentWidth = _collectionView.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
    [_collectionView setContentSize:CGSizeMake(contentWidth, _collectionView.frame.size.height - 80)];
}


- (void)updateTitle
{
//    if (!_hideTitle){
//        [self setTitle:[NSString stringWithFormat:@"%i %@ %i", _currentIndex+1, NSLocalizedString(@"of", @"") , [_photoSource numberOfPhotosForPhotoGallery:self]]];
//    }else{
//        [self setTitle:@""];
//    }
}


- (void)updateButtons
{
//	_prevButton.enabled = ( _currentIndex <= 0 ) ? NO : YES;
//	_nextButton.enabled = ( _currentIndex >= [_photoSource numberOfPhotosForPhotoGallery:self]-1 ) ? NO : YES;
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:isFavoriteForPhotoAtIndex:)])
        {
            bool isFavorite = [_photoSource photoGallery:self isFavoriteForPhotoAtIndex:_currentIndex];
            ((UIButton*)[_favoriteButton customView]).selected = isFavorite;
        }
    }
}


- (void)layoutButtons
{
	NSUInteger buttonWidth = roundf( _toolbar.frame.size.width / [_barItems count] - _prevNextButtonSize * .5);
	
	// loop through all the button items and give them the same width
	NSUInteger i, count = [_barItems count];
	for (i = 0; i < count; i++) {
		UIBarButtonItem *btn = [_barItems objectAtIndex:i];
		btn.width = buttonWidth;
	}
	[_toolbar setNeedsLayout];
}


- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation
{
    int xp = _collectionView.frame.size.width * _currentIndex;
    [_collectionView scrollRectToVisible:CGRectMake(xp, 0, _collectionView.frame.size.width, _collectionView.frame.size.height) animated:animation];
    _isScrolling = animation;;
}

- (void)toggleThumbnailViewWithAnimation:(BOOL)animation
{
    if (_isThumbViewShowing) {
        [self hideThumbnailViewWithAnimation:animation];
    }
    else {
        [self showThumbnailViewWithAnimation:animation];
    }
}


- (void)showThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = YES;
    
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Close", @"")];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"uncurl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
        [_thumbsView setHidden:NO];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:NO];
    }
}


- (void)hideThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = NO;
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"See all", @"")];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"curl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
        [_thumbsView setHidden:YES];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:YES];
    }
    
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)closeClk:(id)sender
{
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    for (i = 0; i < count; i++) {
        FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
        [photo unloadThumbnail];
        [photo unloadFullsize];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteClk:(id)sender
{
	FGalleryPhoto *file = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", _currentIndex]];
    StorageDeleteView *sview = nil;
    VIEW(sview, StorageDeleteView);
    sview.delegate = self;
    sview.infoLabel.text = NSLocalizedString(@"DELETE_PHOTO", nil);
    sview.files = [NSArray arrayWithObjects:file.fullsizeUrl, nil];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
}

- (void)delete:(NSArray*)dfiles {
    if ([self.delegate respondsToSelector:@selector(deleteByFiles:)])
        [self.delegate performSelector:@selector(deleteByFiles:) withObject:dfiles];
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//    _scroller.delegate = nil;
    _collectionView.delegate = nil;
    _photoSource = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addToMyFavoritesClk:(id)sender
{
    if([_photoSource respondsToSelector:@selector(photoGallery:addFavorite:atIndex:)])
    {
        if(((UIButton*)[_favoriteButton customView]).selected){
            ((UIButton*)[_favoriteButton customView]).selected = NO;
            [_photoSource photoGallery:self addFavorite:NO atIndex:_currentIndex];
        }else{
            ((UIButton*)[_favoriteButton customView]).selected = YES;
            [_photoSource photoGallery:self addFavorite:YES atIndex:_currentIndex];
        }
    }
}

- (void)shareClk:(id)sender {
    // 分享
//    NSIndexPath *indexPath = table.indexPathForSelectedRow;
//    NSDictionary *item = items[indexPath.row];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.navigationItem.title];
    [self shareByFileURLStringWithPath:file];
}

-(void)shareByFileURLStringWithPath:(NSString*)file{
    self.fileInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:file]];
    self.fileInteractionController.delegate = self;
    self.fileInteractionController.UTI = [[DataManager sharedInstance] getUTI:[file pathExtension]];
    BOOL isValid = [self.fileInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    if (isValid == FALSE){
        [self.fileInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
        [self showWarnning:_(@"SHARE_ALERT")];
    }
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"CollectionPage_Edit-Share" Label:nil Value:nil];
#endif
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

#pragma mark - Image Loading


- (void)preloadThumbnailImages
{
	NSUInteger index = _currentIndex;
    NSUInteger count = [self.delegate numberOfPhotosForPhotoGallery:self];
    
	// make sure the images surrounding the current index have thumbs loading
	NSUInteger nextIndex = index + 1;
	NSUInteger prevIndex = index - 1;
	
	// the preload count indicates how many images surrounding the current photo will get preloaded.
	// a value of 2 at maximum would preload 4 images, 2 in front of and two behind the current image.
	NSUInteger preloadCount = 1;
	
	FGalleryPhoto *photo;
	
	// check to see if the current image thumb has been loaded
	photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( !photo )
	{
		[self loadThumbnailImageWithIndex:index];
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	}
	
	if( !photo.hasThumbLoaded && !photo.isThumbLoading )
	{
		[photo loadThumbnail];
	}
	
	NSInteger curIndex = prevIndex;
    NSInteger invalidIndex = -1;
	while( (curIndex > invalidIndex) && (curIndex > (prevIndex - preloadCount)) )
	{
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !photo ) {
			[self loadThumbnailImageWithIndex:curIndex];
			photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		if( !photo.hasThumbLoaded && !photo.isThumbLoading )
		{
			[photo loadThumbnail];
		}
		
		curIndex--;
	}
	
	curIndex = nextIndex;
	while( curIndex < count && curIndex < nextIndex + preloadCount )
	{
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !photo ) {
			[self loadThumbnailImageWithIndex:curIndex];
			photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		if( !photo.hasThumbLoaded && !photo.isThumbLoading )
		{
			[photo loadThumbnail];
		}
		
		curIndex++;
	}
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

- (void)loadThumbnailImageWithIndex:(NSUInteger)index
{
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( photo == nil )
		photo = [self createGalleryPhotoForIndex:index];
	
	[photo loadThumbnail];
}


- (void)loadFullsizeImageWithIndex:(NSUInteger)index
{
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( photo == nil )
		photo = [self createGalleryPhotoForIndex:index];
	
	[photo loadFullsize];
}


- (void)unloadFullsizeImageWithIndex:(NSUInteger)index
{
//	if (index < [_photoViews count]) {
    if (index < [self.delegate numberOfPhotosForPhotoGallery:self]) {
		FGalleryPhoto *loader = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
		[loader unloadFullsize];
		
//		FGalleryPhotoView *photoView = [_photoViews objectAtIndex:index];
        FGalleryPhotoView *photoView = nil;
        for(NSIndexPath *indexPath in [_collectionView indexPathsForVisibleItems]){
            if(indexPath.row == index){
                photoView = ((MyCollectionViewCell*)[_collectionView cellForItemAtIndexPath:indexPath]).imageView;
                break;
            }
        }
        
        if(!photoView)
            return;
        
		photoView.imageView.image = loader.thumbnail;
	}
}


- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index
{
	FGalleryPhotoSourceType sourceType = [_photoSource photoGallery:self sourceTypeForPhotoAtIndex:index];
	FGalleryPhoto *photo;
	NSString *thumbPath;
	NSString *fullsizePath;
	
	if( sourceType == FGalleryPhotoSourceTypeLocal )
	{
		thumbPath = [_photoSource photoGallery:self filePathForPhotoSize:FGalleryPhotoSizeThumbnail atIndex:index];
		fullsizePath = [_photoSource photoGallery:self filePathForPhotoSize:FGalleryPhotoSizeFullsize atIndex:index];
		photo = [[[FGalleryPhoto alloc] initWithThumbnailPath:thumbPath fullsizePath:fullsizePath delegate:self] autorelease];
	}
	else if( sourceType == FGalleryPhotoSourceTypeNetwork )
	{
		thumbPath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeThumbnail atIndex:index];
		fullsizePath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeFullsize atIndex:index];
		photo = [[[FGalleryPhoto alloc] initWithThumbnailUrl:thumbPath fullsizeUrl:fullsizePath delegate:self] autorelease];
	}
	else 
	{
		// invalid source type, throw an error.
		[NSException raise:@"Invalid photo source type" format:@"The specified source type of %d is invalid", sourceType];
	}
    
	// assign the photo index
	photo.tag = index;
	
	// store it
	[_photoLoaders setObject:photo forKey: [NSString stringWithFormat:@"%i", index]];
	
	return photo;
}


- (void)scrollingHasEnded {
    NSLog(@"scrollingHasEnded start");
	_isScrolling = NO;
	
//	NSUInteger newIndex = floor( _scroller.contentOffset.x / _scroller.frame.size.width );
    NSUInteger newIndex = floor( _collectionView.contentOffset.x / _collectionView.frame.size.width );
	
	// don't proceed if the user has been scrolling, but didn't really go anywhere.
	if( newIndex == _currentIndex )
		return;
	
	// clear previous
	[self unloadFullsizeImageWithIndex:_currentIndex];
	
	_currentIndex = newIndex;
	[self updateCaption];
	[self updateTitle];
	[self updateButtons];
	[self loadFullsizeImageWithIndex:_currentIndex];
	[self preloadThumbnailImages];
    
    NSLog(@"scrollingHasEnded finish");
}

//////////////////////
////// MyCollection
//////////////////////
static NSString* myFavoritesCellIdentifier = @"MyCollectionCell";

-(void)initMyFavorites{
//    [_collectionView registerNib:[UINib nibWithNibName:@"MyFavoritesCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:myFavoritesCellIdentifier];
    [_collectionView registerClass:MyCollectionViewCell.class forCellWithReuseIdentifier:myFavoritesCellIdentifier];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.showsHorizontalScrollIndicator = NO;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).minimumInteritemSpacing = CGFLOAT_MAX;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).scrollDirection = UICollectionViewScrollDirectionHorizontal;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).minimumLineSpacing = 0;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.delegate numberOfPhotosForPhotoGallery:self];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:myFavoritesCellIdentifier forIndexPath:indexPath];
    
    cell.imageView.photoDelegate = self;
    [cell.imageView.activity startAnimating];
    // only set the fullsize image if we're currently on that image
    if( _currentIndex == indexPath.row )
    {
        FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", indexPath.row]];
        cell.imageView.imageView.image = photo.fullsize;
        if(_currentIndex == _preDisplayView.tag && !photo.thumbnail)
            cell.imageView.thumbView.image = _preDisplayView.image;
        else
            cell.imageView.thumbView.image = photo.thumbnail;
    }
    // otherwise, we don't need to keep this image around
    else
    {
        FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", indexPath.row]];
        [photo unloadFullsize];
        
        cell.imageView.imageView.image = photo.fullsize;
        cell.imageView.thumbView.image = photo.thumbnail;
    }
    
    if(cell.imageView.imageView.image || cell.imageView.thumbView.image){
        [cell.imageView.activity stopAnimating];
    }
    
    return cell;
}

//////////////////////
//////
//////////////////////


#pragma mark - FGalleryPhoto Delegate Methods

-(UIImage *)galleryPhotoLoadThumbnailFromLocal:(FGalleryPhoto *)photo{
    if([_photoSource respondsToSelector:@selector(photoGallery:loadThumbnailFromLocalAtIndex:)])
        return [_photoSource photoGallery:self loadThumbnailFromLocalAtIndex:photo.tag];
    return nil;
}

- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromPath:(NSString*)path
{

}

- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromUrl:(NSString*)url
{

}

- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadThumbnail:(UIImage*)image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadFullsize:(UIImage*)image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

-(void)galleryPhoto:(FGalleryPhoto *)photo loadingThumbnail:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

-(void)galleryPhoto:(FGalleryPhoto *)photo loadingFullsize:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

#pragma mark - UIScrollView Methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	_isScrolling = YES;
}
 

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if( !decelerate )
	{
		[self scrollingHasEnded];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self scrollingHasEnded];
}


#pragma mark - Memory Management Methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	
	NSLog(@"[OfflineFGalleryViewController] didReceiveMemoryWarning! clearing out cached images...");
	// unload fullsize and thumbnail images for all our images except at the current index.
	NSArray *keys = [_photoLoaders allKeys];
	NSUInteger i, count = [keys count];
    if (_isThumbViewShowing==YES) {

    } else {
        for (i = 0; i < count; i++)
        {
            FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", i]];
            if( i != _currentIndex )
            {
                if(photo){
                    NSLog(@"Disable Progressive and unload");
                    photo.enableProgressive = NO;
                    [photo unloadFullsize];
                    [photo unloadThumbnail];
                }
            }else{
                NSLog(@"Disable Progressive");
                photo.enableProgressive = NO;
            }
        }
    }
}


- (void)dealloc {
	
	// remove KVO listener
//	[_container removeObserver:self forKeyPath:@"frame"];
	
	// Cancel all photo loaders in progress
	NSArray *keys = [_photoLoaders allKeys];
	NSUInteger i, count = [keys count];
	for (i = 0; i < count; i++) {
		FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
		photo.delegate = nil;
		[photo unloadThumbnail];
		[photo unloadFullsize];
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	self.galleryID = nil;
	
	_photoSource = nil;
	
    [_container release];
    _container = nil;
	
    [_innerContainer release];
    _innerContainer = nil;
	
    [_toolbar release];
    _toolbar = nil;
	
    [_thumbsView release];
    _thumbsView = nil;
	
    [_collectionView release];
    _collectionView = nil;
    
	[_photoLoaders removeAllObjects];
    [_photoLoaders release];
    _photoLoaders = nil;
	
	[_barItems removeAllObjects];
	[_barItems release];
	_barItems = nil;
	
	[_photoViews removeAllObjects];
    [_photoViews release];
    _photoViews = nil;
    
    [_deleteButton release];
    _deleteButton = nil;
    [_favoriteButton release];
    _favoriteButton = nil;
    [_sendButton release];
    _sendButton = nil;
    
    [activityIndicator release];
    activityIndicator = nil;
    
    _photoSource = nil;
    
    NSLog(@"FG dealloc");
    
    [super dealloc];
}

#pragma mark - UIDocumentInteractionController

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)controller {
    return self;
}

- (UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller {
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller {
    return self.view.frame;
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    
}

-(void)documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *)controller {
    
}

@end


/**
 *	This section overrides the auto-rotate methods for UINaviationController and UITabBarController 
 *	to allow the tab bar to rotate only when a FGalleryController is the visible controller. Sweet.
 */

@implementation UINavigationController (FGallery)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([self.visibleViewController isKindOfClass:[OfflineFGalleryViewController class]])
	{
        return YES;
	}

	// To preserve the UINavigationController's defined behavior,
	// walk its stack.  If all of the view controllers in the stack
	// agree they can rotate to the given orientation, then allow it.
	BOOL supported = YES;
	for(UIViewController *sub in self.viewControllers)
	{
		if(![sub shouldAutorotateToInterfaceOrientation:interfaceOrientation])
		{
			supported = NO;
			break;
		}
	}	
	if(supported)
		return YES;
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	// see if the current controller in the stack is a gallery
	if([self.visibleViewController isKindOfClass:[OfflineFGalleryViewController class]])
	{
		OfflineFGalleryViewController *galleryController = (OfflineFGalleryViewController*)self.visibleViewController;
		[galleryController resetImageViewZoomLevels];
	}
}

@end




@implementation UITabBarController (FGallery)


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // only return yes if we're looking at the gallery
    if( [self.selectedViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navController = (UINavigationController*)self.selectedViewController;
        
        // see if the current controller in the stack is a gallery
        if([navController.visibleViewController isKindOfClass:[OfflineFGalleryViewController class]])
        {
            return YES;
        }
    }
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if([self.selectedViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*)self.selectedViewController;
		
		// see if the current controller in the stack is a gallery
		if([navController.visibleViewController isKindOfClass:[OfflineFGalleryViewController class]])
		{
			OfflineFGalleryViewController *galleryController = (OfflineFGalleryViewController*)navController.visibleViewController;
			[galleryController resetImageViewZoomLevels];
		}
	}
}


@end



