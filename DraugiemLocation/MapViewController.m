//
//  MapViewController.m
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 09/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "MapViewController.h"
#import "MapMainView.h"
#import "UserAnnotationView.h"
#import "UserAnnotation.h"
#import "StreamConverter.h"

@interface MapViewController () <NSStreamDelegate, MKMapViewDelegate, UIAlertViewDelegate>
//Views
@property (nonatomic) MapMainView *mainView;
//MK & CL properties
@property (nonatomic) CLLocationManager *locationManager;
//NSStream properties
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic) NSInputStream *inputStream;
//Arrays
@property (nonatomic) NSMutableArray *allUserAnnotations;
//BOOLs
@property (nonatomic) BOOL didZoomUser;
@property (nonatomic) BOOL alertViewVisible;

@end

@implementation MapViewController

//Lazy load
-(NSMutableArray *)allUserAnnotations
{
    if (!_allUserAnnotations) _allUserAnnotations = [[NSMutableArray alloc] init];
    return _allUserAnnotations;
}
-(MapMainView *)mainView
{
    if (!_mainView) _mainView = [[MapMainView alloc] init];
    return _mainView;
}
-(CLLocationManager *)locationManager
{
    if (!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager;
}
//

//Load view
-(void)loadView
{
    //Add root view
    self.view = self.mainView;
}
//

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Setup controllet
    [self setupController];
    //Create stream
    [self createStreamConnection];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"Application did receive memory warning!");
}

#pragma mark - Helper methods

- (void)setupController
{
    //Main inits
    self.view.backgroundColor = [UIColor clearColor];
    self.didZoomUser = NO;
    
    //Request locationService auth - for iOS 8 only. Remove if running on simulator
    if ([[CLLocationManager class] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    //Setup mapView
    self.mainView.mapView.delegate = self;
    self.mainView.mapView.showsUserLocation = YES;
}

- (void)createStreamConnection
{
    //Create socketToHost pair
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"spacebox.lv", 6111, &readStream, &writeStream);
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    self.inputStream = (__bridge NSInputStream *)readStream;
    
    //Set delegates
    self.outputStream.delegate = self;
    self.inputStream.delegate = self;
    
    //Add to run-loop
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    //Open streams
    [self.outputStream open];
    [self.inputStream open];
}

- (void)authorizeUser
{
    //Send authorization
    NSString *authorizeString = [NSString stringWithFormat:@"AUTHORIZE armands.la@gmail.com\n"];
    NSData *authorizeStringData = [[NSData alloc] initWithData:[authorizeString dataUsingEncoding:NSASCIIStringEncoding]];
    [self.outputStream write:[authorizeStringData bytes] maxLength:[authorizeStringData length]];
    
    //Close outputStream
    [self.outputStream close];
}

- (void)convertStreamOutputToUsableData:(NSString *)outputString
{
    if ([outputString hasPrefix:@"USERLIST"]) {
        //First load
        [StreamConverter convertUserDataToArray:outputString completion:^(NSArray *result) {
            //Create annotation objects
            [self createUserAnnotations:result];
        }];
    } else if ([outputString hasPrefix:@"UPDATE"]) {
        //Update
        //Align output style
        NSString *alignedOutput = [outputString stringByReplacingOccurrencesOfString:@"\n" withString:@";"];
        [StreamConverter convertUserDataToArray:alignedOutput completion:^(NSArray *result) {
            //Update annotation objects
            [self updateUserAnnotation:result];
        }];
    }
}

- (void)createUserAnnotations:(NSArray *)userArray
{
    //Create userObjects from userArray. Add to allUserAnnotations array
    for (NSArray *array in userArray) {
        UserAnnotation *userAnnotation = [[UserAnnotation alloc] initWithArray:array];
        //[self createAnnotation:userObject];
        [self.mainView.mapView addAnnotation:(id)userAnnotation];
        [self.allUserAnnotations addObject:userAnnotation];
    }
}

- (void)updateUserAnnotation:(NSArray *)userArray
{
    //Perform update on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Loop through all updated users
        for (NSArray *array in userArray) {
            //Get userID for user
            NSString *userID = array[0];
            //Loop through all saved annotations
            for (UserAnnotation *annotation in self.allUserAnnotations) {
                //Check for if updated user == saved.
                if ([userID isEqual:annotation.userID]) {
                    //Match found. Update user data on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //Update annotation location and subtitle, animated
                        [UIView animateWithDuration:0.35 animations:^{
                            [annotation setCoordinate:CLLocationCoordinate2DMake([array[1] doubleValue], [array[2] doubleValue])];
                            [self updateCurrentUserStreetAddressByLocation:annotation]; //Not animatable
                        }];
                    });
                }
            }
        }
    });
}

