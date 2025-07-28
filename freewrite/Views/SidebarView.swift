import SwiftUI

struct SidebarView: View {
    @Binding var entries: [HumanEntry]
    @Binding var selectedEntryId: UUID?
    @State private var hoveredEntryId: UUID? = nil
    @State private var hoveredTrashId: UUID? = nil
    @State private var hoveredExportId: UUID? = nil
    @State private var isHoveringHistory = false
    
    let onSelectEntry: (HumanEntry) -> Void
    let onDeleteEntry: (HumanEntry) -> Void
    let onExportEntry: (HumanEntry) -> Void
    let fileService: FileService
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notes")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(entries.count) notes")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    fileService.openDocumentsFolder()
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 16))
                        .foregroundColor(isHoveringHistory ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringHistory = hovering
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            Divider()
            
            // Entries List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        Button(action: {
                            if selectedEntryId != entry.id {
                                onSelectEntry(entry)
                            }
                        }) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(entry.previewText.isEmpty ? "New Note" : entry.previewText)
                                            .font(.system(size: 15, weight: .medium))
                                            .lineLimit(1)
                                            .foregroundColor(entry.id == selectedEntryId ? 
                                                (colorScheme == .dark ? .black : .primary) : .primary)
                                        
                                        Spacer()
                                        
                                        // Export and Trash icons that appear on hover
                                        if hoveredEntryId == entry.id {
                                            HStack(spacing: 8) {
                                                // PDF Export button
                                                Button(action: {
                                                    onExportEntry(entry)
                                                }) {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(hoveredExportId == entry.id ? .blue : .secondary)
                                                }
                                                .buttonStyle(.plain)
                                                .onHover { hovering in
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        hoveredExportId = hovering ? entry.id : nil
                                                    }
                                                    if hovering {
                                                        NSCursor.pointingHand.push()
                                                    } else {
                                                        NSCursor.pop()
                                                    }
                                                }
                                                .help("Export as PDF")
                                                
                                                // Trash button
                                                Button(action: {
                                                    onDeleteEntry(entry)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(hoveredTrashId == entry.id ? .red : .secondary)
                                                }
                                                .buttonStyle(.plain)
                                                .onHover { hovering in
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        hoveredTrashId = hovering ? entry.id : nil
                                                    }
                                                    if hovering {
                                                        NSCursor.pointingHand.push()
                                                    } else {
                                                        NSCursor.pop()
                                                    }
                                                }
                                                .help("Delete entry")
                                            }
                                        }
                                    }
                                    
                                    Text(entry.date)
                                        .font(.system(size: 13))
                                        .foregroundColor(entry.id == selectedEntryId && colorScheme == .dark ? 
                                            .black.opacity(0.7) : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(backgroundColor(for: entry))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredEntryId = hovering ? entry.id : nil
                            }
                        }
                        .onAppear {
                            NSCursor.pop()
                        }
                        .help("Click to select this entry")
                        
                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.never)
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func backgroundColor(for entry: HumanEntry) -> Color {
        if entry.id == selectedEntryId {
            if colorScheme == .dark {
                return Color(red: 1.0, green: 0.871, blue: 0.408).opacity(0.7) // #FFDE68 selection for dark mode
            } else {
                return Color(red: 0.545, green: 0.761, blue: 1.0) // #8BC2FF selection for light mode
            }
        } else if entry.id == hoveredEntryId {
            if colorScheme == .dark {
                return Color.white.opacity(0.05)
            } else {
                return Color.black.opacity(0.05)
            }
        } else {
            return Color.clear
        }
    }
} 