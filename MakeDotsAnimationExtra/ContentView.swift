//
//  ContentView.swift
//  MakeDotsAnimationExtra
//
//  Created by javi www on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    
    let startDate = Date()
    
    ////Left to right vars
    @State private var leftToRightT: Float = 0.0
    @State private var gridSize: Float = 18.0
    @State private var dotSize: Float = 0.25
    @State private var minDotSize: Float = 0.04
    @State private var borderStep: Float = 0.01
    @State private var animatedionSpeedLTR: Float = 2.1
    @State private var loopAnim: Bool = true
    @State private var grad: Float = 1.06

    @State private var showSliders: Bool = false
    
    var body: some View {
        
        TabView {

            ViewWithSliders()
                .statusBarHidden()
            
            VerticalGridLine()
                .statusBarHidden()
            
            WaveLoopView()
                .ignoresSafeArea()
                .statusBarHidden()


        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        
        .statusBarHidden()
        .background {
            Color.black
        }
        .ignoresSafeArea()
    }
    
//    @ViewBuilder
//    func WaveLoop() -> some View {
//        WaveLoopAnimationView()
//    }
    
    @ViewBuilder
    func VerticalGridLine() -> some View {
        VerticalLineScanView()
            .ignoresSafeArea()
            .background {
                Color.black
            }
            .ignoresSafeArea()

    }
    
    @ViewBuilder
    func ViewLeftToRight() -> some View {
        LoadingDotsMetalRenderView(loadingAnim: .leftToRight, leftToRightT: $leftToRightT, gridSize: $gridSize, dotSize: $dotSize, borderStep: $borderStep, animatedionSpeedLTR: $animatedionSpeedLTR, loopAnim: .constant(true), minDotSize: $minDotSize, grad: $grad)
            .background {
                Color.black
            }
    }
    
    @ViewBuilder
    func ViewWithSliders() -> some View {
        VStack {
            LoadingDotsMetalRenderView(loadingAnim: .leftToRight, leftToRightT: $leftToRightT, gridSize: $gridSize, dotSize: $dotSize, borderStep: $borderStep, animatedionSpeedLTR: $animatedionSpeedLTR, loopAnim: $loopAnim, minDotSize: $minDotSize, grad: $grad)
                .background(Color.black)
                .ignoresSafeArea()
                .overlay {
                    VStack {
//                        SliderLabel(value: $leftToRightT, in: 0...1, label: "t \(leftToRightT)")
                        SliderLabel(value: $gridSize, in: 1...46.0, label: "grid size \(String(format:"%.2f", gridSize))")
                        SliderLabel(value: $dotSize, in: 0.01...1.0, label: "dotSize \(String(format:"%d%%", Int(dotSize * 100.0)))")
                        SliderLabel(value: $minDotSize, in: 0.01...0.2, label: "minDotSize \(String(format:"%.2f", minDotSize))")
                        SliderLabel(value: $borderStep, in: 0.001...0.24, label: "border \(String(format:"%.2f", borderStep))")
                        SliderLabel(value: $animatedionSpeedLTR, in: 0.23...6.5, label: "speed \(String(format:"%.2f", animatedionSpeedLTR))")
                        SliderLabel(value: $grad, in: 0.23...6.5, label: "grad \(String(format:"%.2f", grad))")

                        
                        HStack {
                            Text("Loop")
                            Toggle(isOn: $loopAnim, label: {})
                                .tint(Color.accentColor)
                        }
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
//                    .ignoresSafeArea()
            //                .shadow(color: .black, radius: 2, x: 0, y: 0)
            
        }
        .background {
            Rectangle()
                .foregroundStyle(.black)
                .ignoresSafeArea()
        }
//        .overlay {
//            Button {
//                showSliders.toggle()
//            } label: {
//                Image(systemName: "slider.vertical.3")
//                    .font(.title2)
//                    .frame(width: 44, height: 44)
//                    .background {
//                        Circle()
//                            .foregroundStyle(.ultraThinMaterial)
//                            .overlay {
//                                Circle()
//                                    .stroke(lineWidth: 1)
//                                    .opacity(0.2)
//                            }
//                            .shadow(color: .black, radius: 2, x: 0, y: 0)
//                    }
//            }
//            .foregroundStyle(.primary)
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
//            .padding(.trailing, 16)
//            .padding(.bottom, 32)
//        }
        .statusBarHidden()

    }
    
    /// 2 animations, one left to right appear
    /// One loading
    func animateLeftToRight() {
        
    }
    
    func animateLoading() {
        
    }
}

#Preview {
    ContentView()
        .statusBarHidden()
}

struct SliderLabel: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    
    init(value: Binding<Float>, in range: ClosedRange<Float>, label: String) {
        self._value = value
        self.range = range
        self.label = label
    }
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .font(.caption)
            
            Slider(
                value: $value,
                in: range,
                label: { EmptyView() }
            )
        }
    }
}
