//
//  APIRequest.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct APIRequest {
    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]
    public let headers: [String: String]
    public let body: (any Encodable)?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

public struct ApiMultipartRequest {
    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]
    public let headers: [String: String]
    public let fields: [UploadField]
    public let files: [UploadFile]
    public let onProgress:
        (_ sent: Int64, _ total: Int64, _ fraction: Double) -> Void
    public let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod = .post,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        fields: [UploadField],
        files: [UploadFile],
        onProgress: @escaping (_: Int64, _: Int64, _: Double) -> Void = {
            _,
            _,
            _ in
        },
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.fields = fields
        self.files = files
        self.onProgress = onProgress
        self.requiresAuth = requiresAuth
    }
}

public struct EmptyResponse: Decodable { public init() {} }

public enum APIError: Error, LocalizedError {
    case noResponse
    case unauthorized  // 401
    case http(status: Int, message: String, data: Data? = nil)
    case decoding(Error)
    case transport(Error)

    public var errorDescription: String? {
        switch self {
        case .noResponse: return "No response from server."
        case .unauthorized: return "Unauthorized."
        case .http(let status, let message, _):
            return "HTTP \(status): \(message)"
        case .decoding(let err):
            return "Decoding error: \(err.localizedDescription)"
        case .transport(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

@globalActor public actor NetworkActor {
    public static let shared = NetworkActor()
}

public final class APIClient {
    let baseURL: URL
    let urlSession: URLSession
    let session: UserSession

    let decoder: JSONDecoder
    let encoder: JSONEncoder

    private let refreshPath: String
    private var refreshTask: Task<Void, Error>?

    private let delegate: UploadSessionDelegate
    private let writer: MultipartBodyWriter

    public init(
        baseURL: URL,
        session: UserSession,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        urlSession: URLSession = .shared,
        refreshPath: String = "auth/refresh"
    ) {
        self.baseURL = baseURL

        let delegate = UploadSessionDelegate()
        self.delegate = delegate

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true  // pametno sa slabim mrežama
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true  // npr. Low Data Mode – ako želiš ipak slati
        config.allowsExpensiveNetworkAccess = true  // 5G/roaming—po potrebi
        config.timeoutIntervalForRequest = 60  // request timeout
        config.timeoutIntervalForResource = 60 * 2 // cijeli transfer (10 min, prilagodi)
        config.httpMaximumConnectionsPerHost = 6  // default OK
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil  // obično ne keširaš upload rute
        config.networkServiceType = .responsiveData  // ili .default

        self.urlSession = URLSession(
            configuration: config,
            delegate: delegate,
            delegateQueue: nil
        )

        self.session = session
        self.encoder = encoder
        self.decoder = decoder

        self.refreshPath = refreshPath

        self.writer = MultipartBodyWriter(encoder: encoder)
    }

    @discardableResult
    public func send<T: Decodable>(_ req: APIRequest)
        async throws -> T
    {
        try await sendInternal(allowRefreshRetry: req.requiresAuth) {
            try await buildURLRequest(from: req)
        }
    }

    @discardableResult
    public func send<T: Decodable>(
        _ req: ApiMultipartRequest
    )
        async throws -> T
    {
        let body = try writer.write(fields: req.fields, files: req.files)
        defer { try? FileManager.default.removeItem(at: body.fileURL) }
        return try await sendInternal(
            sendMultipartData: true,
            bodyUrl: body.fileURL,
            onProgress: req.onProgress,
            allowRefreshRetry: req.requiresAuth
        ) {
            try await buildURLRequest(
                from: req,
                boundary: body.boundary,
                contentLength: body.contentLength
            )
        }
    }

    public func get<T: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        requiresAuth: Bool = true
    )
        async throws -> T
    {
        try await send(
            APIRequest(
                path: path,
                method: .get,
                query: query,
                requiresAuth: requiresAuth
            )
        )
    }

    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(
            APIRequest(
                path: path,
                method: .post,
                body: body,
                requiresAuth: requiresAuth
            )
        )
    }

    public func post<T: Decodable>(
        _ path: String,
        fields: [UploadField],
        files: [UploadFile],
        onProgress: @escaping (
            _ sent: Int64, _ total: Int64, _ fraction: Double
        ) -> Void = { sent, total, fraction in },
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(
            ApiMultipartRequest(
                path: path,
                method: .post,
                fields: fields,
                files: files,
                onProgress: onProgress,
                requiresAuth: requiresAuth
            )
        )
    }

    public func put<T: Decodable, B: Encodable>(_ path: String, body: B)
        async throws -> T
    {
        try await send(APIRequest(path: path, method: .put, body: body))
    }

    public func put<T: Decodable>(
        _ path: String,
        fields: [UploadField],
        files: [UploadFile],
        onProgress: @escaping (
            _ sent: Int64, _ total: Int64, _ fraction: Double
        ) -> Void = { sent, total, fraction in },
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(
            ApiMultipartRequest(
                path: path,
                method: .put,
                fields: fields,
                files: files,
                onProgress: onProgress,
                requiresAuth: requiresAuth
            )
        )
    }

    public func delete<T: Decodable>(_ path: String) async throws -> T {
        try await send(APIRequest(path: path, method: .delete))
    }

    private func sendInternal<T: Decodable>(
        sendMultipartData: Bool = false,
        bodyUrl: URL? = nil,
        onProgress: @escaping (
            _ sent: Int64, _ total: Int64, _ fraction: Double
        ) -> Void = { sent, total, fraction in },
        allowRefreshRetry: Bool,
        buildURLRequest: () async throws -> URLRequest
    ) async throws -> T {
        let request = try await buildURLRequest()

        do {
            let (data, response) =
                !sendMultipartData
                ? try await urlSession.data(for: request)
                : try await performUpload(
                    request: request,
                    fromFile: bodyUrl!,
                    onProgress: onProgress
                )
            guard let http = response as? HTTPURLResponse else {
                throw APIError.noResponse
            }

            let str = String(bytes: data, encoding: .utf8)

            switch http.statusCode {
            case 200..<300, 400:
                if T.self == EmptyResponse.self { return EmptyResponse() as! T }
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decoding(error)
                }

            case 401:
                // Ako je ruta zaštićena i još nismo probali refresh – pokušaj, pa jedan retry.
                if allowRefreshRetry {
                    try await refreshAccessToken()
                    return try await sendInternal(
                        allowRefreshRetry: false,
                        buildURLRequest: buildURLRequest
                    )
                } else {
                    try await session.logout()
                    throw APIError.unauthorized
                }

            default:
                let msg =
                    String(data: data, encoding: .utf8)
                    ?? HTTPURLResponse.localizedString(
                        forStatusCode: http.statusCode
                    )
                throw APIError.http(status: http.statusCode, message: msg)
            }
        } catch {
            if let apiErr = error as? APIError { throw apiErr }
            throw APIError.transport(error)
        }
    }

    private final class _TaskBox: @unchecked Sendable {
        var task: URLSessionUploadTask?
    }

    private final class _DelegateBox: @unchecked Sendable {
        weak var delegate: UploadSessionDelegate?
    }

    private func performUpload(
        request: URLRequest,
        fromFile fileURL: URL,
        onProgress: @escaping (
            _ sent: Int64, _ total: Int64, _ fraction: Double
        ) -> Void
    ) async throws -> (Data, URLResponse) {

        let taskBox = _TaskBox()
        let delegateBox = _DelegateBox()
        delegateBox.delegate = self.delegate

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation {
                    (
                        continuation: CheckedContinuation<
                            (Data, URLResponse), Error
                        >
                    ) in

                    //Kreiraj upload task
                    let task = urlSession.uploadTask(
                        with: request,
                        fromFile: fileURL
                    ) { data, resp, err in
                        // u svakom završetku očisti handler
                        if let t = taskBox.task {
                            delegateBox.delegate?.clearHandler(for: t)
                        }

                        if let err {
                            continuation.resume(throwing: err)
                            return
                        }
                        guard let data, let resp else {
                            continuation.resume(
                                throwing: URLError(.badServerResponse)
                            )
                            return
                        }
                        continuation.resume(returning: (data, resp))
                    }

                    //Zapamti referencu u box-u (vidljiva i u onCancel)
                    taskBox.task = task

                    delegate.setProgressHandler(onProgress, for: task)
                    task.resume()
                }
            },
            onCancel: {
                // Ako je okružujući Swift Task otkazan, prekini mrežni upload
                taskBox.task?.cancel()
            }
        )
    }

    @NetworkActor
    func refreshAccessToken() async throws {
        if let task = refreshTask {
            // Refresh je već u toku – čekaj rezultat tog taska
            try await task.value
            return
        }

        // Kreiraj single-flight task
        let task = Task {
            // 1) Uzmi refresh token
            guard let rt = try await session.readRefreshToken() else {
                throw APIError.unauthorized
            }

            // 2) Pozovi refresh endpoint (bez Authorization headera, bez daljeg refresh pokušaja)
            struct RefreshBody: Encodable { let refreshToken: String }
            struct RefreshResponse: Decodable {
                let token: String
                let refreshToken: String?
                let user: User?
            }

            let refreshReq = APIRequest(
                path: refreshPath,
                method: .post,
                body: RefreshBody(refreshToken: rt),
                requiresAuth: false  // ← veoma bitno
            )

            let res: RefreshResponse = try await sendInternal(
                allowRefreshRetry: false
            ) { try await buildURLRequest(from: refreshReq) }

            // 3) Sačuvaj nove tokene
            try await session.saveTokens(
                access: res.token,
                refresh: res.refreshToken,
                user: res.user
            )
        }

        refreshTask = task
        do {
            try await task.value
        } catch {
            refreshTask = nil
            throw error
        }
        refreshTask = nil
    }

    @NetworkActor
    private func buildURLRequest(from req: APIRequest) async throws
        -> URLRequest
    {
        var url = baseURL.appendingPathComponent(req.path)
        if !req.query.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = req.query
            url = comps.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = req.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Authorization samo ako je potrebno
        if req.requiresAuth {
            if let token = try await session.readAccessToken() {
                request.setValue(
                    "Bearer \(token)",
                    forHTTPHeaderField: "Authorization"
                )
            }
        }

        // Custom headers
        for (k, v) in req.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        // Body
        if let body = req.body {
            let data = try encoder.encode(AnyEncodable(body))
            request.httpBody = data
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        return request
    }

    @NetworkActor
    private func buildURLRequest(
        from req: ApiMultipartRequest,
        boundary: String,
        contentLength: Int64
    ) async throws
        -> URLRequest
    {
        var url = baseURL.appendingPathComponent(req.path)
        if !req.query.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = req.query
            url = comps.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = req.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            String(contentLength),
            forHTTPHeaderField: "Content-Length"
        )

        // Authorization samo ako je potrebno
        if req.requiresAuth {
            if let token = try await session.readAccessToken() {
                request.setValue(
                    "Bearer \(token)",
                    forHTTPHeaderField: "Authorization"
                )
            }
        }

        // Custom headers
        for (k, v) in req.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        return request
    }

}

