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
    @State private var fourthPageID = UUID()
    @State private var fifthPageID = UUID()
    
    var body: some View {
        VerticalPageViewController(
            pages: [
                AnyView(FirstPage().id(firstPageID)),
                AnyView(AreaChartPage().id(fourthPageID)),
                AnyView(SecondPage().id(secondPageID)),
                AnyView(DonutChartPage().id(fifthPageID)),
                AnyView(ThirdPage().id(thirdPageID))
            ],
            currentPage: $currentPage,
            pageChanged: { newPage in
                // Regenerate the ID for the new page to force a reload
                switch newPage {
                case 0: firstPageID = UUID()
                case 1: fourthPageID = UUID()
                case 2: secondPageID = UUID()
                case 3: fifthPageID = UUID()
                case 4: thirdPageID = UUID()
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

struct AreaChartPage: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "F4F9E1").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                progressText
                Spacer().frame(height: 24)
                progressChart
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
    
    private var progressText: some View {
        Group {
            Text("This month, you ")
            + Text("reached 59,500 steps, ").bold()
            + Text("exceeding your 50,000 goal by day 26 and continuing to build momentum.")
        }
        .font(.system(size: 24))
        .foregroundColor(Color(hex: "76A32C"))
    }
    
    private var progressChart: some View {
        Chart {
            ForEach(cumulativeStepsJuly) { data in
                AreaMark(
                    x: .value("Day", data.day),
                    y: .value("Steps", Double(data.steps) * animationProgress)
                )
                .foregroundStyle(Gradient(colors: [
                    Color(hex: "9CC740").opacity(0.8),
                    Color(hex: "76A32C").opacity(0.3)
                ]))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Day", data.day),
                    y: .value("Steps", Double(data.steps) * animationProgress)
                )
                .foregroundStyle(Color(hex: "76A32C"))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                
                // Add marker for the final total only
                if data.day == 31 {
                    PointMark(
                        x: .value("Day", data.day),
                        y: .value("Steps", Double(data.steps) * animationProgress)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(150)
                    
                    PointMark(
                        x: .value("Day", data.day),
                        y: .value("Steps", Double(data.steps) * animationProgress)
                    )
                    .foregroundStyle(Color(hex: "76A32C"))
                    .symbolSize(100)
                }
            }
        }
        .chartYScale(domain: 0...59500)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let day = value.as(Int.self), day <= dailyStepsJuly.count, day > 0 {
                        Text("Jul \(day)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "76A32C"))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color(hex: "76A32C").opacity(0.2))
                AxisTick().foregroundStyle(Color(hex: "76A32C"))
                AxisValueLabel {
                    if let stepValue = value.as(Int.self) {
                        Text("\(stepValue / 1000)k")
                            .foregroundStyle(Color(hex: "76A32C"))
                    }
                }
            }
        }
        .frame(height: 300)
    }
}

struct DonutChartPage: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "EBF5F7").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                activitiesText
                Spacer().frame(height: 24)
                activitiesChart
                activityLegend
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
    
    private var activitiesText: some View {
        Group {
            Text("Your steps come from ")
            + Text("various activities. ").bold()
            + Text("Most steps were accumulated from casual walking.")
        }
        .font(.system(size: 24))
        .foregroundColor(Color(hex: "156C8A"))
    }
    
    private var activitiesChart: some View {
        Chart {
            ForEach(activityData) { activity in
                SectorMark(
                    angle: .value("Steps", Double(activity.steps) * animationProgress),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(activity.color)
            }
        }
        .frame(height: 300)
    }
    
    private var activityLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(activityData) { activity in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(activity.color)
                        .frame(width: 20, height: 20)
                    Text(activity.name)
                        .foregroundStyle(Color(hex: "156C8A"))
                    Text("(\(activity.percentage)%)")
                        .foregroundStyle(Color(hex: "156C8A").opacity(0.7))
                    Spacer()
                    Text("\(activity.steps) steps")
                        .foregroundStyle(Color(hex: "156C8A"))
                }
            }
        }
        .padding(.top)
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

