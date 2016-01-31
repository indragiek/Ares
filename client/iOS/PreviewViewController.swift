//
//  PreviewViewController.swift
//  Ares
//
//  Created by Indragie on 1/31/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import UIKit
import QuickLook

class PreviewViewController: QLPreviewController, QLPreviewControllerDataSource {
    @objc private class PreviewItem: NSObject, QLPreviewItem {
        @objc let previewItemTitle: String?
        @objc let previewItemURL: NSURL
        
        init(previewItemTitle: String?, previewItemURL: NSURL) {
            self.previewItemTitle = previewItemTitle
            self.previewItemURL = previewItemURL
        }
    }
    
    private let previewItem: PreviewItem
    
    init(fileName: String, URL: NSURL) {
        previewItem = PreviewItem(previewItemTitle: fileName, previewItemURL: URL)
        super.init(nibName: nil, bundle: nil)
        dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: QLPreviewControllerDataSource
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        return previewItem
    }
}
