//
//  TitleCreditExtractionViewModel.swift
//  onraku
//
//  Created by Codex on 2026/04/24.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct TitleCreditExtractionResult {
  var remixers: [String]
  var featuredArtists: [String]

  var isEmpty: Bool {
    remixers.isEmpty && featuredArtists.isEmpty
  }
}

struct TitleCreditExtractionContext {
  var beatsPerMinute: Int?
  var genre: String?
}

enum TitleCreditExtractionState {
  case idle
  case loading
  case loaded(TitleCreditExtractionResult)
  case unavailable(String)
  case failed(String)
}

protocol TitleCreditExtracting {
  func extract(from title: String, context: TitleCreditExtractionContext) async throws
    -> TitleCreditExtractionResult
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct GeneratedTitleCredits {
  @Guide(
    description:
      "Artists explicitly credited as remixers, refixers, reworkers, bootleggers, or flippers in the title."
  )
  var remixers: [String]

  @Guide(
    description:
      "Artists explicitly credited with feat, featuring, ft, or producer credits in the title."
  )
  var featuredArtists: [String]
}

@available(iOS 26.0, *)
struct FoundationModelTitleCreditExtractor: TitleCreditExtracting {
  private let maximumAttemptCount = 3

  func extract(from title: String, context: TitleCreditExtractionContext) async throws
    -> TitleCreditExtractionResult
  {
    let model = SystemLanguageModel(useCase: .contentTagging)

    switch model.availability {
    case .available:
      break
    case .unavailable(.deviceNotEligible):
      throw TitleCreditExtractorError.unavailable(
        "This device does not support Apple Intelligence.")
    case .unavailable(.appleIntelligenceNotEnabled):
      throw TitleCreditExtractorError.unavailable(
        "Apple Intelligence is not enabled.")
    case .unavailable(.modelNotReady):
      throw TitleCreditExtractorError.unavailable(
        "The on-device language model is not ready yet.")
    case .unavailable:
      throw TitleCreditExtractorError.unavailable(
        "The on-device language model is unavailable.")
    }

    let attempts = makeAttempts()
    var bestResult = TitleCreditExtractionResult(remixers: [], featuredArtists: [])

    for attempt in attempts {
      do {
        try Task.checkCancellation()
        let result = try await extractOnce(
          from: title, context: context, model: model, attempt: attempt)
          .removingMetadataValues(context)
          .keepingOnlyNames(in: title)
          .addingAmpersandNameVariants()

        if result.isAcceptable(for: title) {
          return result
        }

        if result.score > bestResult.score {
          bestResult = result
        }
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        continue
      }
    }

    if !bestResult.isEmpty {
      return bestResult
    }

    let fallbackResult = TitleCreditExtractionResult(
      remixers: title.intelligentlyExtractRemixersCredit(),
      featuredArtists: title.intelligentlyExtractFeaturedArtists()
    )
    .removingMetadataValues(context)
    .addingAmpersandNameVariants()
    if !fallbackResult.isEmpty || title.mightContainExplicitCredit {
      return fallbackResult
    }

    return fallbackResult
  }

