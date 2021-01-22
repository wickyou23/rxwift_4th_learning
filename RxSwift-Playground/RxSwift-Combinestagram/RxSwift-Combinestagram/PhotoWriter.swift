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

import Foundation
import UIKit
import RxSwift
import Photos

class PhotoWriter: NSObject {
    static func save(image: UIImage) -> Observable<String> {
        //Case 1: Maybe using Single replace for Observable
        //Case 2: .asSingle() from Observable created
        return Observable<String>.create {
            (obs) -> Disposable in
            var savedId: String?
            PHPhotoLibrary.shared().performChanges {
                let rq = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedId = rq.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    if success, let id = savedId {
                        obs.onNext(id)
                        obs.onCompleted()
                    }
                    else {
                        obs.onError(error ?? NSError(domain: "Could not save photo", code: -1, userInfo: nil))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    static func challengeSave(image: UIImage) -> Single<String> {
        return Single<String>.create { (single) -> Disposable in
            var saveId: String?
            PHPhotoLibrary.shared().performChanges {
                let rq = PHAssetChangeRequest.creationRequestForAsset(from: image)
                saveId = rq.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    if success, let id = saveId {
                        single(.success(id))
                    }
                    else {
                        single(.error(error ?? NSError(domain: "Could not save photo", code: -1, userInfo: nil)))
                    }
                }
            }

            return Disposables.create()
        }
    }
}

