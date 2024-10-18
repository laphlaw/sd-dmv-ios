// File: Services/KBBService.swift

import Foundation

// MARK: - KBBResponse Structures

struct VehicleURLByLicense: Codable {
    let url: String?
    let error: String?
    let make: String?
    let makeId: Int?        // Changed from String? to Int?
    let model: String?
    let modelId: Int?       // Changed from String? to Int?
    let year: String?       // Changed from Int16 to String?
    let vin: String?
    let __typename: String
}

struct DataClass: Codable {
    let vehicleUrlByLicense: VehicleURLByLicense?
}

struct KBBResponse: Codable {
    let data: DataClass?
}

// MARK: - KBBService

class KBBService {
    static func lookup(plate: String, state: String, completion: @escaping (Result<VehicleURLByLicense, Error>) -> Void) {
        let urlString = "https://www.kbb.com/owners-argo/api/"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        // Headers: Replace placeholder values with actual ones
        let headers: [String: String] = [
            "authority": "www.kbb.com",
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "content-type": "application/json",
            "cookie": "Your-Cookie-Values-Here", // Replace with actual cookie values
            "mocks": "undefined",
            "origin": "https://www.kbb.com",
            "referer": "https://www.kbb.com/whats-my-car-worth/",
            "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "user-agent": "Your-User-Agent-Here" // Replace with actual User-Agent
        ]
        
        // Body
        let body: [String: Any] = [
            "operationName": "licenseSLPPageQuery",
            "variables": [
                "lp": plate,
                "state": state
            ],
            "query": "query licenseSLPPageQuery($lp: String, $state: String) {\n  vehicleUrlByLicense: vehicleUrlByLicense(lp: $lp, state: $state) {\n    url\n    error\n    make\n    makeId\n    model\n    modelId\n    year\n    vin\n    __typename\n  }\n}"
        ]
        print("Request body: ")
        print(body)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Function to perform request with retries
            func performRequest(retryCount: Int) {
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        if retryCount < 4 {
                            // Retry after 2 seconds
                            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                                performRequest(retryCount: retryCount + 1)
                            }
                        } else {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        if retryCount < 4 {
                            // Retry after 2 seconds
                            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                                performRequest(retryCount: retryCount + 1)
                            }
                        } else {
                            completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                        }
                        return
                    }
                    
                    if httpResponse.statusCode == 200 {
                        guard let data = data else {
                            completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                            return
                        }
                        
                        // Log the response body as a string for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("KBB API Response: \(responseString)")
                        }
                        
                        do {
                            let decoder = JSONDecoder()
                            let kbbResponse = try decoder.decode(KBBResponse.self, from: data)
                            
                            // Safely unwrap nested optional properties
                            if let vehicleDetails = kbbResponse.data?.vehicleUrlByLicense {
                                completion(.success(vehicleDetails))
                            } else {
                                let parsingError = NSError(domain: "Parsing Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "vehicleUrlByLicense is missing"])
                                completion(.failure(parsingError))
                            }
                        } catch {
                            // Log the error and response for debugging
                            print("Decoding Error: \(error)")
                            completion(.failure(error))
                        }
                    } else {
                        if retryCount < 4 {
                            // Retry after 2 seconds
                            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                                performRequest(retryCount: retryCount + 1)
                            }
                        } else {
                            // Log the HTTP status code and response body
                            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                                print("HTTP Error \(httpResponse.statusCode): \(responseString)")
                            }
                            completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                        }
                    }
                }
                task.resume()
            }
            
            performRequest(retryCount: 0)
            
        } catch {
            completion(.failure(error))
        }
    }
}

