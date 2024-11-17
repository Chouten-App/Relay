// The Swift Programming Language
// https://docs.swift.org/swift-book

import OSLog
import Foundation
import Core
@preconcurrency import JavaScriptCore

public final class Relay: RelayProvider {
    let logger = Logger(subsystem: "com.inumaki.Chouten", category: "Relay")
    
    var type: ModuleType = .video

    var context: JSContext = JSContext()

    var cookies: String?
    
    public init() {
        logger.info("Initializing Relay")
        
        // Handle JavaScript exceptions
        context.exceptionHandler = { _, exception in
            print(exception?.toString() ?? "Unknown error.")
        }
    }
    
    public func loadModule(_ fileURL: URL, completion: @escaping (Result<Module, any Error>) -> Void) {
        completion(.failure("Unimplemented"))
    }
    
    // MARK: General Functions
    
    public func info(_ url: String, completion: @escaping (Result<InfoData, any Error>) -> Void) async {
        log("Info", description: "Fetching Info Data.")
        
        do {
            let value = try await callAsyncFunction("instance.info('\(url)')")
            
            log("Info", description: "Converting jsValue to InfoData.")
            if let info = InfoData(jsValue: value) {
                completion(.success(info))
            }
            
            log("Info", description: "Converting the jsValue to InfoData failed.", type: .error)
            completion(.failure(RelayError.infoConversionFailed))
        } catch {
            log("Info", description: error.localizedDescription, type: .error)
            completion(.failure(RelayError.infoFunctionFailed))
        }
    }
    
    public func search(_ url: String, completion: @escaping (Result<SearchResult, any Error>) -> Void, _ page: Int) async {
        log("Search", description: "Fetching Search Data.")
        
        do {
            let value = try await callAsyncFunction("instance.search('\(url)', \(page))")
            
            log("Search", description: "Converting jsValue to SearchResult.")
            if let searchResult = SearchResult(jsValue: value) {
                completion(.success(searchResult))
            }
            
            log("Search", description: "Converting the jsValue to SearchResult failed.", type: .error)
            completion(.failure(RelayError.searchConversionFailed))
        } catch {
            log("Search", description: error.localizedDescription, type: .error)
            completion(.failure(RelayError.searchFunctionFailed))
        }
    }
    
    public func discover(completion: @escaping (Result<[DiscoverSection], any Error>) -> Void) async {
        completion(.failure("Unimplemented"))
    }
    
    public func media(_ url: String, completion: @escaping (Result<[MediaList], any Error>) -> Void) async {
        completion(.failure("Unimplemented"))
    }
    
    // MARK: Video Content
    
    public func sources(_ url: String, completion: @escaping (Result<[SourceList], any Error>) -> Void) async {
        completion(.failure("Unimplemented"))
    }
    
    public func streams(_ url: String, completion: @escaping (Result<MediaStream, any Error>) -> Void) async {
        completion(.failure("Unimplemented"))
    }
    
    // MARK: Book content
    
    public func pages(_ url: String, completion: @escaping (Result<[String], any Error>) -> Void) async {
        completion(.failure("Unimplemented"))
    }
    
    // MARK: Helpers
    
    public func getCurrentModuleType(completion: @escaping (Result<ModuleType, any Error>) -> Void) {
        completion(.failure("Unimplemented"))
    }
    
    // MARK: Private Functions
    
    private func log(_ title: String, description: String, type: LogType = .info) {
        switch type {
        case .info:
            logger.info("\(description)")
        case .warning:
            logger.warning("\(description)")
        case .error:
            logger.error("\(description)")
        }
        
        /*
        LogManager.shared.log(title, description: description, line: "")
        
        if type == .error {
            DispatchQueue.main.async {
                window?.rootViewController?.view.showErrorDisplay(
                    message: title,
                    description: description,
                    indicator: "Relay",
                    type: ErrorType.error
                )
            }
        }
         */
    }
    
    private func callAsyncFunction(_ js: String) async throws -> JSValue {
        try await context.callAsyncFunction(js)
    }
    