// Sample data for the line chart
let dailyStepsJuly: [DailyStepData] = [
    DailyStepData(day: "Jul 1", steps: 1700, isWeekend: false),
    DailyStepData(day: "Jul 2", steps: 1800, isWeekend: true),
    DailyStepData(day: "Jul 3", steps: 1900, isWeekend: true),
    DailyStepData(day: "Jul 4", steps: 1600, isWeekend: false),
    DailyStepData(day: "Jul 5", steps: 1750, isWeekend: false),
    DailyStepData(day: "Jul 6", steps: 1800, isWeekend: false),
    DailyStepData(day: "Jul 7", steps: 1650, isWeekend: false),
    DailyStepData(day: "Jul 8", steps: 1900, isWeekend: true),
    DailyStepData(day: "Jul 9", steps: 2100, isWeekend: true),
    DailyStepData(day: "Jul 10", steps: 1700, isWeekend: false),
    DailyStepData(day: "Jul 11", steps: 1850, isWeekend: false),
    DailyStepData(day: "Jul 12", steps: 1950, isWeekend: false),
    DailyStepData(day: "Jul 13", steps: 1800, isWeekend: false),
    DailyStepData(day: "Jul 14", steps: 1750, isWeekend: false),
    DailyStepData(day: "Jul 15", steps: 2200, isWeekend: true),
    DailyStepData(day: "Jul 16", steps: 2300, isWeekend: true),
    DailyStepData(day: "Jul 17", steps: 1900, isWeekend: false),
    DailyStepData(day: "Jul 18", steps: 2000, isWeekend: false),
    DailyStepData(day: "Jul 19", steps: 2100, isWeekend: false),
    DailyStepData(day: "Jul 20", steps: 2050, isWeekend: false),
    DailyStepData(day: "Jul 21", steps: 1950, isWeekend: false),
    DailyStepData(day: "Jul 22", steps: 2400, isWeekend: true),
    DailyStepData(day: "Jul 23", steps: 2500, isWeekend: true),
    DailyStepData(day: "Jul 24", steps: 2100, isWeekend: false),
    DailyStepData(day: "Jul 25", steps: 2200, isWeekend: false),
    DailyStepData(day: "Jul 26", steps: 2150, isWeekend: false),
    DailyStepData(day: "Jul 27", steps: 2300, isWeekend: false),
    DailyStepData(day: "Jul 28", steps: 2200, isWeekend: false),
    DailyStepData(day: "Jul 29", steps: 2600, isWeekend: true),
    DailyStepData(day: "Jul 30", steps: 2700, isWeekend: true),
    DailyStepData(day: "Jul 31", steps: 2600, isWeekend: false)
]

// Activity data for the donut chart
let activityData: [ActivityData] = [
    ActivityData(name: "Casual Walking", steps: 35700, percentage: 60, color: Color(hex: "156C8A")),
    ActivityData(name: "Running", steps: 11900, percentage: 20, color: Color(hex: "2A9EB8")),
    ActivityData(name: "Hiking", steps: 5950, percentage: 10, color: Color(hex: "6CBCCE")),
    ActivityData(name: "Shopping", steps: 3570, percentage: 6, color: Color(hex: "A3D5E0")),
    ActivityData(name: "Other", steps: 2380, percentage: 4, color: Color(hex: "D4EBF0"))
]

struct DailyStepData: Identifiable {
    let id = UUID()
    let day: String
    let steps: Int
    let isWeekend: Bool
}

struct ActivityData: Identifiable {
    let id = UUID()
    let name: String
    let steps: Int
    let percentage: Int
    let color: Color
}

// Calculate cumulative steps for area chart
let cumulativeStepsJuly: [CumulativeStepData] = {
    var cumulative = 0
    var result: [CumulativeStepData] = []
    
    for (index, day) in dailyStepsJuly.enumerated() {
        cumulative += day.steps
        
        result.append(CumulativeStepData(
            day: index + 1,
            steps: cumulative,
            milestone: false
        ))
    }
    
    // Scale the final result to ensure the last point is exactly 59,500
    let scaleFactor = 59500.0 / Double(result.last?.steps ?? 59500)
    return result.map { dataPoint in
        CumulativeStepData(
            day: dataPoint.day,
            steps: Int(Double(dataPoint.steps) * scaleFactor),
            milestone: false
        )
    }
}()

struct CumulativeStepData: Identifiable {
    let id = UUID()
    let day: Int
    let steps: Int
    let milestone: Bool
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