// Helper da bi (any Encodable) mogao u JSONEncoder
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

final class UploadSessionDelegate: NSObject, URLSessionTaskDelegate {
    typealias ProgressHandler = (
        _ sent: Int64, _ total: Int64, _ fraction: Double
    ) -> Void
    private let lock = NSLock()
    private var handlers: [Int: ProgressHandler] = [:]

    func setProgressHandler(
        _ handler: @escaping ProgressHandler,
        for task: URLSessionTask
    ) {
        lock.lock()
        handlers[task.taskIdentifier] = handler
        lock.unlock()
    }
    func clearHandler(for task: URLSessionTask) {
        lock.lock()
        handlers.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        lock.lock()
        let handler = handlers[task.taskIdentifier]
        lock.unlock()
        guard let handler else { return }
        let total = max(totalBytesExpectedToSend, 1)
        handler(
            totalBytesSent,
            totalBytesExpectedToSend,
            Double(totalBytesSent) / Double(total)
        )
    }
}

public struct UploadField {
    public let name: String
    public let value: Encodable
    public init(name: String, value: Encodable) {
        self.name = name
        self.value = value
    }
}

public struct UploadFile {
    public enum Source {
        case data(Data)
        case fileURL(URL)
    }
    public let name: String
    public let filename: String
    public let mimeType: String
    public let source: Source

