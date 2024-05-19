//
//  ContentView.swift
//  paper
//
//  Created by Michael Lee on 5/16/24.
//

import SwiftUI

struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        CrumpleView(scale: scale)
            .gesture(MagnificationGesture()
                        .onChanged { value in
                            self.scale = value.magnitude
                        }
            )
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}










