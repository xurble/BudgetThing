//
//  BankClient.swift
//  dime
//
//  Created by Codex on 3/13/26.
//

import Foundation

final class BankClient {
    enum AuthToken {
        case none
        case bff(String)
    }

    struct HealthStatus {
        let status: String
        let environment: String
    }

    struct DeviceRegistrationChallenge {
        let challengeId: String
        let challenge: String
        let expiresAt: Date
        let teamId: String
        let bundleId: String
    }

    struct DeviceRegistrationResult {
        let deviceId: String
        let keyId: String
        let appId: String
        let status: String
        let registeredAt: Date
    }

    struct EntitlementSyncResult {
        let productId: String
        let originalTransactionId: String
        let transactionId: String
        let status: String
        let expiresAt: Date?
        let environment: String
        let lastVerifiedAt: Date
    }

    struct SessionChallenge {
        let challengeId: String
        let challenge: String
        let expiresAt: Date
        let teamId: String
        let bundleId: String
    }

    struct SessionResult {
        let accessToken: String
        let expiresAt: Date
        let expiresInSeconds: Int
        let sessionId: String
        let userId: String
        let deviceId: String
        let entitlementProductId: String
        let entitlementStatus: String
        let entitlementExpiresAt: Date?
    }

    struct DeviceRecord {
        let deviceId: String
        let keyId: String
        let appId: String
        let status: String
        let createdAt: Date
        let lastVerifiedAt: Date?
        let lastAssertionAt: Date?
    }

    struct EntitlementRecord {
        let entitlementId: String
        let platform: String
        let productId: String
        let originalTransactionId: String
        let transactionId: String?
        let status: String
        let environment: String
        let purchasedAt: Date?
        let expiresAt: Date?
        let lastVerifiedAt: Date
    }

    struct LinkTokenResult {
        let linkToken: String
        let expiration: Date
        let requestId: String?
    }

    struct ExchangeResult {
        let connection: ConnectionSummary
        let accounts: [AccountRecord]
    }

    struct ConnectionSummary {
        let connectionId: String
        let institutionId: String?
        let institutionName: String?
        let status: String
        let createdAt: Date
        let updatedAt: Date?
        let lastSyncAt: Date?
        let accountCount: Int
    }

    struct AccountRecord {
        let providerAccountId: String
        let name: String
        let officialName: String?
        let mask: String?
        let type: String?
        let subtype: String?
        let currentBalance: Double?
        let availableBalance: Double?
        let isoCurrencyCode: String?
    }

    struct ConnectionDetail {
        let connectionId: String
        let institutionId: String?
        let institutionName: String?
        let status: String
        let createdAt: Date
        let updatedAt: Date?
        let lastSyncAt: Date?
        let accounts: [AccountRecord]
    }

    struct AccountBalance {
        let providerAccountId: String
        let currentBalance: Double?
        let availableBalance: Double?
        let isoCurrencyCode: String?
    }

    struct TransactionRecord {
        let providerTransactionId: String
        let providerAccountId: String
        let amount: Double
        let isoCurrencyCode: String?
        let date: Date
        let authorizedDate: Date?
        let name: String
        let merchantName: String?
        let paymentChannel: String?
        let pending: Bool
        let personalFinanceCategoryPrimary: String?
        let rawJSON: String?
    }

    struct RemovedTransactionRecord {
        let providerTransactionId: String
    }

    struct SyncTransactions {
        let added: [TransactionRecord]
        let modified: [TransactionRecord]
        let removed: [RemovedTransactionRecord]
    }

    struct SyncResult {
        let connectionId: String
        let status: String
        let syncType: String
        let fetchedAt: Date
        let nextCursor: String?
        let accounts: [AccountBalance]
        let transactions: SyncTransactions
    }

    struct SyncAllEntry {
        let success: Bool
        let connectionId: String
        let result: SyncResult?
        let errorCode: String?
        let errorMessage: String?
    }

