//
//  ContentView.swift
//  photo effect
//
//  Created by Michael Lee on 5/23/24.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    @State private var touchLocation: CGPoint = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            MetalImageView(touchLocation: touchLocation, scale: imageScale)
                .frame(width: 335, height: 335)
                .offset(imageOffset)
            
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            touchLocation = value.location
                            withAnimation(.easeInOut(duration: 0.5)) {
                                imageScale = 0.1
                                imageOffset = CGSize(
                                    width: value.location.x - UIScreen.main.bounds.width / 2,
                                    height: value.location.y - UIScreen.main.bounds.height / 2
                                )
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                imageScale = 1.0
                                imageOffset = .zero
                            }
                        }
                )
        }
    }
}

struct MetalImageView: UIViewRepresentable {
    var touchLocation: CGPoint
    var scale: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(touchLocation: touchLocation, scale: scale)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = false
        view.drawableSize = CGSize(width: 335, height: 335)
        context.coordinator.touchLocation = touchLocation
        context.coordinator.scale = scale
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.touchLocation = touchLocation
        context.coordinator.scale = scale
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var texture: MTLTexture!
        var touchLocation: CGPoint
        var scale: CGFloat
        
        init(touchLocation: CGPoint, scale: CGFloat) {
            self.touchLocation = touchLocation
            self.scale = scale
            super.init()
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            commandQueue = device.makeCommandQueue()
            setupPipelineState(device: device)
            loadTexture(device: device)
        }
        
        func setupPipelineState(device: MTLDevice) {
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertex_main")
            let fragmentFunction = library?.makeFunction(name: "fragment_main")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        func loadTexture(device: MTLDevice) {
            let textureLoader = MTKTextureLoader(device: device)
            if let url = Bundle.main.url(forResource: "space", withExtension: "jpg") {
                texture = try? textureLoader.newTexture(URL: url, options: nil)
            }
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setFragmentTexture(texture, index: 0)
            
            var touchLocation = SIMD2<Float>(Float(self.touchLocation.x / view.drawableSize.width), Float(self.touchLocation.y / view.drawableSize.height))
            var scale = Float(self.scale)
            renderEncoder?.setFragmentBytes(&touchLocation, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
            renderEncoder?.setFragmentBytes(&scale, length: MemoryLayout<Float>.stride, index: 2)
            
            let vertices = [
                VertexIn(position: [-1,  1, 0, 1], textureCoordinate: [0, 1]),
                VertexIn(position: [-1, -1, 0, 1], textureCoordinate: [0, 0]),
                VertexIn(position: [ 1, -1, 0, 1], textureCoordinate: [1, 0]),
                VertexIn(position: [ 1,  1, 0, 1], textureCoordinate: [1, 1])
            ]
            renderEncoder?.setVertexBytes(vertices, length: MemoryLayout<VertexIn>.stride * vertices.count, index: 0)
            renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
            
            renderEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}

struct VertexIn {
    var position: SIMD4<Float>
    var textureCoordinate: SIMD2<Float>
}

struct ContentView_Previews: PreviewProvider {
    static var previews: ContentView {
        ContentView()
    }
}
