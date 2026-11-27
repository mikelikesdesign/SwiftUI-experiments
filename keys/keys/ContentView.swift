import SwiftUI

struct ContentView: View {
    @State private var keyPosition = CGPoint(x: 100, y: 100)
    @State private var isKeyDropped = false
    @State private var codeText: [String] = [""]
    @State private var showChat = false
    private let circleCenter = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)

    var body: some View {
        if showChat {
            ChatView(onRestart: restart)
                .transition(.opacity)
        } else {
            intro
                .transition(.opacity)
        }
    }

    private var intro: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Solid circle that glides between random colors
                ColorCircle(speed: isKeyDropped ? 0.5 : 2)
                    .frame(width: circleDiameter(), height: circleDiameter())
                    .position(circleCenter)
                    .animation(.easeInOut, value: isKeyDropped)

                // Text "Drop Key Here" or Animating Code
                Group {
                    if isKeyDropped {
                        VStack(spacing: 5) {
                            ForEach(0..<codeText.count, id: \.self) { index in
                                Text(codeText[index])
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.black)
                            }
                        }
                        .position(circleCenter)
                    } else {
                        Text("Drop Key Here")
                            .font(.system(size: 20, design: .monospaced))
                            .foregroundColor(.white)
                            .position(circleCenter)
                    }
                }
                
                // Old Key Emoji 🗝️
                Group {
                    Text("🗝️")
                        .font(.system(size: 64))
                        .position(keyPosition)
                        .opacity(isKeyDropped ? 0 : 1)
                        .animation(.easeOut, value: isKeyDropped)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    keyPosition = gesture.location
                                }
                                .onEnded { _ in
                                    if distanceToCenter() < 100 {
                                        isKeyDropped = true
                                        startCodeAnimation()
                                    }
                                }
                        )
                }
            }
        }
    }
    
    // Reset everything back to the initial key screen
    private func restart() {
        keyPosition = CGPoint(x: 100, y: 100)
        isKeyDropped = false
        codeText = [""]
        withAnimation(.easeInOut(duration: 0.5)) {
            showChat = false
        }
    }

    // Calculate the distance between the key position and the circle center
    private func distanceToCenter() -> CGFloat {
        return hypot(keyPosition.x - circleCenter.x, keyPosition.y - circleCenter.y)
    }
    
    // Calculate the diameter of the circle based on key's proximity to the center
    private func circleDiameter() -> CGFloat {
        if isKeyDropped {
            let screenDiagonal = hypot(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            return screenDiagonal * 2 // Expand circle to cover the entire screen
        } else {
            let originalDiameter: CGFloat = 200
            let maxDistance = originalDiameter / 2
            let growthFactor = 1.5 + min(2.5, (maxDistance - distanceToCenter()) / maxDistance * 2.5)
            return max(0, originalDiameter * growthFactor)
        }
    }
    
    // Start the code animation
    private func startCodeAnimation() {
        var rowCount = 1
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            for i in 0..<rowCount {
                if i < codeText.count {
                    codeText[i] = generateRandomCodeText()
                } else {
                    codeText.append(generateRandomCodeText())
                }
            }
            
            if rowCount < 10 {
                rowCount += 1
            }
        }

        // Stop the animation after 5 seconds and hand off to the chat
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            timer.invalidate()
            withAnimation(.easeInOut(duration: 0.5)) {
                showChat = true
            }
        }
    }
    
    // Generate random code text
    private func generateRandomCodeText() -> String {
        let characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<20).map { _ in characters.randomElement()! })
    }
}

struct ChatMessage: Identifiable {
    enum Role { case assistant, user }

    let id = UUID()
    let role: Role
    var text: String
    /// Shows a "Restart demo" button under the message once it has finished typing.
    var showsRestart = false
}

/// Minimal chat: assistant messages are plain text, user messages sit in a quiet bubble.
struct ChatView: View {
    var onRestart: () -> Void

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(messages) { message in
                        MessageRow(message: message, onRestart: onRestart)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) {
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .safeAreaInset(edge: .top) { topBar }
        .safeAreaInset(edge: .bottom) { inputBar }
        .background(Color(.systemBackground))
        .task {
            guard messages.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(300))
            await streamAssistantMessage("How can I help?")
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onRestart) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Spacer()
        }
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Send message...", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(.vertical, 10)
                .padding(.leading, 16)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(canSend ? Color.primary : Color(.systemGray4)))
            }
            .disabled(!canSend)
            .padding(.trailing, 6)
            .padding(.bottom, 4)
            .accessibilityLabel("Send")
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .animation(.easeOut(duration: 0.15), value: canSend)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: text))
        draft = ""
        Task {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 350...600)))
            await streamAssistantMessage("Thanks for the message but this is just a demo.", showsRestart: true)
        }
    }

    /// Appends an assistant message and streams it in a few words at a time,
    /// with slightly uneven timing like a model producing tokens.
    private func streamAssistantMessage(_ text: String, showsRestart: Bool = false) async {
        let message = ChatMessage(role: .assistant, text: "")
        messages.append(message)

        // Split into words, keeping each word's trailing space.
        var words: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == " " {
                words.append(current)
                current = ""
            }
        }
        if !current.isEmpty { words.append(current) }

        var position = 0
        while position < words.count {
            let chunkSize = Int.random(in: 1...3)
            let chunk = words[position..<min(position + chunkSize, words.count)].joined()
            position += chunkSize
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
            messages[index].text += chunk
            try? await Task.sleep(for: .milliseconds(Int.random(in: 25...70)))
        }
        guard showsRestart,
              let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            messages[index].showsRestart = true
        }
    }
}

