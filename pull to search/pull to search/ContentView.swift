//
//  ContentView.swift
//  pull to search
//
//  Created by Michael Lee on 6/2/24.
//

import SwiftUI

private let articleParagraphs = [
    "Prototyping is an important step in the design process that offers numerous benefits. It allows designers to iterate quickly, gather user feedback, test and validate ideas cost-effectively, facilitate communication and collaboration among team members, and mitigate risks by identifying potential issues early on. By creating prototypes, designers can make informed decisions and improve the overall quality of the final product.",
    "Moreover, prototyping helps in exploring and refining user experiences. It enables designers to experiment with different layouts, interactions, and visual designs, ensuring that the product meets user expectations and provides a seamless experience. Prototyping also serves as a valuable tool for presenting ideas to stakeholders and getting their buy-in, as it provides a tangible representation of the product's vision.",
    "Prototyping also plays a crucial role in saving time and resources in the long run. By identifying and addressing usability issues, design flaws, and technical challenges early in the development process, prototyping helps avoid costly mistakes and rework later on. It allows teams to validate assumptions, gather valuable insights, and make data-driven decisions before investing heavily in the final product."
]

struct ContentView: View {
    private let maxOffset: CGFloat = 120
    private let pullMultiplier: CGFloat = 1.2
    private let pullIndicatorYOffset: CGFloat = 32
    private let searchAnimation: Animation = .easeInOut

    @State private var offset: CGFloat = 0
    @State private var showSearchField = false
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ArticleContent()
                .background(Color.white)
                .offset(y: showSearchField ? 0 : offset)
                .animation(searchAnimation, value: offset)
                .zIndex(1)

            if !showSearchField {
                PullToSearch(
                    offset: $offset,
                    showSearchField: $showSearchField,
                    triggerOffset: maxOffset
                )
                .offset(y: max(0, offset - pullIndicatorYOffset))
                .zIndex(2)
            }

            if showSearchField {
                searchOverlay
                    .zIndex(3)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
        .gesture(
            DragGesture()
                .onChanged(handlePullChanged)
                .onEnded { _ in
                    handlePullEnded()
                }
        )
        .onChange(of: showSearchField) { _, isShowing in
            guard isShowing else {
                return
            }

            isSearchFieldFocused = true
        }
    }

    private var searchOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: hideSearch)

            SearchField(text: $searchText, isFocused: $isSearchFieldFocused)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func handlePullChanged(_ value: DragGesture.Value) {
        guard value.translation.height > 0, !showSearchField else {
            return
        }

        offset = min(value.translation.height * pullMultiplier, maxOffset)
    }

    private func handlePullEnded() {
        let shouldShowSearch = offset >= maxOffset

        withAnimation(searchAnimation) {
            offset = 0

            if shouldShowSearch {
                showSearchField = true
            }
        }
    }

    private func hideSearch() {
        isSearchFieldFocused = false
        searchText = ""

        withAnimation(searchAnimation) {
            showSearchField = false
        }
    }
}

private struct ArticleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The Benefits of Prototyping")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: 0x464646))
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)

            ForEach(articleParagraphs, id: \.self) { paragraph in
                ArticleParagraph(text: paragraph)
            }

            Spacer()
        }
    }
}

private struct ArticleParagraph: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: 0x8A8A8A))
            .lineSpacing(6)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}

private struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    private let fieldBackground = Color(uiColor: .secondarySystemBackground)
    private let fieldForeground = Color(uiColor: .label)
    private let fieldBorder = Color(uiColor: .separator)

    var body: some View {
        TextField("Search...", text: $text)
            .textFieldStyle(.plain)
            .foregroundStyle(fieldForeground)
            .tint(fieldForeground)
            .padding()
            .background(fieldBackground)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(fieldBorder.opacity(0.35), lineWidth: 1)
            }
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .focused(isFocused)
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

    let triggerOffset: CGFloat

    var body: some View {
        VStack {
            if offset > 0 {
                Circle()
                    .fill(offset > 80 ? Color.blue : Color.black)
                    .frame(width: min(offset / 1.6, 50), height: min(offset / 1.6, 50))
                    .overlay {
                        if offset > 40 {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .scaleEffect(min(1, (offset - 40) / 40))
                                .animation(.easeInOut, value: offset)
                        }
                    }
                    .animation(.easeInOut, value: offset)
                    .padding(.top, -24)
            }

            Spacer()
        }
        .frame(height: 0)
        .onChange(of: offset) { _, newOffset in
            guard newOffset >= triggerOffset else {
                return
            }

            withAnimation(.easeInOut) {
                showSearchField = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
