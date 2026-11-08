import SwiftUI

struct ContentView: View {
    @StateObject private var studio = DrawingStudio()

    var body: some View {
        ZStack(alignment: .top) {
            GraphPaper().ignoresSafeArea()
            DrawingCanvas(studio: studio).ignoresSafeArea()
            DraggablePalette(studio: studio).ignoresSafeArea()
            StudioHeader(studio: studio).padding(.top, 18)
        }
        .preferredColorScheme(.light)
        .onChange(of: studio.color) { _, _ in studio.applyTool() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
