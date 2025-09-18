//
//  JSONExtension.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

extension JSONDecoder {
    public static func instantDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Invalid date format: \(dateString)")
        }
        
        return decoder
    }
}

extension JSONEncoder {
    public static func instantEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        
        return encoder
    }
}
