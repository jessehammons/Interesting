//
//  INPhotoView.h
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INDispatchRecord;
@class INPhotoObject;
@class INStackObject;

@interface INPhotoView : UIView

@property (nonatomic, strong) UIImageView *progressImageView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *photoFrameView;
@property (nonatomic, strong) INDispatchRecord *imageRecord;
@property (nonatomic, strong) INDispatchRecord *previewImageRecord;

@property (nonatomic, strong) NSDictionary *photo;

- (void)updatePhoto:(NSDictionary*)dictionary;
- (void)loadPhotoURLKey:(NSString*)key;

@end

@interface INPhotoObjectView : UIView

@property (nonatomic, strong) NSArray *imageURLKeys;
@property (nonatomic, strong) NSArray *pipelineObjects;
@property (nonatomic, strong) UIImageView *visibleImageView;
@property (nonatomic, strong) UIImageView *fadingImageView;

@property (nonatomic, strong) INPhotoObject *photoObject;

- (void)updatePhotoObject:(INPhotoObject*)photoObject loadImageURLKeys:(NSArray*)imageURLKeys;
- (void)loadMediaWithPriority:(NSInteger)priority;

@end

@interface INStackView : UIView

@property (nonatomic, strong) UIImageView *stackBackgroundView;
@property (nonatomic, strong) NSMutableArray *photoViews;

@property (nonatomic, strong) INStackObject *stackObject;

- (void)updateStackObject:(INStackObject*)stackObject;

@end

@interface INPhotoGroup : NSObject

@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, readonly) NSArray *photos;

+ (INPhotoGroup*)photoGroupWithPhotosArray:(NSArray*)photos;

- (id)initWithDictionary:(NSDictionary*)value;
- (NSDictionary*)photoAtIndex:(NSInteger)index;
- (NSDictionary*)selectedPhoto;

@end