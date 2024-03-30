// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import Combine

public protocol APIClient {
  
  associatedtype Target: TargetType
  
  /// Requests for a spesific call with `DataTaskPublisher` for with body response
  /// - Parameters:
  ///   - target: `TargetType`
  ///   - urlSession: `URLSession`
  ///   - scheduler:  Threading and execution time helper if you want to run it on main thread just use `DispatchQueue.main`
  ///   - type: Decodable Object Type
  @available(iOS 13.0,macOS 10.15, *)
  func request<D, S>(
    target: Target,
    urlSession: URLSession,
    jsonDecoder: JSONDecoder,
    scheduler: S,
    type: D.Type
  ) -> AnyPublisher<D, JaalError> where D: Decodable, S: Scheduler
}


public class JaalProvider<Target: TargetType>: APIClient {
  
  public init() {}
  
  @available(iOS 13.0,macOS 10.15, *)
  public func request<D, S>(
    target: Target,
    urlSession: URLSession = URLSession.shared,
    jsonDecoder: JSONDecoder = .init(),
    scheduler: S,
    type: D.Type
  ) -> AnyPublisher<D, JaalError> where D : Decodable, S : Scheduler {
    
    let request = constructRequest(with: target)
    
    return urlSession.dataTaskPublisher(for: request)
      .tryCatch { error in
        guard error.networkUnavailableReason == .constrained else {
          throw JaalError.notConnectedToInternet(error)
        }
        return urlSession.dataTaskPublisher(for: request)
      }
      .receive(on: scheduler)
      .tryMap { data, response -> Data in
        guard let httpResponse = response as? HTTPURLResponse else {
          throw JaalError.invalidServerResponse
        }
        if !httpResponse.isSuccessful {
          let error = JaalError.invalidResponse(statusCode: httpResponse.statusCode)
          print(httpResponse)
          throw error
        }
        print(request)
//        print(dataToDictionary(data: data) ?? [:])
        printDataAsPrettyJSON(data)
        return data
      }
      .decode(type: type.self, decoder: jsonDecoder)
      .mapError { error in
        print(error)
        if let error = error as? JaalError {
          return error
        } else {
          return JaalError.invalidData(error)
        }
      }
      .eraseToAnyPublisher()
  }
}


extension HTTPURLResponse {
  var isSuccessful: Bool {
    return (200..<300).contains(statusCode)
  }
}



public extension JaalProvider {
  
  func constructRequest(with target: TargetType) -> URLRequest {
    switch target.method {
    case .get:
       prepareGetRequest(with: target)
    case .post:
       prepareGeneralRequest(with: target)
    }
  }
  
  func prepareGetRequest(with target: TargetType) -> URLRequest {
    let url = target.pathAppendedURL
    switch target.task {
    case let .requestParameters(parameters):
      let url = url.generateUrlWithQuery(with: parameters)
      var request = URLRequest(url: url)
      request.prepareRequest(with: target)
      return request
    default:
      var request = URLRequest(url: url)
      request.prepareRequest(with: target)
      return request
    }
  }
  
  func prepareGeneralRequest(with target: TargetType) -> URLRequest {
    let url = target.pathAppendedURL
    var request = URLRequest(url: url)
    request.prepareRequest(with: target)
    switch target.task {
    case let .requestParameters(parameters):
      request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
      return request
    case let .requestData(data):
      request.httpBody = data
      return request
    case let .requestWithEncodable(encodable, encoder):
      request.httpBody = try? encoder.encode(encodable)
      return request
    default:
      return request
    }
  }
}

internal extension URLRequest {
  mutating func prepareRequest(with target: TargetType) {
    allHTTPHeaderFields = target.headers
    httpMethod = target.method.rawValue
  }
}


extension URL {
  func generateUrlWithQuery(with parameters: [String: Any]) -> URL {
    var quearyItems: [URLQueryItem] = []
    for parameter in parameters {
      quearyItems.append(URLQueryItem(name: parameter.key, value: parameter.value as? String))
    }
    var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)!
    urlComponents.queryItems = quearyItems
    guard let url = urlComponents.url else { fatalError("Wrong URL Provided") }
    return url
  }
}



func dataToDictionary(data: Data) -> [String: Any]? {
  do {
    // Attempt to deserialize the data into a dictionary
    if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
      return dictionary
    } else {
      print("Failed to convert data to dictionary. Data is not in valid JSON format.")
      return nil
    }
  } catch {
    print("Error deserializing data to dictionary: \(error)")
    return nil
  }
}

func printDataAsPrettyJSON(_ data: Data) {
  do {
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
      print(jsonString)
    }
  } catch {
    print("Error: Unable to convert data to JSON - \(error)")
  }
}

