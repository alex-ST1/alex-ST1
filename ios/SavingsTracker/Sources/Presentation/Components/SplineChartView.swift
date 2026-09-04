import SwiftUI

/// High-performance curved Bezier spline chart with interactive touch tooltips.
public struct SplineChartView: View {

    public let records: [MonthlyRecord]
    public let currency: CurrencyType
    public let targetGoal: Decimal

    @Binding public var selectedTimeframe: String // "3M", "6M", "1Y"
    @State private var selectedIndex: Int? = nil

    public init(
        records: [MonthlyRecord],
        currency: CurrencyType,
        targetGoal: Decimal,
        selectedTimeframe: Binding<String>
    ) {
        self.records = records
        self.currency = currency
        self.targetGoal = targetGoal
        self._selectedTimeframe = selectedTimeframe
    }

    private var filteredRecords: [MonthlyRecord] {
        let count: Int
        switch selectedTimeframe {
        case "3M": count = 3
        case "6M": count = 6
        case "1Y": count = 12
        default: count = 6
        }
        return Array(records.suffix(count))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Timeframe Control
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppTheme.emeraldLight)
                        .font(.system(size: 14, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Savings Trajectory")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Monthly progression vs target")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()

                // Segmented picker
                HStack(spacing: 4) {
                    ForEach(["3M", "6M", "1Y"], id: \.self) { tf in
                        Button {
                            AppTheme.triggerHaptic(style: .light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTimeframe = tf
                                selectedIndex = nil
                            }
                        } label: {
                            Text(tf)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    selectedTimeframe == tf
                                        ? Color.white.opacity(0.12)
                                        : Color.clear
                                )
                                .foregroundColor(
                                    selectedTimeframe == tf
                                        ? .white
                                        : AppTheme.textSecondary
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(3)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            }

            // Chart Canvas
            GeometryReader { geometry in
                let points = computePoints(for: filteredRecords, in: geometry.size)

                ZStack {
                    // Target Reference Dashed Line
                    if let targetY = computeTargetY(in: geometry.size) {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: targetY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: targetY))
                        }
                        .stroke(AppTheme.amber.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))

                        Text("Target \(currency.format(amount: targetGoal))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.amber.opacity(0.85))
                            .position(x: geometry.size.width - 45, y: targetY - 8)
                    }

                    // Curved Gradient Area
                    if points.count >= 2 {
                        SplineAreaShape(points: points, bottomY: geometry.size.height - 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.emerald.opacity(0.35),
                                        AppTheme.emerald.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Curved Stroke Line
                        SplineLineShape(points: points)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.emerald, AppTheme.emeraldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                    }

                    // Interactive Point Markers & Labels
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let isLast = index == points.count - 1
                        let isSelected = selectedIndex == index || (selectedIndex == nil && isLast)

                        // Outer Glow Ring
                        Circle()
                            .stroke(AppTheme.emerald, lineWidth: isSelected ? 2.5 : 1.5)
                            .background(Circle().fill(AppTheme.background))
                            .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                            .position(point)
                            .shadow(color: AppTheme.emerald.opacity(isSelected ? 0.6 : 0), radius: 6)

                        // Month Label
                        if index < filteredRecords.count {
                            Text(filteredRecords[index].shortLabel.prefix(3))
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? AppTheme.emeraldLight : AppTheme.textSecondary)
                                .position(x: point.x, y: geometry.size.height - 8)
                        }
                    }

                    // Active Tooltip HUD
                    if let activeIdx = selectedIndex ?? (filteredRecords.isEmpty ? nil : filteredRecords.count - 1),
                       activeIdx < points.count && activeIdx < filteredRecords.count {
                        let activeRecord = filteredRecords[activeIdx]
                        let point = points[activeIdx]

                        VStack(spacing: 2) {
                            Text(activeRecord.shortLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            Text(currency.format(amount: activeRecord.saved))
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(AppTheme.emeraldLight)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.emerald.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        )
                        .position(x: min(max(point.x, 60), geometry.size.width - 60), y: max(22, point.y - 32))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let closest = points.enumerated().min(by: { abs($0.element.x - value.location.x) < abs($1.element.x - value.location.x) })
                            if let newIndex = closest?.offset, newIndex != selectedIndex {
                                selectedIndex = newIndex
                                AppTheme.triggerHaptic(style: .light)
                            }
                        }
                )
            }
            .frame(height: 180)
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Point & Curve Computation

    private func computePoints(for records: [MonthlyRecord], in size: CGSize) -> [CGPoint] {
        guard records.count > 1 else { return [] }

        let padLeft: CGFloat = 16
        let padRight: CGFloat = 16
        let padTop: CGFloat = 34
        let bottomY = size.height - 24

        let maxRecord = records.map { $0.saved }.max() ?? Decimal.zero
        let maxBaseline = max(targetGoal, Decimal(25000))
        let maxDecimal = max(maxRecord, maxBaseline)
        let maxVal = NSDecimalNumber(decimal: maxDecimal).doubleValue * 1.15

        let width = size.width - padLeft - padRight
        let chartHeight = bottomY - padTop

        return records.enumerated().map { index, record in
            let x = padLeft + (CGFloat(index) / CGFloat(records.count - 1)) * width
            let normY = CGFloat((record.saved as NSDecimalNumber).doubleValue / maxVal)
            let y = bottomY - (normY * chartHeight)
            return CGPoint(x: x, y: y)
        }
    }

    private func computeTargetY(in size: CGSize) -> CGFloat? {
        guard targetGoal > 0, let maxSaved = filteredRecords.map({ $0.saved }).max() else { return nil }
        let maxBaseline = max(targetGoal, Decimal(25000))
        let maxDecimal = max(maxSaved, maxBaseline)
        let maxVal = NSDecimalNumber(decimal: maxDecimal).doubleValue * 1.15

        let padTop: CGFloat = 34
        let bottomY = size.height - 24
        let chartHeight = bottomY - padTop

        let normY = CGFloat((targetGoal as NSDecimalNumber).doubleValue / maxVal)
        return bottomY - (normY * chartHeight)
    }
}

// MARK: - Cubic Bezier Spline Path Shapes

struct SplineLineShape: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            let cp1x = p1.x + (p2.x - p0.x) / 6
            let cp1y = p1.y + (p2.y - p0.y) / 6

            let cp2x = p2.x - (p3.x - p1.x) / 6
            let cp2y = p2.y - (p3.y - p1.y) / 6

            path.addCurve(to: p2, control1: CGPoint(x: cp1x, y: cp1y), control2: CGPoint(x: cp2x, y: cp2y))
        }

        return path
    }
}

struct SplineAreaShape: Shape {
    var points: [CGPoint]
    var bottomY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = SplineLineShape(points: points).path(in: rect)
        guard let first = points.first, let last = points.last else { return path }

        path.addLine(to: CGPoint(x: last.x, y: bottomY))
        path.addLine(to: CGPoint(x: first.x, y: bottomY))
        path.closeSubpath()
        return path
    }
}
