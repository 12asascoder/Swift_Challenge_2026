import SwiftUI
import UserNotifications

// MARK: - Notification Settings Store (persisted)
class NotificationSettings: ObservableObject {
    private let ud = UserDefaults.standard

    @Published var dailyReminderEnabled: Bool { didSet { ud.set(dailyReminderEnabled, forKey: "notif_dailyEnabled"); scheduleOrCancelDaily() } }
    @Published var dailyReminderHour: Int      { didSet { ud.set(dailyReminderHour, forKey: "notif_dailyHour"); scheduleOrCancelDaily() } }
    @Published var dailyReminderMinute: Int    { didSet { ud.set(dailyReminderMinute, forKey: "notif_dailyMin"); scheduleOrCancelDaily() } }
    @Published var sessionReminder: Bool       { didSet { ud.set(sessionReminder, forKey: "notif_sessionEnabled") } }
    @Published var streakAlert: Bool           { didSet { ud.set(streakAlert, forKey: "notif_streakAlert") } }

    init() {
        dailyReminderEnabled = ud.bool(forKey: "notif_dailyEnabled")
        dailyReminderHour    = ud.object(forKey: "notif_dailyHour") != nil ? ud.integer(forKey: "notif_dailyHour") : 9
        dailyReminderMinute  = ud.integer(forKey: "notif_dailyMin")
        sessionReminder      = ud.object(forKey: "notif_sessionEnabled") != nil ? ud.bool(forKey: "notif_sessionEnabled") : true
        streakAlert          = ud.object(forKey: "notif_streakAlert") != nil ? ud.bool(forKey: "notif_streakAlert") : true
    }

    private func scheduleOrCancelDaily() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["amber_daily_checkin"])
        guard dailyReminderEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "AMBER Daily Check-in"
        content.body  = "Hey! Time to check your vibe and start a game session 🧠"
        content.sound = .default
        var comps = DateComponents()
        comps.hour   = dailyReminderHour
        comps.minute = dailyReminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "amber_daily_checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}

// MARK: - Account Preferences Store
class AccountPreferences: ObservableObject {
    private let ud = UserDefaults.standard

    @Published var soundEnabled: Bool  { didSet { ud.set(soundEnabled, forKey: "pref_sound") } }
    @Published var hapticsEnabled: Bool { didSet { ud.set(hapticsEnabled, forKey: "pref_haptics") } }
    @Published var avatarColorIndex: Int { didSet { ud.set(avatarColorIndex, forKey: "pref_avatarColor") } }
    @Published var showStreakOnHome: Bool { didSet { ud.set(showStreakOnHome, forKey: "pref_streakHome") } }

    init() {
        soundEnabled     = ud.object(forKey: "pref_sound")    != nil ? ud.bool(forKey: "pref_sound")    : true
        hapticsEnabled   = ud.object(forKey: "pref_haptics")  != nil ? ud.bool(forKey: "pref_haptics")  : true
        avatarColorIndex = ud.object(forKey: "pref_avatarColor") != nil ? ud.integer(forKey: "pref_avatarColor") : 0
        showStreakOnHome  = ud.object(forKey: "pref_streakHome") != nil ? ud.bool(forKey: "pref_streakHome") : true
    }

