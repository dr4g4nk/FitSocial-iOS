//
//  Untitled.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation
import Security

public protocol TokenStore {
    func save(access: String, refresh: String?) throws
    func readAccess() throws -> String?
    func readRefresh() throws -> String?
    func clear() throws
}

/// Keychain implementacija (Generic Password)
public final class KeychainTokenStore: TokenStore {
    private let service: String
    private let accessAccount = "access_token"
    private let refreshAccount = "refresh_token"

    public init(service: String) {
        self.service = service
    }

    public func save(access: String, refresh: String?) throws {
        try upsert(value: access, account: accessAccount)
        if let refresh = refresh {
            try upsert(value: refresh, account: refreshAccount)
        }
    }

    public func readAccess() throws -> String? {
        try read(account: accessAccount)
    }

    public func readRefresh() throws -> String? {
        try read(account: refreshAccount)
    }

    public func clear() throws {
        try delete(account: accessAccount)
        try delete(account: refreshAccount)
    }

    // MARK: - Private Keychain helpers

    private func upsert(value: String, account: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.from(status: addStatus) }
        default:
            throw KeychainError.from(status: status)
        }
    }

    private func read(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            if let data = item as? Data {
                return String(data: data, encoding: .utf8)
            }
            return nil
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.from(status: status)
        }
    }

    private func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.from(status: status)
        }
    }
}

public enum KeychainError: LocalizedError {
    case status(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .status(let code):
            if let msg = SecCopyErrorMessageString(code, nil) as String? {
                return "Keychain error (\(code)): \(msg)"
            }
            return "Keychain error (\(code))"
        }
    }

    static func from(status: OSStatus) -> KeychainError { .status(status) }
}
