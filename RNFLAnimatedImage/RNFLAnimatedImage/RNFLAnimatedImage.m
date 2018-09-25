//
//  RNFLAnimatedImage.m
//  RNFLAnimatedImage
//
//  Created by Neo on 16/9/13.
//  Copyright © 2016 Neo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

#import "FLAnimatedImage.h"
#import "RNFLAnimatedImage.h"

#import <React/RCTBridgeModule.h>
#import "RCTImageUtils.h"
#import <React/UIView+React.h>
#import <React/RCTLog.h>

NSCache* cache;

@implementation RNFLAnimatedImage  {
  
  FLAnimatedImage *_image;
  FLAnimatedImageView *_imageView;
  UIImageView *_staticImageView;
  
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _imageView = [[FLAnimatedImageView alloc] init];
    _staticImageView = [[UIImageView alloc] init];
    
    [_imageView addObserver:self forKeyPath:@"currentFrameIndex" options:0 context:nil];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)


- (void)dealloc
{
  [_imageView removeObserver:self forKeyPath:@"currentFrameIndex"];
}

- (void)layoutSubviews
{
  _imageView.frame = self.bounds;
  _staticImageView.frame = self.bounds;
  [self addSubview:_imageView];
  [self addSubview:_staticImageView];
}

- (void)setSrc:(NSString *)src
{
  if (![src isEqual:_src]) {
    _src = [src copy];
    [self reloadImage];
  }
}

- (void)setContentMode:(NSNumber *)contentMode
{
  if(![contentMode isEqual:_contentMode]) {
    _contentMode = contentMode;
    [self reloadImage];
  }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
  if (object == _imageView) {
    if ([keyPath isEqualToString:@"currentFrameIndex"]) {
      if(_onFrameChange){
        _onFrameChange(@{
                         @"currentFrameIndex":[NSNumber numberWithUnsignedInteger:[object currentFrameIndex]],
                         @"frameCount": [NSNumber numberWithUnsignedInteger:[_image frameCount]],
                         });
      }
    }
  }
}

-(void)reloadImage {
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSData *_imageData = [cache objectForKey:_src];
    
    if(_imageData == nil) {
      _imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_src]];
      [cache setObject:_imageData forKey: _src];
    }
    
    if(_imageData == nil) {
      _imageData = [NSData dataWithContentsOfFile:[NSURL URLWithString:_src]];
      [cache setObject:_imageData forKey: _src];
    }
    
    if(_imageData == nil) {
      if(_onLoadEnd) {
        _onLoadEnd(@{});
      }
      return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *meta = RCTGetImageMetadata(_imageData);
      CGSize size = (CGSize) {
        [meta[(id)kCGImagePropertyPixelWidth] doubleValue],
        [meta[(id)kCGImagePropertyPixelHeight] doubleValue],
      };
      
      if(_onLoadEnd) {
        _onLoadEnd(@{
                     @"size":@{
                         @"width": @(size.width),
                         @"height": @(size.height),
                         }
                     });
      }
      
      _image = [FLAnimatedImage animatedImageWithGIFData:_imageData];
      if (_image) {
        _imageView.contentMode = [_contentMode integerValue];
        _imageView.animatedImage = _image;
      } else {
        _staticImageView.contentMode = [_contentMode integerValue];
        _staticImageView.image = [UIImage imageWithData: _imageData];
      }
    });
  });
}

@end
