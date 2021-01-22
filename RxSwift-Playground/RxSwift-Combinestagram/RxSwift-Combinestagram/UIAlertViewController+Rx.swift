//
//  UIAlertViewController+Rx.swift
//  Combinestagram
//
//  Created by Apple on 12/1/20.
//  Copyright © 2020 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift

//MARK: Challenge 2: Add custom observable to present alert

extension UIViewController {
    func showAlertMessage(_ title: String, description: String? = nil) -> Completable {
        return Completable.create {
            [weak self] (com) -> Disposable in
            let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: {(_) in
                com(.completed)
            }))
            
            self?.present(alert, animated: true, completion: nil)
            
            //Dismiss the alert controller when the subscription is dismissed, so that you don't have any dangling alert
            return Disposables.create {
                [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
