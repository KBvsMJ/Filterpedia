//
//  MercurializeFilter.swift
//  Filterpedia
//
//  Created by Simon Gladman on 19/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import CoreImage
import SceneKit

class MercurializeFilter: CIFilter
{
    // MARK: Filter parameters
    
    var inputImage: CIImage?
    
    var inputEdgeThickness: CGFloat = 5
    
    var inputScale: CGFloat = 10

    // MARK: Shading image attributes

    var inputLightColor = CIColor(red: 1, green: 1, blue: 0.75)
    {
        didSet
        {
            sphereImage = nil
        }
    }
    
    var inputLightPosition = CIVector(x: 0, y: 1)
    {
        didSet
        {
            sphereImage = nil
        }
    }
    
    var inputAmbientLightColor = CIColor(red: 0.5, green: 0.5, blue: 0.75)
    {
        didSet
        {
            sphereImage = nil
        }
    }
    
    var inputShininess: CGFloat = 0.05
    {
        didSet
        {
            sphereImage = nil
        }
    }
    
    // MARK: SceneKit Objects
    
    let material = SCNMaterial()
    
    let sceneKitView = SCNView()
    
    let omniLight = OmniLight()
    
    let ambientLight = SCNLight()
    
    // MARK: Attributes
    
    override func setDefaults()
    {
        inputEdgeThickness = 5
        inputLightColor = CIColor(red: 1, green: 1, blue: 0.75)
        inputLightPosition = CIVector(x: 0, y: 1)
        inputAmbientLightColor = CIColor(red: 0.5, green: 0.5, blue: 0.75)
        inputShininess = 0.05
        inputScale = 10
    }
    
    override var attributes: [String : AnyObject]
    {
        return [
            kCIAttributeFilterDisplayName: "Mercurialize Filter",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputLightColor": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIColor",
                kCIAttributeDisplayName: "Light Color",
                kCIAttributeDefault: CIColor(red: 1, green: 1, blue: 0.75),
                kCIAttributeType: kCIAttributeTypeColor],
            
            "inputLightPosition": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Light Position",
                kCIAttributeDefault: CIVector(x: 0, y: 1),
                kCIAttributeDescription: "Vector defining normalised light position. (0, 0) is bottom left, (1, 1) is top right.",
                kCIAttributeType: kCIAttributeTypeColor],
            
            "inputAmbientLightColor": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIColor",
                kCIAttributeDisplayName: "Ambient Light Color",
                kCIAttributeDefault: CIColor(red: 0.5, green: 0.5, blue: 0.75),
                kCIAttributeType: kCIAttributeTypeColor],
            
            "inputShininess": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDisplayName: "Shininess",
                kCIAttributeDefault: 0.05,
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 0.5,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputEdgeThickness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDisplayName: "Edge Thickness",
                kCIAttributeDefault: 5,
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 20,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputScale": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDisplayName: "Scale",
                kCIAttributeDefault: 10,
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 20,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    // MARK: Initialisation
    
    override init()
    {
        super.init()
        
        setUpSceneKit()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Output Image
    
    private var sphereImage: CIImage?
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        if sphereImage == nil
        {
            material.shininess = inputShininess
            
            omniLight.color = inputLightColor
            omniLight.position.x = Float(-50 + (inputLightPosition.X * 100))
            omniLight.position.y = Float(-50 + (inputLightPosition.Y * 100))
            
            ambientLight.color = UIColor(CIColor: inputAmbientLightColor)
            
            sceneKitView.prepareObject(sceneKitView.scene!, shouldAbortBlock: {false})
            
            sphereImage = CIImage(image: sceneKitView.snapshot())
        }
        
        let edgeWork = CIFilter(name: "CIEdgeWork",
            withInputParameters: [kCIInputImageKey: inputImage,
            kCIInputRadiusKey: inputEdgeThickness])!
        
        let heightField = CIFilter(name: "CIHeightFieldFromMask",
                withInputParameters: [
                kCIInputRadiusKey: inputScale,
                kCIInputImageKey: edgeWork.outputImage!])!
        
        let shadedMaterial = CIFilter(name: "CIShadedMaterial",
                withInputParameters: [
                kCIInputScaleKey: inputScale,
                kCIInputImageKey: heightField.outputImage!,
                kCIInputShadingImageKey: sphereImage!])!
        
        return shadedMaterial.outputImage
    }
    
    // MARK: SceneKit set up
    
    func setUpSceneKit()
    {
        sceneKitView.frame = CGRect(x: 0, y: 0, width: 320, height: 320)
        
        sceneKitView.backgroundColor = UIColor.blackColor()
        
        let scene = SCNScene()
        
        sceneKitView.scene = scene
        
        let camera = SCNCamera()
        
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        
        let cameraNode = SCNNode()
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        
        scene.rootNode.addChildNode(cameraNode)
        
        // sphere...
        
        let sphere = SCNSphere(radius: 1)
        let sphereNode = SCNNode(geometry: sphere)
        
        sphereNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(sphereNode)
        
        // Lights
        
        ambientLight.type = SCNLightTypeAmbient
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        
        scene.rootNode.addChildNode(ambientLightNode)
        
        scene.rootNode.addChildNode(omniLight)
        
        // Material
        
        material.lightingModelName = SCNLightingModelPhong
        material.specular.contents = UIColor.whiteColor()
        material.diffuse.contents = UIColor.darkGrayColor()
        material.shininess = 0.15
        
        sphere.materials = [material]
    }
}

// MARK: OmniLight class - SceneKit node with Omni light

class OmniLight: SCNNode
{
    override init()
    {
        super.init()
        
        let omniLight = SCNLight()
        omniLight.type = SCNLightTypeOmni
        
        light = omniLight
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    var color: CIColor = CIColor(red: 0, green: 0, blue: 0)
    {
        didSet
        {
            light?.color = UIColor(CIColor: color)
        }
    }
}
