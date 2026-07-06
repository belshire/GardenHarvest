import Foundation
import FoundationModels

/// Generates the "story of the season" with the on-device Apple Intelligence
/// model from the season's facts and the gardener's own harvest notes.
/// Availability is double-gated: `#available(iOS 26, *)` at call sites plus
/// the runtime model check (absent on non-eligible devices, when Apple
/// Intelligence is off, or while the model downloads). Any failure returns
/// nil and the story section stays hidden — never a user-facing error.
@available(iOS 26.0, *)
enum FoundationModelComposer {
    @Generable
    struct Story {
        @Guide(description: "A warm 2-4 sentence story of the garden's season, one paragraph, narrating the crops in the third person — never in the gardener's first-person voice.")
        let story: String
    }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Narrates the season from the extracted facts plus any harvest notes;
    /// with no notes it narrates from the facts alone.
    static func storyText(facts: [InsightFact], notes: [String], season: Int) async -> String? {
        guard isAvailable, !facts.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
            You write a short story-of-the-season recap of a home gardener's \
            \(season) harvest. Narrate the crops and the garden in the third \
            person, like "The asparagus was a true workhorse, bringing 95 \
            days of delicious harvest." You may address the reader as "you" \
            or "your", but NEVER write in the gardener's own voice — no "I", \
            "me", "my", or "mine". Tone: warm, playful, a little whimsical. \
            Write 2 to 4 sentences as one paragraph. Use only the facts and \
            notes provided. Never invent numbers, weights, percentages, or \
            events that are not stated.
            """)
        var prompt = "Facts about the season:\n"
            + facts.map { "- \($0.promptLine)" }.joined(separator: "\n")
        if !notes.isEmpty {
            prompt += "\n\nNotes you wrote while harvesting:\n"
                + notes.map { "- \($0)" }.joined(separator: "\n")
        }
        prompt += "\n\nWrite the story of this season."
        guard let response = try? await session.respond(to: prompt, generating: Story.self)
        else { return nil }
        let text = response.content.story.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !containsFirstPerson(text) else { return nil }
        return text
    }

    /// The small on-device model occasionally slips into the gardener's own
    /// voice despite the instructions; a story that does is discarded (the
    /// section stays hidden and generation retries on the next view).
    static func containsFirstPerson(_ text: String) -> Bool {
        text.range(
            of: #"\b(I|I'[a-z]+|me|my|mine|myself)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
