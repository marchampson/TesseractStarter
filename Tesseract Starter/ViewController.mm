//
//  ViewController.m
//  Tesseract Starter
//
//  Created by Marc Hampson on 07/01/2017.
//  Copyright © 2017 Marc Hampson. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    CvVideoCamera *camera;
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *resultImageView;
@property (strong, nonatomic) IBOutlet UIView *targetArea;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Camera Setup
    camera = [[CvVideoCamera alloc] initWithParentView:_imageView];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    camera.defaultFPS = 15;
    camera.grayscaleMode = NO;
    camera.delegate = self;
    
    // Add a border to the target
    _targetArea.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor;
    _targetArea.layer.borderWidth = 1.0f; //make border 1px thick
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [camera start];
}

- (void)processImage:(cv::Mat &)image {
    NSLog(@"foo");
    //@autoreleasepool {
    
    // create a new image
    cv::Mat image_copy;
    
    // copy the processed image to the new holder and make grey
    cvtColor(image, image_copy, CV_BGR2GRAY);
    
    // Initialise Tesseract
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    
    // Optionaly: You could specify engine to recognize with.
    // G8OCREngineModeTesseractOnly by default. It provides more features and faster
    // than Cube engine. See G8Constants.h for more information.
    tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    // Set up the delegate to receive Tesseract's callbacks.
    // self should respond to TesseractDelegate and implement a
    // "- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract"
    // method to receive a callback to decide whether or not to interrupt
    // Tesseract before it finishes a recognition.
    tesseract.delegate = self;
    
    // Optional: Limit the character set Tesseract should try to recognize from
    tesseract.charWhitelist = @"0123456789";
    
    // Disable dictionaries as we are only looking for numbers
    [tesseract setVariableValue:@"0" forKey:@"tessedit_enable_doc_dict"];
    
    
    // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
    // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
    // See G8TesseractParameters.h for a complete list of Tesseract variables
    
    // Optional: Limit the character set Tesseract should not try to recognize from
    //tesseract.charBlacklist = @"OoZzBbSs";
    tesseract.charBlacklist = @"aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ£&/- ";
    
    // Optional: Limit the area of the image Tesseract should recognize on to a rectangle
    tesseract.rect = CGRectMake(20, 20, 100, 100);
    
    // Optional: Limit recognition time with a few seconds
    //tesseract.maximumRecognitionTime = 2.0;
    
    
    /*
    // Start the recognition
    [tesseract recognize];
    
    // Retrieve the recognized text
    NSLog(@"%@", [tesseract recognizedText]);
    
    // You could retrieve more information about recognized text with that methods:
    NSArray *characterBoxes = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
    NSArray *paragraphs = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
    NSArray *characterChoices = tesseract.characterChoices;
    UIImage *imageWithBlocks = [tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:NO];
     */
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // Specify the image Tesseract should recognize on
        [tesseract setImage:[self UIImageFromCVMat:image_copy]];
        
        // Start the recognition
        [tesseract recognize];
        
        // String to check for product numbers
        NSString *string = [tesseract recognizedText];
        
        NSError * error = nil;
        
        NSString *regexAsString = @"[0-9]{6}";
        
        // Create instance of NSRegularExpression
        // which is a compiled regular expression pattern
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexAsString options:0 error:&error];
        
        NSArray *numbersToFind = @[@"771758", @"833028"];
        
        if (!error)
        {
            // Array of matches of regex in string
            NSArray *results = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
            
            // View results to see range and length of matches
            //NSLog(@"results: %@", results);
            
            // For each item found...
            for (NSTextCheckingResult *entry in results)
            {
                // Get product code from str using range
                NSString *text = [string substringWithRange:entry.range];
                
                BOOL contains = [numbersToFind containsObject:[NSString stringWithFormat:@"%@",text]];
                if(contains) {
                    NSLog(@"Found %@", text);
                }
            }
            
            NSArray *characterBoxes = [tesseract confidencesByIteratorLevel:G8PageIteratorLevelSymbol];
            
            //NSArray *paragraphs = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
            //NSArray *characterChoices = tesseract.characterChoices;
            UIImage *imageWithBlocks = [tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_resultImageView setImage:imageWithBlocks];
            });
            
        }
        else
            NSLog(@"Invalid expression pattern: %@", error);
        
    });

}



// http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    
    CGImageRef imageRef = CGImageCreate(
                                    480,//width
                                    640,//height
                                    8,//bits per component
                                    8 * cvMat.elemSize(),                      //bits per pixel
                                    cvMat.step[0],                            //bytesPerRow
                                    colorSpace,                                 //colorspace
                                    kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                    provider,                                   //CGDataProviderRef
                                    NULL,                                       //decode
                                    false,                                      //should interpolate
                                    kCGRenderingIntentDefault                   //intent
                                    );
    
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
    
}



@end