private struct MessageRow: View {
    let message: ChatMessage
    var onRestart: () -> Void

    var body: some View {
        switch message.role {
        case .assistant:
            VStack(alignment: .leading, spacing: 14) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.primary)

                if message.showsRestart {
                    Button("Restart demo", action: onRestart)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(Capsule().strokeBorder(Color(.separator)))
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .user:
            Text(message.text)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.leading, 48)
        }
    }
}

/// A solid circle that moves through random colors. Each color eases into the next
/// along the hue wheel, so it never strobes or passes through muddy in-between grays.
struct ColorCircle: View {
    /// How many colors it moves through per second.
    var speed: Double

    /// How long a change in `speed` takes to settle, so the orb eases rather than lurches.
    private let rampDuration: Double = 1.6

    @State private var anchorDate = Date.now
    @State private var anchorPhase: Double = 0
    @State private var rampStartSpeed: Double
    @State private var seed = UInt64.random(in: 0...UInt64.max)

    init(speed: Double) {
        self.speed = speed
        _rampStartSpeed = State(initialValue: speed)
    }

    var body: some View {
        TimelineView(.animation) { context in
            Circle()
                .fill(color(at: phase(at: context.date, targetSpeed: speed)))
        }
        .onChange(of: speed) { oldSpeed, _ in
            // Re-anchor at the current phase and speed so the motion stays continuous.
            let now = Date.now
            anchorPhase = phase(at: now, targetSpeed: oldSpeed)
            rampStartSpeed = currentSpeed(at: now, targetSpeed: oldSpeed)
            anchorDate = now
        }
    }

    /// Blends between the random keyframe colors on either side of `phase`.
    private func color(at phase: Double) -> Color {
        let index = Int(phase.rounded(.down))
        let from = keyframe(index)
        let to = keyframe(index + 1)
        let t = phase - Double(index)
        let eased = t * t * (3 - 2 * t) // smoothstep: settle on each color, then glide on

        var hueDelta = to.hue - from.hue
        if hueDelta > 0.5 { hueDelta -= 1 }
        if hueDelta < -0.5 { hueDelta += 1 }
        let hue = (from.hue + hueDelta * eased + 1).truncatingRemainder(dividingBy: 1)

        return Color(
            hue: hue,
            saturation: from.saturation + (to.saturation - from.saturation) * eased,
            brightness: from.brightness + (to.brightness - from.brightness) * eased
        )
    }

    /// A random but repeatable color for keyframe `index`.
    private func keyframe(_ index: Int) -> (hue: Double, saturation: Double, brightness: Double) {
        var state = seed &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
        func next() -> Double {
            // SplitMix64
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z ^= z >> 31
            return Double(z >> 11) / Double(1 << 53)
        }
        return (hue: next(), saturation: 0.55 + next() * 0.45, brightness: 0.8 + next() * 0.2)
    }

    private func currentSpeed(at date: Date, targetSpeed: Double) -> Double {
        let progress = min(1, max(0, date.timeIntervalSince(anchorDate) / rampDuration))
        return rampStartSpeed + (targetSpeed - rampStartSpeed) * progress
    }

    /// Integrates a linear ramp from `rampStartSpeed` to `targetSpeed`.
    private func phase(at date: Date, targetSpeed: Double) -> Double {
        let elapsed = max(0, date.timeIntervalSince(anchorDate))
        let rampTime = min(elapsed, rampDuration)
        let delta = targetSpeed - rampStartSpeed
        let duringRamp = rampStartSpeed * rampTime + delta * rampTime * rampTime / (2 * rampDuration)
        let afterRamp = targetSpeed * (elapsed - rampTime)
        return anchorPhase + duringRamp + afterRamp
    }
}

#Preview {
    ContentView()
}

#Preview("Color circle") {
    ColorCircle(speed: 2)
        .frame(width: 300, height: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
}
