//
//  VerticalLineScanView.swift
//  MakeDotsAnimationExtra
//
//  Created by javi www on 7/3/25.
//

import SwiftUI
import MetalKit

struct FragmentUniformsBasic {
    let iTime: Float
    let renderSize: vector_float2
    
}




struct VerticalLineScanView: UIViewRepresentable {
    
    func makeCoordinator() -> VerticalRenderer {
        VerticalRenderer(self)
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
        mtkView.isOpaque = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {

    }
    

}

class VerticalRenderer: NSObject, MTKViewDelegate {
    
    var parent: VerticalLineScanView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let vertexBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
//    let fragmentUniformsBuffer: MTLBuffer
    
    var lastRenderTime: CFTimeInterval? = nil
    // This is the current time in our app, starting at 0, in units of seconds
    var currentTime: Double = 0
    
    var isLoop: Bool = false

    init(_ parent: VerticalLineScanView) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShaderVerticalLine")
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
        
        let timeFloat = Float(currentTime)
        let renderSize = SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        
        var uniforms = FragmentUniformsBasic(iTime: timeFloat, renderSize: renderSize)
        renderEncoder?.setFragmentBytes(&uniforms, length: MemoryLayout.size(ofValue: uniforms), index: 0)

        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 3, vertexCount: 6)

        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}


#Preview {
    VerticalLineScanView()
        .background {
            Color.black
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
}
