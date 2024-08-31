//
//  ContentView.swift
//  walk charts
//
//  Created by Michael Lee on 7/24/24.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var currentPage = 0
    @State private var firstPageID = UUID()
    @State private var secondPageID = UUID()
    @State private var thirdPageID = UUID()
    
    var body: some View {
        VerticalPageViewController(
            pages: [
                AnyView(FirstPage().id(firstPageID)),
                AnyView(SecondPage().id(secondPageID)),
                AnyView(ThirdPage().id(thirdPageID))
            ],
            currentPage: $currentPage,
            pageChanged: { newPage in
                // Regenerate the ID for the new page to force a reload
                switch newPage {
                case 0: firstPageID = UUID()
                case 1: secondPageID = UUID()
                case 2: thirdPageID = UUID()
                default: break
                }
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct VerticalPageViewController: UIViewControllerRepresentable {
    var pages: [AnyView]
    @Binding var currentPage: Int
    var pageChanged: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: .forward,
            animated: true)
        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: .forward,
            animated: true)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalPageViewController
        var controllers: [UIViewController]

        init(_ pageViewController: VerticalPageViewController) {
            parent = pageViewController
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 { return nil }
            return controllers[index - 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index + 1 == controllers.count { return nil }
            return controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
                parent.pageChanged(index)
            }
        }
    }
}

struct FirstPage: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                headerText
                Spacer().frame(height: 24)
                stepsChart
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animationProgress = 1
            }
        }
    }
    
    private var headerText: some View {
        (Text("You walked ")
        + Text("59,500").bold()
        + Text(" steps this month. That's your highest month yet."))
        .font(.system(size: 24))
        .foregroundColor(.black)
    }
    
    private var stepsChart: some View {
        Chart {
            ForEach(monthlySteps) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Steps", Double(data.steps) * animationProgress)
                )
                .foregroundStyle(data.month == "Jul" ? Color.black.opacity(0.5).gradient : Color.gray.opacity(0.5).gradient)
                .cornerRadius(12)
            }
        }
        .chartYScale(domain: 0...80000)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let stepValue = value.as(Int.self) {
                        Text("\(stepValue / 1000)k")
                    }
                }
            }
        }
        .frame(height: 300)
    }
}

struct SecondPage: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "E8E9FF").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                goalText
                Spacer().frame(height: 24)
                goalChart
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animationProgress = 1
            }
        }
    }
    
    private var goalText: some View {
        let remainingSteps = 100000 - 59500
        return Group {
            Text("In order to meet your goal of walking ")
            + Text("100,000").bold()
            + Text(" steps this month, you need to walk ")
            + Text("\(remainingSteps)").bold()
            + Text(" more.")
        }
        .font(.system(size: 24))
        .foregroundColor(Color(hex: "1E25FF"))
    }

    private var goalChart: some View {
        Chart {
            BarMark(
                x: .value("Label", "Current"),
                y: .value("Steps", Double(59500) * animationProgress)
            )
            .foregroundStyle(Color(hex: "A1A4FF"))
            .cornerRadius(16)
            
            BarMark(
                x: .value("Label", "Goal"),
                y: .value("Steps", Double(100000) * animationProgress)
            )
            .foregroundStyle(Color(hex: "1E25FF"))
            .cornerRadius(16)
        }
        .chartYScale(domain: 0...100000)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color(hex: "1E25FF").opacity(0.2))
                AxisTick().foregroundStyle(Color(hex: "1E25FF"))
                AxisValueLabel() {
                    if let stepValue = value.as(Int.self) {
                        Text("\(stepValue / 1000)k")
                            .foregroundStyle(Color(hex: "1E25FF"))
                    }
                }
            }
        }
        .frame(height: 300)
    }
}

struct ThirdPage: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "D9F8F6").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                forecastText
                Spacer().frame(height: 24)
                forecastChart
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animationProgress = 1
            }
        }
    }
    
    private var forecastText: some View {
        Group {
            Text("If you continue on this growth ")
            + Text("trajectory, you'll be walking ")
            + Text("75,000").bold()
            + Text(" steps in August.")
        }
        .font(.system(size: 24))
        .foregroundColor(Color(hex: "01ACA1"))
    }
    
    private var forecastChart: some View {
        Chart {
            ForEach(monthlyStepsWithForecast) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Steps", Double(data.steps) * animationProgress)
                )
                .foregroundStyle(data.month == "Aug" ? Color(hex: "01ACA1").gradient : Color(hex: "01ACA1").opacity(0.3).gradient)
                .cornerRadius(8)
            }
        }
        .chartYScale(domain: 0...80000)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color(hex: "01ACA1").opacity(0.2))
                AxisTick().foregroundStyle(Color(hex: "01ACA1"))
                AxisValueLabel {
                    if let stepValue = value.as(Int.self) {
                        Text("\(stepValue / 1000)k")
                            .foregroundStyle(Color(hex: "01ACA1"))
                    }
                }
            }
        }
        .frame(height: 300)
    }
}

let monthlySteps: [StepData] = [
    StepData(month: "Mar", steps: 45000),
    StepData(month: "Apr", steps: 52000),
    StepData(month: "May", steps: 48000),
    StepData(month: "Jun", steps: 55000),
    StepData(month: "Jul", steps: 59500)
]

let monthlyStepsWithForecast: [StepData] = monthlySteps + [StepData(month: "Aug", steps: 75000)]

struct StepData: Identifiable {
    let id = UUID()
    let month: String
    let steps: Int
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
