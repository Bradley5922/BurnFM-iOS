//
//  HelpperFunctions.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 22/09/2024.
//

import SwiftyJSON
import Foundation

func getJSONfromURL(URL_string: String, completion: @escaping (Result<JSON, Error>) -> Void) {
    guard let url = URL(string: URL_string) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
            return
        }

        do {
            let json = try JSON(data: data)
            completion(.success(json))
        } catch let parseError {
            completion(.failure(parseError))
        }
    }
    
    task.resume()
}

