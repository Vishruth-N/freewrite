import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var placeholderText: String
    @State private var viewHeight: CGFloat = 0
    
    let bottomNavOpacity: Double
    let onTextChange: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var lineHeight: CGFloat {
        fontSize * 0.3
    }
    
    private var backgroundColor: Color {
        colorScheme == .light ? Color(red: 0.992, green: 0.992, blue: 0.992) : Color(red: 0.08, green: 0.08, blue: 0.08)
    }
    
    private var textEditorForegroundColor: Color {
        colorScheme == .light ? Color(red: 0.165, green: 0.165, blue: 0.165) : Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private var placeholderColor: Color {
        colorScheme == .light ? .gray.opacity(0.5) : .gray.opacity(0.6)
    }
    
    private var cursorColor: Color {
        colorScheme == .light ? Color(red: 0.078, green: 0.502, blue: 0.969) : Color(red: 1.0, green: 0.871, blue: 0.408)
    }
    
    var body: some View {
        TextEditor(text: $text)
            .background(backgroundColor)
            .font(.custom(selectedFont, size: fontSize))
            .foregroundColor(textEditorForegroundColor)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .lineSpacing(lineHeight)
            .frame(maxWidth: 650)
            .padding(.leading, 5)
            .padding(.top, 40)
            .id("\(selectedFont)-\(fontSize)")
            .padding(.bottom, bottomNavOpacity > 0 ? 68 : 0)
            .ignoresSafeArea()
            .colorScheme(colorScheme)
            .tint(cursorColor)
            .onAppear {
                placeholderText = AppSettings.placeholderOptions.randomElement() ?? "Begin writing"
            }
            .overlay(placeholderOverlay, alignment: .topLeading)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                viewHeight = height
            }
            .contentMargins(.bottom, viewHeight / 4)
            .onChange(of: text) { oldValue, newValue in
                onTextChange()
            }
    }
    
    private var placeholderOverlay: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholderText)
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(placeholderColor)
                    .allowsHitTesting(false)
                    .padding(.leading, 10)
                    .padding(.top, 40)
            }
        }
    }
} 