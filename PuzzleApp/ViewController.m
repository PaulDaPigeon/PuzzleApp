//
//  ViewController.m
//  PuzzleApp
//
//  Created by Pal Hebok on 28/02/16.
//  Copyright © 2016 HebokPal. All rights reserved.
//


#import "ViewController.h"
#import "UIView+draggable.h"
#import "PuzzleGenerator.h"


typedef NS_ENUM(NSInteger, Orientation) {
    OrientationTop,
    OrientationRight,
    OrientationBottom,
    OrientationLeft
};


static const CGFloat PuzzlePieceSnappingTolerance = 20.0f;
static const NSUInteger shuffleCount = 5;


@interface ViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate>


@property (nonatomic, strong) NSArray *puzzlePieces;
@property (assign, nonatomic) NSUInteger rows;
@property (assign, nonatomic) NSUInteger coloumns;
@property (assign, nonatomic) CGFloat xRatio;
@property (assign, nonatomic) CGFloat yRatio;
@property (assign, nonatomic) NSUInteger shuffleCount;
@property (strong, nonatomic) UIImageView *referenceImageView;


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
    
    self.rows = 4;
    self.coloumns = 4;
    
    self.puzzlePieces = [PuzzleGenerator generate:self.rows by:self.coloumns puzzleFromImage:image withSize:image.size];
    
    self.referenceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 300, image.size.width, image.size.height)];
    [self.referenceImageView setImage:image];
    [self.referenceImageView setAlpha:0.6f];
    [self.view addSubview:self.referenceImageView];
    
    self.xRatio = size.width / (self.coloumns * PuzzlePieceBaseSize);
    self.yRatio = size.height / (self.rows * PuzzlePieceBaseSize);
    
    [self displayPuzzle];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidLoad];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(shufflePieces) userInfo:nil repeats:NO];
}


#pragma mark - Displaying


- (void)displayPuzzle
{
    for (NSUInteger row = 0; row < self.rows; row++) {
        for (NSUInteger coloumn = 0; coloumn < self.coloumns; coloumn++) {
            UIImageView *imageView = [self.puzzlePieces objectAtIndex:((row * self.coloumns) + coloumn)];
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(coloumn * PuzzlePieceBaseSize * self.xRatio, (row * PuzzlePieceBaseSize * self.yRatio) + 300, PuzzlePieceBaseSize * self.xRatio, PuzzlePieceBaseSize * self.yRatio)];
            [view enableDragging];
            [view addSubview:imageView];
            view.tag = -1;
            view.cagingArea = self.view.frame;
            __weak UIView *weakView = view;
            view.draggingStartedBlock = ^{
                [self draggingStarted:weakView];
            };
            view.draggingEndedBlock = ^{
                [self draggingEnded:weakView];
            };
            [self.view addSubview:view];
        }
    }
}


#pragma mark - Attaching


- (void)draggingStarted:(UIView *)view
{
    if (view.tag != 1) {
        [self.view bringSubviewToFront:view];
    }
}


