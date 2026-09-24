import Foundation

/// Deterministic, rule-based cleanup of a raw ASR transcript — no ML involved.
/// Mirrors typevoice's rule-based cleanup stage: collapse whitespace, drop
/// filler words, and capitalize sentences so the result reads like a message
/// someone actually typed.
enum TextCleanup {
    /// Kept deliberately short and unambiguous to avoid stripping real words
    /// (e.g. "like" is excluded — it's too often meaningful).
    private static let fillerWords: Set<String> = ["um", "umm", "uh", "uhh", "er", "erm"]

    static func clean(_ raw: String) -> String {
        let collapsed = collapseWhitespace(raw)
        let withoutFillers = removeFillerWords(collapsed)
        let recollapsed = collapseWhitespace(withoutFillers)
        return capitalizeSentences(recollapsed)
    }

    private static func collapseWhitespace(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removeFillerWords(_ text: String) -> String {
        text
            .split(separator: " ")
            .filter { word in
                let bare = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                return !fillerWords.contains(bare)
            }
            .joined(separator: " ")
    }

    private static func capitalizeSentences(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        let terminators: Set<Character> = [".", "!", "?"]
        var result = ""
        var capitalizeNext = true

        for character in text {
            if capitalizeNext, character.isLetter {
                result.append(contentsOf: character.uppercased())
                capitalizeNext = false
            } else {
                result.append(character)
                if terminators.contains(character) {
                    capitalizeNext = true
                } else if !character.isWhitespace {
                    capitalizeNext = false
                }
            }
        }

        return result
    }
}
