import Flutter
import Foundation

final class SharedImportBridgeHandler {
  private enum SharedImportError: Error {
    case containerUnavailable
  }

  private let appGroupIdentifier = "group.com.curator.curatorMobile"
  private let pendingDirectoryName = "SharedImports"

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "listPendingSharedFiles":
        result(try listPendingSharedFiles())
      case "clearPendingSharedFiles":
        let arguments = call.arguments as? [String: Any]
        let rawPaths = arguments?["paths"] as? [String] ?? []
        try clearPendingSharedFiles(paths: rawPaths)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch SharedImportError.containerUnavailable {
      result(
        FlutterError(
          code: "APP_GROUP_UNAVAILABLE",
          message: "Unable to access the shared app group container.",
          details: nil
        )
      )
    } catch {
      result(
        FlutterError(
          code: "SHARED_IMPORT_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func listPendingSharedFiles() throws -> [[String: String]] {
    let directoryURL = try pendingDirectoryURL(createIfNeeded: true)
    let fileManager = FileManager.default
    let fileURLs = try fileManager.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: [.creationDateKey],
      options: [.skipsHiddenFiles]
    )
    let allowedExtensions = Set(["txt", "md"])

    return try fileURLs
      .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
      .sorted(by: { lhs, rhs in
        let lhsValues = try? lhs.resourceValues(forKeys: [.creationDateKey])
        let rhsValues = try? rhs.resourceValues(forKeys: [.creationDateKey])
        let lhsDate = lhsValues?.creationDate ?? .distantPast
        let rhsDate = rhsValues?.creationDate ?? .distantPast
        return lhsDate < rhsDate
      })
      .map { fileURL in
        [
          "path": fileURL.path,
          "name": fileURL.lastPathComponent,
        ]
      }
  }

  private func clearPendingSharedFiles(paths: [String]) throws {
    guard !paths.isEmpty else {
      return
    }

    let directoryURL = try pendingDirectoryURL(createIfNeeded: true)
    let directoryPath = directoryURL.standardizedFileURL.path
    let fileManager = FileManager.default

    for rawPath in paths {
      let fileURL = URL(fileURLWithPath: rawPath).standardizedFileURL
      guard fileURL.path.hasPrefix(directoryPath + "/") else {
        continue
      }

      if fileManager.fileExists(atPath: fileURL.path) {
        try fileManager.removeItem(at: fileURL)
      }
    }
  }

  private func pendingDirectoryURL(createIfNeeded: Bool) throws -> URL {
    guard let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else {
      throw SharedImportError.containerUnavailable
    }

    let directoryURL = containerURL.appendingPathComponent(
      pendingDirectoryName,
      isDirectory: true
    )
    if createIfNeeded {
      try FileManager.default.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }
    return directoryURL
  }
}
