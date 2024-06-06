//
//  ContentView.swift
//  pull to search
//
//  Created by Michael Lee on 6/2/24.
//

import SwiftUI

struct ContentView: View {
    @State private var offset: CGFloat = 0
    @State private var showSearchField = false
    @State private var searchText: String = ""
    private let maxOffset: CGFloat = 120 // Threshold for maximum pull (decreased by 20%)

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Benefits of Prototyping")
                    .font(.system(size: 24, weight: .bold)) // Decrease header font size by 4 points
                    .foregroundColor(Color(hex: 0x464646)) // Set header color to #464646
                    .padding(.horizontal)
                    .padding(.bottom, 8) // Adjust spacing between header and first paragraph
                    .padding(.top, 24) // Push down the header by 24 pixels
                
                Text("Prototyping is an important step in the design process that offers numerous benefits. It allows designers to iterate quickly, gather user feedback, test and validate ideas cost-effectively, facilitate communication and collaboration among team members, and mitigate risks by identifying potential issues early on. By creating prototypes, designers can make informed decisions and improve the overall quality of the final product.")
                    .font(.system(size: 14)) // Decrease font size by 2 points
                    .foregroundColor(Color(hex: 0x8A8A8A)) // Set body text color to #8A8A8A
                    .lineSpacing(6) // Increase line spacing
                    .padding(.horizontal)
                    .padding(.bottom, 8) // Add bottom padding to create spacing between paragraphs
                
                Text("Moreover, prototyping helps in exploring and refining user experiences. It enables designers to experiment with different layouts, interactions, and visual designs, ensuring that the product meets user expectations and provides a seamless experience. Prototyping also serves as a valuable tool for presenting ideas to stakeholders and getting their buy-in, as it provides a tangible representation of the product's vision.")
                    .font(.system(size: 14)) // Decrease font size by 2 points
                    .foregroundColor(Color(hex: 0x8A8A8A)) // Set body text color to #8A8A8A
                    .lineSpacing(6) // Increase line spacing
                    .padding(.horizontal)
                    .padding(.bottom, 8) // Add bottom padding to create spacing between paragraphs
                
                Text("Prototyping also plays a crucial role in saving time and resources in the long run. By identifying and addressing usability issues, design flaws, and technical challenges early in the development process, prototyping helps avoid costly mistakes and rework later on. It allows teams to validate assumptions, gather valuable insights, and make data-driven decisions before investing heavily in the final product.")
                    .font(.system(size: 14)) // Decrease font size by 2 points
                    .foregroundColor(Color(hex: 0x8A8A8A)) // Set body text color to #8A8A8A
                    .lineSpacing(6) // Increase line spacing
                    .padding(.horizontal)
                    .padding(.bottom) // Add bottom padding
                
                Spacer() // Add a Spacer to push the content to the top
            }
            .background(Color.white)
            .offset(y: showSearchField ? 0 : offset)
            .animation(.easeInOut, value: offset)
            .zIndex(1)
            
            if !showSearchField {
                PullToSearch(offset: $offset, showSearchField: $showSearchField)
                    .offset(y: max(0, offset - 32)) // Adjust this value to position the circle above the header (decreased by 20%)
                    .zIndex(2)
            }

            if showSearchField {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            self.showSearchField = false
                            self.searchText = ""
                            UIApplication.shared.endEditing() // Dismiss the keyboard
                        }
                    }
                    .zIndex(3)

                VStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(100)
                        .shadow(radius: 10)
                        .padding(.horizontal, 20)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIApplication.shared.showKeyboard() // Show the keyboard
                            }
                        }
                }
                .padding(.top, 60)
                .transition(.move(edge: .top))
                .animation(.easeInOut)
                .zIndex(4)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .gesture(DragGesture()
            .onChanged { value in
                if value.translation.height > 0 && !self.showSearchField {
                    self.offset = min(value.translation.height * 1.2, maxOffset) // Increase the speed by 20%
                }
            }
            .onEnded { value in
                if self.offset == maxOffset {
                    withAnimation {
                        self.showSearchField = true
                    }
                    withAnimation {
                        self.offset = 0
                    }
                } else {
                    withAnimation {
                        self.offset = 0
                    }
                }
            }
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct PullToSearch: View {
    @Binding var offset: CGFloat
    @Binding var showSearchField: Bool

    var body: some View {
        VStack {
            if offset > 0 {
                Circle()
                    .fill(offset > 80 ? Color.blue : Color.black) // Decrease the threshold to 80 (decreased by 20%)
                    .frame(width: min(offset / 1.6, 50), height: min(offset / 1.6, 50)) // Increase the size faster (decreased by 20%)
                    .overlay(
                        Group {
                            if offset > 40 { // Decrease the threshold to 40 (search icon appears earlier)
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .scaleEffect(min(1, (offset - 40) / 40)) // Scale the search icon based on the offset
                                    .animation(.easeInOut, value: offset)
                            }
                        }
                    )
                    .animation(.easeInOut, value: offset)
                    .padding(.top, -24) // Adjust to position the circle from the top (decreased by 20%)
            }
            Spacer()
        }
        .frame(height: 0)
        .onChange(of: offset) { _ in
            if offset >= 120 { // Decrease the threshold to 120 (decreased by 20%)
                withAnimation {
                    showSearchField = true
                }
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func showKeyboard() {
        // A hack to show the keyboard
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first

        let textField = UITextField()
        keyWindow?.addSubview(textField)
        textField.becomeFirstResponder()
        textField.resignFirstResponder()
        textField.removeFromSuperview()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
