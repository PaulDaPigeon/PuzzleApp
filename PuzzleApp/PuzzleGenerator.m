//
//  PuzzleGenerator.m
//  PuzzleApp
//
//  Created by Pal Hebok on 20/03/16.
//  Copyright © 2016 HebokPal. All rights reserved.
//


#import "PuzzleGenerator.h"
#import <QuartzCore/QuartzCore.h>


const CGFloat PuzzlePieceBaseSize = 122.0f;


typedef NS_ENUM(NSUInteger, Position) {
    PositionMiddle = 0,
    PositionTop = 1,
    PositionBottom = 1 << 1,
    PositionLeft = 1 << 2,
    PositionRight = 1 << 3,
    PositionTopLeft = 5,
    PositionTopRigth = 9,
    PositionBottomLeft = 6,
    PositionBottomRight = 10,
};



@implementation PuzzleGenerator


+ (NSArray *)generate:(NSInteger)rows by:(NSInteger)coloumns puzzleFromImage:(UIImage *)image withSize:(CGSize)size
{
    CGPoint positionInImage = CGPointZero;
    CGPoint positionModifier = CGPointZero;
    
    CGFloat xRatio = size.width / (coloumns * PuzzlePieceBaseSize);
    CGFloat yRatio = size.height / (rows * PuzzlePieceBaseSize);
    
    NSMutableArray *puzzlePieces = [NSMutableArray array];
    
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger coloumn = 0; coloumn < coloumns; coloumn ++) {
            Position position = PositionMiddle;
            
            if (coloumn == 0) {
                position = position | PositionLeft;
            }
            else if (coloumn == (coloumns - 1)) {
                position = position | PositionRight;
            }
            
            if (row == 0) {
                position = position | PositionTop;
            }
            else if (row == (rows - 1)) {
                position = position | PositionBottom;
            }
            
            
            UIImage *maskImage;
            switch (position) {
                case PositionMiddle: {
                    maskImage = [UIImage imageNamed:@"Middle"];
                    if ((coloumn + row) % 2 == 0) {
                        positionModifier = CGPointMake(-32, -9);
                    }
                    else {
                        maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationRight];
                        positionModifier = CGPointMake(-9, -32);
                    }
                    break;
                }
                case PositionTop: {
                    if (coloumn % 2 == 0) {
                        maskImage = [UIImage imageNamed:@"Side1"];
                    }
                    else {
                        maskImage = [UIImage imageNamed:@"Side2"];
                    }
                    positionModifier = CGPointMake(-32, 0);
                    break;
                }
                case PositionTopRigth: {
                    maskImage = [UIImage imageNamed:@"Corner"];
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationRight];
                    positionModifier = CGPointMake(-32, 0);
                    break;
                }
                case PositionRight: {
                    if ((row + coloumns) % 2 == 0) {
                        maskImage = [UIImage imageNamed:@"Side1"];
                        positionModifier = CGPointMake(-9, -32);
                    }
                    else {
                        maskImage = [UIImage imageNamed:@"Side2"];
                        positionModifier = CGPointMake(-32, -32);
                    }
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationRight];
                    break;
                }
                case PositionBottomRight: {
                    maskImage = [UIImage imageNamed:@"Corner"];
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationDown];
                    positionModifier = CGPointMake(-9, -32);
                    break;
                }
                case PositionBottom: {
                    if ((rows + coloumn) % 2 == 0) {
                        maskImage = [UIImage imageNamed:@"Side2"];
                        positionModifier = CGPointMake(-32, -9);
                    }
                    else {
                        maskImage = [UIImage imageNamed:@"Side1"];
                        positionModifier = CGPointMake(-9, -9);
                    }
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationDown];
                    break;
                }
                case PositionBottomLeft: {
                    maskImage = [UIImage imageNamed:@"Corner"];
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationLeft];
                    positionModifier = CGPointMake(0, -9);
                    break;
                }
                case PositionLeft: {
                    if (row % 2 == 0) {
                        maskImage = [UIImage imageNamed:@"Side2"];
                    }
                    else {
                        maskImage = [UIImage imageNamed:@"Side2"];
                    }
                    positionModifier = CGPointMake(0, -9);
                    maskImage = [PuzzleGenerator rotateimage:maskImage toOrientation:UIImageOrientationLeft];
                    break;
                }
                case PositionTopLeft: {
                    maskImage = [UIImage imageNamed:@"Corner"];
                    break;
                }
            }
            
            CGSize size = CGSizeMake(maskImage.size.width * xRatio, maskImage.size.height * yRatio);
            UIGraphicsBeginImageContext(size);
            [maskImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
            maskImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            CALayer *layerMask = [CALayer layer];
            layerMask.contents = (id)maskImage.CGImage;
            layerMask.frame = CGRectMake(0, 0, maskImage.size.width, maskImage.size.height);
            UIImageView *piece = [[UIImageView alloc] initWithFrame:CGRectMake(positionModifier.x, positionModifier.y, maskImage.size.width, maskImage.size.height)];
            piece.backgroundColor = [UIColor greenColor];
            piece.tag = coloumn;
            piece.layer.mask = layerMask;
            piece.layer.masksToBounds = YES;
            
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake((positionInImage.x + positionModifier.x) * xRatio, (positionInImage.y + positionModifier.y) * yRatio, maskImage.size.width, maskImage.size.height));
            [piece setImage:[UIImage imageWithCGImage:imageRef scale:image.scale orientation:UIImageOrientationUp]];
            positionInImage.x += PuzzlePieceBaseSize;
            
            [puzzlePieces addObject:piece];
        }
        positionInImage.x = 0;
        positionInImage.y += PuzzlePieceBaseSize;
    }
    
    return [puzzlePieces copy];
}


+ (UIImage *)rotateimage:(UIImage *)src toOrientation:(UIImageOrientation)orientation
{
    CGSize imageSize = src.size;
    CGSize rotatedSize;
    CGFloat radians;
    if (orientation == UIImageOrientationRight) {
        radians = M_PI_2;
    } else if (orientation == UIImageOrientationLeft) {
        radians = -M_PI_2;
    } else if (orientation == UIImageOrientationDown) {
        radians = M_PI;
    } else if (orientation == UIImageOrientationUp) {
        radians = 0;
    }

    if (radians == M_PI_2 || radians == -M_PI_2) {
        rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
    } else {
        rotatedSize = imageSize;
    }
    
    double rotatedCenterX = rotatedSize.width / 2.f;
    double rotatedCenterY = rotatedSize.height / 2.f;

    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
    CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
    if (radians == 0.f || radians == M_PI) {
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        if (radians == 0.0f) {
            CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        } else {
            CGContextScaleCTM(rotatedContext, -1.f, 1.f);
        }
        CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
    } else if (radians == M_PI_2 || radians == -M_PI_2) {
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        CGContextRotateCTM(rotatedContext, radians);
        CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
    }
    
    CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
    CGContextDrawImage(rotatedContext, drawingRect, src.CGImage);
    CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);
    UIImage *image = [UIImage imageWithCGImage:rotatedCGImage];
    UIGraphicsEndImageContext();
    
    return image;
}


@end
