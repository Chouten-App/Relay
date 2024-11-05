//
//  RequestLocalNetworkAuthorization.swift
//  Nonstrict
//
//  Created by Nonstrict on 10/01/2024.
//

import Foundation
import Network
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nonstrict.localNetworkAuthCheck", category: #fileID)
private let type = "_CC1AD845._googlecast._tcp"

/// Checks whether Local Network permission has been granted, if the authorization state for Local Network usage isn't yet determined it will request the user for permission.
///
/// - Throws: When a network error occurs or a `CancellationError` when cancelled.
/// - Returns: A boolean indicating whether Local Network permission is granted.
func requestLocalNetworkAuthorization() async throws -> Bool {
    let queue = DispatchQueue(label: "com.nonstrict.localNetworkAuthCheck")

    logger.info("Setup listener.")
    let listener = try NWListener(using: NWParameters(tls: .none, tcp: NWProtocolTCP.Options()))
    listener.service = NWListener.Service(name: UUID().uuidString, type: type)
    listener.newConnectionHandler = { _ in } // Must be set or else the listener will error with POSIX error 22

    logger.info("Setup browser.")
    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: parameters)

    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            class LocalState {
                var didResume = false
            }
            let local = LocalState()
            @Sendable func resume(with result: Result<Bool, Error>) {
                if local.didResume {
                    logger.warning("Already resumed, ignoring subsequent result.")
                    return
                }
                local.didResume = true

                // Teardown listener and browser
                listener.stateUpdateHandler = { _ in }
                browser.stateUpdateHandler = { _ in }
                browser.browseResultsChangedHandler = { _, _ in }
                listener.cancel()
                browser.cancel()

                continuation.resume(with: result)
            }

            // Do not setup listener/browser is we're already cancelled, it does work but logs a lot of very ugly errors
            if Task.isCancelled {
                logger.notice("Task cancelled before listener & browser started.")
                resume(with: .failure(CancellationError()))
                return
            }

            listener.stateUpdateHandler = { newState in
                switch newState {
                case .setup:
                    logger.debug("Listener performing setup.")
                case .ready:
                    logger.notice("Listener ready to be discovered.")
                case .cancelled:
                    logger.notice("Listener cancelled.")
                    resume(with: .failure(CancellationError()))
                case .failed(let error):
                    logger.error("Listener failed, stopping. \(error, privacy: .public)")
                    resume(with: .failure(error))
                case .waiting(let error):
                    logger.warning("Listener waiting, stopping. \(error, privacy: .public)")
                    resume(with: .failure(error))
                @unknown default:
                    logger.warning("Ignoring unknown listener state: \(String(describing: newState), privacy: .public)")
                }
            }
            listener.start(queue: queue)

            browser.stateUpdateHandler = { newState in
                switch newState {
                case .setup:
                    logger.debug("Browser performing setup.")
                    return
                case .ready:
                    logger.notice("Browser ready to discover listeners.")
                    return
                case .cancelled:
                    logger.notice("Browser cancelled.")
                    resume(with: .failure(CancellationError()))
                case .failed(let error):
                    logger.error("Browser failed, stopping. \(error, privacy: .public)")
                    resume(with: .failure(error))
                case let .waiting(error):
                    switch error {
                    case .dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied)):
                        logger.notice("Browser permission denied, reporting failure.")
                        resume(with: .success(false))
                    default:
                        logger.error("Browser waiting, stopping. \(error, privacy: .public)")
                        resume(with: .failure(error))
                    }
                @unknown default:
                    logger.warning("Ignoring unknown browser state: \(String(describing: newState), privacy: .public)")
                    return
                }
            }

            browser.browseResultsChangedHandler = { results, changes in
                if results.isEmpty {
                    logger.warning("Got empty result set from browser, ignoring.")
                    return
                }

                logger.notice("Discovered \(results.count) listeners, reporting success.")
                resume(with: .success(true))
            }
            browser.start(queue: queue)

            // Task cancelled while setting up listener & browser, tear down immediatly
            if Task.isCancelled {
                logger.notice("Task cancelled during listener & browser start. (Some warnings might be logged by the listener or browser.)")
                resume(with: .failure(CancellationError()))
                return
            }
        }
    } onCancel: {
        listener.cancel()
        browser.cancel()
    }
}
