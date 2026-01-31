//
//  ARQiblaARView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import SwiftUI
import ARKit
import SceneKit
import CoreLocation

/// ARKit-based Qibla direction view using camera passthrough
struct ARQiblaARView: UIViewRepresentable {
    @ObservedObject var compass: CompassManager
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading // Aligns with True North
        arView.session.run(configuration)
        
        // Add Qibla indicator node
        let qiblaNode = createQiblaIndicator()
        qiblaNode.name = "qiblaIndicator"
        arView.scene.rootNode.addChildNode(qiblaNode)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update Qibla indicator position based on direction
        guard let qiblaNode = uiView.scene.rootNode.childNode(withName: "qiblaIndicator", recursively: false) else { return }
        
        // Convert Qibla direction to radians (measured from North, clockwise)
        let qiblaRadians = compass.qiblaDirection * .pi / 180.0
        
        // Position the indicator 3 meters away in the Qibla direction
        let distance: Float = 3.0
        let x = Float(sin(qiblaRadians)) * distance
        let z = -Float(cos(qiblaRadians)) * distance // Negative Z is forward in SceneKit
        
        // Smoothly animate position update
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        qiblaNode.position = SCNVector3(x, 0, z)
        
        // Rotate indicator to face the camera
        qiblaNode.eulerAngles.y = Float(qiblaRadians)
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    /// Creates a 3D Qibla indicator (golden arrow pointing up with Kaaba-like cube)
    private func createQiblaIndicator() -> SCNNode {
        let containerNode = SCNNode()
        
        // Main Kaaba-like cube
        let cubeGeometry = SCNBox(width: 0.15, height: 0.15, length: 0.15, chamferRadius: 0.01)
        let cubeMaterial = SCNMaterial()
        cubeMaterial.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // Dark black
        cubeMaterial.metalness.contents = 0.8
        cubeMaterial.roughness.contents = 0.2
        cubeGeometry.materials = [cubeMaterial]
        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.position = SCNVector3(0, 0, 0)
        
        // Gold band around the cube (like Kaaba's gold band)
        let bandGeometry = SCNBox(width: 0.16, height: 0.02, length: 0.16, chamferRadius: 0.005)
        let goldMaterial = SCNMaterial()
        goldMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        goldMaterial.metalness.contents = 1.0
        goldMaterial.roughness.contents = 0.3
        bandGeometry.materials = [goldMaterial]
        let bandNode = SCNNode(geometry: bandGeometry)
        bandNode.position = SCNVector3(0, 0.05, 0) // Upper third position
        
        // Upward pointing arrow/cone above cube
        let coneGeometry = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.1)
        coneGeometry.materials = [goldMaterial]
        let coneNode = SCNNode(geometry: coneGeometry)
        coneNode.position = SCNVector3(0, 0.15, 0)
        
        // Add glow effect
        let glowNode = SCNNode()
        let sphereGeometry = SCNSphere(radius: 0.2)
        let glowMaterial = SCNMaterial()
        glowMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.15)
        glowMaterial.isDoubleSided = true
        sphereGeometry.materials = [glowMaterial]
        glowNode.geometry = sphereGeometry
        glowNode.position = SCNVector3(0, 0, 0)
        
        // Add floating animation
        let floatUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1.0)
        let floatDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 1.0)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        let floatSequence = SCNAction.sequence([floatUp, floatDown])
        let floatForever = SCNAction.repeatForever(floatSequence)
        
        // Rotation animation for glow
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4.0)
        let rotateForever = SCNAction.repeatForever(rotate)
        
        containerNode.addChildNode(cubeNode)
        containerNode.addChildNode(bandNode)
        containerNode.addChildNode(coneNode)
        containerNode.addChildNode(glowNode)
        
        containerNode.runAction(floatForever)
        glowNode.runAction(rotateForever)
        
        return containerNode
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
        }
    }
}

/// Check if device supports ARKit
func isARKitSupported() -> Bool {
    return ARWorldTrackingConfiguration.isSupported
}
