//
//  ContentView.swift
//  demo
//
//  Created by Michael Lee on 12/28/24.
//

import SwiftUI

struct ContentView: View {
    @State private var points: [(CGPoint, Double)] = []
    @State private var time = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 20))
                
                for (point, creationTime) in points {
                    let age = time - creationTime
                    let color = Color(hue: age.truncatingRemainder(dividingBy: 1),
                                   saturation: 1,
                                   brightness: 1)
                    
                    context.addFilter(.blur(radius: max(1, 30 - age * 10)))
                    context.fill(Circle().path(in: CGRect(x: point.x - 30,
                                                        y: point.y - 30,
                                                        width: 60,
                                                        height: 60)),
                               with: .color(color.opacity(max(0, 1 - age/3))))
                }
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    points.append((value.location, time))
                    if points.count > 100 {
                        points.removeFirst()
                    }
                }))
            .onAppear {
                time = timeline.date.timeIntervalSince1970
            }
            .onChange(of: timeline.date) { oldValue, newValue in
                time = newValue.timeIntervalSince1970
            }
        }
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    ContentView()
}
