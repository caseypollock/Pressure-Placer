//
//  ViewController.swift
//  Pressure Placer
//
//  Created by Casey on 7/29/17.
//  Copyright © 2017 Near Future Marketing. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var consoleLabel: UILabel!
    @IBOutlet weak var planeDetectButton: UIButton!
    
    let scene = SCNScene()
    let configuration = ARWorldTrackingConfiguration()
    var uiSoundEngine = AVAudioPlayer()
    var hitPosition : SCNVector3? //The 3D coordinates of your tap.
    var hitTransform : SCNMatrix4?
    var rootPlanePlaced = false
    var rootPlaneHandicap = false
    var finalTouchPressure = 0.0
    
    let arrayOfTrees = ["LP Tree Small.scn","LP Tree Medium.scn","LP Tree Large.scn","LP Tree Italian Cypress.scn"]

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.session.run(configuration)
        // Do any additional setup a)fter loading the view, typically from a nib.
        configuration.planeDetection = .horizontal
        sceneView.autoenablesDefaultLighting = true
    }
    
    @objc func uiSoundFXEngine(playSound: String) {
        do { if let selectedSound = Bundle.main.url(forResource: playSound, withExtension: "mp3") {
            print(selectedSound.absoluteURL)
            uiSoundEngine = try AVAudioPlayer(contentsOf: selectedSound)
            uiSoundEngine.prepareToPlay()
            uiSoundEngine.play()
            }} catch let error as NSError { print(error.description) }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
         */
        planeNode.eulerAngles.x = -.pi / 2
        //        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        planeNode.opacity = 0.0
        node.addChildNode(planeNode)
        if rootPlanePlaced != true {
            rootPlanePlaced = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var results : [ARHitTestResult]
        if planeDetectButton.currentTitle == "Plane Detection Off" {
            results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        } else {
            results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlane])
        }
        
        guard let hitFeature = results.last else {
            if planeDetectButton.currentTitle == "Plane Detection Off" {
                consoleLabel.text = "No feature points detected there.."
            }
            return
        }
         hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let tempHitPosition = SCNVector3Make(hitTransform!.m41,
                                         hitTransform!.m42,
                                         hitTransform!.m43)
        hitPosition = tempHitPosition
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkTouchPressure), userInfo: nil, repeats: false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                //print("LOOKS LIKE 3D TOUCH IS WORKING 🔥")
                let touchForce = touch.force/touch.maximumPossibleForce
//                print("\(touchForce)% of Maximum")
                finalTouchPressure = Double(touchForce)
            }}
    }
    
    @objc func updateDetectedSurfaces() {
        //Checks if the rootPlanePlane is placed.
        if rootPlanePlaced == true && consoleLabel.text != "Surface detected!" {
            consoleLabel.text = "Surface detected!"
        } else if rootPlanePlaced == false {
            switch consoleLabel.text! {
            case "No surfaces detected.": consoleLabel.text = "No surfaces detected.."
            case "No surfaces detected..": consoleLabel.text = "No surfaces detected..."
            default: consoleLabel.text = "No surfaces detected."
        }
            let consoleRefreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateDetectedSurfaces), userInfo: nil, repeats: false)
        }
    }
    
    @objc func checkTouchPressure() {
        var newNode : SCNNode!
        let tree = drawRandomTree()
        //Creates a copy of the rootNode from the randomly selected tree's SCNScene.
        newNode = tree.rootNode.clone()
        //Scales the tree before it is placed in the scene, based on the 3D Touch pressure recorded.
        if finalTouchPressure == 1.0 {
            consoleLabel.text = "Hard tap!"
            uiSoundFXEngine(playSound: "UISound - Heavy 3D Touch")
            newNode.scale = SCNVector3Make(0.37, 0.37, 0.37)
        } else if finalTouchPressure >= 0.42 {
            consoleLabel.text = "Medium tap!"
            uiSoundFXEngine(playSound: "UISound - Medium 3D Touch")
            newNode.scale = SCNVector3Make(0.25, 0.25, 0.25)
        } else {
            consoleLabel.text = "Soft tap!"
            uiSoundFXEngine(playSound: "UISound - Soft 3D Touch")
            newNode.scale = SCNVector3Make(0.15, 0.15, 0.15)
        }
        //Positions and adds our new tree to the scene.
        if hitPosition != nil {
            newNode.position = hitPosition!
            sceneView.scene.rootNode.addChildNode(newNode)
        }
        //Resets the console after 2 seconds.
         let consoleRefreshTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(resetConsoleText), userInfo: nil, repeats: false)
    }

    func drawRandomTree() -> SCNScene {
        //Randomly selects a string from the arrayOfTrees.
        let randomlySelectedTree = arc4random() % UInt32(arrayOfTrees.count)
        let selectedTreeName = arrayOfTrees[Int(randomlySelectedTree)]
        let selectedModel = SCNScene(named: "art.scnassets/\(selectedTreeName)")
        return selectedModel!
    }
    
    
    @IBAction func planeDetectionToggled(_ sender: Any) {
        if planeDetectButton.currentTitle == "Plane Detection On" {
            planeDetectButton.setTitle("Plane Detection Off", for: .normal)
            rootPlaneHandicap = true
            rootPlanePlaced = true
        } else if planeDetectButton.currentTitle == "Plane Detection Off" {
            planeDetectButton.setTitle("Plane Detection On", for: .normal)
            rootPlaneHandicap = false
            rootPlanePlaced = false
            updateDetectedSurfaces()
        }
    }
    
    @IBAction func resetScenePressed(_ sender: Any) {
        //Erases the scene and world origin.
        self.rootPlanePlaced = false
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (newChildNode, _) in
            newChildNode.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        if planeDetectButton.currentTitle == "Plane Detection On" {
            planeDetectionToggled(self)
        }
        uiSoundFXEngine(playSound: "UISound - Reset Scene")
        viewDidLoad()
    }
    
    @objc func resetConsoleText() {
        consoleLabel.text = ""
    }
    

} //End of page

