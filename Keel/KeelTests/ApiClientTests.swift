// import XCTest
// @testable import Keel

// Mock URLProtocol for testing
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // Required by URLProtocol
    }
}

// final class ApiClientTests: XCTestCase {
    var apiClient: ApiClient!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Create URLSession with mock protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        apiClient = ApiClient()
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        apiClient = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testResolveSuccess() async throws {
        // Mock successful resolve response
        let mockResponse = """
        {
            "merchant": "Starbucks",
            "mcc": "5814",
            "category": "dining"
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/resolve")
            XCTAssertEqual(request.httpMethod, "GET")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            
            return (response, mockResponse.data(using: .utf8)!)
        }
        
        // Test the resolve method
        let result = try await apiClient.resolve(lat: 37.7749, lon: -122.4194)
        
        XCTAssertEqual(result.merchant, "Starbucks")
        XCTAssertEqual(result.mcc, "5814")
        XCTAssertEqual(result.category, "dining")
    }
    
    func testResolveFailure() async {
        // Mock failed resolve response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data())
        }
        
        // Test that resolve throws on non-200 status
        do {
            _ = try await apiClient.resolve(lat: 37.7749, lon: -122.4194)
            XCTFail("Expected resolve to throw error")
        } catch {
            XCTAssertTrue(error is ApiError)
        }
    }
    
    func testScoreSuccess() async throws {
        // Mock successful score response
        let mockResponse = """
        {
            "top": [
                {
                    "card": "Citi Custom Cash",
                    "score": 5.0,
                    "reason": "5x dining"
                },
                {
                    "card": "Amex Gold",
                    "score": 4.0,
                    "reason": "4x dining"
                },
                {
                    "card": "Chase Freedom",
                    "score": 1.0,
                    "reason": "1x base"
                }
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/score")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            
            return (response, mockResponse.data(using: .utf8)!)
        }
        
        // Test the score method
        let scoreRequest = ScoreRequest(
            merchant: "Starbucks",
            mcc: "5814",
            category: "dining",
            cards: ["Amex Gold", "Chase Freedom", "Citi Custom Cash"]
        )
        
        let result = try await apiClient.score(req: scoreRequest)
        
        XCTAssertEqual(result.top.count, 3)
        XCTAssertEqual(result.top[0].card, "Citi Custom Cash")
        XCTAssertEqual(result.top[0].score, 5.0)
        XCTAssertEqual(result.top[0].reason, "5x dining")
        XCTAssertEqual(result.top[1].card, "Amex Gold")
        XCTAssertEqual(result.top[1].score, 4.0)
        XCTAssertEqual(result.top[1].reason, "4x dining")
        XCTAssertEqual(result.top[2].card, "Chase Freedom")
        XCTAssertEqual(result.top[2].score, 1.0)
        XCTAssertEqual(result.top[2].reason, "1x base")
    }
    
    func testScoreFailure() async {
        // Mock failed score response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data())
        }
        
        // Test that score throws on non-200 status
        let scoreRequest = ScoreRequest(
            merchant: "Starbucks",
            mcc: "5814",
            category: "dining",
            cards: ["Amex Gold"]
        )
        
        do {
            _ = try await apiClient.score(req: scoreRequest)
            XCTFail("Expected score to throw error")
        } catch {
            XCTAssertTrue(error is ApiError)
        }
    }
    
    func testResolveQueryParameters() async throws {
        // Test that resolve includes correct query parameters
        let expectedLat = 37.7749
        let expectedLon = -122.4194
        
        MockURLProtocol.requestHandler = { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = urlComponents?.queryItems
            
            let latItem = queryItems?.first { $0.name == "lat" }
            let lonItem = queryItems?.first { $0.name == "lon" }
            
            XCTAssertEqual(latItem?.value, String(expectedLat))
            XCTAssertEqual(lonItem?.value, String(expectedLon))
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let mockData = """
            {
                "merchant": "Test",
                "mcc": "5999",
                "category": "other"
            }
            """.data(using: .utf8)!
            
            return (response, mockData)
        }
        
        _ = try await apiClient.resolve(lat: expectedLat, lon: expectedLon)
    }
    
    func testScoreRequestEncoding() async throws {
        // Test that score request is properly encoded
        let scoreRequest = ScoreRequest(
            merchant: "Test Merchant",
            mcc: "5814",
            category: "dining",
            cards: ["Card1", "Card2"]
        )
        
        MockURLProtocol.requestHandler = { request in
            // Verify request body contains expected JSON
            guard let body = request.httpBody else {
                XCTFail("Request body should not be nil")
                return (HTTPURLResponse(), Data())
            }
            
            let decoder = JSONDecoder()
            let decodedRequest = try decoder.decode(ScoreRequest.self, from: body)
            
            XCTAssertEqual(decodedRequest.merchant, "Test Merchant")
            XCTAssertEqual(decodedRequest.mcc, "5814")
            XCTAssertEqual(decodedRequest.category, "dining")
            XCTAssertEqual(decodedRequest.cards, ["Card1", "Card2"])
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let mockData = """
            {
                "top": [
                    {
                        "card": "Card1",
                        "score": 1.0,
                        "reason": "1x base"
                    }
                ]
            }
            """.data(using: .utf8)!
            
            return (response, mockData)
        }
        
        _ = try await apiClient.score(req: scoreRequest)
    }
}
