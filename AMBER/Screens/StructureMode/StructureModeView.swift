import SwiftUI

struct StructureModeView: View {
    @StateObject private var vm = StructureModeViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore

    // Drag state
    @State private var draggingIdx: Int? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var dragIsOver: Bool = false

    // Grid frame in global coordinates (set from GeometryReader)
    @State private var gridFrame: CGRect = .zero

    var body: some View {
        ZStack {
            Color(hex: "0A0A07").ignoresSafeArea()
            RadialGradient(colors: [Color.amberAccent.opacity(0.06), .clear],
                           center: .center, startRadius: 0, endRadius: 320)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Spacer(minLength: 10)
                gridView
                Spacer(minLength: 10)
                stabilityBar.padding(.horizontal, 20).padding(.bottom, 12)
                trayView.padding(.horizontal, 16).padding(.bottom, 28)
            }

            // Floating piece that follows finger
            if let idx = draggingIdx, idx < vm.tray.count {
                floatingPiece(piece: vm.tray[idx])
                    .position(dragLocation)
                    .allowsHitTesting(false)
                    .zIndex(10)
            }
        }
        .onAppear { vm.start() }
        .sheet(isPresented: $vm.sessionEnded) { sessionSheet }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button { appState.activeGame = nil } label: {
                Image(systemName: "xmark").foregroundColor(.white)
                    .frame(width: 34, height: 34).background(Circle().fill(Color.amberCard))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("ZEN BLOCKS")
                    .font(.system(size: 12, weight: .bold)).kerning(2.5).foregroundColor(.amberAccent)
                Text("ZEN PROGRESS")
                    .font(.system(size: 9)).foregroundColor(.amberSubtext).kerning(1.5)
            }
            Spacer()
            ZStack {
                Circle().stroke(Color.amberAccent.opacity(0.3), lineWidth: 1.5).frame(width: 34, height: 34)
                Image(systemName: "leaf.fill").foregroundColor(.amberAccent).font(.system(size: 14))
            }
        }
        .padding(.horizontal, 20).padding(.top, 52).padding(.bottom, 10)
    }

    // MARK: - Grid
    private var gridView: some View {
        GeometryReader { geo in
            let cs = max(1, (geo.size.width - CGFloat(StructureModeViewModel.COLS - 1) * 2) / CGFloat(StructureModeViewModel.COLS))
            VStack(spacing: 2) {
                ForEach(0..<StructureModeViewModel.ROWS, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<StructureModeViewModel.COLS, id: \.self) { c in
                            let placed = vm.grid[r][c]
                            ZStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(placed != nil
                                          ? AnyShapeStyle(placed!)
                                          : AnyShapeStyle(Color(hex: "181811")))
                                    .overlay(RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.amberCardBorder.opacity(0.3), lineWidth: 0.5))
                                    .shadow(color: placed != nil ? placed!.opacity(0.3) : .clear, radius: 3)
                            }
                            .frame(width: cs, height: cs)
                        }
                    }
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "111108"))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            dragIsOver ? Color.amberAccent.opacity(0.6) : Color.amberCardBorder.opacity(0.5),
                            lineWidth: dragIsOver ? 1.5 : 1
                        ))
                    // Capture global frame of the grid content area
                    .background(
                        GeometryReader { g in
                            Color.clear.onAppear {
                                gridFrame = g.frame(in: .global)
                            }
                            .onChange(of: geo.size) { _ in
                                gridFrame = g.frame(in: .global)
                            }
                        }
                    )
            )
        }
        .frame(height: gridHeight)
        .padding(.horizontal, 16)
    }

    private var gridHeight: CGFloat {
        let screenW = UIScreen.main.bounds.width - 32
        let cs = max(1, (screenW - CGFloat(StructureModeViewModel.COLS - 1) * 2) / CGFloat(StructureModeViewModel.COLS))
        return cs * CGFloat(StructureModeViewModel.ROWS) + CGFloat(StructureModeViewModel.ROWS - 1) * 2 + 12
    }

    // MARK: - Stability bar
    private var stabilityBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ZEN PROGRESS")
                    .font(.system(size: 10, weight: .bold)).kerning(2).foregroundColor(.amberSubtext)
                Spacer()
                Text("\(Int(vm.stability * 100))%")
                    .font(AMBERFont.mono(12, weight: .bold)).foregroundColor(.amberAccent)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "222215")).frame(height: 6)
                    if g.size.width > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [Color.amberAccentDim, Color.amberAccent],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, g.size.width * vm.stability), height: 6)
                            .animation(.easeOut(duration: 0.4), value: vm.stability)
                    }
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Tray
    private var trayView: some View {
        HStack(spacing: 14) {
            ForEach(Array(vm.tray.enumerated()), id: \.element.id) { idx, piece in
                ZStack {
                    pieceCard(piece: piece, idx: idx)
                        .opacity(draggingIdx == idx ? 0.3 : 1.0)

                    // Rotate button overlay
                    VStack {
                        HStack {
                            Spacer()
                            Button { vm.rotatePiece(at: idx) } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.amberSubtext)
                                    .padding(5)
                                    .background(Circle().fill(Color.amberBG))
                            }
                        }
                        Spacer()
                    }
                    .padding(4)
                }
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .global)
                        .onChanged { val in
                            if draggingIdx == nil { draggingIdx = idx }
                            dragLocation = val.location
                            dragIsOver = gridFrame.contains(val.location)
                        }
                        .onEnded { val in
                            handleDrop(pieceIdx: idx, at: val.location)
                            draggingIdx = nil
                            dragIsOver  = false
                        }
                )
            }
        }
    }

    // MARK: - Piece card (in tray)
    private func pieceCard(piece: BlockPiece, idx: Int) -> some View {
        let maxDim = max(piece.width, piece.height)
        let cs: CGFloat = maxDim <= 2 ? 22 : 18
        return VStack(spacing: 2) {
            ForEach(0..<piece.height, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<piece.width, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(piece.cells[r][c] ? AnyShapeStyle(piece.color) : AnyShapeStyle(Color.clear))
                            .frame(width: cs, height: cs)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }

    // MARK: - Floating piece (drag ghost)
    private func floatingPiece(piece: BlockPiece) -> some View {
        let cs: CGFloat = 28
        return VStack(spacing: 2) {
            ForEach(0..<piece.height, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<piece.width, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(piece.cells[r][c]
                                  ? AnyShapeStyle(piece.color)
                                  : AnyShapeStyle(Color.clear))
                            .frame(width: cs, height: cs)
                            .shadow(color: piece.color.opacity(0.5), radius: 5)
                    }
                }
            }
        }
        .scaleEffect(1.15)
    }

    // MARK: - Drop handler
    private func handleDrop(pieceIdx: Int, at location: CGPoint) {
        guard gridFrame.width > 0, gridFrame.height > 0,
              gridFrame.contains(location),
              pieceIdx < vm.tray.count else { return }

        // Convert global location → grid row/col
        let localX = location.x - gridFrame.minX - 6  // subtract padding
        let localY = location.y - gridFrame.minY - 6
        let cs = (gridFrame.width - 12 - CGFloat(StructureModeViewModel.COLS - 1) * 2) / CGFloat(StructureModeViewModel.COLS)
        guard cs > 0 else { return }

        let piece = vm.tray[pieceIdx]
        let dropCol = max(0, min(StructureModeViewModel.COLS - piece.width,  Int(localX / (cs + 2))))
        let dropRow = max(0, min(StructureModeViewModel.ROWS - piece.height, Int(localY / (cs + 2))))

        withAnimation(.spring(response: 0.2)) {
            vm.tryPlace(pieceIdx: pieceIdx, gridRow: dropRow, gridCol: dropCol)
        }
    }

    // MARK: - Session summary
    private var sessionSheet: some View {
        ZStack {
            Color(hex: "0A0A07").ignoresSafeArea()
            VStack(spacing: 22) {
                Text("✦ Session Complete")
                    .font(.system(size: 22, weight: .black)).foregroundColor(.white).padding(.top, 40)
                Text(String(format: "Zen Progress: %.0f%%", vm.stability * 100))
                    .font(.system(size: 18, weight: .semibold)).foregroundColor(.amberAccent)
                HStack(spacing: 12) {
                    Button { vm.sessionEnded = false; vm.start() } label: {
                        Text("Play Again")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberAccent))
                    }
                    Button { vm.sessionEnded = false; appState.activeGame = nil } label: {
                        Text("Exit")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RoundedRectangle(cornerRadius: 14)
                                .fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder)))
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}
