import Foundation
import FoundationModels

/// Rewords extracted facts with the on-device Apple Intelligence model.
/// Availability is double-gated: `#available(iOS 26, *)` at call sites plus
/// the runtime model check (absent on non-eligible devices, when Apple
/// Intelligence is off, or while the model downloads). Any failure returns
/// nil and the caller keeps template wording — never a user-facing error.
@available(iOS 26.0, *)
enum FoundationModelComposer {
    @Generable
    struct Wordings {
        @Guide(description: "Exactly one short, playful sentence per fact, in the same order the facts were given.")
        let sentences: [String]
    }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static func compose(facts: [InsightFact], season: Int) async -> [Insight]? {
        guard isAvailable, !facts.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
            You write one-sentence insights for a home gardener's \(season) \
            year-in-review. Tone: warm, playful, a little whimsical. Write \
            exactly one sentence per fact, in the order given. Use only the \
            facts provided. Never invent numbers, weights, percentages, or \
            comparisons that are not stated in the fact.
            """)
        let prompt = "Reword each of these harvest facts as one fun sentence:\n"
            + facts.enumerated()
                .map { "\($0.offset + 1). \($0.element.promptLine)" }
                .joined(separator: "\n")
        guard let response = try? await session.respond(to: prompt, generating: Wordings.self),
              response.content.sentences.count == facts.count
        else { return nil }
        return zip(facts, response.content.sentences).map { fact, sentence in
            Insight(kind: fact.kind, text: sentence, cropName: fact.primaryCrop)
        }
    }
}