  private func extractOnce(
    from title: String,
    context: TitleCreditExtractionContext,
    model: SystemLanguageModel,
    attempt: TitleCreditExtractionAttempt
  ) async throws -> TitleCreditExtractionResult {
    let instructions = """
      Extract explicit music credits from a track title.
      Only use names that appear in the given title.
      Do not infer artists from outside knowledge.
      Do not include the main artist or the track title.
      A remixer credit is the artist name immediately before Remix, Refix, Re-fix, Rework, Bootleg, Boot, or Flip.
      A featured artist credit is the artist name immediately after feat, feat., featuring, ft, ft., or Prod.
      Stop a featured artist credit before a following parenthesized or bracketed remix credit.
      Use BPM and genre only as metadata to disambiguate the title.
      Never return BPM values or genre names as artist names.
      If a remixer credit contains the BPM value, remove the BPM value and return only the artist name.
      If a credited artist name is written as two proper names joined by &, return the full name and each side as candidates.
      Return empty arrays when there is no explicit credit.

      Examples:

      Track title: Song Title
      remixers: []
      featuredArtists: []

      Track title: Artist Name - Song Title
      remixers: []
      featuredArtists: []

      Track title: Song Title _Alex Remix_
      remixers: []
      featuredArtists: []

      Track title: Song Title (Original Mix)
      remixers: []
      featuredArtists: []

      Track title: Foobar (Artist 170 Remix)
      BPM: 170
      Genre: Drum & Bass
      remixers: ["Artist"]
      featuredArtists: []

      Track title: Foobar (170 Remix)
      BPM: 170
      Genre: Jungle
      remixers: []
      featuredArtists: []

      Track title: Song Title -Alex Remix-
      remixers: ["Alex"]
      featuredArtists: []

      Track title: Song Title - Blake Remix -
      remixers: ["Blake"]
      featuredArtists: []

      Track title: Song Title (Casey Remix)
      remixers: ["Casey"]
      featuredArtists: []

      Track title: Song Title (Dana remix)
      remixers: ["Dana"]
      featuredArtists: []

      Track title: Song Title [Elliot Remix]
      remixers: ["Elliot"]
      featuredArtists: []

      Track title: Song Title [Elliot Re-fix]
      remixers: ["Elliot"]
      featuredArtists: []

      Track title: Song Title (Riley Rework)
      remixers: ["Riley"]
      featuredArtists: []

      Track title: Song Title (DJ Nova Remix)
      remixers: ["DJ Nova"]
      featuredArtists: []

      Track title: Song Title (DJ Echo Bootleg)
      remixers: ["DJ Echo"]
      featuredArtists: []

      Track title: Song Title (Riley Flip)
      remixers: ["Riley"]
      featuredArtists: []

      Track title: Song Title (Alex & Blake Remix)
      BPM: 124
      Genre: House
      remixers: ["Alex & Blake", "Alex", "Blake"]
      featuredArtists: []

      Track title: Song Title feat. Mia Lee
      remixers: []
      featuredArtists: ["Mia Lee"]

      Track title: Song Title ft. Riley
      remixers: []
      featuredArtists: ["Riley"]

      Track title: Song Title feat.  Blake
      remixers: []
      featuredArtists: ["Blake"]

      Track title: Song Title featuring Alex
      remixers: []
      featuredArtists: ["Alex"]

      Track title: Song Title feat. Casey (Dana remix)
      remixers: ["Dana"]
      featuredArtists: ["Casey"]

      Track title: Song Title feat. Casey [Dana remix]
      remixers: ["Dana"]
      featuredArtists: ["Casey"]

      Track title: Song Title Prod. Elliot [Dana remix]
      remixers: ["Dana"]
      featuredArtists: ["Elliot"]
      """

    let session = LanguageModelSession(model: model, instructions: instructions)
    let prompt = """
      Track title: \(title)
      BPM: \(context.beatsPerMinute.map(String.init) ?? "unknown")
      Genre: \(context.genre ?? "unknown")
      """
    let response = try await session.respond(
      to: Prompt(prompt),
      generating: GeneratedTitleCredits.self,
      options: attempt.options
    )

    return TitleCreditExtractionResult(
      remixers: response.content.remixers.cleanedCreditNames(),
      featuredArtists: response.content.featuredArtists.cleanedCreditNames()
    )
  }

  private func makeAttempts() -> [TitleCreditExtractionAttempt] {
    (0..<maximumAttemptCount).map { index in
      let seed = UInt64.random(in: UInt64.min...UInt64.max)
      return TitleCreditExtractionAttempt(
        options: GenerationOptions(
          sampling: .random(probabilityThreshold: 0.92, seed: seed),
          temperature: index == 0 ? 0.2 : 0.35
        )
      )
    }
  }
}

@available(iOS 26.0, *)
private struct TitleCreditExtractionAttempt {
  var options: GenerationOptions
}
#endif

enum TitleCreditExtractorError: LocalizedError {
  case unavailable(String)

  var errorDescription: String? {
    switch self {
    case .unavailable(let reason):
      return reason
    }
  }
}

struct UnavailableTitleCreditExtractor: TitleCreditExtracting {
  func extract(from title: String, context: TitleCreditExtractionContext) async throws
    -> TitleCreditExtractionResult
  {
    throw TitleCreditExtractorError.unavailable(
      "This build cannot use Foundation Models.")
  }
}

private extension Array where Element == String {
  func cleanedCreditNames() -> [String] {
    map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .filter { $0.count <= 80 }
      .unique()
  }
}

private extension TitleCreditExtractionResult {
  var score: Int {
    remixers.count + featuredArtists.count
  }

  func isAcceptable(for title: String) -> Bool {
    !title.mightContainExplicitCredit || !isEmpty
  }

