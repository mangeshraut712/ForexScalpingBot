//
//  ForexAPIService.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import Combine

// MARK: - Forex API Service (FXCM/OANDA Integration)

class ForexAPIService: ObservableObject {
    static let shared = ForexAPIService()

    // API Endpoints for different brokers
    enum Broker: String {
        case fxcm = "FXCM"
        case oanda = "OANDA"
        case mock = "MOCK" // For development
    }

    @Published var isConnected = false
    @Published var lastUpdate: Date?
    @Published var connectionStatus = ConnectionStatus.disconnected

    private var selectedBroker: Broker = .mock
    private var apiKey: String?
    private var accountId: String?
    private var cancellables = Set<AnyCancellable>()
    private var priceUpdatesTimer: Timer?
    private var websocketConnection: URLSessionWebSocketTask?

    init() {
        // Load saved broker preferences
        loadBrokerConfiguration()
        connectToBroker()
    }

    // MARK: - Broker Configuration

    func configureBroker(broker: Broker, apiKey: String, accountId: String? = nil) {
        self.selectedBroker = broker
        self.apiKey = apiKey
        self.accountId = accountId

        // Save configuration securely
        saveBrokerConfiguration()

        // Reconnect with new credentials
        disconnect()
        connectToBroker()
    }

    private func loadBrokerConfiguration() {
        // In real app, load from Keychain
        if let savedBroker = UserDefaults.standard.string(forKey: "selectedBroker"),
           let broker = Broker(rawValue: savedBroker) {
            selectedBroker = broker
        }

        // Load API key from secure storage
        apiKey = UserDefaults.standard.string(forKey: "apiKey")
        accountId = UserDefaults.standard.string(forKey: "accountId")
    }

    private func saveBrokerConfiguration() {
        UserDefaults.standard.set(selectedBroker.rawValue, forKey: "selectedBroker")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(accountId, forKey: "accountId")
    }

    // MARK: - Connection Management

    func connectToBroker() {
        connectionStatus = .connecting

        switch selectedBroker {
        case .fxcm:
            connectToFXCM()
        case .oanda:
            connectToOANDA()
        case .mock:
            connectToMock()
        }
    }

    func disconnect() {
        priceUpdatesTimer?.invalidate()
        websocketConnection?.cancel()
        connectionStatus = .disconnected
        isConnected = false
    }

    private func connectToFXCM() {
        // FXCM API Integration
        guard let apiKey = apiKey else {
            connectionStatus = .error("API key missing")
            return
        }

        // FXCM REST API endpoints
        let baseURL = "https://api.fxcm.com"
        let socketURL = URL(string: "wss://websocket.fxcm.com")!

        // Authenticate with FXCM
        authenticateWithFXCM(baseURL: baseURL) { [weak self] success, authToken in
            if success, let token = authToken {
                // Connect to FXCM WebSocket
                self?.connectWebSocket(url: socketURL, withToken: token)
                self?.connectionStatus = .connected
                self?.isConnected = true
            } else {
                self?.connectionStatus = .error("FXCM authentication failed")
            }
        }
    }

    private func connectToOANDA() {
        // OANDA API Integration
        guard let apiKey = apiKey, let accountId = accountId else {
            connectionStatus = .error("API key or account ID missing")
            return
        }

        let baseURL = "https://api-fxpractice.oanda.com/v3" // Practice account
        let socketURL = URL(string: "wss://stream-fxpractice.oanda.com/v3")!

        // OANDA uses Bearer token authentication
        let headers = ["Authorization": "Bearer \(apiKey)"]

        // Get account information first
        validateOandaAccount(baseURL: baseURL, headers: headers) { [weak self] success in
            if success {
                // Connect to OANDA streaming API
                self?.connectWebSocket(url: socketURL, headers: headers)
                self?.connectionStatus = .connected
                self?.isConnected = true
            } else {
                self?.connectionStatus = .error("OANDA authentication failed")
            }
        }
    }

