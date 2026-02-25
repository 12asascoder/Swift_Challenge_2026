import SwiftUI

struct GameCardView: View {
    let game: GameType
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.amberIconBG)
                        .frame(width: 50, height: 50)
                    Image(systemName: game.systemIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.amberAccent)
                }

                Text(game.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(game.description)
                    .font(.system(size: 14))
                    .foregroundColor(.amberSubtext)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(game.statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.amberAccent)
                    Spacer()
                    Button(action: onTap) {
                        HStack(spacing: 4) {
                            Text(game.buttonLabel)
                                .font(.system(size: 14, weight: .semibold))
                            if game.isPrimaryButton {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .foregroundColor(game.isPrimaryButton ? .black : .white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(game.isPrimaryButton ? Color.amberAccent : Color.amberButtonOlive)
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.amberCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.amberCardBorder, lineWidth: 1)
                    )
            )

            // Badge
            if let badge = game.badge {
                Text(badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.amberAccent))
                    .padding(14)
            }
        }
    }
}