  func keepingOnlyNames(in title: String) -> TitleCreditExtractionResult {
    TitleCreditExtractionResult(
      remixers: remixers.filter { title.containsCreditName($0) },
      featuredArtists: featuredArtists.filter { title.containsCreditName($0) }
    )
  }

  func removingMetadataValues(_ context: TitleCreditExtractionContext) -> TitleCreditExtractionResult {
    TitleCreditExtractionResult(
      remixers: remixers.removingMetadataValues(context),
      featuredArtists: featuredArtists.removingMetadataValues(context)
    )
  }

  func addingAmpersandNameVariants() -> TitleCreditExtractionResult {
    TitleCreditExtractionResult(
      remixers: remixers.addingAmpersandNameVariants(),
      featuredArtists: featuredArtists.addingAmpersandNameVariants()
    )
  }
}

private extension Array where Element == String {
  func removingMetadataValues(_ context: TitleCreditExtractionContext) -> [String] {
    let genreNames = context.genre?.intelligentlySplitIntoSubGenres() ?? []

    return map { name in
      if let beatsPerMinute = context.beatsPerMinute {
        return name.removingStandaloneNumber(beatsPerMinute)
      }
      return name
    }
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }
    .filter { name in
      !genreNames.contains { genreName in
        name.compare(genreName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
      }
    }
    .unique()
  }

  func addingAmpersandNameVariants() -> [String] {
    flatMap { name -> [String] in
      guard name.contains(" & ") else { return [name] }

      let splitNames = name.intelligentlySplitIntoSubArtists()
      guard splitNames.count > 1 else { return [name] }

      return [name] + splitNames
    }
    .unique()
  }
}

private extension String {
  var mightContainExplicitCredit: Bool {
    range(
      of: #"(remix|refix|re-fix|rework|bootleg|boot|flip|feat\.?|featuring|ft\.?|prod\.?)"#,
      options: [.regularExpression, .caseInsensitive]
    ) != nil
  }

  func containsCreditName(_ name: String) -> Bool {
    range(
      of: name.trimmingCharacters(in: .whitespacesAndNewlines),
      options: [.caseInsensitive, .diacriticInsensitive]
    ) != nil
  }

  func removingStandaloneNumber(_ number: Int) -> String {
    replacingOccurrences(
      of: #"(?<!\d)\#(number)(?!\d)"#,
      with: "",
      options: .regularExpression
    )
  }
}

@MainActor
final class TitleCreditExtractionViewModel: ObservableObject {
  @Published private(set) var state: TitleCreditExtractionState = .idle

  private let extractor: TitleCreditExtracting
  private var extractionTask: Task<Void, Never>?

  init(extractor: TitleCreditExtracting? = nil) {
    if let extractor {
      self.extractor = extractor
    } else {
      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        self.extractor = FoundationModelTitleCreditExtractor()
      } else {
        self.extractor = UnavailableTitleCreditExtractor()
      }
      #else
      self.extractor = UnavailableTitleCreditExtractor()
      #endif
    }
  }

  deinit {
    extractionTask?.cancel()
  }

  func reset() {
    extractionTask?.cancel()
    state = .idle
  }

  func extractCredits(for song: SongDetailLike) async {
    guard let title = song.title?.trimmingCharacters(in: .whitespacesAndNewlines),
      !title.isEmpty
    else {
      state = .failed("This song has no title to analyze.")
      return
    }

    state = .loading
    extractionTask?.cancel()
    let requestedIdentifier = song.refreshingIdentifier
    let genre = song.genre?.trimmingCharacters(in: .whitespacesAndNewlines)
    let extractionContext = TitleCreditExtractionContext(
      beatsPerMinute: song.beatsPerMinute > 0 ? song.beatsPerMinute : nil,
      genre: genre?.isEmpty == false ? genre : nil
    )

    extractionTask = Task { [weak self] in
      guard let self else { return }

      do {
        let result = try await extractor.extract(from: title, context: extractionContext)
        guard !Task.isCancelled,
          requestedIdentifier == song.refreshingIdentifier
        else { return }

        await MainActor.run {
          self.state = .loaded(result)
        }
      } catch let error as TitleCreditExtractorError {
        guard !Task.isCancelled else { return }
        await MainActor.run {
          self.state = .unavailable(error.localizedDescription)
        }
      } catch {
        guard !Task.isCancelled else { return }
        await MainActor.run {
          self.state = .failed(error.localizedDescription)
        }
      }
    }

    await extractionTask?.value
  }
}
