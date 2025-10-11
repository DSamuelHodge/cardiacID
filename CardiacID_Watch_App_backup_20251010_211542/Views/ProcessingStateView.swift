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
            // Simplified Heart Icon (removed multiple animations to prevent crashes)
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .scaleEffect(isPulsating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsating)
            
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
                        .frame(width: CGFloat(max(0, min(200, safeProgress * 200))), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: safeProgress)
                }
                .frame(width: 200)
                
                // Progress percentage (with safety check)
                Text("\(Int(max(0, min(100, safeProgress * 100))))%")
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
    }
}

#Preview {
    ProcessingStateView(progress: 0.5, title: "Processing Authentication")
}
