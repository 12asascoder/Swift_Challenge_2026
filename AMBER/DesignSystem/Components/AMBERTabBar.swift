import SwiftUI

struct AMBERTabBar: View {
    @Binding var selected: AMBERTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AMBERTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selected == tab ? .bold : .regular))
                            .foregroundColor(selected == tab ? .amberAccent : .amberSubtext)
                        if selected == tab {
                            Circle()
                                .fill(Color.amberAccent)
                                .frame(width: 4, height: 4)
                        } else {
                            Color.clear.frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            Rectangle()
                .fill(Color.amberCard)
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    Rectangle()
                        .fill(Color.amberCardBorder)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}