    private func connectToMock() {
        // Mock connection for development
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate connection delay

            await MainActor.run {
                self.connectionStatus = .connected
                self.isConnected = true
                self.startMockPriceUpdates()
            }
        }
    }

    // MARK: - WebSocket Connection

    private func connectWebSocket(url: URL, withToken token: String? = nil, headers: [String: String]? = nil) {
        var request = URLRequest(url: url)

        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        let session = URLSession(configuration: .default)
        websocketConnection = session.webSocketTask(with: request)
        websocketConnection?.resume()

        receiveWebSocketMessages()
    }

    private func receiveWebSocketMessages() {
        websocketConnection?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                // Continue receiving messages
                self?.receiveWebSocketMessages()
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.reconnectWebSocket()
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8) {
                parsePriceData(data)
            }
        case .data(let data):
            parsePriceData(data)
        @unknown default:
            break
        }

        lastUpdate = Date()
    }

    private func parsePriceData(_ data: Data) {
        do {
            // Parse broker-specific price format
            switch selectedBroker {
            case .fxcm:
                let fxcmPrices = try JSONDecoder().decode(FXCMPriceResponse.self, from: data)
                updatePrices(with: fxcmPrices)
            case .oanda:
                let oandaPrices = try JSONDecoder().decode(OANDAPriceResponse.self, from: data)
                updatePrices(with: oandaPrices)
            case .mock:
                // Mock data already handled separately
                break
            }
        } catch {
            print("Price parsing error: \(error)")
        }
    }

    private func updatePrices(with fxcmPrices: FXCMPriceResponse) {
        // Update ForexViewModel with new prices
        for price in fxcmPrices.prices {
            if let quote = convertFXCMPriceToQuote(price) {
                ForexViewModel.shared.updateQuote(quote)
            }
        }
    }

    private func updatePrices(with oandaPrices: OANDAPriceResponse) {
        // Update ForexViewModel with OANDA prices
        for price in oandaPrices.prices {
            if let quote = convertOANDAPriceToQuote(price) {
                ForexViewModel.shared.updateQuote(quote)
            }
        }
    }

    private func convertFXCMPriceToQuote(_ fxcmPrice: FXCMPrice) -> ForexQuote? {
        return ForexQuote(
            symbol: fxcmPrice.symbol,
            bid: fxcmPrice.bid,
            ask: fxcmPrice.ask,
            change: fxcmPrice.change,
            changePercent: fxcmPrice.changePercent,
            timestamp: Date()
        )
    }

    private func convertOANDAPriceToQuote(_ oandaPrice: OANDAPrice) -> ForexQuote? {
        return ForexQuote(
            symbol: oandaPrice.instrument,
            bid: oandaPrice.bids.first?.price ?? 0,
            ask: oandaPrice.asks.first?.price ?? 0,
            change: 0, // Calculate from close
            changePercent: 0, // Calculate from close
            timestamp: Date()
        )
    }

    private func reconnectWebSocket() {
        // Implement exponential backoff for reconnection
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.connectToBroker()
        }
    }

    // MARK: - Authentication Methods

    private func authenticateWithFXCM(baseURL: String, completion: @escaping (Bool, String?) -> Void) {
        guard let apiKey = apiKey else {
            completion(false, nil)
            return
        }

        let loginURL = "\(baseURL)/login"
        let parameters = ["api_key": apiKey]

        // Make authentication request
        makeAPIRequest(url: loginURL, method: "POST", parameters: parameters) { result in
            switch result {
            case .success(let data):
                if let response = try? JSONDecoder().decode(FXCMAuthResponse.self, from: data) {
                    completion(response.success, response.token)
                } else {
                    completion(false, nil)
                }
            case .failure(let error):
                print("FXCM auth error: \(error)")
                completion(false, nil)
            }
        }
    }

    private func validateOandaAccount(baseURL: String, headers: [String: String], completion: @escaping (Bool) -> Void) {
        guard let accountId = accountId else {
            completion(false)
            return
        }

        let accountURL = "\(baseURL)/accounts/\(accountId)"

        makeAPIRequest(url: accountURL, method: "GET", headers: headers) { result in
            switch result {
            case .success(let data):
                if let response = try? JSONDecoder().decode(OANDAAccountResponse.self, from: data) {
                    completion(response.account.id == accountId)
                } else {
                    completion(false)
                }
            case .failure(let error):
                print("OANDA validation error: \(error)")
                completion(false)
            }
        }
    }

    // MARK: - API Request Helper

    private func makeAPIRequest(
        url: String,
        method: String = "GET",
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let urlObj = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data", code: 0)))
            }
        }.resume()
    }

    // MARK: - Mock Data for Development

    private func startMockPriceUpdates() {
        priceUpdatesTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.generateMockPriceUpdates()
        }
    }

    private func generateMockPriceUpdates() {
        let pairs = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD"]

        for pair in pairs {
            let currentQuote = ForexViewModel.shared.currentQuotes[pair] ?? ForexQuote(
                symbol: pair,
                bid: 1.0,
                ask: 1.0,
                change: 0,
                changePercent: 0,
                timestamp: Date()
            )

            // Simulate realistic price movements
            let volatility = Double.random(in: -0.001...0.001)

            var newBid = currentQuote.bid + volatility
            newBid = max(newBid, 0.1) // Prevent negative prices

            let spread = Double.random(in: 0.0001...0.0005)
            let newAsk = newBid + spread

            let change = newBid - 1.0 // Assuming 1.0 as baseline
            let changePercent = (change / 1.0) * 100

            let updatedQuote = ForexQuote(
                symbol: pair,
                bid: newBid,
                ask: newAsk,
                change: change,
                changePercent: changePercent,
                timestamp: Date()
            )

            ForexViewModel.shared.updateQuote(updatedQuote)
        }

        lastUpdate = Date()
    }

    // MARK: - Error Handling

    enum ConnectionStatus: Equatable {
        case connected
        case connecting
        case disconnected
        case error(String)

        var description: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
}

// MARK: - API Response Models

struct FXCMAuthResponse: Codable {
    let success: Bool
    let token: String?
    let message: String?
}

struct FXCMPriceResponse: Codable {
    let prices: [FXCMPrice]
}

struct FXCMPrice: Codable {
    let symbol: String
    let bid: Double
    let ask: Double
    let change: Double
    let changePercent: Double
    let volume: Int
}

struct OANDAAccountResponse: Codable {
    let account: OANDAAccount
}

struct OANDAAccount: Codable {
    let id: String
    let balance: String
    let marginAvailable: String
}

struct OANDAPriceResponse: Codable {
    let prices: [OANDAPrice]
}

struct OANDAPrice: Codable {
    let instrument: String
    let bids: [OANDAPricePoint]
    let asks: [OANDAPricePoint]
    let closeoutBid: String
    let closeoutAsk: String
}

struct OANDAPricePoint: Codable {
    let price: Double
    let liquidity: Int
}

// MARK: - Extension to share with ForexViewModel

extension ForexViewModel {
    static var shared: ForexViewModel {
        let forexVM = ForexViewModel()
        // Additional setup if needed
        return forexVM
    }

    func updateQuote(_ quote: ForexQuote) {
        currentQuotes[quote.symbol] = quote
        objectWillChange.send()
    }
}
