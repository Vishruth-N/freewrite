import SwiftUI


struct FontButtonsSection: View {
    @Binding var fontSize: CGFloat
    @Binding var selectedFont: String
    @Binding var currentRandomFont: String

    @State private var isHoveringSize = false
    @State private var isHoveringBottomNav = false
    @State private var hoveredFont: String?
    
    @Environment(\.colorScheme) var colorScheme
    private var textHoverColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }

    private var textColor: Color {
        colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
    }
    
    var randomButtonTitle: String {
        return currentRandomFont.isEmpty ? "Random" : "Random [\(currentRandomFont)]"
    }

    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
    let fontSizes: [CGFloat]
    let availableFonts: [String]
    
    var body: some View {
        HStack(spacing: 8) {
            Button(fontSizeButtonTitle) {
                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                    let nextIndex = (currentIndex + 1) % fontSizes.count
                    fontSize = fontSizes[nextIndex]
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringSize ? textHoverColor : textColor)
            .onHover { hovering in
                isHoveringSize = hovering
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button("Arial") {
                selectedFont = "Arial"
                currentRandomFont = ""
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Arial" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Arial" : nil
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button("Serif") {
                selectedFont = "Times New Roman"
                currentRandomFont = ""
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Serif" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Serif" : nil
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("•")
                .foregroundColor(.gray)
            
            Button(randomButtonTitle) {
                if let randomFont = availableFonts.randomElement() {
                    selectedFont = randomFont
                    currentRandomFont = randomFont
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(hoveredFont == "Random" ? textHoverColor : textColor)
            .onHover { hovering in
                hoveredFont = hovering ? "Random" : nil
                isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(8)
        .cornerRadius(6)
        .onHover { hovering in
            isHoveringBottomNav = hovering
        }
    }
}

