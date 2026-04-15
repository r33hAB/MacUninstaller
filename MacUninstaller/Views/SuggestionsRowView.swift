import SwiftUI

struct SuggestionsRowView: View {
    let suggestions: [CleanupSuggestion]
    let onDismiss: (CleanupSuggestion) -> Void
    let onReview: (CleanupSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUGGESTIONS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions) { suggestion in
                        SuggestionCardView(
                            suggestion: suggestion,
                            onReview: { onReview(suggestion) },
                            onDismiss: { onDismiss(suggestion) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}
