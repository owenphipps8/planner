// NotesView.swift
// DailyPlanner
//
// View for managing notes with labels, search, and organization features.

import SwiftUI
import SwiftData

struct NotesViewTab: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    private let theme = AppTheme.shared

    // MARK: - Data

    @Query(sort: \PlannerNote.modifiedDate, order: .reverse) private var allNotes: [PlannerNote]
    @Query(sort: \NoteLabel.order) private var labels: [NoteLabel]

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedLabel: NoteLabel?
    @State private var activeEditor: NoteEditorSheet?

    // MARK: - Computed Properties

    private var filteredNotes: [PlannerNote] {
        var filtered = allNotes

        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.labelName.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let selectedLabel = selectedLabel {
            filtered = filtered.filter { $0.labelName == selectedLabel.name }
        }

        return filtered
    }

    private var pinnedNotes: [PlannerNote] { filteredNotes.filter { $0.isPinned } }
    private var unpinnedNotes: [PlannerNote] { filteredNotes.filter { !$0.isPinned } }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader
            searchBar
            labelFilters

            if allNotes.isEmpty {
                emptyState
            } else {
                notesList
            }
        }
        .sheet(item: $activeEditor) { editor in
            switch editor {
            case .add:
                NoteEditorView(isPresented: .constant(true))
            case .edit(let note):
                NoteEditorView(note: note, isPresented: .constant(true))
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: 14) {
            Text("Notes")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#2F3851"))
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.8))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)

            Spacer(minLength: 0)

            Button {
                activeEditor = .add
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(theme.buttonGradient))
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .shadow(color: theme.buttonShadowColor, radius: 14, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#5D6785"))
            TextField("Search notes", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#1C2B3A"))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(hex: "#5D6785").opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Label Filters

    private var labelFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                LabelFilterButton(
                    name: "All",
                    color: Color(hex: "#999999"),
                    isSelected: selectedLabel == nil
                ) {
                    selectedLabel = nil
                }

                ForEach(labels) { label in
                    LabelFilterButton(
                        name: label.name,
                        color: Color(hex: label.colorHex),
                        isSelected: selectedLabel?.id == label.id
                    ) {
                        selectedLabel = label.id == selectedLabel?.id ? nil : label
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#5D6785").opacity(0.5))
            Text("No notes yet")
                .font(.headline)
                .foregroundStyle(Color(hex: "#2F3851"))
            Text("Start capturing your ideas, thoughts,\nand important information here.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#5D6785"))
                .multilineTextAlignment(.center)
            Button("Create a note") {
                activeEditor = .add
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Capsule().fill(theme.buttonGradientH))
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Notes List

    private var notesList: some View {
        List {
            if !pinnedNotes.isEmpty {
                Section {
                    ForEach(pinnedNotes) { note in
                        noteRow(for: note)
                    }
                } header: {
                    Text("Pinned")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .textCase(nil)
                }
            }

            if !unpinnedNotes.isEmpty {
                Section {
                    ForEach(unpinnedNotes) { note in
                        noteRow(for: note)
                    }
                } header: {
                    Text("Notes")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .textCase(nil)
                }
            }

            if filteredNotes.isEmpty && !allNotes.isEmpty {
                Section {
                    Text("No notes match your search.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func noteRow(for note: PlannerNote) -> some View {
        NoteRow(note: note)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.07), radius: 8, y: 3)
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .contentShape(Rectangle())
            .onTapGesture { activeEditor = .edit(note) }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    deleteNote(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - Actions

    private func deleteNote(_ note: PlannerNote) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}

private enum NoteEditorSheet: Identifiable {
    case add
    case edit(PlannerNote)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let note):
            return note.id.uuidString
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {

    let note: PlannerNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.content)
                        .lineLimit(2)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "#1C2B3A"))

                    HStack(spacing: 8) {
                        Label(note.labelName, systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: note.colorHex))

                        Text(note.modifiedDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#5D6785"))
                    }
                }

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.orange)
                }
            }

            if !note.imageURLs.isEmpty {
                Text("\(note.imageURLs.count) image\(note.imageURLs.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#5D6785"))
            }
        }
    }
}

// MARK: - Label Filter Button

struct LabelFilterButton: View {

    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color(hex: "#2F3851"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.78))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? color : Color.white.opacity(0.9), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Note Editor View

struct NoteEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \NoteLabel.order) private var labels: [NoteLabel]

    @State private var content: String = ""
    @State private var selectedLabelName: String = "Personal"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var imageURLs: [String] = []
    @State private var isPinned: Bool = false

    let note: PlannerNote?
    @Binding var isPresented: Bool

    init(note: PlannerNote? = nil, isPresented: Binding<Bool>) {
        self.note = note
        self._isPresented = isPresented

        if let note = note {
            _content = State(initialValue: note.content)
            _selectedLabelName = State(initialValue: note.labelName)
            _selectedColorHex = State(initialValue: note.colorHex)
            _imageURLs = State(initialValue: note.imageURLs)
            _isPinned = State(initialValue: note.isPinned)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                Section("Label") {
                    Picker("Label", selection: $selectedLabelName) {
                        ForEach(defaultLabels + labels.map { $0.name }, id: \.self) { label in
                            Text(label).tag(label)
                        }
                    }
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DefaultColors.allCases, id: \.self) { color in
                                Button {
                                    selectedColorHex = color.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColorHex == color.hex ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section {
                    Toggle("Pin this note", isOn: $isPinned)
                }

                if note != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteNote()
                        } label: {
                            Label("Delete Note", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .colorScheme(AppTheme.shared.colorScheme)
            .background(TodayScreenBackground())
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var defaultLabels: [String] {
        ["Personal", "Work", "Ideas", "Important", "Travel"]
    }

    private func saveNote() {
        if let existingNote = note {
            existingNote.content = content
            existingNote.labelName = selectedLabelName
            existingNote.colorHex = selectedColorHex
            existingNote.imageURLs = imageURLs
            existingNote.isPinned = isPinned
            existingNote.modifiedDate = .now
        } else {
            let newNote = PlannerNote(
                content: content,
                labelName: selectedLabelName,
                colorHex: selectedColorHex,
                imageURLs: imageURLs,
                isPinned: isPinned
            )
            modelContext.insert(newNote)
        }

        try? modelContext.save()
        isPresented = false
        dismiss()
    }

    private func deleteNote() {
        guard let existingNote = note else { return }
        modelContext.delete(existingNote)
        try? modelContext.save()
        isPresented = false
        dismiss()
    }
}

enum DefaultColors: CaseIterable {
    case red, orange, yellow, green, blue, purple, pink, gray

    var hex: String {
        switch self {
        case .red: return "#FF6B6B"
        case .orange: return "#FFA500"
        case .yellow: return "#FFD93D"
        case .green: return "#51CF66"
        case .blue: return "#5E8FFF"
        case .purple: return "#9775FA"
        case .pink: return "#FF8CC9"
        case .gray: return "#888888"
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#A8C9FF"), Color(hex: "#D7E3FF"), Color(hex: "#F5DCEB")],
            startPoint: .bottomLeading, endPoint: .topTrailing
        )
        .ignoresSafeArea()
        NotesViewTab()
    }
    .modelContainer(for: [PlannerNote.self, NoteLabel.self], inMemory: true)
}