- (void)updateCurrentUserStreetAddressByLocation:(UserAnnotation *)annotation
{
    //Get location from annotation
    CLLocation *loc = [[CLLocation alloc]initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    //Reverse Geocode to get street address
    [ceo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        //Get first and only object
        CLPlacemark *placemark = placemarks[0];
        //Get street name from placemark
        NSString *streetName;
        NSString *streetNumber;
        if (placemark.thoroughfare) streetName = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
        else {
            streetName = @"somewhere...";
            streetNumber = @"";
        }
        //Get street number from placemark
        if (placemark.subThoroughfare) streetNumber = [NSString stringWithFormat:@"%@", placemark.subThoroughfare];
        else streetNumber = @"";
        //Update annotation object
        annotation.subtitle = [NSString stringWithFormat:@"%@ %@", streetName, streetNumber];
    }];
}

- (void)handleBadConnectionError:(NSError *)error
{
    if (self.alertViewVisible) return;
    //Create error string
    NSString *errorString = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    //Show alertView
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hmm..." message:[NSString stringWithFormat:@"Diemžēl kaut kas nogāja greizi.\n\n %@", errorString] delegate:self cancelButtonTitle:@"Paldies" otherButtonTitles:nil];
    [alertView show];
    self.alertViewVisible = YES;
}

#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            //Stream is open
            break;
            
        case NSStreamEventHasBytesAvailable:
            //inputStream -  data is available
            NSLog(@"puk");
            //Check stream ID
            if (aStream == self.inputStream) {
                //Create buffer
                uint8_t buffer[1024];
                long lenght;
                //Check if stream contains anything
                while ([self.inputStream hasBytesAvailable]) {
                    lenght = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (lenght > 0) {
                        //Output string
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:lenght encoding:NSUTF8StringEncoding];
                        if (output != nil) {
                            //Convert output
                            [self convertStreamOutputToUsableData:output];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            //outputStream - space is available
            //Authorize user
            if (aStream == self.outputStream) {
                [self authorizeUser];
            }
            break;
            
        case NSStreamEventEndEncountered:
            //Stream reached end, close and remove
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        case NSStreamEventErrorOccurred:
            //Error
            [self handleBadConnectionError:[aStream streamError]];
            break;
            
        default:
            //Unknown event
            NSLog(@"NSStream - unknown event");
            break;
    }
}

#pragma mark - MKMapView Delegates

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    //Zoom to user location. Only when app is launched for the first time
    if (!self.didZoomUser) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 25600, 25600);
        [self.mainView.mapView setRegion:[self.mainView.mapView regionThatFits:region] animated:YES];
        self.didZoomUser = YES;
    }
    
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[UserAnnotation class]]) {
        
        //Custom MKAnnotation protocol class
        UserAnnotation *userAnnotation = annotation;
        //Custom MKAnnotationView class
        UserAnnotationView *annotationView = (UserAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"UserAnnotation"];
        //Create UserAnnotationView if it doesn't exist
        if (annotationView == nil) annotationView = [[UserAnnotationView alloc] init];
        
        //Customizations
        annotationView.annotation = (id)userAnnotation;
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        userAnnotation.title = userAnnotation.userName;
        userAnnotation.subtitle = @"Somewhere..."; // Placehoder
        
        //Start user image loading
        [annotationView notifyToLoadImage];
        
        //Get current user street by location
        [self updateCurrentUserStreetAddressByLocation:userAnnotation];
        
        return annotationView;
    }
    else return nil;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            //Cancel - Button pressed
            self.alertViewVisible = NO;
        }
    }
}

@end