//
//  HandGestureRecognizerDelegate.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import Foundation

protocol HandGestureRecognizerDelegate: NSObjectProtocol {
    @MainActor
    func didDetect(for action: DriveAction)
}
