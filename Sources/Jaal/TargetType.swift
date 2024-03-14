//
//  File.swift
//  
//
//  Created by Priyadarshan Meshram on 14/03/24.
//

import Foundation


/// The protocol used to define the specifications necessary for a `Jaal`.
public protocol TargetType {
  
  /// The target's base `URL`.
  var baseURL: URL { get }
  
  /// The path to be appended to `baseURL` to form the full `URL`.
  var path: String { get }
  
  /// The HTTP method used in the request.
  var method: HTTPMethod { get }
  
  /// The type of HTTP task to be performed.
  var task: HTTPTaskType { get }
  
  /// The headers to be used in the request.
  var headers: [String: String]? { get }
}

extension TargetType {
  var pathAppendedURL: URL {
    var url = baseURL
    url.appendPathComponent(path)
    return url
  }
}
