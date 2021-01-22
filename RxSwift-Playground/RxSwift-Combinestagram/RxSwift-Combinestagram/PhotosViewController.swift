/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Photos
import RxSwift

class PhotosViewController: UICollectionViewController {
    
    // MARK: public properties
    
    let bag = DisposeBag()
    var selectPhotos: Observable<UIImage> {
        return self.selectedPhotosSubject.asObservable()
    }
    
    
    // MARK: private properties
    private let selectedPhotosSubject = PublishSubject<UIImage>()
    private lazy var photos = PhotosViewController.loadPhotos()
    private lazy var imageManager = PHCachingImageManager()
    
    private lazy var thumbnailSize: CGSize = {
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let auth = PHPhotoLibrary.authorized.share()
        auth
            .skipWhile({ $0 == false })
            .subscribe (onNext: { (_) in
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.collectionView.reloadData()
                }
            })
            .disposed(by: self.bag)
        
        auth
            .distinctUntilChanged()
            .takeLast(1)
            .filter({ $0 == false })
            .subscribe (onNext: { [weak self] (_) in
                guard let self = self else { return }
                DispatchQueue.main.async(execute: self.errorMessage)
            })
            .disposed(by: self.bag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.selectedPhotosSubject.onCompleted()
    }
    
    // MARK: - Actions -
    
    private func errorMessage() {
        self.showAlertMessage("No access to Camera Roll", description: "You can grant access to Combinestagram from the Setting app")
            .asObservable()
            .take(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onDisposed: {
                [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.bag)
    }
    
    // MARK: UICollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = photos.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset,
                                  targetSize: thumbnailSize,
                                  contentMode: .aspectFill,
                                  options: nil,
                                  resultHandler: { image, _ in
                                    if cell.representedAssetIdentifier == asset.localIdentifier {
                                        cell.imageView.image = image
                                    }
                                  })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos.object(at: indexPath.item)
        self.imageManager.requestImage(for: asset,
                                       targetSize: thumbnailSize,
                                       contentMode: .aspectFill,
                                       options: nil,
                                       resultHandler: { [weak self] image, info in
                                        if let isThumbnail = info?[PHImageResultIsDegradedKey as NSString] as? Bool,
                                           !isThumbnail,
                                           let img = image {
                                            self?.selectedPhotosSubject.onNext(img)
                                        }
                                       })
    }
}
