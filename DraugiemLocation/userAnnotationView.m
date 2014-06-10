//
//  userAnnotationView.m
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "UserAnnotationView.h"
#import "UserAnnotation.h"

//MKAnnotationView image view size. Hardcoded, can't get programmatically.
static int const kUserImageSize = 55;
//Callout image seperator line width
static int const kUserImageSeperatorLineWidth = 3;

@interface UserAnnotationView()

@property (nonatomic) UIImageView *userImageView;
@property (nonatomic) UserAnnotation *customAnnotation;

@end

@implementation UserAnnotationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        [self setupViews:frame];
        
        //Listen to UserAnnotation notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUserAnnotationDidEndLoadingImage:)
                                                     name:USER_IMAGE_DID_END_LOADING
                                                   object:nil];
    }
    return self;
}

#pragma mark - Views

- (void)setupViews:(CGRect)frame
{
    //UIImage - image
    self.image = [UIImage imageNamed:@"userAnnotationIcon"];
    
    //UIView - contentView
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kUserImageSize+kUserImageSeperatorLineWidth, kUserImageSize)];
    self.contentView.backgroundColor = [UIColor colorWithRed:253.0f/255.0f green:130.0f/255.0f blue:45.0f/255.0f alpha:1.0]; // Orange color
    
    //UIImageView - userImageView
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, kUserImageSize, kUserImageSize)];
    self.userImageView.backgroundColor = [UIColor lightGrayColor];
    self.userImageView.image = [UIImage imageNamed:@"noUserImage"]; //Placeholder
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill; // Deployment targets pre-iOS8 might ignore this.
    self.userImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.userImageView];
    
    //Setup UserAnnotationAccessoryView
    self.leftCalloutAccessoryView = self.contentView;
}

#pragma mark - Data Methods

- (void)notifyToLoadImage
{
    //Create pointer to UserAnnotation object
    self.customAnnotation = (UserAnnotation *)self.annotation;
    //Start user image loading
    [self.customAnnotation loadUserImage];
}

- (void)handleUserAnnotationDidEndLoadingImage:(NSNotificationCenter *)sender
{
    //Did finish loading, update UI
    if (self.customAnnotation.userImage) self.userImageView.image = self.customAnnotation.userImage;
}

-(void)prepareForReuse
{
    //Cleanup before reuse
    self.customAnnotation = nil;
    self.annotation = nil;
    self.userImageView.image = nil;
}

-(void)dealloc
{
    //Remove NSNotificationCenter. If not removed, will cause error.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