    private func registerInContext(_ context: JSContext) {
        let consoleLog: @convention(block) (String, String, Int, Int) -> Void = { message, url, line, column in
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: date)

            // LogManager.shared.log("Log", description: message, line: "\(line):\(column)")

            print("LOG: \(message)")
            print("Time: \(dateString)")
            print("File: \(url)")
            print("Line: \(line)")
            print("Column: \(column)")
        }

        // Define the consoleError block to include error details
        let consoleError: @convention(block) (String, String, Int, Int) -> Void = { message, url, line, column in
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: date)

            // LogManager.shared.log("Log", description: message, type: .error, line: "\(line):\(column)")

            /*
            DispatchQueue.main.async {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                let window = windowScene?.windows.first

                if let view = window?.rootViewController?.view {
                    view.showErrorDisplay(message: "Relay", description: message, type: .error)
                }
            }
            */
            print("ERROR: \(message)")
            print("Time: \(dateString)")
            print("File: \(url)")
            print("Line: \(line)")
            print("Column: \(column)")
        }

        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        context.setObject(consoleError, forKeyedSubscript: "consoleError" as NSString)
        context.evaluateScript("""
            function getStackDetails() {
                return {
                    url: "hm",
                    line: 0,
                    column: 0
                };
            }

            console.log = function(message) {
                var details = getStackDetails();
                consoleLog(message, details.url, details.line, details.column);
            };

            console.error = function(message) {
                var details = getStackDetails();
                consoleError(message, details.url, details.line, details.column);
            };
        """)

        let sendRequest: @convention(block) (String, String, [String: String], String?) -> JSValue = { url, method, headers, body in
            self.sendRequest(url: url, method: method, headers: headers, body: body)
        }

        context.setObject(sendRequest, forKeyedSubscript: "request" as NSString)

        let callWebview: @convention(block) (String) -> JSValue = { url in
            self.callWebviewJS(url: url)
        }

        context.setObject(callWebview, forKeyedSubscript: "callWebview" as NSString)
    }
}

// MARK: SendRequest Extension
extension Relay {
    public func sendRequest(url: String, method: String, headers: [String: String] = [:], body: String? = nil) -> JSValue {
        logger.info("""
        ------------
        🌐 URL Request 🌐
        ------------
        Method: \(method)
        URL: \(url)
        Headers: \(headers)
        Body: \(body)
        """)
        // swiftlint:disable force_unwrapping
        let context = JSContext.current()!
        // swiftlint:enable force_unwrapping

        let promiseFunction: @convention(block) (JSValue, JSValue) -> Void = { resolve, reject in
            // Assuming self.sendRequest is a function that performs the network request and calls the completion handler with RequestResponse and an optional Error
            self.sendRequest(url: url, method: method, headers: headers, body: body) { (response: Response?, error: Error?) in
                if let error = error {
                    print("Rejected the promise. Reason: \(error.localizedDescription)")
                    reject.call(withArguments: [error.localizedDescription])
                } else if let response = response {
                    /*
                    self.logger.info("""
                    ------------
                    🌐 URL Response 🌐
                    ------------
                    Status Code: \(response.statusCode)
                    Content-Type: \(response.contentType)
                    Headers: \(response.headers)
                    Response Body: \(response.body)
                    """)
                     */
                    let jsResponse = JSValue.fromRequestResponse(response, in: context)
                    resolve.call(withArguments: [jsResponse as Any])
                }
            }
        }

        let promise = context.objectForKeyedSubscript("Promise").construct(withArguments: [JSValue(object: promiseFunction, in: context) as Any])
        // swiftlint:disable force_unwrapping
        return promise!
        // swiftlint:enable force_unwrapping
    }

