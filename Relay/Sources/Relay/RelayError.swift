//
//  RelayError.swift
//  Relay
//
//  Created by Inumaki on 11/11/2024.
//

import Foundation

enum RelayError: Error, Sendable {
    case jsNotFound
    case malformedModule
    case malformedData
    case malformedJS
    case infoConversionFailed
    case infoFunctionFailed
    case searchConversionFailed
    case searchFunctionFailed
    case mediaConversionFailed
    case mediaFunctionFailed
    // SendRequest Errors
    case invalidURL
    case httpRequestFailed
    case invalidResponseData
    case sessionError(error: Error)
    case customError(_ string: String)
}
