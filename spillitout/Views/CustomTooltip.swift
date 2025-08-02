import SwiftUI

struct CustomTooltip: ViewModifier {
    let text: String
    @State private var showTooltip = false
    @State private var hoverTimer: Timer?
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering {
                    // Show tooltip instantly
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) { _ in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showTooltip = true
                        }
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showTooltip = false
                    }
                }
            }
            .overlay(
                Group {
                    if showTooltip {
                        TooltipView(text: text)
                            .transition(AnyTransition.asymmetric(
                                insertion: AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.8)),
                                removal: AnyTransition.opacity
                            ))
                            .zIndex(9999) // High z-index for the tooltip container
                    }
                },
                alignment: .top
            )
    }
}

struct TooltipView: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .light ? Color.black.opacity(0.85) : Color.white.opacity(0.9)
    }
    
    private var textColor: Color {
        colorScheme == .light ? Color.white : Color.black
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat bubble main body
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    // Chat bubble shape with authentic rounded corners
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            colorScheme == .light 
                                ? Color(red: 0.2, green: 0.2, blue: 0.2)
                                : Color(red: 0.95, green: 0.95, blue: 0.95)
                        )
                        .overlay(
                            // Subtle inner highlight for depth
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    colorScheme == .light 
                                        ? Color.white.opacity(0.15)
                                        : Color.black.opacity(0.1),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                )
            
            // Chat bubble tail positioned at bottom center
            ChatBubbleTail()
                .fill(
                    colorScheme == .light 
                        ? Color(red: 0.2, green: 0.2, blue: 0.2)
                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                )
                .frame(width: 12, height: 6)
                .offset(y: -1) // Slight overlap with bubble for seamless connection
        }
        .offset(x: -8, y: -50) // Position above the element, slightly to the left
        .zIndex(10000) // Very high z-index to ensure it appears above navbar and other elements
    }
}

// Chat bubble tail shape
struct ChatBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create a more authentic chat bubble tail with curved edges
        path.move(to: CGPoint(x: width * 0.2, y: 0))
        
        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.3, y: height * 0.3)
        )
        
        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.8, y: 0),
            control: CGPoint(x: width * 0.7, y: height * 0.3)
        )
        
        path.closeSubpath()
        
        return path
    }
}

// Extension to make it easy to use
extension View {
    func customTooltip(_ text: String) -> some View {
        self.modifier(CustomTooltip(text: text))
    }
}