    struct SyncSummary {
        let connectionCount: Int
        let successCount: Int
        let failureCount: Int
        let addedCount: Int
        let modifiedCount: Int
        let removedCount: Int
    }

    struct SyncAllResult {
        let results: [SyncAllEntry]
        let summary: SyncSummary
    }

    struct UnlinkResult {
        let connectionId: String
        let status: String
    }

    enum BankClientError: Error, LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case httpError(statusCode: Int, code: String?, message: String?, correlationId: String?)
        case validationError(statusCode: Int, body: String)
        case missingToken

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Invalid base URL"
            case .invalidResponse:
                return "Invalid response"
            case let .httpError(statusCode, code, message, correlationId):
                let parts = [code, message, correlationId].compactMap { $0 }
                let detail = parts.isEmpty ? "" : " (\(parts.joined(separator: ", ")))"
                return "HTTP \(statusCode)\(detail)"
            case let .validationError(statusCode, body):
                return "Validation error \(statusCode): \(body)"
            case .missingToken:
                return "Missing auth token"
            }
        }
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL? = nil, session: URLSession = .shared) throws {
        self.baseURL = try baseURL ?? BankClient.defaultBaseURL()
        self.session = session
        self.decoder = BankClient.makeDecoder()
        self.encoder = BankClient.makeEncoder()
    }

    static func defaultBaseURL() throws -> URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "APP_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }

        guard let url = URL(string: "http://localhost:8787") else {
            throw BankClientError.invalidBaseURL
        }

        return url
    }

    func health() async throws -> HealthStatus {
        let response: HealthResponse = try await send(
            path: "/health",
            method: "GET",
            token: .none
        )

        return HealthStatus(status: response.status, environment: response.environment)
    }

    func deviceRegisterChallenge(accountId: String, deviceId: String) async throws -> DeviceRegistrationChallenge {
        let response: DeviceRegisterChallengeResponse = try await send(
            path: "/auth/device/register/challenge",
            method: "POST",
            token: .none,
            body: DeviceRegisterChallengeRequest(accountId: accountId, deviceId: deviceId)
        )

        return DeviceRegistrationChallenge(
            challengeId: response.challengeId,
            challenge: response.challenge,
            expiresAt: response.expiresAt,
            teamId: response.attestation.teamId,
            bundleId: response.attestation.bundleId
        )
    }

    func deviceRegister(
        challengeId: String,
        accountId: String,
        deviceId: String,
        keyId: String,
        attestationObject: String
    ) async throws -> DeviceRegistrationResult {
        let response: DeviceRegisterResponse = try await send(
            path: "/auth/device/register",
            method: "POST",
            token: .none,
            body: DeviceRegisterRequest(
                challengeId: challengeId,
                accountId: accountId,
                deviceId: deviceId,
                keyId: keyId,
                attestationObject: attestationObject
            )
        )

        return DeviceRegistrationResult(
            deviceId: response.device.deviceId,
            keyId: response.device.keyId,
            appId: response.device.appId,
            status: response.device.status,
            registeredAt: response.device.registeredAt
        )
    }

    func syncEntitlement(
        accountId: String,
        productId: String,
        transactionId: String,
        originalTransactionId: String,
        appAccountToken: String?,
        signedTransactionInfo: String?,
        signedRenewalInfo: String?,
        challengeId: String? = nil,
        deviceId: String? = nil,
        keyId: String? = nil,
        assertion: String? = nil
    ) async throws -> EntitlementSyncResult {
        let response: EntitlementSyncResponse = try await send(
            path: "/auth/entitlements/app-store/sync",
            method: "POST",
            token: .none,
            body: EntitlementSyncRequest(
                accountId: accountId,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                appAccountToken: appAccountToken,
                signedTransactionInfo: signedTransactionInfo,
                signedRenewalInfo: signedRenewalInfo,
                challengeId: challengeId,
                deviceId: deviceId,
                keyId: keyId,
                assertion: assertion
            )
        )

        return EntitlementSyncResult(
            productId: response.entitlement.productId,
            originalTransactionId: response.entitlement.originalTransactionId,
            transactionId: response.entitlement.transactionId,
            status: response.entitlement.status,
            expiresAt: response.entitlement.expiresAt,
            environment: response.entitlement.environment,
            lastVerifiedAt: response.entitlement.lastVerifiedAt
        )
    }

    func authChallenge(accountId: String, deviceId: String, purpose: String? = nil) async throws -> SessionChallenge {
        let response: AuthChallengeResponse = try await send(
            path: "/auth/challenge",
            method: "POST",
            token: .none,
            body: AuthChallengeRequest(accountId: accountId, deviceId: deviceId, purpose: purpose)
        )

        return SessionChallenge(
            challengeId: response.challengeId,
            challenge: response.challenge,
            expiresAt: response.expiresAt,
            teamId: response.attestation.teamId,
            bundleId: response.attestation.bundleId
        )
    }

    func authSession(
        challengeId: String,
        accountId: String,
        deviceId: String,
        keyId: String,
        assertion: String
    ) async throws -> SessionResult {
        let response: AuthSessionResponse = try await send(
            path: "/auth/session",
            method: "POST",
            token: .none,
            body: AuthSessionRequest(
                challengeId: challengeId,
                accountId: accountId,
                deviceId: deviceId,
                keyId: keyId,
                assertion: assertion
            )
        )

        return SessionResult(
            accessToken: response.accessToken,
            expiresAt: response.expiresAt,
            expiresInSeconds: response.expiresInSeconds,
            sessionId: response.session.sessionId,
            userId: response.session.userId,
            deviceId: response.session.deviceId,
            entitlementProductId: response.entitlement.productId,
            entitlementStatus: response.entitlement.status,
            entitlementExpiresAt: response.entitlement.expiresAt
        )
    }

    func listDevices(bffToken: String) async throws -> [DeviceRecord] {
        let response: DevicesResponse = try await send(
            path: "/auth/devices",
            method: "GET",
            token: .bff(bffToken)
        )

        return response.devices.map {
            DeviceRecord(
                deviceId: $0.deviceId,
                keyId: $0.keyId,
                appId: $0.appId,
                status: $0.status,
                createdAt: $0.createdAt,
                lastVerifiedAt: $0.lastVerifiedAt,
                lastAssertionAt: $0.lastAssertionAt
            )
        }
    }

    func listEntitlements(bffToken: String) async throws -> [EntitlementRecord] {
        let response: EntitlementsResponse = try await send(
            path: "/auth/entitlements",
            method: "GET",
            token: .bff(bffToken)
        )

        return response.entitlements.map {
            EntitlementRecord(
                entitlementId: $0.entitlementId,
                platform: $0.platform,
                productId: $0.productId,
                originalTransactionId: $0.originalTransactionId,
                transactionId: $0.transactionId,
                status: $0.status,
                environment: $0.environment,
                purchasedAt: $0.purchasedAt,
                expiresAt: $0.expiresAt,
                lastVerifiedAt: $0.lastVerifiedAt
            )
        }
    }

    func createLinkToken(
        clientName: String? = nil,
        language: String? = nil,
        countryCodes: [String]? = nil,
        products: [String]? = nil,
        redirectUri: String? = nil,
        bffToken: String
    ) async throws -> LinkTokenResult {
        let response: LinkTokenResponse = try await send(
            path: "/link/token/create",
            method: "POST",
            token: .bff(bffToken),
            body: LinkTokenRequest(
                clientName: clientName,
                language: language,
                countryCodes: countryCodes,
                products: products,
                redirectUri: redirectUri
            )
        )

        return LinkTokenResult(
            linkToken: response.linkToken,
            expiration: response.expiration,
            requestId: response.requestId
        )
    }

    func exchangePublicToken(publicToken: String, bffToken: String) async throws -> ExchangeResult {
        let response: LinkExchangeResponse = try await send(
            path: "/link/exchange",
            method: "POST",
            token: .bff(bffToken),
            body: LinkExchangeRequest(publicToken: publicToken)
        )

        let accounts = response.accounts.map { mapAccountRecord($0) }
        let connection = mapConnectionSummary(response.connection, accountCountFallback: accounts.count)
        return ExchangeResult(connection: connection, accounts: accounts)
    }

    func listConnections(bffToken: String) async throws -> [ConnectionSummary] {
        let response: ConnectionsResponse = try await send(
            path: "/connections",
            method: "GET",
            token: .bff(bffToken)
        )

        return response.connections.map { mapConnectionSummary($0, accountCountFallback: $0.accountCount ?? 0) }
    }

    func connectionDetail(connectionId: String, bffToken: String) async throws -> ConnectionDetail {
        let response: ConnectionDetailResponse = try await send(
            path: "/connections/\(connectionId)",
            method: "GET",
            token: .bff(bffToken)
        )

        let accounts = response.accounts.map { mapAccountRecord($0) }
        return ConnectionDetail(
            connectionId: response.connection.connectionId,
            institutionId: response.connection.institutionId,
            institutionName: response.connection.institutionName,
            status: response.connection.status,
            createdAt: response.connection.createdAt,
            updatedAt: response.connection.updatedAt,
            lastSyncAt: response.connection.lastSyncAt,
            accounts: accounts
        )
    }

    func syncConnection(
        connectionId: String,
        cursor: String? = nil,
        daysBackForInitialImport: Int? = nil,
        bffToken: String
    ) async throws -> SyncResult {
        let response: SyncConnectionResponse = try await send(
            path: "/sync/connection/\(connectionId)",
            method: "POST",
            token: .bff(bffToken),
            body: SyncConnectionRequest(cursor: cursor, daysBackForInitialImport: daysBackForInitialImport)
        )

        return mapSyncResult(
            connectionId: response.connectionId,
            status: response.status,
            syncType: response.syncType,
            fetchedAt: response.fetchedAt,
            nextCursor: response.nextCursor,
            accounts: response.accounts,
            transactions: response.transactions
        )
    }

    func syncAll(bffToken: String) async throws -> SyncAllResult {
        let response: SyncAllResponse = try await send(
            path: "/sync/all",
            method: "POST",
            token: .bff(bffToken),
            body: EmptyBody()
        )

        let results = response.results.map { entry in
            if entry.success,
               let status = entry.status,
               let syncType = entry.syncType,
               let fetchedAt = entry.fetchedAt,
               let accounts = entry.accounts,
               let transactions = entry.transactions {
                let result = mapSyncResult(
                    connectionId: entry.connectionId,
                    status: status,
                    syncType: syncType,
                    fetchedAt: fetchedAt,
                    nextCursor: entry.nextCursor,
                    accounts: accounts,
                    transactions: transactions
                )
                return SyncAllEntry(
                    success: true,
                    connectionId: entry.connectionId,
                    result: result,
                    errorCode: nil,
                    errorMessage: nil
                )
            }

            return SyncAllEntry(
                success: false,
                connectionId: entry.connectionId,
                result: nil,
                errorCode: entry.error?.code,
                errorMessage: entry.error?.message
            )
        }

        let summary = SyncSummary(
            connectionCount: response.summary.connectionCount,
            successCount: response.summary.successCount,
            failureCount: response.summary.failureCount,
            addedCount: response.summary.addedCount,
            modifiedCount: response.summary.modifiedCount,
            removedCount: response.summary.removedCount
        )

        return SyncAllResult(results: results, summary: summary)
    }

    func unlinkConnection(connectionId: String, bffToken: String) async throws -> UnlinkResult {
        let response: UnlinkResponse = try await send(
            path: "/unlink/connection/\(connectionId)",
            method: "POST",
            token: .bff(bffToken),
            body: EmptyBody()
        )

        return UnlinkResult(connectionId: response.connectionId, status: response.status)
    }

    private func mapConnectionSummary(_ payload: ConnectionPayload, accountCountFallback: Int) -> ConnectionSummary {
        ConnectionSummary(
            connectionId: payload.connectionId,
            institutionId: payload.institutionId,
            institutionName: payload.institutionName,
            status: payload.status,
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            lastSyncAt: payload.lastSyncAt,
            accountCount: payload.accountCount ?? accountCountFallback
        )
    }

    private func mapAccountRecord(_ payload: AccountPayload) -> AccountRecord {
        AccountRecord(
            providerAccountId: payload.providerAccountId,
            name: payload.name,
            officialName: payload.officialName,
            mask: payload.mask,
            type: payload.type,
            subtype: payload.subtype,
            currentBalance: payload.currentBalance,
            availableBalance: payload.availableBalance,
            isoCurrencyCode: payload.isoCurrencyCode
        )
    }

    private func mapAccountBalance(_ payload: AccountBalancePayload) -> AccountBalance {
        AccountBalance(
            providerAccountId: payload.providerAccountId,
            currentBalance: payload.currentBalance,
            availableBalance: payload.availableBalance,
            isoCurrencyCode: payload.isoCurrencyCode
        )
    }

    private func mapTransactionRecord(_ payload: TransactionPayload) -> TransactionRecord {
        TransactionRecord(
            providerTransactionId: payload.providerTransactionId,
            providerAccountId: payload.providerAccountId,
            amount: payload.amount,
            isoCurrencyCode: payload.isoCurrencyCode,
            date: payload.date,
            authorizedDate: payload.authorizedDate,
            name: payload.name,
            merchantName: payload.merchantName,
            paymentChannel: payload.paymentChannel,
            pending: payload.pending,
            personalFinanceCategoryPrimary: payload.personalFinanceCategoryPrimary,
            rawJSON: Self.jsonString(from: payload.raw)
        )
    }

    private func mapSyncResult(
        connectionId: String,
        status: String,
        syncType: String,
        fetchedAt: Date,
        nextCursor: String?,
        accounts: [AccountBalancePayload],
        transactions: TransactionsPayload
    ) -> SyncResult {
        let balances = accounts.map { mapAccountBalance($0) }
        let syncTransactions = SyncTransactions(
            added: transactions.added.map { mapTransactionRecord($0) },
            modified: transactions.modified.map { mapTransactionRecord($0) },
            removed: transactions.removed.map { RemovedTransactionRecord(providerTransactionId: $0.providerTransactionId) }
        )

        return SyncResult(
            connectionId: connectionId,
            status: status,
            syncType: syncType,
            fetchedAt: fetchedAt,
            nextCursor: nextCursor,
            accounts: balances,
            transactions: syncTransactions
        )
    }

    private static func jsonString(from value: JSONValue?) -> String? {
        guard let value else { return nil }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        token: AuthToken
    ) async throws -> Response {
        try await send(path: path, method: method, token: token, bodyData: nil)
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        token: AuthToken,
        body: Body
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await send(path: path, method: method, token: token, bodyData: data)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        token: AuthToken,
        bodyData: Data?
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw BankClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        switch token {
        case .none:
            break
        case let .bff(value):
            guard !value.isEmpty else { throw BankClientError.missingToken }
            request.setValue("Bearer \(value)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BankClientError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try decoder.decode(Response.self, from: data)
        }

        if httpResponse.statusCode == 400 {
            if let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) {
                throw BankClientError.httpError(
                    statusCode: httpResponse.statusCode,
                    code: envelope.error.code,
                    message: envelope.error.message,
                    correlationId: envelope.correlationId
                )
            }

            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw BankClientError.validationError(statusCode: httpResponse.statusCode, body: bodyString)
        }

        if let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) {
            throw BankClientError.httpError(
                statusCode: httpResponse.statusCode,
                code: envelope.error.code,
                message: envelope.error.message,
                correlationId: envelope.correlationId
            )
        }

        throw BankClientError.httpError(
            statusCode: httpResponse.statusCode,
            code: nil,
            message: nil,
            correlationId: nil
        )
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = isoFormatter.date(from: value) {
                return date
            }

            let isoNoFraction = ISO8601DateFormatter()
            isoNoFraction.formatOptions = [.withInternetDateTime]

            if let date = isoNoFraction.date(from: value) {
                return date
            }

            let dateOnly = DateFormatter()
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
            dateOnly.dateFormat = "yyyy-MM-dd"

            if let date = dateOnly.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(value)"
            )
        }

        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private struct ErrorEnvelope: Decodable {
    let success: Bool
    let error: ErrorDetail
    let correlationId: String?

    struct ErrorDetail: Decodable {
        let code: String
        let message: String
        let details: JSONValue?
    }
}

private enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

private struct HealthResponse: Decodable {
    let success: Bool
    let status: String
    let environment: String
}

private struct DeviceRegisterChallengeRequest: Encodable {
    let accountId: String
    let deviceId: String
}

private struct DeviceRegisterChallengeResponse: Decodable {
    let success: Bool
    let challengeId: String
    let challenge: String
    let expiresAt: Date
    let attestation: Attestation

    struct Attestation: Decodable {
        let teamId: String
        let bundleId: String
    }
}

private struct DeviceRegisterRequest: Encodable {
    let challengeId: String
    let accountId: String
    let deviceId: String
    let keyId: String
    let attestationObject: String
}

private struct DeviceRegisterResponse: Decodable {
    let success: Bool
    let device: Device

    struct Device: Decodable {
        let deviceId: String
        let keyId: String
        let appId: String
        let status: String
        let registeredAt: Date
    }
}

private struct EntitlementSyncRequest: Encodable {
    let accountId: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let appAccountToken: String?
    let signedTransactionInfo: String?
    let signedRenewalInfo: String?
    let challengeId: String?
    let deviceId: String?
    let keyId: String?
    let assertion: String?
}

private struct EntitlementSyncResponse: Decodable {
    let success: Bool
    let entitlement: Entitlement

    struct Entitlement: Decodable {
        let productId: String
        let originalTransactionId: String
        let transactionId: String
        let status: String
        let expiresAt: Date?
        let environment: String
        let lastVerifiedAt: Date
    }
}

