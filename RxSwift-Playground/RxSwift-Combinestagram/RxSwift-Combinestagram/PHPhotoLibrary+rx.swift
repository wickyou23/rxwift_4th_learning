//
//  PHPhotoLibrary+rx.swift
//  Combinestagram
//
//  Created by Alexander Spirichev on 21/08/2017.
//  Copyright © 2017 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        return Observable.create { (obs) -> Disposable in
            if self.authorizationStatus() == .authorized {
                obs.onNext(true)
                obs.onCompleted()
            }
            else {
                obs.onNext(false)
                self.requestAuthorization { (status) in
                    obs.onNext(status == .authorized)
                    obs.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
