import Foundation

/// Production service for fetching LiveKit authentication tokens
///
/// This service connects to your production token server to generate LiveKit access tokens.
/// 
/// Setup:
/// - Deploy your token server (server.py) to render.com or similar platform
/// - Update the `productionServerUrl` below to point to your deployed server
/// - Ensure your server has the correct LIVEKIT_API_KEY, LIVEKIT_API_SECRET, and LIVEKIT_URL configured
///
/// For development, you can point to localhost (e.g., "http://localhost:8080")
/// For production, use your deployed URL (e.g., "https://your-app.onrender.com")
///
/// See [docs](https://docs.livekit.io/home/server/generating-tokens/) for more information.
actor TokenService {
    enum TokenServiceError: Error, LocalizedError {
        case serverNotConfigured
        case networkError(String)
        case invalidResponse(Int)
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .serverNotConfigured:
                return "Token server URL is not configured"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse(let statusCode):
                return "Invalid response from token server: \(statusCode)"
            case .decodingError:
                return "Failed to decode response from token server"
            }
        }
    }
    
    struct ConnectionDetails: Codable {
        let serverUrl: String
        let roomName: String
        let participantName: String
        let participantToken: String
    }

    func fetchConnectionDetails(roomName: String, participantName: String) async throws -> ConnectionDetails? {
        do {
            return try await fetchConnectionDetailsFromProduction(roomName: roomName, participantName: participantName)
        } catch {
            print("TokenService error: \(error.localizedDescription)")
            return nil
        }
    }

    private let productionServerUrl: String = "https://tokenserver-2.onrender.com"
    
    private func fetchConnectionDetailsFromProduction(roomName: String, participantName: String) async throws -> ConnectionDetails {
        guard !productionServerUrl.isEmpty else {
            throw TokenServiceError.serverNotConfigured
        }
        
        guard let url = URL(string: "\(productionServerUrl)/getToken") else {
            throw TokenServiceError.networkError("Invalid server URL")
        }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "roomName", value: roomName),
            URLQueryItem(name: "participantName", value: participantName),
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TokenServiceError.networkError("Invalid response type")
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw TokenServiceError.invalidResponse(httpResponse.statusCode)
            }

            do {
                let connectionDetails = try JSONDecoder().decode(ConnectionDetails.self, from: data)
                print("Successfully fetched production connection details: \(connectionDetails)")
                return connectionDetails
            } catch {
                throw TokenServiceError.decodingError
            }
        } catch {
            if error is TokenServiceError {
                throw error
            } else {
                throw TokenServiceError.networkError(error.localizedDescription)
            }
        }
    }

}
