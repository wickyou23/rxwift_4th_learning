//
//  DownloadView.swift
//  RxSwift-OutPlanet
//
//  Created by Apple on 1/6/21.
//

import Foundation
import UIKit

class DownloadView: UIView {
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    
    static var csView: DownloadView {
        let nib = UINib(nibName: "DownloadView", bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! DownloadView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
