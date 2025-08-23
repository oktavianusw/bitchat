import SwiftUI

enum EditGroupStep: Int, CaseIterable {
    case overview = 0
    case members
    case about
    case name
    
    var title: String {
        switch self {
        case .overview: return "Edit Options"
        case .members: return "Edit Members"
        case .about: return "Edit About"
        case .name: return "Group Information"
        }
    }
    
    func next() -> EditGroupStep {
        let all = Self.allCases
        let i = min(self.rawValue + 1, all.count - 1)
        return all[i]
    }
    
    func back() -> EditGroupStep {
        let i = max(self.rawValue - 1, 0)
        return Self.allCases[i]
    }
}

struct EditGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var draft: CreateCircleDraft
    @State private var step: EditGroupStep = .overview
    @State private var showSheet = true
    
    let chat: Chat
    let nearbyProfiles: [NearbyProfile]
    var onSave: ((CreateCircleDraft) -> Void)? = nil
    
    init(chat: Chat, nearbyProfiles: [NearbyProfile], onSave: ((CreateCircleDraft) -> Void)? = nil) {
        self.chat = chat
        self.nearbyProfiles = nearbyProfiles
        self.onSave = onSave
        
        let initialDraft = CreateCircleDraft(
            name: chat.title,
            about: chat.about ?? "",
            color: chat.color ?? .blue,
            selectedMembers: chat.members
        )
        _draft = StateObject(wrappedValue: initialDraft)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background
            VStack {
                Image("bubble")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 350)
                    .offset(x: 40)
            }
            VStack(spacing: 8) {
                EditableCircleAvatar(onEdit: {
                    step = .name
                }, color: $draft.color)
                Text(draft.name)
                    .font(.title3.weight(.semibold))
            }
            .padding(.top, 120)
        }
        .ignoresSafeArea(.all)
        .navigationTitle("Edit Group")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            if #available(iOS 16.4, *) {
                EditGroupSheetContainer(
                    draft: draft,
                    step: $step,
                    nearbyProfiles: nearbyProfiles,
                    onDone: {
                        onSave?(draft)
                        showSheet = false
                        dismiss()
                    }
                )
                .presentationDetents([.fraction(0.75)])
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .id(step)
            } else {
                EditGroupSheetContainer(
                    draft: draft,
                    step: $step,
                    nearbyProfiles: nearbyProfiles,
                    onDone: {
                        onSave?(draft)
                        showSheet = false
                        dismiss()
                    }
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .id(step)
            }
        }
    }
}

struct OverViewStep: View {
    @ObservedObject var draft: CreateCircleDraft
    var onEditMembers: (() -> Void)?
    var onEditAbout: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("Members (\(draft.selectedMembers.count))")
                        .font(.system(.title, weight: .bold))
                        .foregroundStyle(Color.textHeader)
                        .accessibilityAddTraits(.isHeader)
                    Button(action: onEditMembers ?? {}) {
                        Image("union")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .padding(6)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.brandPrimary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit")
                    .accessibilityHint("Edit members")
                    .accessibilityAddTraits(.isButton)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 16, alignment: .top)], alignment: .leading, spacing: 16) {
                    ForEach(draft.selectedMembers) { m in
                        VStack(spacing: 6) {
                            NearbyProfileCardView(profile: m, isScanning: false)
                                .frame(width: 72 + 24)
                        }
                        .accessibilityLabel("\(m.name)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("About")
                        .font(.system(.title, weight: .bold))
                        .foregroundStyle(Color.textHeader)
                        .accessibilityAddTraits(.isHeader)
                    Button(action: onEditAbout ?? {}) {
                        Image("union")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .padding(6)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.brandPrimary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit")
                    .accessibilityHint("Edit about")
                    .accessibilityAddTraits(.isButton)
                }
                InfoBox(text: .constant(draft.about), placeholder: nil, isDisabled: true)
            }
        }
    }
}

