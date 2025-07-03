//
//  WaveLoopAnimationView.swift
//  MakeDotsAnimationExtra
//
//  Created by javi www on 7/3/25.
//

import SwiftUI
import MetalKit

struct WaveLoopView: View {
    
    @State private var gridSize: Float = 13.0
    @State private var animSpeed: Float = 1.0
    @State private var minRad: Float = 0.08
    @State private var maxRad: Float = 0.15
    @State private var yWaveAmpl: Float = -0.52
    @State private var yWaveFreq: Float = 0.5

    @State private var showSliders: Bool = false

    var body: some View {
        WaveLoopAnimationView(gridSize: $gridSize, animSpeed: $animSpeed, minRad: $minRad, maxRad: $maxRad, yWaveAmpl: $yWaveAmpl, yWaveFreq: $yWaveFreq)
            .overlay {
                VStack {
                    SliderLabel(value: $gridSize, in: 1...46.0, label: "grid size \(String(format:"%.2f", gridSize))")
                    SliderLabel(value: $animSpeed, in: 0.1...14.0, label: "anim speed \(String(format:"%.2f", animSpeed))")
                    SliderLabel(value: $minRad, in: 0.0...0.2, label: "min rad \(String(format:"%.2f", minRad))")
                    SliderLabel(value: $maxRad, in: 0.05...0.3, label: "max rad \(String(format:"%.2f", maxRad))")
                    SliderLabel(value: $yWaveAmpl, in: -1.4...1.4, label: "y ampl \(String(format:"%.2f", yWaveAmpl))")
                    SliderLabel(value: $yWaveFreq, in: -10.4...11.4, label: "y freq \(String(format:"%.2f", yWaveFreq))")
                }
                .padding(28)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .foregroundStyle(.ultraThinMaterial)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 16)
                .padding(.bottom, 84)
                .opacity(showSliders ? 1 : 0)

            }
            .contentShape(.rect)
            .onTapGesture {
                showSliders.toggle()
            }

    }
}

struct FragmentUniforms {
    let iTime: Float
    let renderSize: vector_float2
    var gridSize: Float
    var animSpeed: Float
    var minRad: Float;
    var maxRad: Float;
}


struct FragmentFreq {
    var yWaveAmpl: Float;
    var yFreqVal: Float;
};

struct WaveLoopAnimationView: UIViewRepresentable {
    
    @Binding var gridSize: Float
    @Binding var animSpeed: Float
    @Binding var minRad: Float
    @Binding var maxRad: Float
    @Binding var yWaveAmpl: Float
    @Binding var yWaveFreq: Float

    func makeCoordinator() -> WaveLoopRenderer {
        WaveLoopRenderer(self)
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
        context.coordinator.gridSize = gridSize
        context.coordinator.animSpeed = animSpeed
        context.coordinator.minRad = minRad
        context.coordinator.maxRad = maxRad
        context.coordinator.yWaveAmpl = yWaveAmpl;
        context.coordinator.yWaveFreq = yWaveFreq
    }

}

class WaveLoopRenderer: NSObject, MTKViewDelegate {
    
    var parent: WaveLoopAnimationView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let vertexBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
//    let fragmentUniformsBuffer: MTLBuffer
    
    var lastRenderTime: CFTimeInterval? = nil
    // This is the current time in our app, starting at 0, in units of seconds
    var currentTime: Double = 0
    
    var isLoop: Bool = false
    
    var gridSize: Float = 12
    var animSpeed: Float = 1
    var minRad: Float = 0.01
    var maxRad: Float = 0.2
    var yWaveAmpl: Float = 2.0;
    var yWaveFreq: Float = 0.5;

    init(_ parent: WaveLoopAnimationView) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentWaveLoop")
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
        
        var uniforms = FragmentUniforms(iTime: timeFloat, renderSize: renderSize, gridSize: gridSize, animSpeed: animSpeed, minRad: minRad, maxRad: maxRad)
        renderEncoder?.setFragmentBytes(&uniforms, length: MemoryLayout.size(ofValue: uniforms), index: 0)
        var freqs = FragmentFreq(yWaveAmpl: yWaveAmpl, yFreqVal: yWaveFreq)
        renderEncoder?.setFragmentBytes(&freqs, length: MemoryLayout.size(ofValue: freqs), index: 1)

        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 3, vertexCount: 6)

        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

#Preview {
    WaveLoopView()
        .background {
            Color.black
        }
        .ignoresSafeArea()
}
