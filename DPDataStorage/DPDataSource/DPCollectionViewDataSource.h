//
//  DPCollectionViewDataSource.h
//  Commentator
//
//  Created by Dmitriy Petrusevich on 28/04/15.
//  Copyright (c) 2015 Dmitriy Petrusevich. All rights reserved.
//

#import "DPBaseDataSource.h"

@interface DPCollectionViewDataSource : DPBaseDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UIView *noDataView;
@property (nonatomic, copy, nullable) IBInspectable NSString *cellIdentifier; // Cell must conform <DPDataSourceCell>
@property (nonatomic) IBInspectable BOOL disableAnimations;

- (instancetype _Nonnull)initWithCollectionView:(UICollectionView * _Nullable)collectionView listController:(id<DataSourceContainerController> _Nullable)listController forwardDelegate:(id _Nullable)forwardDelegate cellIdentifier:(NSString * _Nullable)cellIdentifier;

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView * _Nullable)collectionView;
- (NSInteger)collectionView:(UICollectionView * _Nullable)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell * _Nonnull)collectionView:(UICollectionView * _Nullable)collectionView cellForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath;
@end
