//
//  OutgoingFileTransfer.swift
//  Ares
//
//  Created by Indragie on 1/31/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public protocol OutgoingFileTransferDelegate: AnyObject {
    func outgoingFileTransfer(transfer: OutgoingFileTransfer, didStartWithProgress progress: NSProgress)
    func outgoingFileTransferDidComplete(transfer: OutgoingFileTransfer)
    func outgoingFileTransfer(transfer: OutgoingFileTransfer, didFailWithError error: NSError)
}

@objc public final class OutgoingFileTransfer: NSObject, MCSessionDelegate {
    public let context: FileTransferContext
    let session: MCSession
    private let remotePeerID: MCPeerID
    
    public weak var delegate: OutgoingFileTransferDelegate?
    
    init(context: FileTransferContext, localPeerID: MCPeerID, remotePeerID: MCPeerID) {
        self.context = context
        self.session = MCSession(peer: localPeerID)
        self.remotePeerID = remotePeerID
        
        super.init()
        
        self.session.delegate = self
    }
    
    // MARK: MCSessionDelegate
    
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        guard peerID == remotePeerID else { return }
        guard state == .Connected else { return }
        
        let URL = NSURL(fileURLWithPath: context.filePath)
        let name = (context.filePath as NSString).lastPathComponent
        let progress = session.sendResourceAtURL(URL, withName: name, toPeer: peerID) { error in
            if let error = error {
                self.delegate?.outgoingFileTransfer(self, didFailWithError: error)
            } else {
                self.delegate?.outgoingFileTransferDidComplete(self)
            }
            session.disconnect()
        }
        if let progress = progress {
            self.delegate?.outgoingFileTransfer(self, didStartWithProgress: progress)
        }
    }
    
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        guard peerID == remotePeerID else { return }
        certificateHandler(true)
    }
    
    // Unused
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {}
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
}
