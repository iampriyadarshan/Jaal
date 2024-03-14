//
//  JaalError.swift
//
//
//  Created by Priyadarshan Meshram on 14/03/24.
//

import Foundation

///  Types of Network Error received with `Error`
public enum JaalError: Error {
  case notConnectedToInternet(Error)
  case invalidResponse(statusCode: Int)
  case invalidData(Error)
  case invalidServerResponse
}