struct EditGroupSheetContainer: View {
    @ObservedObject var draft: CreateCircleDraft
    @Binding var step: EditGroupStep
    
    let nearbyProfiles: [NearbyProfile]
    let onDone: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let bottomInset = geo.safeAreaInsets.bottom
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if step == .about {
                        HStack {
                            SectionHeaderView(title: step.title)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 48)
                    }
                    
                    Group {
                        switch step {
                        case .overview:
                            OverViewStep(
                                draft: draft,
                                onEditMembers: { step = .members },
                                onEditAbout: { step = .about }
                            )
                        case .members:
                            EditMembersStep(draft: draft, nearbyProfiles: nearbyProfiles)
                        case .about:
                            EditAboutStep(text: $draft.about)
                        case .name:
                            EditNameStep(color: $draft.color, name: $draft.name)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 36)
                .background(Color.activityView)
            }
            
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                    if step == .overview {
                        PrimaryButton(title: "Done") {
                            onDone()
                        }
                    } else {
                        PrimaryButton(title: "Save") {
                            step = .overview
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .padding(.bottom, max(12, bottomInset))
            }
        }
        .background(.activityView)
    }
}

struct EditMembersStep: View {
    @ObservedObject var draft: CreateCircleDraft
    let nearbyProfiles: [NearbyProfile]
    
    private let cardSize: CGFloat = 64
    private let spacing: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(title: "Nearby")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyProfiles) { p in
                            NearbyProfileCardView(profile: p, size: cardSize, ringWidth: 3) {
                                draft.toggle(p)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Members (\(draft.selectedMembers.count))")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }

                if draft.selectedMembers.isEmpty {
                    Text("No members yet. Pick from Nearby above.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(draft.selectedMembers) { m in
                            MemberRow(profile: m)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct EditAboutStep: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoBox(text: $text, placeholder: "Description of the group")
        }
    }
}

struct EditNameStep: View {
    @Binding var color: Color
    @Binding var name: String
    let availableColors: [Color] = [.orange, .blue, .gray, .pink, .yellow]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                InputLabel(title: "Group Name")
                RoundedTextField(text: $name, placeholder: "Enter group name")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                InputLabel(title: "Group Color")
                ColorPickerRow(selectedColor: $color, colors: availableColors)
            }
        }
        .padding(.top, 48)
        .padding(.horizontal)
    }
}

private struct MemberRow: View {
    let profile: NearbyProfile
    var size: CGFloat = 64
    var ringWidth: CGFloat = 4
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: ringWidth)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                
                if let img = profile.image {
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - ringWidth * 2, height: size - ringWidth * 2)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Text(profile.initials)
                                .font(.system(size: size * 0.35, weight: .semibold))
                                .foregroundStyle(.primary)
                        )
                        .frame(width: size - ringWidth * 2, height: size - ringWidth * 2)
                        .accessibilityHidden(true)
                }
            }
            Text(profile.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name), \(profile.team)")
    }
}

// Preview
#Preview {
    let sampleChat = Chat(
        type: .group,
        title: "Design Team",
        color: .blue,
        about: "Team for design discussions",
        members: [
            NearbyProfile(name: "Ayu", team: "Team 2", image: nil, initials: "AY"),
            NearbyProfile(name: "Putri", team: "Team 3", image: nil, initials: "PT")
        ]
    )
    
    let nearbyProfiles: [NearbyProfile] = [
        .init(name: "Saputra", team: "Team 1", image: nil, initials: "SU"),
        .init(name: "Fahrel", team: "Team 5", image: nil, initials: "FA"),
        .init(name: "Bam", team: "Team 4", image: nil, initials: "BAM")
    ]
    
    NavigationStack {
        EditGroupView(
            chat: sampleChat,
            nearbyProfiles: nearbyProfiles
        ) { updatedDraft in
            print("Group updated: \(updatedDraft.name)")
        }
    }
}
