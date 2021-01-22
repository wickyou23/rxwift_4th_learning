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
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    private let bag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>.init(value: [])
    private var imageCache = [Int]()
    
    // MARK: - View Controller life cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imgShare = self.images.share()
        imgShare.asObservable()
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                [weak imagePreview] (photos) in
                guard let preview = imagePreview else { return }
                preview.image = photos.collage(size: preview.frame.size)
            })
            .disposed(by: self.bag)
        
        imgShare.asObservable()
            .subscribe(onNext: {
                [weak self] photos in
                self?.updateUI(photos: photos)
            })
            .disposed(by: self.bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Actions and func -
    
    func updateUI(photos: [UIImage]) {
        self.buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        self.buttonClear.isEnabled = photos.count > 0
        self.itemAdd.isEnabled = photos.count < 6
        self.title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
        if photos.isEmpty {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    @IBAction func actionClear() {
        self.images.accept([])
        self.imageCache.removeAll()
    }
    
    @IBAction func actionSave() {
        guard let image = imagePreview.image else { return }
        
        PhotoWriter.save(image: image)
            .asSingle()
            .subscribe {
                [weak self] (photoID) in
                guard let self = self else { return }
                self.showMessage("Saved with id: \(photoID)")
                self.actionClear()
            } onError: {
                [weak self] (error) in
                self?.showMessage("Error", description: error.localizedDescription)
            }
            .disposed(by: self.bag)
    }
    
    @IBAction func actionAdd() {
        let photoVC = self.storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        let newPhotos = photoVC.selectPhotos.share()
        newPhotos
            .takeWhile({ [weak self] (_) -> Bool in
                guard let self = self else { return false }
                return self.images.value.count < 6
            })
            .filter({ $0.size.width > $0.size.height })
            .filter({ [weak self] (newImage) -> Bool in
                let len = newImage.pngData()?.count ?? 0
                guard let self = self,
                      !self.imageCache.contains(len) else { return false }
                self.imageCache.append(len)
                return true
            })
            .subscribe(onNext: {
                [weak self] (newImage) in
                guard let images = self?.images else { return }
                images.accept(images.value + [newImage])
            },
            onDisposed: {
                print("Completed photo selected")
            })
            .disposed(by: self.bag)
        
        newPhotos
            .ignoreElements()
            .subscribe(onCompleted: {
                [weak self] in
                self?.updateNavigationIcon()
            })
            .disposed(by: self.bag)
        
        self.navigationController?.pushViewController(photoVC, animated: true)
    }
    
    private func updateNavigationIcon() {
        let icon = self.imagePreview.image?.scaled(CGSize(width: 22, height: 22)).withRenderingMode(.alwaysOriginal)
        self.navigationItem.leftBarButtonItem = icon == nil ? nil : UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        self.showAlertMessage(title, description: description)
            .subscribe()
            .disposed(by: self.bag)
    }
}
