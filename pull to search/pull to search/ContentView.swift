//
//  ContentView.swift
//  pull to search
//
//  Created by Michael Lee on 4/7/24.
//

import SwiftUI

struct ContentView: View {
    @State private var searchProgress: CGFloat = 0
    @State private var showSearchModal = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Circle()
                    .fill(Color.clear)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 5)
                            .opacity(searchProgress)
                    )
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let progress = value.translation.height / geometry.size.height
                                searchProgress = min(1, max(0, progress))
                            }
                            .onEnded { _ in
                                if searchProgress >= 1 {
                                    showSearchModal = true
                                }
                                searchProgress = 0
                            }
                    )
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .sheet(isPresented: $showSearchModal) {
                SearchModalView()
            }
        }
    }
}

struct SearchModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    ContentView()
}
