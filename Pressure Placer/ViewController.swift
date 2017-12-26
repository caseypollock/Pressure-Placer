//
//  ViewController.swift
//  Pressure Placer
//
//  Created by Casey on 7/29/17.
//  Copyright © 2017 Near Future Marketing. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate {
    
    var currentTouchPressure = 0.0
    var finalTouchPressure = 0.0
//    var timerStarted = false
    var soundEffectPlayer: AVAudioPlayer!
    var treeNode : SCNNode?
    var pressureSize = "Soft Pressure"
    var hitTransform : SCNMatrix4?
    var hitPosition : SCNVector3?
    var treeScale : SCNMatrix4?
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/LowPolyTree.dae")!
        treeNode = scene.rootNode.childNode(withName: "lowPolyTreeNode", recursively: true)
        treeNode?.position = SCNVector3Make(0, 0, -1)

        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.whatsTheTouchPressure), userInfo: nil, repeats: false)
        
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitFeature = results.last else { return }
         hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let tempHitPosition = SCNVector3Make(hitTransform!.m41,
                                         hitTransform!.m42,
                                         hitTransform!.m43)
        hitPosition = tempHitPosition
//        treeNode?.position = hitPosition "Teleports the Original"

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                //                    print("LOOKS LIKE 3D TOUCH IS WORKING 🔥")
                let touchForce = touch.force/touch.maximumPossibleForce
//                print("\(touchForce)% of Maximum")
                currentTouchPressure = Double(touchForce)
            }}
    }
    
    @objc func whatsTheTouchPressure() {
        finalTouchPressure = currentTouchPressure
        let treeClone = treeNode!.clone()
        
        if finalTouchPressure == 1.0 {
//            print("Hard Pressure")
            treeClone.scale = SCNVector3Make(0.1, 0.1, 0.1)
        } else if finalTouchPressure >= 0.42 {
//            print("Medium Pressure")
            treeClone.scale = SCNVector3Make(0.05, 0.05, 0.05)
        } else {
//            print("Soft Pressure")
            treeClone.scale = SCNVector3Make(0.01, 0.01, 0.01)
        }
        if hitPosition != nil {
            treeClone.position = hitPosition!
            sceneView.scene.rootNode.addChildNode(treeClone)
        }
    }
    

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

