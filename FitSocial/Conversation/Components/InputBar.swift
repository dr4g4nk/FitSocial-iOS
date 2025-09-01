import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let showExtras: Bool
    let isSending: Bool
    let onSend: () -> Void
    let onCamera: () -> Void
    let onAttach: () -> Void
    
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if showExtras {
                Button(action: onCamera) {
                    Image(systemName: "camera")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kamera")
                
                Button(action: onAttach) {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dodaj prilog")
            }
            
            // Tekst polje
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 36, maxHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
                .accessibilityLabel("Poruka")
                .onSubmit { onSend() }
                .focused($focused)
            
            // Send — vidljiv samo kad korisnik kuca (text nije prazan)
            if !showExtras {
                Button {
                    onSend()
                } label: {
                    if isSending {
                        ProgressView().padding(.horizontal, 6)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .padding(8)
                    }
                }
                .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Pošalji")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8) // dodatni padding da "diše" iznad home indicatora
    }
}