import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showResetAlert = false
    @State private var editingName    = false
    @State private var draftName      = ""

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    navBar
                    avatarSection
                    statCardsRow
                    tierSection
                    personalBests
                    settingsSection
                    resetButton
                    Spacer(minLength: 100)
                }
            }
        }
        .alert("Reset Training Data", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { dataStore.resetAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently erase all your XP, sessions, combos and streaks. This cannot be undone.")
        }
        .sheet(isPresented: $editingName) {
            NameEditSheet(name: $draftName) { dataStore.userName = draftName; editingName = false }
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.amberCard))
            Spacer()
            Text("Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundColor(.amberSubtext)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Avatar section
    private var avatarSection: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.amberAccent.opacity(0.3), .clear],
                            center: .center, startRadius: 30, endRadius: 70))
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(Color.amberAccent, lineWidth: 3)
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.amberCard)
                        .frame(width: 96, height: 96)
                    Image(systemName: "person.fill")
                        .font(.system(size: 46))
                        .foregroundColor(.amberAccent.opacity(0.9))
                }
                // Level badge
                Text("LVL \(dataStore.level)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.amberAccent))
                    .offset(y: 14)
            }
            .padding(.bottom, 14)

            // Name (tappable to edit)
            Button { draftName = dataStore.userName; editingName = true } label: {
                Text(dataStore.userName)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }

            Text(dataStore.userTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.amberAccent)
            Text(dataStore.joinDateString)
                .font(.system(size: 13))
                .foregroundColor(.amberSubtext)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Stats row
    private var statCardsRow: some View {
        HStack(spacing: 10) {
            ProfileStatPill(label: "TOTAL XP",  value: dataStore.xp >= 1000 ? String(format: "%.1fk", Double(dataStore.xp)/1000) : "\(dataStore.xp)")
            ProfileStatPill(label: "SESSIONS",  value: "\(dataStore.totalSessions)")
            ProfileStatPill(label: "STREAK",    value: "\(dataStore.streak)d")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Tier section
    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT TIER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.amberSubtext)
                        .kerning(1.5)
                    Text(dataStore.tierName)
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.amberAccent)
                }
                Spacer()
                Text("\(dataStore.tierXP) / \(dataStore.tierMaxXP) XP")
                    .font(AMBERFont.mono(13, weight: .bold))
                    .foregroundColor(.amberSubtext)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.amberButtonOlive).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(Color.amberAccent)
                        .frame(width: g.size.width * dataStore.levelProgress, height: 8)
                }
            }
            .frame(height: 8)
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12))
                    .foregroundColor(.amberSubtext)
                Text("Amber Elite Member")
                    .font(.system(size: 12))
                    .foregroundColor(.amberSubtext)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Personal Bests
    private var personalBests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERSONAL BESTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(2)
                .padding(.horizontal, 16)

            VStack(spacing: 1) {
                PersonalBestRow(
                    icon: "scope",
                    title: "Focus Arena",
                    subtitle: "Peak Performance",
                    value: dataStore.bestFocusAccuracy > 0 ? String(format: "%.1f", dataStore.bestFocusAccuracy) : "—",
                    metricLabel: "ACCURACY %"
                )
                Divider().background(Color.amberCardBorder)
                PersonalBestRow(
                    icon: "square.grid.2x2",
                    title: "Flow Grid",
                    subtitle: "Mental Speed",
                    value: dataStore.bestFlowScore > 0 ? "\(dataStore.bestFlowScore)" : "—",
                    metricLabel: "K-SCORE"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.amberCard)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Settings
    private var settingsSection: some View {
        VStack(spacing: 1) {
            SettingsRow(icon: "person.circle", label: "Account Preferences")
            Divider().background(Color.amberCardBorder)
            SettingsRow(icon: "bell", label: "Notification Settings")
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Reset button
    private var resetButton: some View {
        Button { showResetAlert = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                Text("RESET TRAINING DATA")
                    .font(.system(size: 14, weight: .bold))
                    .kerning(0.5)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Supporting Subviews

struct ProfileStatPill: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }
}

struct PersonalBestRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let metricLabel: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.amberIconBG)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.amberAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.amberSubtext)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(AMBERFont.mono(22, weight: .black))
                    .foregroundColor(.amberAccent)
                Text(metricLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.amberSubtext)
                    .kerning(0.8)
            }
        }
        .padding(16)
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.amberSubtext)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.amberSubtext)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Name Edit Sheet
struct NameEditSheet: View {
    @Binding var name: String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.amberBG.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Your name", text: $name)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberCard)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder)))
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave() }.foregroundColor(.amberAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
