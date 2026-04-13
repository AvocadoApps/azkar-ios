// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation
import Alamofire

public extension DataRequest {

    @discardableResult
    func asyncDecodable<T: Decodable>(
        of type: T.Type = T.self,
        queue: DispatchQueue = .main,
        dataPreprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
        decoder: DataDecoder = JSONDecoder(),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
        emptyRequestMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            responseDecodable(of: type, queue: queue, dataPreprocessor: dataPreprocessor, decoder: decoder, emptyResponseCodes: emptyResponseCodes, emptyRequestMethods: emptyRequestMethods) { response in
                switch response.result {
                case .success(let decodedResponse):
                    queue.async {
                        continuation.resume(returning: decodedResponse)
                    }
                case .failure(let error):
                    queue.async {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
}
