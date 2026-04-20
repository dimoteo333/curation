import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private enum ShareError: LocalizedError {
    case noSupportedAttachments
    case containerUnavailable
    case unsupportedAttachment

    var errorDescription: String? {
      switch self {
      case .noSupportedAttachments:
        return "No supported shared content was found."
      case .containerUnavailable:
        return "Unable to access the shared app group container."
      case .unsupportedAttachment:
        return "The shared item is not a supported text or markdown payload."
      }
    }
  }

  private let appGroupIdentifier = "group.com.curator.curatorMobile"
  private let pendingDirectoryName = "SharedImports"
  private var hasProcessedInput = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !hasProcessedInput else {
      return
    }

    hasProcessedInput = true
    processSharedContent()
  }

  private func processSharedContent() {
    let extensionItems = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    let attachments = extensionItems.flatMap { $0.attachments ?? [] }
    guard !attachments.isEmpty else {
      completeRequest()
      return
    }

    let dispatchGroup = DispatchGroup()
    let sharedAt = Date()
    var savedCount = 0
    var firstError: Error?

    for (index, provider) in attachments.enumerated() {
      dispatchGroup.enter()
      saveAttachment(
        provider,
        sharedAt: sharedAt,
        index: index
      ) { result in
        switch result {
        case .success:
          savedCount += 1
        case .failure(let error):
          firstError = firstError ?? error
        }
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      if savedCount > 0 {
        self.completeRequest()
        return
      }

      self.cancelRequest(error: firstError ?? ShareError.noSupportedAttachments)
    }
  }

  private func saveAttachment(
    _ provider: NSItemProvider,
    sharedAt: Date,
    index: Int,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    let suggestedBaseName = normalizedBaseName(
      provider.suggestedName,
      sharedAt: sharedAt,
      index: index
    )

    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
      provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
        if let error {
          completion(.failure(error))
          return
        }

        guard let sourceURL = self.extractURL(from: item) else {
          completion(.failure(ShareError.unsupportedAttachment))
          return
        }

        do {
          try self.copyFileIfSupported(from: sourceURL, preferredBaseName: suggestedBaseName)
          completion(.success(()))
        } catch {
          completion(.failure(error))
        }
      }
      return
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
        if let error {
          completion(.failure(error))
          return
        }

        guard let url = self.extractURL(from: item) else {
          completion(.failure(ShareError.unsupportedAttachment))
          return
        }

        do {
          if url.isFileURL {
            try self.copyFileIfSupported(from: url, preferredBaseName: suggestedBaseName)
          } else {
            try self.writeText(url.absoluteString, baseName: suggestedBaseName, fileExtension: "txt")
          }
          completion(.success(()))
        } catch {
          completion(.failure(error))
        }
      }
      return
    }

    let supportedTextTypes = [UTType.plainText.identifier, UTType.text.identifier]
    if let textType = supportedTextTypes.first(where: provider.hasItemConformingToTypeIdentifier(_:)) {
      provider.loadItem(forTypeIdentifier: textType, options: nil) { item, error in
        if let error {
          completion(.failure(error))
          return
        }

        guard let text = self.extractText(from: item), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          completion(.failure(ShareError.unsupportedAttachment))
          return
        }

        do {
          try self.writeText(text, baseName: suggestedBaseName, fileExtension: "txt")
          completion(.success(()))
        } catch {
          completion(.failure(error))
        }
      }
      return
    }

    completion(.failure(ShareError.unsupportedAttachment))
  }

  private func copyFileIfSupported(from sourceURL: URL, preferredBaseName: String) throws {
    let fileManager = FileManager.default
    let fileExtension = sourceURL.pathExtension.lowercased()
    guard fileExtension == "txt" || fileExtension == "md" else {
      let text = try String(contentsOf: sourceURL, encoding: .utf8)
      try writeText(text, baseName: preferredBaseName, fileExtension: "txt")
      return
    }

    let destinationURL = try uniqueDestinationURL(
      baseName: preferredBaseName,
      fileExtension: fileExtension
    )
    if fileManager.fileExists(atPath: destinationURL.path) {
      try fileManager.removeItem(at: destinationURL)
    }
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
  }

  private func writeText(_ text: String, baseName: String, fileExtension: String) throws {
    let destinationURL = try uniqueDestinationURL(
      baseName: baseName,
      fileExtension: fileExtension
    )
    try text.write(to: destinationURL, atomically: true, encoding: .utf8)
  }

  private func uniqueDestinationURL(baseName: String, fileExtension: String) throws -> URL {
    let pendingDirectory = try pendingDirectoryURL()
    let fileName = "\(baseName)-\(UUID().uuidString).\(fileExtension)"
    return pendingDirectory.appendingPathComponent(fileName, isDirectory: false)
  }

  private func pendingDirectoryURL() throws -> URL {
    guard let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else {
      throw ShareError.containerUnavailable
    }

    let directoryURL = containerURL.appendingPathComponent(
      pendingDirectoryName,
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true,
      attributes: nil
    )
    return directoryURL
  }

  private func normalizedBaseName(_ rawValue: String?, sharedAt: Date, index: Int) -> String {
    let candidate = (rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      ? rawValue
      : timestampFormatter.string(from: sharedAt) + "-\(index + 1)") ?? "apple-note"
    let sanitized = candidate
      .replacingOccurrences(
        of: "[^A-Za-z0-9가-힣_-]+",
        with: "-",
        options: .regularExpression
      )
      .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
    return sanitized.isEmpty ? "apple-note" : sanitized
  }

  private func extractURL(from item: NSSecureCoding?) -> URL? {
    if let url = item as? URL {
      return url
    }
    if let text = item as? String {
      return URL(string: text)
    }
    return nil
  }

  private func extractText(from item: NSSecureCoding?) -> String? {
    if let text = item as? String {
      return text
    }
    if let attributedText = item as? NSAttributedString {
      return attributedText.string
    }
    if let url = item as? URL {
      return url.absoluteString
    }
    return nil
  }

  private func completeRequest() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  private func cancelRequest(error: Error) {
    extensionContext?.cancelRequest(withError: error)
  }

  private let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter
  }()
}
