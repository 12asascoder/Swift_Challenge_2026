import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategory: AchievementCategory = .all
    @State private var showRewardClaimed = false

    private var achievements: [Achievement] { DataStore.buildAchievements(from: dataStore) }

    private var filtered: [Achievement] {
        selectedCategory == .all ? achievements : achievements.filter { $0.category == selectedCategory }
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.amberBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                    profileMiniCard
                    filterPills
                    achievementGrid
                    Spacer(minLength: 120)
                }
            }
            rewardBanner
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(.amberAccent)
                    .font(.system(size: 18))
                Text("AMBER")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.amberAccent)
                    Text("LVL \(dataStore.level)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.amberAccent)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.amberCard)
                    .overlay(Capsule().stroke(Color.amberAccent.opacity(0.5), lineWidth: 1)))

                Image(systemName: "bell.fill")
                    .foregroundColor(.amberSubtext)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Profile mini card
    private var profileMiniCard: some View {
        VStack(spacing: 14) {
            // Avatar + name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.amberAccent, lineWidth: 2.5)
                        .frame(width: 60, height: 60)
                    Circle()
                        .fill(Color.amberCard)
                        .frame(width: 55, height: 55)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.amberAccent.opacity(0.8))
                    // Badge
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.amberAccent)
                        .offset(x: 18, y: 18)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataStore.userName)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                    Text("\(dataStore.xp > 1000 ? String(format: "%.1f", Double(dataStore.xp)/1000) + "K" : "\(dataStore.xp)") XP Total Bonus")
                        .font(.system(size: 13))
                        .foregroundColor(.amberSubtext)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Stats row
            HStack(spacing: 12) {
                MiniProfileStat(
                    label: "ACHIEVEMENTS",
                    value: "\(dataStore.completedCount)/\(DataStore.buildAchievements(from: dataStore).count)",
                    progress: Double(dataStore.completedCount) / max(1, Double(DataStore.buildAchievements(from: dataStore).count))
                )
                MiniProfileStat(
                    label: "GLOBAL RANK",
                    value: "#\(max(1, 1204 - dataStore.xp / 10))",
                    delta: "+12%",
                    subtitle: "Top 5% of all users"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.amberCardBorder, lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    // MARK: - Filter pills
    private var filterPills: some View {
        HStack(spacing: 10) {
            ForEach(AchievementCategory.allCases, id: \.self) { cat in
                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = cat } } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedCategory == cat ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedCategory == cat ? Color.amberAccent : Color.amberCard)
                                .overlay(Capsule().stroke(Color.amberCardBorder, lineWidth: selectedCategory == cat ? 0 : 1))
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filtered) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.25), value: selectedCategory)
    }

    // MARK: - Weekly Reward Banner
    private var rewardBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.amberAccent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.amberAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Weekly Reward Ready")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Claim 500 Amber Shards")
                    .font(.system(size: 12))
                    .foregroundColor(.amberSubtext)
            }
            Spacer()
            Button {
                withAnimation(.spring()) { showRewardClaimed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showRewardClaimed = false }
            } label: {
                Text(showRewardClaimed ? "✓ CLAIMED" : "CLAIM")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(showRewardClaimed ? Color.green : Color.amberAccent))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.amberCardBorder, lineWidth: 1))
                .shadow(color: Color.amberAccent.opacity(0.1), radius: 12)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 80)
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? Color.amberAccent.opacity(0.2) : Color(hex: "222215"))
                    .frame(width: 52, height: 52)
                if achievement.isCompleted {
                    Circle()
                        .stroke(Color.amberAccent.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                }
                Image(systemName: achievement.systemIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(achievement.isCompleted ? .amberAccent : .amberSubtext)
            }

            // Text
            Text(achievement.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(achievement.description)
                .font(.system(size: 12))
                .foregroundColor(.amberSubtext)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Progress
            VStack(alignment: .leading, spacing: 5) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.amberButtonOlive).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(achievement.isCompleted ? Color.green : Color.amberAccent)
                            .frame(width: g.size.width * achievement.progress, height: 5)
                    }
                }
                .frame(height: 5)

                if achievement.isCompleted {
                    Text("Completed")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text(achievement.progressLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.amberSubtext)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.amberCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(achievement.isCompleted ? Color.amberAccent.opacity(0.4) : Color.amberCardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Mini Profile Stat
struct MiniProfileStat: View {
    let label: String
    let value: String
    var delta: String = ""
    var subtitle: String = ""
    var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                if !delta.isEmpty {
                    Text(delta)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.amberSubtext)
            }
            if progress > 0 {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.amberButtonOlive).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3).fill(Color.amberAccent)
                            .frame(width: g.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.amberBG)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }
}