- (void)draggingEnded:(UIView *)view;
{
    NSMutableArray *connectedPieces = [NSMutableArray new];
    if (view.tag == -1) {
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
    NSUInteger index = [self.puzzlePieces indexOfObject:[puzzlePiece.subviews objectAtIndex:0]];
    NSUInteger coloumn = index % self.coloumns;
    NSUInteger row = index / self.coloumns;
    CGPoint puzzlePieceInView = [self.view convertPoint:puzzlePiece.frame.origin fromView:puzzlePiece.superview];
    
    if (row != 0) {
        UIView *otherPiece = [self.puzzlePieces objectAtIndex:index - self.coloumns];
        otherPiece = otherPiece.superview;
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS((puzzlePieceInView.y) - (otherPieceInView.y + PuzzlePieceBaseSize * self.yRatio)) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, puzzlePieceInView.y - (otherPieceInView.y + PuzzlePieceBaseSize * self.yRatio));
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationTop];
                }
            }
        }
    }
    
    if (row != self.rows - 1) {
        UIView *otherPiece = [self.puzzlePieces objectAtIndex:index + self.coloumns];
        otherPiece = otherPiece.superview;
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS((puzzlePieceInView.y + PuzzlePieceBaseSize * self.yRatio) - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, (puzzlePieceInView.y + PuzzlePieceBaseSize * self.yRatio) - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationBottom];
                }
            }
        }
    }
    
    if (coloumn != 0) {
        UIView *otherPiece = [self.puzzlePieces objectAtIndex:index - 1];
        otherPiece = otherPiece.superview;
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS((puzzlePieceInView.x) - ((otherPieceInView.x + PuzzlePieceBaseSize * self.xRatio))) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - (otherPieceInView.x + PuzzlePieceBaseSize * self.xRatio), puzzlePieceInView.y - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance andOrientation:OrientationLeft];
                }
            }
        }
    }
    
    if (coloumn != self.coloumns - 1) {
        UIView *otherPiece = [self.puzzlePieces objectAtIndex:index + 1];
        otherPiece = otherPiece.superview;
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:otherPiece.superview];
            if (ABS((puzzlePieceInView.x + PuzzlePieceBaseSize * self.xRatio) - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake((puzzlePieceInView.x + PuzzlePieceBaseSize * self.xRatio) - otherPieceInView.x, puzzlePieceInView.y - otherPieceInView.y);
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
        [containerView enableDragging];
        containerView.cagingArea = pieceA.cagingArea;
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
    
    if (containerView.frame.size.width == self.view.frame.size.width) {
        containerView.tag = 1;
        [containerView setShouldMoveAlongX:NO];
        containerView.cagingArea = CGRectMake(containerView.cagingArea.origin.x, containerView.cagingArea.origin.y, containerView.cagingArea.size.width * 2, containerView.cagingArea.size.height);
        [self.view sendSubviewToBack:containerView];
        [self.view sendSubviewToBack:self.referenceImageView];
    }
    
    [UIView animateWithDuration:1.0f animations:^{
        for (UIView *view in viewsToMove) {
            view.frame = CGRectMake(view.frame.origin.x + distance.x, view.frame.origin.y + distance.y, view.frame.size.width, view.frame.size.height);
        }
    } completion:^(BOOL finished) {
        if (containerView.subviews.count == (self.rows * self.coloumns)) {
            [self showSolvedAlert];
        }
    }];
}


#pragma mark - Shuffling


- (IBAction)shufflePieces
{
    NSMutableArray *pieces = [self.puzzlePieces mutableCopy];
    for (NSUInteger i = pieces.count; i > 1; i--) [pieces exchangeObjectAtIndex:i - 1 withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    
    for (UIImageView *imageView in pieces) {
        [self.view bringSubviewToFront:imageView.superview];
    }
    
    [self shufflePositions:0];
}


- (void)shufflePositions:(NSUInteger)count
{
    [UIView animateWithDuration:1.0f animations:^{
        for (UIImageView *imageView in self.puzzlePieces) {
            UIView *superview = imageView.superview;
            CGPoint max = CGPointMake(superview.cagingArea.size.width - (PuzzlePieceBaseSize * self.xRatio), superview.cagingArea.size.height - (PuzzlePieceBaseSize * self.yRatio));
            imageView.superview.frame = CGRectMake(arc4random_uniform((uint32_t)max.x), arc4random_uniform((uint32_t)max.y), imageView.superview.frame.size.width, imageView.superview.frame.size.width);
        }
    } completion:^(BOOL finished) {
        NSUInteger nextCount = count + 1;
        if (nextCount < shuffleCount) {
            [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(shufflePositionsWithTimer:) userInfo:[NSNumber numberWithUnsignedInteger:nextCount] repeats:NO];
        }
     }];
}


- (void)shufflePositionsWithTimer:(NSTimer *)timer {
    NSNumber *count = timer.userInfo;
    [self shufflePositions:count.unsignedIntegerValue];
}


#pragma mark - PuzzleSolved


- (void)showSolvedAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Puzzle solved!" message:@"Congratulations!\nYou solved the puzzle!" delegate:self cancelButtonTitle:@"Shuffle again" otherButtonTitles:nil];
    [alertView show];
}


#pragma mark - UIAlertViewDelegate


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    for (UIImageView *imageView in self.puzzlePieces) {
        [imageView removeFromSuperview];
    }
    [self displayPuzzle];
    [self shufflePieces];
}


@end