private struct AuthChallengeRequest: Encodable {
    let accountId: String
    let deviceId: String
    let purpose: String?
}

private struct AuthChallengeResponse: Decodable {
    let success: Bool
    let challengeId: String
    let challenge: String
    let expiresAt: Date
    let attestation: Attestation

    struct Attestation: Decodable {
        let teamId: String
        let bundleId: String
    }
}

private struct AuthSessionRequest: Encodable {
    let challengeId: String
    let accountId: String
    let deviceId: String
    let keyId: String
    let assertion: String
}

private struct AuthSessionResponse: Decodable {
    let success: Bool
    let accessToken: String
    let expiresAt: Date
    let expiresInSeconds: Int
    let session: Session
    let entitlement: Entitlement

    struct Session: Decodable {
        let sessionId: String
        let userId: String
        let deviceId: String
    }

    struct Entitlement: Decodable {
        let productId: String
        let status: String
        let expiresAt: Date?
    }
}

private struct DevicesResponse: Decodable {
    let success: Bool
    let devices: [Device]

    struct Device: Decodable {
        let deviceId: String
        let keyId: String
        let appId: String
        let status: String
        let createdAt: Date
        let lastVerifiedAt: Date?
        let lastAssertionAt: Date?
    }
}

private struct EntitlementsResponse: Decodable {
    let success: Bool
    let entitlements: [Entitlement]

