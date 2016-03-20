//
//  ViewController.m
//  PuzzleApp
//
//  Created by Pal Hebok on 28/02/16.
//  Copyright © 2016 HebokPal. All rights reserved.
//


#import "ViewController.h"
#import <UIView+draggable.h>
#import "PuzzleGenerator.h"


typedef NS_ENUM(NSInteger, Orientation) {
    OrientationTop,
    OrientationRight,
    OrientationBottom,
    OrientationLeft
};


static const CGFloat PuzzlePieceSnappingTolerance = 10.0f;


@interface ViewController () <UIGestureRecognizerDelegate>


@property (nonatomic, strong) NSMutableArray *puzzlePieceRows;
@property (nonatomic, strong) NSArray *puzzlePieces;


@end


@implementation ViewController


#pragma mark - Lifecycle


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    UIImage *image = [UIImage imageNamed:@"Image"];
    CGFloat aspectRatio;
    aspectRatio = image.size.height / image.size.width;
    
    CGSize size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.width * aspectRatio);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSInteger rows = 3;
    NSInteger coloumns = 3;
    
    self.puzzlePieces = [PuzzleGenerator generate:rows by:coloumns puzzleFromImage:image withSize:image.size];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
    [imageView setImage:image];
    [view addSubview:imageView];
    [view enableDragging];
    [self.view addSubview:imageView];
    
    CGFloat xRatio = size.width / (coloumns * PuzzlePieceBaseSize);
    CGFloat yRatio = size.height / (rows * PuzzlePieceBaseSize);
    self.puzzlePieceRows = [NSMutableArray array];
    for (NSInteger row = 0; row < rows; row++) {
        [self.puzzlePieceRows addObject:[NSMutableArray new]];
        for (NSInteger coloumn = 0; coloumn < coloumns; coloumn ++) {
            UIImageView *imageView = [self.puzzlePieces objectAtIndex:((coloumns * row) + coloumn)];
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PuzzlePieceBaseSize * xRatio, PuzzlePieceBaseSize * yRatio)];
            [view enableDragging];
            [view addSubview:imageView];
            UIView *touchArea = [[UIView alloc] initWithFrame:view.frame];
            touchArea.backgroundColor = [UIColor greenColor];
            [touchArea setAlpha:0.5f];
            [view addSubview:touchArea];
            view.tag = row;
            view.cagingArea = self.view.frame;
            __weak UIView *weakView = view;
            view.draggingEndedBlock = ^{
                [self draggingEnded:weakView];
            };
            [self.view addSubview:view];
            
            [((NSMutableArray *)self.puzzlePieceRows[row]) addObject:view];
        }
    }
}


#pragma mark - Attaching


- (void)draggingEnded:(UIView *)view;
{
    NSMutableArray *connectedPieces = [NSMutableArray new];
    //change back to 2 after test
    if (view.subviews.count < 3) {
        [self attachNeighboursForPuzzlePiece:view withConnectedPieces:connectedPieces];
    }
    else {
        [connectedPieces addObjectsFromArray:view.subviews];
        for (UIView *puzzlePiece in view.subviews) {
            [self attachNeighboursForPuzzlePiece:puzzlePiece withConnectedPieces:connectedPieces];
        }
    }
}


- (void)attachNeighboursForPuzzlePiece:(UIView *)puzzlePiece withConnectedPieces:(NSMutableArray *)connectedPieces
{
    NSInteger coloumn = [self.puzzlePieceRows[puzzlePiece.tag] indexOfObject:puzzlePiece];
    
    CGPoint puzzlePieceInView = [self.view convertPoint:puzzlePiece.frame.origin fromView:puzzlePiece.superview];
    
    if (puzzlePiece.tag != 0) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag - 1] objectAtIndex:coloumn];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS((puzzlePieceInView.y) - (otherPieceInView.y + PuzzlePieceBaseSize)) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, puzzlePieceInView.y - (otherPieceInView.y + PuzzlePieceBaseSize));
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationTop];
                }
            }
        }
    }
    
    if (puzzlePiece.tag != (self.puzzlePieceRows.count -1)) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag + 1] objectAtIndex:coloumn];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS((puzzlePieceInView.y + PuzzlePieceBaseSize) - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, (puzzlePieceInView.y + PuzzlePieceBaseSize) - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationBottom];
                }
            }
        }
    }
    
    if (coloumn != 0) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag] objectAtIndex:coloumn - 1];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS((puzzlePieceInView.x) - ((otherPieceInView.x + PuzzlePieceBaseSize))) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - (otherPieceInView.x + PuzzlePieceBaseSize), puzzlePieceInView.y - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationLeft];
                }
            }
        }
    }
    
    if (coloumn != ((NSMutableArray *)self.puzzlePieceRows[puzzlePiece.tag]).count - 1) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag] objectAtIndex:coloumn + 1];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS((puzzlePieceInView.x + PuzzlePieceBaseSize) - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake((puzzlePieceInView.x + PuzzlePieceBaseSize) - otherPieceInView.x, puzzlePieceInView.y - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationRight];
                    
                }
            }
        }
    }
}