    func sendRequest(url: String, method: String, headers: [String: String] = [:], body: String? = nil, completion: @Sendable @escaping (Response?, RelayError?) -> Void) {
        guard let requestUrl = URL(string: url) else {
            completion(nil, .invalidURL)
            return
        }

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": Constants.userAgent]
        let session = URLSession(configuration: config)

        var request = URLRequest(url: requestUrl)
        request.httpMethod = method

        if method.lowercased() == "post" {
            request.httpBody = body?.data(using: .utf8)
        }

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        if let cookies = UserDefaults.standard.string(forKey: "Cookies-\(requestUrl.getDomain() ?? "")") {
            request.addValue(cookies, forHTTPHeaderField: "Cookie")
        }

        request.addValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")

        session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("session error: \(String(describing: error?.localizedDescription))")
                completion(nil, .sessionError(error: error!))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { // , 200..<300 ~= httpResponse.statusCode else {
                print("http request failed")
                completion(nil, .httpRequestFailed)
                return
            }

            if let responseData = String(data: data, encoding: .utf8) {
                completion(
                    Response(
                        statusCode: httpResponse.statusCode,
                        headers: [:],
                        contentType: httpResponse.mimeType ?? "",
                        body: responseData
                    ),
                    nil
                )
            } else {
                print("invalid response data")
                completion(nil, .invalidResponseData)
            }
        }.resume()
    }
}

// MARK: Webview Extension
extension Relay {
    func callWebviewJS(url: String) -> JSValue {
        // swiftlint:disable force_unwrapping
        let context = JSContext.current()!

        let promise = JSValue(newPromiseIn: context) { resolve, reject in
            self.callWebviewInternal(url: url) { value, error in
                if let error = error {
                    reject?.call(withArguments: [error.localizedDescription])
                } else if let response = value {
                    // Convert response to JSValue
                    let jsResponse = self.convertToJSValue(response, in: context, with: url)
                    resolve?.call(withArguments: [jsResponse])
                } else {
                    reject?.call(withArguments: ["Unexpected response format"])
                }
            }
        }

        return promise!
        // swiftlint:enable force_unwrapping
    }

    func convertCookiesToString(cookies: [String: Any]) -> String {
        var cookiesString = ""

        for (key, value) in cookies {
            if let cookieDict = value as? [String: Any],
               let cookieValue = cookieDict["Value"] as? String {
                if !cookiesString.isEmpty {
                    cookiesString += "; "
                }
                cookiesString += "\(key)=\(cookieValue)"
            }
        }

        return cookiesString
    }

    // Function to encapsulate the concatenated cookies string into a dictionary
    func convertCookiesToJSHeaders(cookies: [String: Any]) -> [String: String] {
        let cookiesString = convertCookiesToString(cookies: cookies)
        self.cookies = cookiesString
        return ["Cookie": cookiesString]
    }

    // Helper function to convert [String: Any] with string values to JSValue
    private func convertToJSValue(_ dictionary: [String: Any], in context: JSContext, with url: String) -> JSValue {
        let jsObject = JSValue(newObjectIn: context)

        let converted = convertCookiesToJSHeaders(cookies: dictionary)

        if let hostUrl = URL(string: url) {
            let userDefaults = UserDefaults.standard
            userDefaults.set(converted.first?.value, forKey: "Cookies-\(hostUrl.getDomain() ?? "")")
        }
        for (key, value) in converted {
            jsObject?.setObject(value, forKeyedSubscript: key as NSString)
        }

        // swiftlint:disable force_unwrapping
        return jsObject!
        // swiftlint:enable force_unwrapping
    }

    func callWebviewInternal(url: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        DispatchQueue.main.async {
//            DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 4) {
//                completion(["HM": "HM"], nil)
//            }
            /*
            let scenes = UIApplication.shared.connectedScenes
            guard let windowScene = scenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let navController = window.rootViewController as? UINavigationController else {
//                DispatchQueue.global(qos: .background).async {
//                    completion(nil, NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to find the root view controller"]))
//                }
                return
            }
            let vc = CloudflareWebview(url: url) { value, error in
                DispatchQueue.global(qos: .background).async {
                    completion(value, error)
                    DispatchQueue.main.async {
                        navController.dismiss(animated: true)
                    }
                }
            }

            let popoverController = vc.popoverPresentationController
            popoverController?.sourceView = navController.view
            popoverController?.sourceRect = navController.view.bounds
            popoverController?.permittedArrowDirections = .any

            navController.present(vc, animated: true, completion: nil)
             */
        }
    }
}