    public init(name: String, filename: String, mimeType: String, data: Data) {
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
        self.source = .data(data)
    }
    public init(name: String, fileURL: URL, filename: String, mimeType: String)
    {
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
        self.source = .fileURL(fileURL)
    }
}

final class MultipartBodyWriter {
    private let newline = "\r\n"
    struct Result {
        let fileURL: URL
        let contentLength: Int64
        let boundary: String
    }

    private let encoder: JSONEncoder

    init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    func write(fields: [UploadField], files: [UploadFile]) throws -> Result {
        let boundary = "Boundary-\(UUID().uuidString)"
        let tmp = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        let bodyURL = tmp.appendingPathComponent(
            "multipart-\(UUID().uuidString).tmp"
        )
        FileManager.default.createFile(
            atPath: bodyURL.path,
            contents: nil,
            attributes: nil
        )
        let handle = try FileHandle(forWritingTo: bodyURL)

        var length: Int64 = 0
        func append(_ s: String) throws {
            let d = Data(s.utf8)
            try handle.write(contentsOf: d)
            length += Int64(d.count)
        }
        func append(_ d: Data) throws {
            try handle.write(contentsOf: d)
            length += Int64(d.count)
        }

        for f in fields {
            try append("--\(boundary)\(newline)")
            try append(
                "Content-Disposition: form-data; name=\"\(f.name)\"\(newline)"
            )
            try append(
                "Content-Type: application/json; charset=utf-8\(newline)\(newline)"
            )
            let value = try encoder.encode(f.value)
            try append(value)
            try append("\(newline)")
        }
        for f in files {
            try append("--\(boundary)\(newline)")
            try append(
                "Content-Disposition: form-data; name=\"\(f.name)\"; filename=\"\(f.filename)\"\(newline)"
            )
            try append("Content-Type: \(f.mimeType)\(newline)\(newline)")
            switch f.source {
            case .data(let data): try append(data)
            case .fileURL(let url):
                let r = try FileHandle(forReadingFrom: url)
                while autoreleasepool(invoking: {
                    let chunk = r.readData(ofLength: 1_048_576)
                    if !chunk.isEmpty {
                        try? append(chunk)
                        return true
                    }
                    return false
                }) {}
                try r.close()
            }
            try append(newline)
        }
        try append("--\(boundary)--\(newline)")
        try handle.close()

        return .init(
            fileURL: bodyURL,
            contentLength: length,
            boundary: boundary
        )
    }
}
