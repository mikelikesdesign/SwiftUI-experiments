//
//  ContentView.swift
//  drag delete
//
//  Created by Michael Lee on 5/11/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        KeyboardPrototypeView()
            .ignoresSafeArea()
    }
}

private struct KeyboardPrototypeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> KeyboardPrototypeViewController {
        KeyboardPrototypeViewController()
    }

    func updateUIViewController(_ uiViewController: KeyboardPrototypeViewController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
