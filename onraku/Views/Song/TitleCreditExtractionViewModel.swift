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

enum TitleCreditExtractionState {
  case idle
  case loading
  case loaded(TitleCreditExtractionResult)
  case unavailable(String)
  case failed(String)
}

protocol TitleCreditExtracting {
  func extract(from title: String) async throws -> TitleCreditExtractionResult
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
  func extract(from title: String) async throws -> TitleCreditExtractionResult {
    let model = SystemLanguageModel.default

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

    let instructions = """
      Extract explicit music credits from a track title.
      Only use names that appear in the given title.
      Do not infer artists from outside knowledge.
      Do not include the main artist or the track title.
      A remixer credit is the artist name immediately before Remix, Refix, Re-fix, Rework, Bootleg, Boot, or Flip.
      A featured artist credit is the artist name immediately after feat, feat., featuring, ft, ft., or Prod.
      Stop a featured artist credit before a following parenthesized or bracketed remix credit.
      Return empty arrays when there is no explicit credit.

      Examples:

      Track title: hoge
      remixers: []
      featuredArtists: []

      Track title: hoge -ababa Remix-
      remixers: ["ababa"]
      featuredArtists: []

      Track title: hoge - obobo Remix -
      remixers: ["obobo"]
      featuredArtists: []

      Track title: hoge (fuga Remix)
      remixers: ["fuga"]
      featuredArtists: []

      Track title: hoge [foo Remix]
      remixers: ["foo"]
      featuredArtists: []

      Track title: hoge (DJ Nantoka Remix)
      remixers: ["DJ Nantoka"]
      featuredArtists: []

      Track title: hoge (DJ Untara Bootleg)
      remixers: ["DJ Untara"]
      featuredArtists: []

      Track title: hoge (bar Flip)
      remixers: ["bar"]
      featuredArtists: []

      Track title: hoge feat. pi yo
      remixers: []
      featuredArtists: ["pi yo"]

      Track title: hoge ft. bar
      remixers: []
      featuredArtists: ["bar"]

      Track title: hoge featuring ababa
      remixers: []
      featuredArtists: ["ababa"]

      Track title: hoge feat. fuga (piyo remix)
      remixers: ["piyo"]
      featuredArtists: ["fuga"]

      Track title: hoge feat. fuga2 [piyo remix]
      remixers: ["piyo"]
      featuredArtists: ["fuga2"]

      Track title: hoge Prod. foo [piyo remix]
      remixers: ["piyo"]
      featuredArtists: ["foo"]
      """
    let session = LanguageModelSession(instructions: instructions)
    let prompt = "Track title: \(title)"
    let response = try await session.respond(
      to: Prompt(prompt),
      generating: GeneratedTitleCredits.self
    )

    return TitleCreditExtractionResult(
      remixers: response.content.remixers.cleanedCreditNames(),
      featuredArtists: response.content.featuredArtists.cleanedCreditNames()
    )
  }
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
  func extract(from title: String) async throws -> TitleCreditExtractionResult {
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

    extractionTask = Task { [weak self] in
      guard let self else { return }

      do {
        let result = try await extractor.extract(from: title)
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
