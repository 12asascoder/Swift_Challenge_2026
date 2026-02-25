import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.fill")
                .foregroundColor(.amberAccent)
                .font(.system(size: 16))
            Text("\(streak) DAY STREAK")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .kerning(1.2)
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < streak ? Color.amberAccent : Color.amberSubtext.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.amberCard)
                .overlay(Capsule().stroke(Color.amberCardBorder, lineWidth: 1))
        )
        .padding(.bottom, 8)
    }
}
