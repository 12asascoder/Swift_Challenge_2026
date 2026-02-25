import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var ringAnimate = false

    private let days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.amberSubtext)
                        Spacer()
                        Text("Stats & Streaks")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.amberSubtext)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Streak Ring
                    streakRing
                        .padding(.bottom, 28)

                    // Weekly goal bar
                    weeklyGoalBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    // Stat cards
                    if sizeClass == .regular {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            statCards
                        }
                        .padding(.horizontal, 20)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            statCards
                        }
                        .padding(.horizontal, 20)
                    }

                    // Mood Trends chart
                    moodTrendsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { ringAnimate = true } }
    }

    // MARK: - Streak Ring
    private var streakRing: some View {
        ZStack {
            Circle()
                .stroke(Color.amberCard, lineWidth: 10)
                .frame(width: 140, height: 140)
            Circle()
                .trim(from: 0, to: ringAnimate ? min(Double(dataStore.streak) / 7.0, 1.0) : 0)
                .stroke(Color.amberAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.4), value: ringAnimate)
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.amberAccent)
                Text("\(dataStore.streak)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                Text("DAY STREAK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.amberSubtext)
                    .kerning(1.5)
            }
        }
    }

    // MARK: - Weekly Goal
    private var weeklyGoalBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Weekly Goal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(min(dataStore.streak, 7)) / 7 Days")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.amberAccent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.amberButtonOlive).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(Color.amberAccent)
                        .frame(width: geo.size.width * min(Double(dataStore.streak) / 7.0, 1.0) * (ringAnimate ? 1 : 0), height: 8)
                        .animation(.easeOut(duration: 1.2), value: ringAnimate)
                }
            }
            .frame(height: 8)
            Text(dataStore.streak >= 7 ? "You're on fire! Keep the momentum going." : "Keep going, you're building momentum!")
                .font(.system(size: 13).italic())
                .foregroundColor(.amberSubtext)
        }
    }

    // MARK: - Stat Cards
    @ViewBuilder
    private var statCards: some View {
        // Sessions
        StatCard2(
            icon: "checkmark.circle.fill", iconColor: .amberAccent,
            label: "Sessions",
            mainValue: "\(dataStore.totalSessions)",
            subtitle: "+12% from last week", subtitleColor: .green
        )
        // Total XP
        StatCard2(
            icon: "trophy.fill", iconColor: .amberAccent,
            label: "Total XP",
            mainValue: dataStore.xp >= 1000
                ? String(format: "%.1fK", Double(dataStore.xp)/1000)
                : "\(dataStore.xp)",
            subtitle: "Gold League", subtitleColor: .amberAccent
        )
        // Best Focus
        StatCard2(
            icon: "scope", iconColor: .amberAccent,
            label: "Best Focus",
            mainValue: "\(Int(dataStore.levelProgress * 100))%",
            subtitle: "Deep Work State"
        )
        // Flow Master
        StatCard2(
            icon: "bolt.fill", iconColor: .amberAccent,
            label: "Flow Master",
            mainValue: "Lvl \(dataStore.level)",
            hasProgressBar: true,
            progress: dataStore.levelProgress
        )
    }

    // MARK: - Mood Trends
    private var moodTrendsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Mood Trends")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Past 7 Days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.amberAccent))
            }
            .padding(18)

            // Chart
            Chart {
                ForEach(Array(zip(days, dataStore.moodTrend)), id: \.0) { day, val in
                    LineMark(
                        x: .value("Day", day),
                        y: .value("Mood", val)
                    )
                    .foregroundStyle(Color.amberAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", day),
                        y: .value("Mood", val)
                    )
                    .foregroundStyle(Color.amberAccent)
                    .symbolSize(50)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: days) { val in
                    AxisValueLabel()
                        .foregroundStyle(Color.amberSubtext)
                        .font(.system(size: 10))
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
            .frame(height: 130)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }
}

// MARK: - Stat Card
struct StatCard2: View {
    let icon: String
    let iconColor: Color
    let label: String
    let mainValue: String
    var subtitle: String = ""
    var subtitleColor: Color = Color.amberSubtext
    var hasProgressBar: Bool = false
    var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.amberSubtext)
            }
            Text(mainValue)
                .font(.system(size: 30, weight: .black))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)

            if hasProgressBar {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.amberButtonOlive).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3).fill(Color.amberAccent)
                            .frame(width: g.size.width * progress, height: 5)
                    }
                }
                .frame(height: 5)
            } else if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(subtitleColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }
}
