import SwiftUI
import CoreHaptics

struct PomodoroView: View {
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 60 * 60
    @State private var endTime: Date?
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var isDragging = false
    @State private var initialAngle: CGFloat?
    @State private var initialRemainingTime: TimeInterval?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 240, height: 240)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 6)
                )

            Sector(remainingTime: remainingTime, totalTime: totalTime)
                .fill(Color.red.opacity(1))
                .frame(width: 170, height: 170)
                .compositingGroup()
                .id(remainingTime)
            
            ForEach(0..<60) { numericMark -> AnyView in
                if numericMark % 5 == 0 {
                    return AnyView(
                        Group {
                            Text("\(numericMark)")
                                .font(.system(size: 14, design: .rounded))
                                .fontWeight(.black)
                                .position(labelPosition(angle: .degrees(Double(numericMark) * 6 - 90), distance: 100))
                                .foregroundColor(.black)

                            LongTick()
                                .rotationEffect(.degrees(Double(numericMark) * 6 - 90))
                                .position(x: 120, y: 120)
                        }
                    )
                } else {
                    return AnyView(
                        ShortTick()
                            .rotationEffect(.degrees(Double(numericMark) * 6 - 90))
                            .position(x: 120, y: 120)
                    )
                }
            }

            Circle()
                .fill(Color.blue.opacity(0.001))
                .frame(width: 165, height: 165)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            updateRemainingTime(with: value)
                        }
                        .onEnded { _ in
                            initialAngle = nil
                        }
                )
            
            Circle()
                .fill(Color.gray)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .frame(width: 40, height: 40)
                .scaleEffect(buttonScale)
                .onTapGesture {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                    withAnimation(.spring()) {
                        buttonScale = pressing ? 0.9 : 1.0
                    }
                }, perform: { })
        }
        
        .frame(width: 240, height: 240)
        .rotation3DEffect(
            .degrees(15),
            axis: (x: 0.0, y: 0.0, z: 0.0)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 40, x: 40, y: 40)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 20, y: 20)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 5, y: 5)
        
    }

    private func labelPosition(angle: Angle, distance: CGFloat) -> CGPoint {
        let angleInRadians = angle.radians
        let xOffset = distance * cos(CGFloat(angleInRadians))
        let yOffset = distance * sin(CGFloat(angleInRadians))
        return CGPoint(x: 120 + xOffset, y: 120 + yOffset)
    }

    private func startTimer() {
        isTimerRunning = true
        endTime = Date().addingTimeInterval(remainingTime)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remainingTime = endTime?.timeIntervalSinceNow ?? 0

            if remainingTime <= 0 {
                timer?.invalidate()
                timer = nil
                isTimerRunning = false
            }
        }
    }

    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
    
    private func updateRemainingTime(with value: DragGesture.Value) {
        guard !isTimerRunning else {
            playHapticFeedback()
            return
        }

        let currentLocation = value.location
        let currentAngle = atan2(currentLocation.x - 100, currentLocation.y - 100) + .pi / 2

        if initialAngle == nil {
            initialAngle = currentAngle
            initialRemainingTime = remainingTime
        }

        guard let unwrappedInitialAngle = initialAngle, let unwrappedInitialRemainingTime = initialRemainingTime else {
            return
        }

        let angleDifference = unwrappedInitialAngle - currentAngle
        var newRemainingTime = unwrappedInitialRemainingTime + totalTime * Double(angleDifference) / (2 * .pi)

        if newRemainingTime <= 0 {
            playHapticFeedback()
            remainingTime = 0
        } else if newRemainingTime >= totalTime {
            playHapticFeedback()
            remainingTime = totalTime
        } else {
            let clampedAngle = max(min(currentAngle, Double(__designTimeInteger("#3572.[2].[14].[7].[2].[0].value.arg[0].value.arg[1].value.[0]", fallback: 3)) * .pi / __designTimeInteger("#3572.[2].[14].[7].[2].[0].value.arg[0].value.arg[1].value.[1]", fallback: 2)), Double(-1 * __designTimeInteger("#3572.[2].[14].[7].[2].[0].value.arg[1].value.[0]", fallback: 1)) * .pi / __designTimeInteger("#3572.[2].[14].[7].[2].[0].value.arg[1].value.[1]", fallback: 2))
            let clampedAngleDifference = unwrappedInitialAngle - clampedAngle
            newRemainingTime = unwrappedInitialRemainingTime + totalTime * Double(clampedAngleDifference) / (2 * .pi)
            remainingTime = newRemainingTime
        }
    }
    
    private func playHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var engine: CHHapticEngine?

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the haptic engine: \(error)")
            return
        }

        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("There was an error playing the haptic feedback: \(error)")
        }
    }
}

struct LongTick: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.black)
            .frame(width: 2, height: 30)
            .offset(x: 0, y: -70)
    }
}

struct ShortTick: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.black)
            .frame(width: 1, height: 10)
            .offset(x: 0, y: -80)
    }
}

struct Sector: Shape {
    let remainingTime: TimeInterval
    let totalTime: TimeInterval

    func path(in rect: CGRect) -> Path {
        let percentage = remainingTime / totalTime
        let endAngle = 2 * .pi * percentage - .pi / 2
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .radians(-.pi / 2), endAngle: .radians(endAngle), clockwise: false)
        path.closeSubpath()

        return path
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(backgroundOption: .whiteMarble) // Change the option here to see different backgrounds
                PomodoroView()
                    .frame(width: 200, height: 200)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