    struct Entitlement: Decodable {
        let entitlementId: String
        let platform: String
        let productId: String
        let originalTransactionId: String
        let transactionId: String?
        let status: String
        let environment: String
        let purchasedAt: Date?
        let expiresAt: Date?
        let lastVerifiedAt: Date
    }
}

private struct EmptyBody: Encodable {}

private struct LinkTokenRequest: Encodable {
    let clientName: String?
    let language: String?
    let countryCodes: [String]?
    let products: [String]?
    let redirectUri: String?
}

private struct LinkTokenResponse: Decodable {
    let success: Bool
    let linkToken: String
    let expiration: Date
    let requestId: String?
}

private struct LinkExchangeRequest: Encodable {
    let publicToken: String
}

private struct LinkExchangeResponse: Decodable {
    let success: Bool
    let connection: ConnectionPayload
    let accounts: [AccountPayload]
}

private struct ConnectionsResponse: Decodable {
    let success: Bool
    let connections: [ConnectionPayload]
}

private struct ConnectionDetailResponse: Decodable {
    let success: Bool
    let connection: ConnectionPayload
    let accounts: [AccountPayload]
}

private struct SyncConnectionRequest: Encodable {
    let cursor: String?
    let daysBackForInitialImport: Int?
}

private struct SyncConnectionResponse: Decodable {
    let success: Bool
    let connectionId: String
    let status: String
    let syncType: String
    let fetchedAt: Date
    let nextCursor: String?
    let accounts: [AccountBalancePayload]
    let transactions: TransactionsPayload
}

