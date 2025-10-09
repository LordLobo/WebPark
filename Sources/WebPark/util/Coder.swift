//
//  Coder.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

public class Coder<T: Codable> {
    public static func encode(_ data: T) throws -> Data {
        do {
            let ret = try JSONEncoder().encode(data)
            return ret
        } catch {
            throw WebParkError.encodeFailure(underlying: error.localizedDescription)
        }
    }
    
    public static func decode(_ data: Data) throws -> T {
        do {
            let ret = try JSONDecoder().decode(T.self, from: data)
            return ret
        } catch {
            throw WebParkError.decodeFailure(underlying: error.localizedDescription)
        }
    }
}

@available(*, deprecated, message: "Use WebParkError.encodeFailure and WebParkError.decodeFailure instead")
public enum JSONCodingError: Error {
    case encodingError
    case decodingError
}
