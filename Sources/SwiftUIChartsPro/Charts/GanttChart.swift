import SwiftUI

// MARK: - Gantt Chart

/// A timeline chart for project management and scheduling.
///
/// Gantt charts display tasks over time, showing start dates, end dates,
/// progress, and dependencies between tasks.
///
/// ```swift
/// let tasks = [
///     GanttTask(name: "Design", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 5)),
///     GanttTask(name: "Development", startDate: Date().addingTimeInterval(86400 * 3), endDate: Date().addingTimeInterval(86400 * 10))
/// ]
///
/// GanttChart(tasks: tasks)
/// ```
public struct GanttChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The tasks to display
    public let tasks: [GanttTask]
    
    /// Row height for each task
    public let rowHeight: CGFloat
    
    /// Whether to show task labels
    public let showLabels: Bool
    
    /// Whether to show progress indicators
    public let showProgress: Bool
    
    /// Whether to show dependency lines
    public let showDependencies: Bool
    
    /// Whether to show date markers
    public let showDateMarkers: Bool
    
    /// Whether to show today indicator
    public let showTodayIndicator: Bool
    
    /// Corner radius for task bars
    public let barCornerRadius: CGFloat
    
    /// The date range to display (auto-calculated if nil)
    public let dateRange: ClosedRange<Date>?
    
    /// Date format for markers
    public let dateFormat: String
    
    /// Time scale granularity
    public let timeScale: TimeScale
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedTask: UUID?
    @State private var hoveredTask: UUID?
    @State private var scrollOffset: CGFloat = 0
    
    /// Creates a Gantt chart.
    public init(
        tasks: [GanttTask],
        rowHeight: CGFloat = 40,
        showLabels: Bool = true,
        showProgress: Bool = true,
        showDependencies: Bool = true,
        showDateMarkers: Bool = true,
        showTodayIndicator: Bool = true,
        barCornerRadius: CGFloat = 4,
        dateRange: ClosedRange<Date>? = nil,
        dateFormat: String = "MMM d",
        timeScale: TimeScale = .day
    ) {
        self.tasks = tasks
        self.rowHeight = rowHeight
        self.showLabels = showLabels
        self.showProgress = showProgress
        self.showDependencies = showDependencies
        self.showDateMarkers = showDateMarkers
        self.showTodayIndicator = showTodayIndicator
        self.barCornerRadius = barCornerRadius
        self.dateRange = dateRange
        self.dateFormat = dateFormat
        self.timeScale = timeScale
    }
    
    private var effectiveDateRange: ClosedRange<Date> {
        if let range = dateRange { return range }
        
        let minDate = tasks.map { $0.startDate }.min() ?? Date()
        let maxDate = tasks.map { $0.endDate }.max() ?? Date()
        
        // Add padding
        let padding = max(86400, maxDate.timeIntervalSince(minDate) * 0.1)
        return minDate.addingTimeInterval(-padding)...maxDate.addingTimeInterval(padding)
    }
    
    private var totalDuration: TimeInterval {
        effectiveDateRange.upperBound.timeIntervalSince(effectiveDateRange.lowerBound)
    }
    
    private var groupedTasks: [String: [GanttTask]] {
        Dictionary(grouping: tasks) { $0.group ?? "Ungrouped" }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let labelWidth: CGFloat = showLabels ? 150 : 0
            let chartWidth = geometry.size.width - labelWidth
            
            VStack(spacing: 0) {
                // Header with date markers
                if showDateMarkers {
                    dateMarkersView(width: chartWidth, labelOffset: labelWidth)
                        .frame(height: 30)
                }
                
                // Chart content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            taskRow(
                                task: task,
                                index: index,
                                chartWidth: chartWidth,
                                labelWidth: labelWidth
                            )
                        }
                    }
                }
                
                // Dependency lines overlay
                if showDependencies {
                    dependencyLines(chartWidth: chartWidth, labelWidth: labelWidth)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gantt chart with \(tasks.count) tasks")
    }
    
    // MARK: - Date Markers
    
    private func dateMarkersView(width: CGFloat, labelOffset: CGFloat) -> some View {
        let markers = generateDateMarkers()
        
        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(theme.backgroundColor)
            
            // Grid lines
            ForEach(markers, id: \.self) { date in
                let x = xPosition(for: date, in: width) + labelOffset
                
                VStack(spacing: 0) {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                        .position(x: x, y: 10)
                    
                    Rectangle()
                        .fill(theme.gridColor)
                        .frame(width: 1)
                }
            }
            
            // Today indicator
            if showTodayIndicator {
                let todayX = xPosition(for: Date(), in: width) + labelOffset
                if todayX >= labelOffset && todayX <= labelOffset + width {
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 2)
                        .position(x: todayX, y: 15)
                }
            }
        }
    }
    
    private func generateDateMarkers() -> [Date] {
        var markers: [Date] = []
        let calendar = Calendar.current
        var currentDate = effectiveDateRange.lowerBound
        
        while currentDate <= effectiveDateRange.upperBound {
            markers.append(currentDate)
            
            switch timeScale {
            case .hour:
                currentDate = calendar.date(byAdding: .hour, value: 6, to: currentDate) ?? currentDate
            case .day:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .week:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .month:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return markers
    }
    
    private func xPosition(for date: Date, in width: CGFloat) -> CGFloat {
        let elapsed = date.timeIntervalSince(effectiveDateRange.lowerBound)
        return (CGFloat(elapsed / totalDuration) * width)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
    
    // MARK: - Task Row
    
    private func taskRow(task: GanttTask, index: Int, chartWidth: CGFloat, labelWidth: CGFloat) -> some View {
        let isSelected = selectedTask == task.id
        let isHovered = hoveredTask == task.id
        let color = task.color ?? theme.color(at: index)
        
        return HStack(spacing: 0) {
            // Task label
            if showLabels {
                Text(task.name)
                    .font(theme.font)
                    .foregroundColor(isSelected ? theme.accentColor : theme.foregroundColor)
                    .frame(width: labelWidth, alignment: .trailing)
                    .padding(.trailing, 8)
                    .lineLimit(1)
            }
            
            // Task bar
            ZStack(alignment: .leading) {
                // Background grid
                Rectangle()
                    .fill(index % 2 == 0 ? Color.clear : theme.gridColor.opacity(0.3))
                
                // Task bar
                taskBar(
                    task: task,
                    color: color,
                    chartWidth: chartWidth,
                    isSelected: isSelected,
                    isHovered: isHovered
                )
            }
            .frame(height: rowHeight)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTask = selectedTask == task.id ? nil : task.id
            }
        }
        .onHover { hovering in
            hoveredTask = hovering ? task.id : nil
        }
        .accessibilityElement()
        .accessibilityLabel("\(task.name), \(task.durationInDays) days, \(Int(task.progress * 100))% complete")
    }
    
    @ViewBuilder
    private func taskBar(
        task: GanttTask,
        color: Color,
        chartWidth: CGFloat,
        isSelected: Bool,
        isHovered: Bool
    ) -> some View {
        let startX = xPosition(for: task.startDate, in: chartWidth)
        let endX = xPosition(for: task.endDate, in: chartWidth)
        let barWidth = max(4, (endX - startX) * animationProgress)
        let barHeight = rowHeight * 0.6
        
        ZStack(alignment: .leading) {
            // Background bar
            RoundedRectangle(cornerRadius: barCornerRadius)
                .fill(color.opacity(0.3))
                .frame(width: barWidth, height: barHeight)
            
            // Progress bar
            if showProgress && task.progress > 0 {
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(color)
                    .frame(width: barWidth * CGFloat(task.progress), height: barHeight)
            }
            
            // Border
            RoundedRectangle(cornerRadius: barCornerRadius)
                .stroke(isSelected ? theme.accentColor : color, lineWidth: isSelected ? 2 : 1)
                .frame(width: barWidth, height: barHeight)
            
            // Hover highlight
            if isHovered {
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: barWidth, height: barHeight)
            }
            
            // Task name on bar (if wide enough)
            if barWidth > 60 {
                Text(task.name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .lineLimit(1)
            }
        }
        .offset(x: startX, y: 0)
    }
    
    // MARK: - Dependency Lines
    
    private func dependencyLines(chartWidth: CGFloat, labelWidth: CGFloat) -> some View {
        Canvas { context, size in
            for task in tasks {
                for depId in task.dependencies {
                    guard let dependentTask = tasks.first(where: { $0.id == depId }) else { continue }
                    
                    let fromX = labelWidth + xPosition(for: dependentTask.endDate, in: chartWidth)
                    let toX = labelWidth + xPosition(for: task.startDate, in: chartWidth)
                    
                    let fromIndex = tasks.firstIndex(where: { $0.id == depId }) ?? 0
                    let toIndex = tasks.firstIndex(where: { $0.id == task.id }) ?? 0
                    
                    let fromY = CGFloat(fromIndex) * rowHeight + rowHeight / 2
                    let toY = CGFloat(toIndex) * rowHeight + rowHeight / 2
                    
                    var path = Path()
                    path.move(to: CGPoint(x: fromX, y: fromY))
                    path.addLine(to: CGPoint(x: fromX + 10, y: fromY))
                    path.addLine(to: CGPoint(x: fromX + 10, y: toY))
                    path.addLine(to: CGPoint(x: toX, y: toY))
                    
                    context.stroke(
                        path,
                        with: .color(theme.gridColor),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                    )
                    
                    // Arrow head
                    var arrowPath = Path()
                    arrowPath.move(to: CGPoint(x: toX - 6, y: toY - 4))
                    arrowPath.addLine(to: CGPoint(x: toX, y: toY))
                    arrowPath.addLine(to: CGPoint(x: toX - 6, y: toY + 4))
                    
                    context.stroke(
                        arrowPath,
                        with: .color(theme.gridColor),
                        lineWidth: 1
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Supporting Types

/// Time scale granularity for Gantt charts
public enum TimeScale {
    /// Hourly scale
    case hour
    
    /// Daily scale
    case day
    
    /// Weekly scale
    case week
    
    /// Monthly scale
    case month
}

// MARK: - Gantt Task Extensions

public extension GanttTask {
    /// Creates a task with a duration in days from today
    static func from(
        name: String,
        daysFromNow startDays: Int,
        duration days: Int,
        progress: Double = 0,
        color: Color? = nil,
        group: String? = nil
    ) -> GanttTask {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: startDays, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: days, to: startDate) ?? startDate
        
        return GanttTask(
            name: name,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            color: color,
            group: group
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct GanttChart_Previews: PreviewProvider {
    static var previews: some View {
        let task1 = GanttTask.from(name: "Research", daysFromNow: -5, duration: 5, progress: 1.0, color: .blue)
        let task2 = GanttTask.from(name: "Design", daysFromNow: 0, duration: 7, progress: 0.6, color: .green, group: "Phase 1")
        let task3 = GanttTask.from(name: "Development", daysFromNow: 5, duration: 14, progress: 0.2, color: .orange, group: "Phase 1")
        let task4 = GanttTask.from(name: "Testing", daysFromNow: 15, duration: 7, progress: 0, color: .purple, group: "Phase 2")
        let task5 = GanttTask.from(name: "Deployment", daysFromNow: 20, duration: 3, progress: 0, color: .red, group: "Phase 2")
        
        GanttChart(
            tasks: [task1, task2, task3, task4, task5],
            showDependencies: false
        )
        .frame(height: 300)
        .padding()
    }
}
#endif