private struct SyncAllResponse: Decodable {
    let success: Bool
    let results: [SyncAllEntryPayload]
    let summary: SyncSummaryPayload
}

private struct UnlinkResponse: Decodable {
    let success: Bool
    let connectionId: String
    let status: String
}

private struct ConnectionPayload: Decodable {
    let connectionId: String
    let institutionId: String?
    let institutionName: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date?
    let lastSyncAt: Date?
    let accountCount: Int?
}

private struct AccountPayload: Decodable {
    let providerAccountId: String
    let name: String
    let officialName: String?
    let mask: String?
    let type: String?
    let subtype: String?
    let currentBalance: Double?
    let availableBalance: Double?
    let isoCurrencyCode: String?
}

private struct AccountBalancePayload: Decodable {
    let providerAccountId: String
    let currentBalance: Double?
    let availableBalance: Double?
    let isoCurrencyCode: String?
}

private struct TransactionPayload: Decodable {
    let providerTransactionId: String
    let providerAccountId: String
    let amount: Double
    let isoCurrencyCode: String?
    let date: Date
    let authorizedDate: Date?
    let name: String
    let merchantName: String?
    let paymentChannel: String?
    let pending: Bool
    let personalFinanceCategoryPrimary: String?
    let raw: JSONValue?
}

private struct RemovedTransactionPayload: Decodable {
    let providerTransactionId: String
}

private struct TransactionsPayload: Decodable {
    let added: [TransactionPayload]
    let modified: [TransactionPayload]
    let removed: [RemovedTransactionPayload]
}

private struct SyncAllEntryPayload: Decodable {
    let success: Bool
    let connectionId: String
    let status: String?
    let syncType: String?
    let fetchedAt: Date?
    let nextCursor: String?
    let accounts: [AccountBalancePayload]?
    let transactions: TransactionsPayload?
    let error: SyncErrorPayload?
}

private struct SyncErrorPayload: Decodable {
    let code: String
    let message: String
}

private struct SyncSummaryPayload: Decodable {
    let connectionCount: Int
    let successCount: Int
    let failureCount: Int
    let addedCount: Int
    let modifiedCount: Int
    let removedCount: Int
}