    static let avatarColors: [Color] = [
        Color(red: 0.9, green: 0.65, blue: 0.1),    // Amber (default)
        Color(red: 0.0, green: 0.80, blue: 0.75),   // Cyan
        Color(red: 0.6, green: 0.35, blue: 0.90),   // Violet
        Color(red: 1.0, green: 0.42, blue: 0.42),   // Coral
        Color(red: 0.42, green: 0.80, blue: 0.50)   // Sage
    ]
    var selectedColor: Color { Self.avatarColors[avatarColorIndex] }
}

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var notifSettings  = NotificationSettings()
    @StateObject private var accountPrefs   = AccountPreferences()

    @State private var showResetAlert       = false
    @State private var editingName          = false
    @State private var draftName            = ""
    @State private var showNotifSheet       = false
    @State private var showAccountSheet     = false
    @State private var notifPermDenied      = false

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
        .alert("Notifications Disabled", isPresented: $notifPermDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications for AMBER in iOS Settings to use reminders.")
        }
        .sheet(isPresented: $editingName) {
            NameEditSheet(name: $draftName) { dataStore.userName = draftName; editingName = false }
        }
        .sheet(isPresented: $showNotifSheet) {
            NotificationSettingsSheet(settings: notifSettings, onPermDenied: { notifPermDenied = true })
        }
        .sheet(isPresented: $showAccountSheet) {
            AccountPreferencesSheet(prefs: accountPrefs, dataStore: dataStore,
                                    onEditName: { draftName = dataStore.userName; showAccountSheet = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { editingName = true } })
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
            ZStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [accountPrefs.selectedColor.opacity(0.3), .clear],
                            center: .center, startRadius: 30, endRadius: 70))
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(accountPrefs.selectedColor, lineWidth: 3)
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.amberCard)
                        .frame(width: 96, height: 96)
                    Image(systemName: "person.fill")
                        .font(.system(size: 46))
                        .foregroundColor(accountPrefs.selectedColor.opacity(0.9))
                }
                Text("LVL \(dataStore.level)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accountPrefs.selectedColor))
                    .offset(y: 14)
            }
            .padding(.bottom, 14)

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

    // MARK: - Settings (tappable)
    private var settingsSection: some View {
        VStack(spacing: 1) {
            TappableSettingsRow(icon: "person.circle", label: "Account Preferences") {
                showAccountSheet = true
            }
            Divider().background(Color.amberCardBorder)
            TappableSettingsRow(icon: "bell", label: "Notification Settings") {
                showNotifSheet = true
            }
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

// MARK: - Notification Settings Sheet
struct NotificationSettingsSheet: View {
    @ObservedObject var settings: NotificationSettings
    let onPermDenied: () -> Void
    @Environment(\.dismiss) var dismiss

    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }

    // Binding for a Date to drive the time picker
    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = settings.dailyReminderHour; c.minute = settings.dailyReminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                settings.dailyReminderHour   = c.hour   ?? 9
                settings.dailyReminderMinute = c.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.amberBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        // Daily check-in reminder
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("DAILY CHECK-IN")

                            settingsToggleRow(
                                icon: "bell.badge",
                                label: "Daily Reminder",
                                subtitle: "Get nudged to check in every day",
                                isOn: Binding(
                                    get: { settings.dailyReminderEnabled },
                                    set: { newVal in
                                        if newVal {
                                            settings.requestPermission { granted in
                                                if granted { settings.dailyReminderEnabled = true }
                                                else { onPermDenied() }
                                            }
                                        } else {
                                            settings.dailyReminderEnabled = false
                                        }
                                    }
                                )
                            )

                            if settings.dailyReminderEnabled {
                                Divider().background(Color.amberCardBorder).padding(.horizontal, 18)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reminder Time")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("When should we remind you?")
                                            .font(.system(size: 12))
                                            .foregroundColor(.amberSubtext)
                                    }
                                    Spacer()
                                    DatePicker("", selection: reminderDate, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .tint(amber)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .animation(.easeInOut(duration: 0.25), value: settings.dailyReminderEnabled)

                        // Session & streak alerts
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("SESSION & STREAKS")

                            settingsToggleRow(
                                icon: "flame.fill",
                                label: "Streak Alerts",
                                subtitle: "Warn when your streak is at risk",
                                isOn: $settings.streakAlert
                            )
                            Divider().background(Color.amberCardBorder).padding(.horizontal, 18)
                            settingsToggleRow(
                                icon: "clock.arrow.circlepath",
                                label: "Session Reminders",
                                subtitle: "Remind you to complete a session",
                                isOn: $settings.sessionReminder
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.amberSubtext)
            .kerning(2)
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func settingsToggleRow(icon: String, label: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.amberIconBG).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16)).foregroundColor(.amberAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.amberSubtext)
            }
            Spacer()
            Toggle("", isOn: isOn).tint(amber).labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Account Preferences Sheet
struct AccountPreferencesSheet: View {
    @ObservedObject var prefs: AccountPreferences
    @ObservedObject var dataStore: DataStore
    let onEditName: () -> Void
    @Environment(\.dismiss) var dismiss

    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }

    var body: some View {
        NavigationView {
            ZStack {
                Color.amberBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile identity
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("IDENTITY")

                            // Name row
                            Button(action: { dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onEditName() } }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.amberIconBG).frame(width: 40, height: 40)
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16)).foregroundColor(.amberAccent)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Display Name").font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                                        Text(dataStore.userName).font(.system(size: 13)).foregroundColor(.amberSubtext)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.amberSubtext).font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color.amberCardBorder).padding(.horizontal, 18)

                            // Avatar color picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avatar Colour")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                HStack(spacing: 14) {
                                    ForEach(AccountPreferences.avatarColors.indices, id: \.self) { i in
                                        let color = AccountPreferences.avatarColors[i]
                                        let selected = prefs.avatarColorIndex == i
                                        Circle()
                                            .fill(color)
                                            .frame(width: 34, height: 34)
                                            .overlay(Circle().stroke(Color.white, lineWidth: selected ? 2.5 : 0))
                                            .scaleEffect(selected ? 1.15 : 1.0)
                                            .shadow(color: selected ? color.opacity(0.6) : .clear, radius: 6)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3)) {
                                                    prefs.avatarColorIndex = i
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // Audio & haptics
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("AUDIO & FEEDBACK")

                            prefToggleRow(icon: "speaker.wave.2.fill", label: "Sound Effects",
                                          subtitle: "In-game audio and ambient music", isOn: $prefs.soundEnabled)
                            Divider().background(Color.amberCardBorder).padding(.horizontal, 18)
                            prefToggleRow(icon: "iphone.radiowaves.left.and.right", label: "Haptic Feedback",
                                          subtitle: "Vibrations on taps and events", isOn: $prefs.hapticsEnabled)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // Display
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("DISPLAY")

                            prefToggleRow(icon: "flame.fill", label: "Show Streak on Home",
                                          subtitle: "Display daily streak badge on home screen", isOn: $prefs.showStreakOnHome)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Account Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.amberSubtext)
            .kerning(2)
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func prefToggleRow(icon: String, label: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.amberIconBG).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.amberAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.amberSubtext)
            }
            Spacer()
            Toggle("", isOn: isOn).tint(amber).labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
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

/// Original static SettingsRow kept for compatibility
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

/// Tappable version used in ProfileView
struct TappableSettingsRow: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
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
