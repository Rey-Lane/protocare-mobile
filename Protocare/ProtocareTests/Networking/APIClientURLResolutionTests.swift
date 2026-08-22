import XCTest
@testable import Protocare

final class APIClientURLResolutionTests: XCTestCase {

    private func makeClient(baseURLString: String) -> APIClient {
        APIClient(baseURL: URL(string: baseURLString)!)
    }

    func testURLResolution_WithV1BaseURL_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/protocols")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/protocols")
    }

    func testURLResolution_SubstancesPath_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/substances")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/substances")
    }

    func testURLResolution_AuthPath_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/auth/login")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/auth/login")
    }

    func testURLResolution_NestedPath_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/protocols/abc/daily-status")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/protocols/abc/daily-status")
    }

    func testURLResolution_QueryString_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/protocols/abc/daily-status?date=2026-01-01")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/protocols/abc/daily-status?date=2026-01-01")
    }

    func testURLResolution_ImagePath_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/images/checkins/123")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/images/checkins/123")
    }

    func testURLResolution_ProductionBaseURL_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "https://api.protocare.com/v1")
        let url = client.resolveURL(path: "/protocols")
        XCTAssertEqual(url?.absoluteString, "https://api.protocare.com/v1/protocols")
    }

    func testURLResolution_StagingBaseURL_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "https://staging-api.protocare.com/v1")
        let url = client.resolveURL(path: "/auth/register")
        XCTAssertEqual(url?.absoluteString, "https://staging-api.protocare.com/v1/auth/register")
    }

    func testURLResolution_MultipleQueryParams_ResolvesCorrectly() {
        let client = makeClient(baseURLString: "http://192.168.1.71:8000/v1")
        let url = client.resolveURL(path: "/protocols/abc/checkins?date_from=2026-01-01&date_to=2026-01-31")
        XCTAssertEqual(url?.absoluteString, "http://192.168.1.71:8000/v1/protocols/abc/checkins?date_from=2026-01-01&date_to=2026-01-31")
    }
}
