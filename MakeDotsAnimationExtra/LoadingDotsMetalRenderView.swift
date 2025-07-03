//
//  MetalRenderView.swift
//  ShaderToyyToSwiftUI
//
//  Created by javi www on 6/4/23.
//

import SwiftUI
import MetalKit
import simd

enum LoadingAnimationType {
    case leftToRight
    case wave
}

struct LoadingDotsMetalRenderView: UIViewRepresentable {
    
    let loadingAnim: LoadingAnimationType
    
    @Binding var leftToRightT: Float
    @Binding var gridSize: Float
    @Binding var dotSize: Float
    @Binding var borderStep: Float
    @Binding var animatedionSpeedLTR: Float
    @Binding var loopAnim: Bool
    @Binding var minDotSize: Float
    @Binding var grad: Float

//    @State var lastLoop = false
    
    func makeCoordinator() -> Renderer {
        Renderer(self, loadingAnim)
    }
    
    func makeUIView(context: Context) -> MTKView  {
        
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.backgroundColor = .clear
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.backgroundColor = UIColor.clear
        uiView.isOpaque = false
        if(context.coordinator.isLoop != loopAnim) {
            context.coordinator.currentTime = 0
            context.coordinator.lastRenderTime = nil
            print("Update uiview")
        }
        context.coordinator.isLoop = loopAnim
    }
    
}

struct MetalRenderView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Vertex {
    let position: vector_float2
    let color: vector_float4
}

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: LoadingDotsMetalRenderView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let vertexBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
//    let fragmentUniformsBuffer: MTLBuffer
    
    var lastRenderTime: CFTimeInterval? = nil
    // This is the current time in our app, starting at 0, in units of seconds
    var currentTime: Double = 0
    
    var isLoop: Bool = false

    init(_ parent: LoadingDotsMetalRenderView, _ anim: LoadingAnimationType) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShaderLeftToRigt")
//        if anim == .wave {
//            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShaderWave")
//        }
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print(error)
            fatalError()
        }
        let vertices = [
            Vertex(position: [-1, -1], color: [1, 0, 0, 1]),
            Vertex(position: [1, -1], color: [0, 1, 0, 1]),
            Vertex(position: [1, 1], color: [0, 0, 1, 1]),
            Vertex(position: [1, 1], color: [0, 0, 1, 1]),
            Vertex(position: [-1, 1], color: [0, 0, 1, 1]),
            Vertex(position: [-1, -1], color: [0, 0, 1, 1])
        ]
        self.vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        
//        var initialFragmentUniforms = FragmentUniforms(iTime: 0.0)
//        fragmentUniformsBuffer = metalDevice.makeBuffer(bytes: &initialFragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])!

        super.init()
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func update(dt: CFTimeInterval) {
        currentTime += dt
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let systemTime = CACurrentMediaTime()
        let timeDifference = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        // Save this system time
        lastRenderTime = systemTime

        // Update state
        update(dt: timeDifference)

        let commandBuffer = metalCommandQueue.makeCommandBuffer()
        
        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor?.colorAttachments[0].loadAction = .clear
        renderPassDescriptor?.colorAttachments[0].storeAction = .store
        guard let renderPassDescriptor else {
            return
        }
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var timeFloat = Float(currentTime)
        var renderSize = SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        var leftToRightT = parent.leftToRightT
        var gridSize = parent.gridSize
        var dotSize = parent.dotSize
        var borderStep = parent.borderStep
        var speedTime = parent.animatedionSpeedLTR
        var loopANim = parent.loopAnim
        var minDotSize = parent.minDotSize
        var grad = parent.grad
//        print("Time diff \(currentTime) renderSize \(renderSize) leftToRightT \(leftToRightT)")
        renderEncoder?.setFragmentBytes(&timeFloat, length: MemoryLayout.size(ofValue: timeFloat), index: 0)
        renderEncoder?.setFragmentBytes(&renderSize, length: MemoryLayout.size(ofValue: renderSize), index: 1)
        renderEncoder?.setFragmentBytes(&leftToRightT, length: MemoryLayout.size(ofValue: leftToRightT), index: 2)
        renderEncoder?.setFragmentBytes(&gridSize, length: MemoryLayout.size(ofValue: leftToRightT), index: 3)
        renderEncoder?.setFragmentBytes(&dotSize, length: MemoryLayout.size(ofValue: leftToRightT), index: 4)
        renderEncoder?.setFragmentBytes(&borderStep, length: MemoryLayout.size(ofValue: borderStep), index: 5)
        renderEncoder?.setFragmentBytes(&speedTime, length: MemoryLayout.size(ofValue: speedTime), index: 6)
        renderEncoder?.setFragmentBytes(&loopANim, length: MemoryLayout.size(ofValue: loopANim), index: 7)
        renderEncoder?.setFragmentBytes(&minDotSize, length: MemoryLayout.size(ofValue: minDotSize), index: 8)
        renderEncoder?.setFragmentBytes(&grad, length: MemoryLayout.size(ofValue: minDotSize), index: 9)


        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 3, vertexCount: 6)

        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
