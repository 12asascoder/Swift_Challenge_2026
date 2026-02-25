import SwiftUI

// MARK: - Zen Blocks View

struct StructureModeView: View {
    @StateObject private var vm = StructureModeViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore

    // Drag state
    @State private var draggingIdx: Int? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var shakeOffset: CGFloat = 0
    @State private var highlightCells: Set<GridPos> = []

    // Grid geometry
    @State private var gridFrame: CGRect = .zero

    // Ambient particles
    @State private var particlePhase: CGFloat = 0

    struct GridPos: Hashable { let r: Int; let c: Int }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0A07").ignoresSafeArea()
            RadialGradient(
                colors: [Color.amberAccent.opacity(0.06), .clear],
                center: .center, startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            // Ambient particles
            ambientParticles

            VStack(spacing: 0) {
                headerBar
                Spacer(minLength: 10)
                gridView
                Spacer(minLength: 10)
                stabilityBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                trayView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
            }

            // Floating ghost piece during drag
            if let idx = draggingIdx, idx < vm.tray.count {
                ghostPiece(for: vm.tray[idx])
            }

            // Zen glow overlay at 100%
            if vm.showZenGlow {
                zenGlowOverlay
            }
        }
        .onAppear {
            vm.start(difficulty: appState.gameDifficulty)
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }
        }
        .sheet(isPresented: $vm.sessionEnded) {
            sessionSummarySheet
        }
        .offset(x: shakeOffset)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button {
                appState.activeGame = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.amberSubtext)
            }

            Spacer()

            Text("Zen Blocks")
                .font(AMBERFont.rounded(20, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Grid View

    private var gridView: some View {
        GeometryReader { geo in
            let pad: CGFloat = 6
            let spacing: CGFloat = 2
            let availableW = geo.size.width - pad * 2
            let cs = max(1, (availableW - CGFloat(GridEngine.cols - 1) * spacing) / CGFloat(GridEngine.cols))
            let totalW = CGFloat(GridEngine.cols) * cs + CGFloat(GridEngine.cols - 1) * spacing + pad * 2
            let totalH = CGFloat(GridEngine.rows) * cs + CGFloat(GridEngine.rows - 1) * spacing + pad * 2

            VStack(spacing: spacing) {
                ForEach(0..<GridEngine.rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<GridEngine.cols, id: \.self) { col in
                            cellView(row: row, col: col, size: cs)
                        }
                    }
                }
            }
            .padding(pad)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "111110"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.amberAccent.opacity(0.12), lineWidth: 1)
                    )
            )
            .frame(width: totalW, height: totalH)
            .background(
                GeometryReader { inner in
                    Color.clear
                        .onAppear { gridFrame = inner.frame(in: .global) }
                        .onChange(of: geo.size) { _ in
                            gridFrame = inner.frame(in: .global)
                        }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 16)
    }

    private func cellView(row: Int, col: Int, size: CGFloat) -> some View {
        let cell: GridCell = {
            guard vm.grid.indices.contains(row),
                  vm.grid[row].indices.contains(col) else { return GridCell() }
            return vm.grid[row][col]
        }()
        let lit = highlightCells.contains(GridPos(r: row, c: col))

        return RoundedRectangle(cornerRadius: 3)
            .fill(cellFill(cell, lit: lit))
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(cellStroke(cell, lit: lit), lineWidth: 0.5)
            )
            .opacity(cell.isClearing ? 0.3 : 1.0)
            .animation(.easeOut(duration: 0.25), value: cell.isClearing)
    }

    private func cellFill(_ cell: GridCell, lit: Bool) -> Color {
        if cell.isClearing { return Color.amberAccent.opacity(0.6) }
        if cell.isOccupied { return cell.color ?? Color.amberAccent.opacity(0.7) }
        if lit { return Color.amberAccent.opacity(0.18) }
        return Color(hex: "1A1A12")
    }

    private func cellStroke(_ cell: GridCell, lit: Bool) -> Color {
        if cell.isClearing { return Color.amberAccent.opacity(0.8) }
        if cell.isOccupied { return (cell.color ?? Color.amberAccent).opacity(0.4) }
        if lit { return Color.amberAccent.opacity(0.3) }
        return Color(hex: "2E2D1A").opacity(0.5)
    }

    // MARK: - Zen Progress Bar

    private var stabilityBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Zen")
                    .font(AMBERFont.mono(11, weight: .medium))
                    .foregroundColor(Color.amberSubtext)
                Spacer()
                Text("\(Int(vm.zenProgress * 100))%")
                    .font(AMBERFont.mono(11, weight: .semibold))
                    .foregroundColor(Color.amberAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "1A1A12"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.amberAccentDim, Color.amberAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(vm.zenProgress),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.4), value: vm.zenProgress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Tray View

    private var trayView: some View {
        HStack(spacing: 20) {
            ForEach(Array(vm.tray.enumerated()), id: \.element.id) { idx, block in
                VStack(spacing: 8) {
                    blockPreview(block)
                        .opacity(draggingIdx == idx ? 0.3 : 1.0)
                        .gesture(dragGesture(for: idx))

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            vm.rotatePiece(at: idx)
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.amberSubtext)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "131310").opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "2E2D1A").opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func blockPreview(_ block: Block) -> some View {
        let s: CGFloat = 14
        let sp: CGFloat = 2
        return VStack(spacing: sp) {
            ForEach(0..<block.height, id: \.self) { r in
                HStack(spacing: sp) {
                    ForEach(0..<block.width, id: \.self) { c in
                        if block.shape[r][c] == 1 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(block.color.opacity(0.85))
                                .frame(width: s, height: s)
                        } else {
                            Color.clear.frame(width: s, height: s)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Drag Gesture

    private func dragGesture(for idx: Int) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                draggingIdx = idx
                dragLocation = value.location
                updateHighlight(for: idx, at: value.location)
            }
            .onEnded { value in
                attemptDrop(idx: idx, at: value.location)
                draggingIdx = nil
                highlightCells = []
            }
    }

    private func updateHighlight(for idx: Int, at loc: CGPoint) {
        guard idx < vm.tray.count else {
            highlightCells = []
            return
        }
        let block = vm.tray[idx]
        guard let snap = GridEngine.snapToGrid(
            location: loc,
            gridFrame: gridFrame,
            block: block
        ) else {
            highlightCells = []
            return
        }

        var cells = Set<GridPos>()
        if GridEngine.canPlace(block, at: snap.row, col: snap.col, in: vm.grid) {
            for r in 0..<block.height {
                for c in 0..<block.width where block.shape[r][c] == 1 {
                    cells.insert(GridPos(r: snap.row + r, c: snap.col + c))
                }
            }
        }
        highlightCells = cells
    }

    private func attemptDrop(idx: Int, at loc: CGPoint) {
        guard idx < vm.tray.count else { return }
        let block = vm.tray[idx]
        guard let snap = GridEngine.snapToGrid(
            location: loc,
            gridFrame: gridFrame,
            block: block
        ) else {
            triggerShake()
            return
        }

        let placed = vm.tryPlace(pieceIdx: idx, gridRow: snap.row, gridCol: snap.col)
        if !placed {
            triggerShake()
        }
    }

    private func triggerShake() {
        withAnimation(.easeInOut(duration: 0.06).repeatCount(4, autoreverses: true)) {
            shakeOffset = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.1)) {
                shakeOffset = 0
            }
        }
    }

    // MARK: - Ghost Piece

    private func ghostPiece(for block: Block) -> some View {
        let s: CGFloat = 24
        let sp: CGFloat = 2
        return VStack(spacing: sp) {
            ForEach(0..<block.height, id: \.self) { r in
                HStack(spacing: sp) {
                    ForEach(0..<block.width, id: \.self) { c in
                        if block.shape[r][c] == 1 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(block.color.opacity(0.6))
                                .frame(width: s, height: s)
                        } else {
                            Color.clear.frame(width: s, height: s)
                        }
                    }
                }
            }
        }
        .position(dragLocation)
        .allowsHitTesting(false)
    }

    // MARK: - Zen Glow Overlay

    private var zenGlowOverlay: some View {
        Color.amberAccent.opacity(0.08)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
    }

    // MARK: - Ambient Particles

    private var ambientParticles: some View {
        Canvas { context, size in
            let count = 25
            let phase: Double = Double(particlePhase)
            let w: Double = Double(size.width)
            let h: Double = Double(size.height)

            for i in 0..<count {
                let seed: Double = Double(i) / Double(count)
                let angX: Double = seed * .pi * 4 + phase * .pi * 2
                let angY: Double = seed * .pi * 3 + phase * .pi * 2 * 0.7
                let x: CGFloat = CGFloat((sin(angX) * 0.5 + 0.5) * w)
                let y: CGFloat = CGFloat((cos(angY) * 0.5 + 0.5) * h)
                let radius: CGFloat = CGFloat(2.0 + seed * 3.0)
                let alpha: Double = 0.04 + seed * 0.06
                let rect = CGRect(
                    x: x - radius, y: y - radius,
                    width: radius * 2, height: radius * 2
                )
                context.opacity = alpha
                context.fill(Path(ellipseIn: rect), with: .color(Color.amberAccent))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Session Summary Sheet

    private var sessionSummarySheet: some View {
        VStack(spacing: 28) {
            Text("Session Complete")
                .font(AMBERFont.rounded(24, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                summaryRow(label: "Lines Cleared", value: "\(vm.linesCleared)")
                summaryRow(
                    label: "Clean Placement",
                    value: "\(Int(vm.cleanPlacementPercent * 100))%"
                )
                summaryRow(label: "Duration", value: vm.sessionDurationFormatted)
                summaryRow(label: "Zen Progress", value: "\(Int(vm.zenProgress * 100))%")
            }

            Button {
                vm.sessionEnded = false
                appState.completeSession(
                    score: vm.linesCleared * 10,
                    xp: vm.linesCleared * 5
                )
            } label: {
                Text("Done")
                    .font(AMBERFont.rounded(16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.amberAccent)
                    )
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(Color(hex: "111110").ignoresSafeArea())
        .presentationDetents([.medium])
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AMBERFont.mono(14))
                .foregroundColor(Color.amberSubtext)
            Spacer()
            Text(value)
                .font(AMBERFont.mono(16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
