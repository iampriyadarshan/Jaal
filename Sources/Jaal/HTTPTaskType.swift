//
//  HTTPTaskType.swift
//  
//
//  Created by Priyadarshan Meshram on 14/03/24.
//

import Foundation

public enum HTTPTaskType {
  case requestPlain
  case requestData(data: Data)
  case requestParameters(parameters: [String: Any])
  case requestWithEncodable(encodable: any Encodable, encoding: JSONEncoder = JSONEncoder())
}
