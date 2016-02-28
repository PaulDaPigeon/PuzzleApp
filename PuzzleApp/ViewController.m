//
//  ViewController.m
//  PuzzleApp
//
//  Created by Pal Hebok on 28/02/16.
//  Copyright © 2016 HebokPal. All rights reserved.
//


#import "ViewController.h"
#import <UIView+draggable.h>


@interface ViewController ()


@property (nonatomic, strong) NSMutableArray *puzzlePieceRows;


@end


static const CGFloat PuzzlePieceHeight = 80.0f;
static const CGFloat PuzzlePieceWidth = 80.0f;
static const CGFloat PuzzlePieceSnappingTolerance = 10.0f;


@implementation ViewController


#pragma mark - Lifecycle


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.puzzlePieceRows = [NSMutableArray new];
    
    for (NSInteger row = 0; row < 3; row++) {
        [self.puzzlePieceRows addObject:[NSMutableArray new]];
        for (NSInteger column = 0; column < 3; column++) {
            CGFloat interimSpacing = 20.0f;
            UIView *puzzlePiece = [[UIView alloc] initWithFrame:CGRectMake((70 + (row * (PuzzlePieceWidth + interimSpacing))), (100 + (column * (PuzzlePieceHeight + interimSpacing))), PuzzlePieceWidth, PuzzlePieceHeight)];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, PuzzlePieceWidth, PuzzlePieceHeight)];
            label.text = [NSString stringWithFormat:@"%li", ((3 * column) + row + 1)];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:28];
            label.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            puzzlePiece.backgroundColor = [UIColor greenColor];
            puzzlePiece.tag = row;
            [puzzlePiece enableDragging];
            [puzzlePiece addSubview:label];
            puzzlePiece.cagingArea = self.view.frame;
            __weak UIView *weakPuzzlePiece = puzzlePiece;
            puzzlePiece.draggingEndedBlock = ^{
                [self draggingEnded:weakPuzzlePiece];
            };
            
            puzzlePiece.draggingStartedBlock = ^{
                [self draggingStarted];
            };
            
            [((NSMutableArray *)self.puzzlePieceRows[row]) addObject:puzzlePiece];
            
            [self.view addSubview:puzzlePiece];
        }
    }
}


#pragma mark - Attaching


- (void)draggingStarted
{
    [UIView animateWithDuration:0.5f animations:^{
        for (NSArray *array in self.puzzlePieceRows) {
            for (UIView *view in array) {
                view.backgroundColor = [UIColor greenColor];
            }
        }
    }];
}


- (void)draggingEnded:(UIView *)view;
{
    NSMutableArray *connectedPieces = [NSMutableArray new];
    if (view.superview == self.view) {
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
    NSInteger row = [self.puzzlePieceRows[puzzlePiece.tag] indexOfObject:puzzlePiece];
    
    CGPoint puzzlePieceInView = [self.view convertPoint:puzzlePiece.frame.origin fromView:puzzlePiece.superview];
    
    if (puzzlePiece.tag != 0) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag - 1] objectAtIndex:row];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:puzzlePiece.superview];
            if (ABS(puzzlePieceInView.x - (otherPieceInView.x + PuzzlePieceWidth)) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - (otherPieceInView.x + PuzzlePieceWidth), puzzlePieceInView.y - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance];
                }
            }
        }
    }
    
    if (puzzlePiece.tag != (self.puzzlePieceRows.count -1)) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag + 1] objectAtIndex:row];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:puzzlePiece.superview];
            if (ABS((puzzlePieceInView.x + PuzzlePieceWidth) - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake((puzzlePieceInView.x + PuzzlePieceWidth) - otherPieceInView.x, puzzlePieceInView.y - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance];

                }
            }
        }
    }
    
    if (row != 0) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag] objectAtIndex:row - 1];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:puzzlePiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS(puzzlePieceInView.y - (otherPieceInView.y + PuzzlePieceHeight)) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, puzzlePieceInView.y - (otherPieceInView.y + PuzzlePieceHeight));
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance];
                }
            }
        }
    }
    
    if (row != ((NSMutableArray *)self.puzzlePieceRows[puzzlePiece.tag]).count - 1) {
        UIView *otherPiece = [self.puzzlePieceRows[puzzlePiece.tag] objectAtIndex:row + 1];
        if ([connectedPieces indexOfObject:otherPiece] == NSNotFound) {
            CGPoint otherPieceInView = [self.view convertPoint:otherPiece.frame.origin fromView:puzzlePiece.superview];
            if (ABS(puzzlePieceInView.x - otherPieceInView.x) <= PuzzlePieceSnappingTolerance) {
                if (ABS((puzzlePieceInView.y + PuzzlePieceHeight) - otherPieceInView.y) <= PuzzlePieceSnappingTolerance) {
                    if (otherPiece.superview != self.view) {
                        for (UIView *view in otherPiece.superview.subviews) {
                            [connectedPieces addObject:view];
                        }
                    }
                    else {
                        [connectedPieces addObject:otherPiece];
                    }
                    CGPoint distance = CGPointMake(puzzlePieceInView.x - otherPieceInView.x, (puzzlePieceInView.y + PuzzlePieceHeight) - otherPieceInView.y);
                    [self attachPuzzlePiece:puzzlePiece toPuzzlePiece:otherPiece withDistance:distance];
                }
            }
        }
    }
}


- (void)attachPuzzlePiece:(UIView *)pieceA toPuzzlePiece:(UIView *)pieceB withDistance:(CGPoint)distance
{
    [UIView animateWithDuration:0.5f animations:^{
        pieceB.backgroundColor = [UIColor redColor];
    }];
//    UIView *containerView;
//    if (pieceA.superview != self.view) {
//        containerView = pieceA.superview;
//    }
//    else {
//        [pieceA setDraggable:NO];
//        containerView = [[UIView alloc] initWithFrame:pieceA.frame];
//        [containerView enableDragging];
//        containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
//    }
//    
//    UIView *viewToMove;
//    if (pieceB.superview != self.view) {
//        viewToMove = pieceB.superview;
//        
//    }
//    else {
//        [pieceB setDraggable:NO];
//        viewToMove = pieceB;
//    }
//    
//    [UIView animateWithDuration:1.0f animations:^{
//    }];
}


@end
