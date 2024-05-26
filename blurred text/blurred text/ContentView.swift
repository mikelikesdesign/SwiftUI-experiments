//
//  ContentView.swift
//  blurred text
//
//  Created by Michael Lee on 5/20/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProgressiveBlurText(text: "Prototyping is an essential part of the design process. It allows designers to quickly test and iterate on their ideas before investing significant time and resources into development. By creating a prototype, designers can gather valuable feedback from users and stakeholders early on, helping to identify potential issues and opportunities for improvement.", index: 0)
                
                ProgressiveBlurText(text: "One of the key benefits of prototyping is that it enables designers to communicate their vision more effectively. A prototype can help to clarify the design intent and make it easier for others to understand how the final product will look and function. This can be particularly useful when collaborating with team members from different disciplines, such as developers or business stakeholders.", index: 1)
                
                ProgressiveBlurText(text: "Prototyping also allows designers to experiment with different design concepts and explore alternative solutions. By creating multiple prototypes, designers can compare and contrast different approaches and make informed decisions about which direction to pursue. This can help to reduce the risk of investing time and resources into a design that may not be effective or feasible.", index: 2)
                
                ProgressiveBlurText(text: "Another benefit of prototyping is that it can help to identify usability issues early on in the design process. By testing a prototype with users, designers can gather feedback on how well the design works in practice and identify any areas that may be confusing or difficult to use. This can help to ensure that the final product is intuitive and user-friendly.", index: 3)
                
                ProgressiveBlurText(text: "Finally, prototyping can also be a valuable tool for building consensus and gaining buy-in from stakeholders. By demonstrating a working prototype, designers can help to build excitement and enthusiasm for the project and show the potential value of the final product. This can be particularly important when seeking funding or approval for a project.", index: 4)
            }
            .padding()
        }
        .background(Color.black)
    }
}

struct ProgressiveBlurText: View {
    let text: String
    let index: Int
    
    @State private var opacity: Double = 0
    
    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .opacity(opacity)
            .onAppear {
                if index == 0 {
                    withAnimation(.easeOut(duration: 1)) {
                        opacity = 1
                    }
                }
            }
            .onDisappear {
                opacity = 0
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