- (void)attachPuzzlePiece:(UIView *)pieceA toPuzzlePiece:(UIView *)pieceB withDistance:(CGPoint)distance andOrientation:(Orientation)orientation
{
    UIView *containerView;
    if (pieceA.superview != self.view) {
        containerView = pieceA.superview;
    }
    else {
        [pieceA setDraggable:NO];
        containerView = [[UIView alloc] initWithFrame:pieceA.frame];
        containerView.tag = -1;
        [containerView enableDragging];
        [containerView.panGesture setDelegate:self];
        __weak UIView *weakContainerView = containerView;
        containerView.draggingEndedBlock = ^{
            [self draggingEnded:weakContainerView];
        };
        
        containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        [self.view addSubview:containerView];
        [pieceA removeFromSuperview];
        CGPoint point = [containerView convertPoint:pieceA.frame.origin fromView:self.view];
        pieceA.frame = CGRectMake(point.x, point.y, pieceA.frame.size.width, pieceA.frame.size.height);
        [containerView addSubview:pieceA];
    }
    
    NSMutableArray *viewsToMove = [NSMutableArray new];
    if (pieceB.superview != self.view) {
        CGFloat distanceX = pieceB.superview.frame.origin.x + distance.x - containerView.frame.origin.x;
        CGFloat x;
        if (distanceX < 0) {
            x = pieceB.superview.frame.origin.x + distance.x;
        }
        else {
            x = containerView.frame.origin.x;
            distanceX = 0;
        }
        
        CGFloat distanceY = pieceB.superview.frame.origin.y + distance.y - containerView.frame.origin.y;
        CGFloat y;
        if (distanceY < 0) {
            y = pieceB.superview.frame.origin.y + distance.y;
        }
        else {
            y = containerView.frame.origin.y;
            distanceY = 0;
        }
        
        if (!(distanceX == 0 && distanceY == 0)) {
            for (UIView *view in containerView.subviews) {
                view.frame = CGRectMake(view.frame.origin.x - distanceX, view.frame.origin.y - distanceY, view.frame.size.width, view.frame.size.height);
            }
        }
        
        CGFloat width = containerView.frame.origin.x + containerView.frame.size.width > pieceB.superview.frame.origin.x + pieceB.superview.frame.size.width + distance.x ? containerView.frame.origin.x + containerView.frame.size.width - x : pieceB.superview.frame.origin.x + pieceB.superview.frame.size.width + distance.x - x;
        CGFloat height = containerView.frame.origin.y + containerView.frame.size.height > pieceB.superview.frame.origin.y + pieceB.superview.frame.size.height + distance.y ? containerView.frame.origin.y + containerView.frame.size.height - y : pieceB.superview.frame.origin.y + pieceB.superview.frame.size.height + distance.y - y;
        
        containerView.frame = CGRectMake(x, y, width, height);
        
        UIView *previousSuperView = pieceB.superview;
        
        for (UIView *view in previousSuperView.subviews) {
            [viewsToMove addObject:view];
            [view removeFromSuperview];
            CGPoint point = [containerView convertPoint:view.frame.origin fromView:previousSuperView];
            view.frame = CGRectMake(point.x, point.y, view.frame.size.width, view.frame.size.height);
            [containerView addSubview:view];
        }
        
        [previousSuperView removeFromSuperview];
    }
    else {
        CGFloat distanceX = pieceB.frame.origin.x + distance.x - containerView.frame.origin.x;
        CGFloat x;
        if (distanceX < 0) {
            x = pieceB.frame.origin.x + distance.x;
        }
        else {
            x = containerView.frame.origin.x;
            distanceX = 0;
        }
        
        CGFloat distanceY = pieceB.frame.origin.y + distance.y - containerView.frame.origin.y;
        CGFloat y;
        if (distanceY < 0) {
            y = pieceB.frame.origin.y + distance.y;
        }
        else {
            y = containerView.frame.origin.y;
            distanceY = 0;
        }
        
        if (!(distanceX == 0 && distanceY == 0)) {
            for (UIView *view in containerView.subviews) {
                view.frame = CGRectMake(view.frame.origin.x - distanceX, view.frame.origin.y - distanceY, view.frame.size.width, view.frame.size.height);
            }
        }
        
        CGFloat width = containerView.frame.origin.x + containerView.frame.size.width > pieceB.frame.origin.x + pieceB.frame.size.width + distance.x ? containerView.frame.origin.x + containerView.frame.size.width - x : pieceB.frame.origin.x + pieceB.frame.size.width + distance.x - x;
        CGFloat height = containerView.frame.origin.y + containerView.frame.size.height > pieceB.frame.origin.y + pieceB.frame.size.height + distance.y ? containerView.frame.origin.y + containerView.frame.size.height - y : pieceB.frame.origin.y + pieceB.frame.size.height + distance.y - y;
        
        containerView.frame = CGRectMake(x, y, width, height);
        
        [pieceB setDraggable:NO];
        [viewsToMove addObject:pieceB];
        [pieceB removeFromSuperview];
        CGPoint point = [containerView convertPoint:pieceB.frame.origin fromView:self.view];
        pieceB.frame = CGRectMake(point.x, point.y, pieceB.frame.size.width, pieceB.frame.size.height);
        [containerView addSubview:pieceB];
    }
    
    [UIView animateWithDuration:1.0f animations:^{
        for (UIView *view in viewsToMove) {
            view.frame = CGRectMake(view.frame.origin.x + distance.x, view.frame.origin.y + distance.y, view.frame.size.width, view.frame.size.height);
        }
    }];
}


@end
