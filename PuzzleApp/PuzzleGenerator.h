//
//  PuzzleGenerator.h
//  PuzzleApp
//
//  Created by Pal Hebok on 20/03/16.
//  Copyright © 2016 HebokPal. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern const CGFloat PuzzlePieceBaseSize;


@interface PuzzleGenerator : NSObject


+ (NSArray *)generate:(NSInteger)rows by:(NSInteger)coloumns puzzleFromImage:(UIImage *)image withSize:(CGSize)size;


@end
