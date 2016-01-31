//
//  IncomingFileTransfer.swift
//  Ares
//
//  Created by Indragie on 1/31/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public protocol IncomingFileTransferDelegate: AnyObject {
    func incomingFileTransfer(transfer: IncomingFileTransfer, didStartReceivingFileWithName name: String, progress: NSProgress)
    func incomingFileTransfer(transfer: IncomingFileTransfer, didReceiveFileWithName name: String, URL: NSURL)
    func incomingFileTransfer(transfer: IncomingFileTransfer, didFailToReceiveFileWithName name: String, error: NSError)
}

@objc public final class IncomingFileTransfer: NSObject, MCSessionDelegate {
    let session: MCSession
    private let remotePeerID: MCPeerID
    
    public weak var delegate: IncomingFileTransferDelegate?
    
    init(localPeerID: MCPeerID, remotePeerID: MCPeerID) {
        self.session = MCSession(peer: localPeerID)
        self.remotePeerID = remotePeerID

        super.init()
        
        self.session.delegate = self
    }
    
    // MARK: MCSessionDelegate
    
    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        delegate?.incomingFileTransfer(self, didStartReceivingFileWithName: resourceName, progress: progress)
    }
    
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        if let error = error {
            delegate?.incomingFileTransfer(self, didFailToReceiveFileWithName: resourceName, error: error)
        } else {
            delegate?.incomingFileTransfer(self, didReceiveFileWithName: resourceName, URL: localURL)
        }
    }
    
    // Unused
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {}
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {}
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {}
}
