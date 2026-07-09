import Testing
@testable import LLMProviderKit

@Suite("extractedJSON")
struct ExtractedJSONTests {

    @Test("raw object passes through")
    func rawObject() {
        let s = #"{"name":"хлеб","value":100}"#
        #expect(s.extractedJSON() == s)
    }

    @Test("strips ```json fences")
    func jsonFence() {
        let s = "```json\n{\"a\":1}\n```"
        #expect(s.extractedJSON() == #"{"a":1}"#)
    }

    @Test("strips bare ``` fences")
    func bareFence() {
        let s = "```\n{\"a\":1}\n```"
        #expect(s.extractedJSON() == #"{"a":1}"#)
    }

    @Test("drops prose around the object")
    func surroundingProse() {
        let s = "Вот ваш рецепт:\n{\"a\":1}\nНадеюсь, поможет!"
        #expect(s.extractedJSON() == #"{"a":1}"#)
    }

    @Test("keeps nested braces intact")
    func nestedBraces() {
        let s = #"prefix {"a":{"b":2},"c":[1,2]} suffix"#
        #expect(s.extractedJSON() == #"{"a":{"b":2},"c":[1,2]}"#)
    }

    @Test("extracts a top-level array")
    func topLevelArray() {
        let s = "[\n  {\"a\":1}\n]"
        #expect(s.extractedJSON() == "[\n  {\"a\":1}\n]")
    }

    @Test("returns trimmed input when no JSON delimiters")
    func noDelimiters() {
        #expect("  no json here  ".extractedJSON() == "no json here")
    }
}
