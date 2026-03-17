import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    var isApplied: Bool = false

    enum Role {
        case user, assistant
    }
}

struct ChatDrawerView<CollapsedExtra: View>: View {
    @Binding var isExpanded: Bool
    @Binding var pendingMessage: String?
    var placeholder: String
    var workoutName: String?
    var elapsedTime: String?
    var exerciseProgress: String?
    var collapsedHeight: CGFloat = 80
    var onSend: (String) async -> AsyncThrowingStream<ChatStreamEvent, Error>?
    @ViewBuilder var collapsedExtra: () -> CollapsedExtra

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool
    @State private var barText = ""
    @FocusState private var isBarFocused: Bool
    @State private var selectedDetent: PresentationDetent = .height(80)

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                sheetContent
                    .presentationDetents(
                        [.height(collapsedHeight), .large],
                        selection: $selectedDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(collapsedHeight)))
                    .interactiveDismissDisabled()
                    .presentationCornerRadius(16)
                    .presentationBackground(.white)
            }
            .onChange(of: selectedDetent) { _, newValue in
                isExpanded = (newValue == .large)
            }
            .onChange(of: isExpanded) { _, newValue in
                selectedDetent = newValue ? .large : .height(collapsedHeight)
            }
            .onAppear {
                selectedDetent = isExpanded ? .large : .height(collapsedHeight)
            }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if selectedDetent == .large {
            expandedContent
        } else {
            collapsedBar
        }
    }

    // MARK: - Collapsed Bar

    private var collapsedBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                if isBarFocused {
                    TextField(placeholder, text: $barText, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1...5)
                        .focused($isBarFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(hex: 0xF5F5F5))
                        .clipShape(RoundedRectangle(cornerRadius: 21))
                        .onSubmit { sendFromBar() }
                } else {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.black.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(hex: 0xF5F5F5))
                        .clipShape(RoundedRectangle(cornerRadius: 21))
                        .onTapGesture { isBarFocused = true }
                }

                Button {
                    if isBarFocused {
                        sendFromBar()
                    } else {
                        isBarFocused = true
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(
                            isBarFocused && !barText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(hex: 0x0A0A0A)
                            : Color.black.opacity(0.15)
                        )
                }
            }

            collapsedExtra()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat")
                    .font(.custom("SpaceGrotesk-Bold", size: 20))
                    .tracking(-0.4)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                Spacer()
                Button { isExpanded = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: 0xF5F5F5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            messageView(message)
                        }

                        if isSending && (messages.isEmpty || messages.last?.role == .user) {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Thinking...")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("loading")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: messages.last?.text) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: isSending) {
                    if isSending {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(RoundedRectangle(cornerRadius: 21))
                    .onSubmit { Task { await send() } }
                    .disabled(isSending)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending
                            ? Color.black.opacity(0.15)
                            : Color(hex: 0x0A0A0A)
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .task(id: isExpanded) {
                guard isExpanded, let message = pendingMessage else { return }
                pendingMessage = nil
                messages.append(ChatMessage(role: .user, text: message))
                await streamResponse(for: message)
            }
        }
    }

    // MARK: - Message Views

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 60)
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x2C2C2E))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(Color(hex: 0x0A0A0A).opacity(0.85))

                if message.isApplied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Changes applied to your workout")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: 0x34C759))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func sendFromBar() {
        let text = barText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        pendingMessage = text
        barText = ""
        isBarFocused = false
        isExpanded = true
    }

    private func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: text))
        inputText = ""
        await streamResponse(for: text)
    }

    private func streamResponse(for text: String) async {
        isSending = true

        guard let stream = await onSend(text) else {
            isSending = false
            return
        }

        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, text: ""))

        do {
            for try await event in stream {
                switch event {
                case .text(let delta):
                    messages[assistantIndex].text += delta
                case .result(let result):
                    if !result.explanation.isEmpty {
                        messages[assistantIndex].text = result.explanation
                    }
                    messages[assistantIndex].isApplied = true
                }
            }
        } catch {
            if messages[assistantIndex].text.isEmpty {
                messages[assistantIndex].text = "Error: \(error.localizedDescription)"
            } else {
                messages[assistantIndex].text += "\n\nError: \(error.localizedDescription)"
            }
        }

        isSending = false
    }
}
