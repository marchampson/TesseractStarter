//
//  ViewController.h
//  Tesseract Starter
//
//  Created by Marc Hampson on 07/01/2017.
//  Copyright © 2017 Marc Hampson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h> 
#import <opencv2/imgproc/imgproc.hpp>
#import <TesseractOCR/G8Tesseract.h>

@interface ViewController : UIViewController <CvVideoCameraDelegate, G8TesseractDelegate>

- (UIImage *) UIImageFromCVMat:(cv::Mat)cvMat;

@end
