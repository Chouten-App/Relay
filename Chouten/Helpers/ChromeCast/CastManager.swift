//
//  DeviceDiscovery.swift
//  Chouten
//
//  Created by Cel on 04/11/2024.
//

import Foundation
import GoogleCast

class CastManager: NSObject, GCKSessionManagerListener, GCKDiscoveryManagerListener {
    private var sessionManager: GCKSessionManager {
        return GCKCastContext.sharedInstance().sessionManager
    }
    
    private var discoveryManager: GCKDiscoveryManager {
        return GCKCastContext.sharedInstance().discoveryManager
    }

    override init() {
        super.init()
        discoveryManager.add(self)
        discoveryManager.startDiscovery()
    }

    func discoveryManager(_ discoveryManager: GCKDiscoveryManager, didAdd device: GCKDevice) {
        print("Device found: \(device.friendlyName)")
    }

    func discoveryManager(_ discoveryManager: GCKDiscoveryManager, didRemove device: GCKDevice) {
        print("Device removed: \(device.friendlyName)")
    }

    func discoveryManagerDidUpdateDevices(_ discoveryManager: GCKDiscoveryManager) {
        let devicesCount = discoveryManager.deviceCount
        
        print("Devices Count: \(devicesCount)")
        
        for deviceIndex in 0..<devicesCount {
            print("Device: \(discoveryManager.device(at: deviceIndex))")
        }
    }

    func stopDiscovery() {
        discoveryManager.stopDiscovery()
        discoveryManager.remove(self)
    }
}
