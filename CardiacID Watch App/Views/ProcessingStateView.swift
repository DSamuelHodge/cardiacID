import SwiftUI

struct ProcessingStateView: View {
    let progress: Double
    let title: String
    @State private var isPulsating = false
    @State private var heartScale: CGFloat = 1.0
    
    // Safe progress value to prevent NaN issues
    private var safeProgress: Double {
        guard progress.isFinite && !progress.isNaN else { return 0.0 }
        return max(0.0, min(1.0, progress))
    }
    
    
    var body: some View {
        VStack(spacing: 20) {
            // Pulsating Heart Icon
            ZStack {
                // Background circle for visual appeal
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsating ? 1.2 : 1.0)
                    .opacity(isPulsating ? 0.3 : 0.1)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsating)
                
                // Heart icon with pulsating effect
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .scaleEffect(heartScale)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: heartScale)
            }
            
            // Progress Bar
            VStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Progress bar container
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(safeProgress) * 200, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: safeProgress)
                }
                .frame(width: 200)
                
                // Progress percentage
                Text("\(Int(safeProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Status text
            VStack(spacing: 4) {
                Text("Analyzing your heart pattern...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Please keep the watch on your wrist")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Processing steps indicator
                if safeProgress > 0.8 {
                    Text("Almost complete...")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                } else if safeProgress > 0.5 {
                    Text("Processing data...")
                        .font(.caption2)
                        .foregroundColor(.blue)
                } else {
                    Text("Initializing analysis...")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            startPulsatingAnimation()
        }
    }
    
    private func startPulsatingAnimation() {
        isPulsating = true
        heartScale = 1.2
    }
}

#Preview {
    ProcessingStateView(progress: 0.5, title: "Processing Authentication")
}
