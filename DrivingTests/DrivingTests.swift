//
//  DrivingTests.swift
//  DrivingTests
//
//  Created by Nathan Mak on 2024/5/22.
//

@testable import Driving
import Foundation
import RealityKit
import simd
import XCTest
import SwiftUI

class DrivingTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let angle = Angle(degrees: 30)
        print(sin(angle.radians))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    func decomposeTransform(matrix: simd_float4x4) -> (translation: SIMD3<Float>, rotation: simd_quatf, scale: SIMD3<Float>) {
        // Extract the translation
        let translation = SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)

        // Extract the scale factors
        let scaleX = length(SIMD3<Float>(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z))
        let scaleY = length(SIMD3<Float>(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z))
        let scaleZ = length(SIMD3<Float>(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z))
        let scale = SIMD3<Float>(scaleX, scaleY, scaleZ)

        // Remove the scale from the matrix
        var rotationMatrix = matrix
        rotationMatrix.columns.0 /= scaleX
        rotationMatrix.columns.1 /= scaleY
        rotationMatrix.columns.2 /= scaleZ

        // Extract the rotation quaternion
        let rotation = simd_quatf(rotationMatrix)

        return (translation, rotation, scale)
    }

    func getYYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let siny_cosp = 2 * (quat.real * quat.imag.y + quat.imag.z * quat.imag.x)
        let cosy_cosp = 1 - 2 * (quat.imag.y * quat.imag.y + quat.imag.z * quat.imag.z)

        // 计算 yaw 角（绕 y 轴的旋转角度）
        let yaw = atan2(siny_cosp, cosy_cosp)

        return yaw * (180 / .pi)
    }

    func getXYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let sinr_cosp = 2 * (quat.real * quat.imag.x + quat.imag.y * quat.imag.z)
        let cosr_cosp = 1 - 2 * (quat.imag.x * quat.imag.x + quat.imag.y * quat.imag.y)

        // 计算 yaw 角（绕 x 轴的旋转角度）
        let yaw = atan2(sinr_cosp, cosr_cosp)

        return yaw * (180 / .pi)
    }

    func getZYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let siny_cosp = 2 * (quat.real * quat.imag.z + quat.imag.x * quat.imag.y)
        let cosy_cosp = 1 - 2 * (quat.imag.z * quat.imag.z + quat.imag.x * quat.imag.x)

        // 计算 yaw 角（绕 z 轴的旋转角度）
        let yaw = atan2(siny_cosp, cosy_cosp)

        return yaw * (180 / .pi)
    }
    
    private func isLeft(rotation: simd_quatf) -> Bool {
        let xAxisPositive = simd_float3(1, 0, 0)
        let rotatedVector = rotation.act(xAxisPositive)
        print(rotatedVector)
        let threshold: Float = 0.0001
        return simd_length(rotatedVector - simd_float3(-1, 0, 0)) < threshold
    }
}
