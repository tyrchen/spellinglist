//
//  OCRServiceTests.swift
//  spellinglistTests
//
//  Created by cynthia on 10/18/25.
//

import XCTest
import UIKit
import PDFKit
@testable import spellinglist

final class OCRServiceTests: XCTestCase {

    var ocrService: OCRService!

    override func setUp() {
        super.setUp()
        ocrService = OCRService.shared
    }

    override func tearDown() {
        ocrService = nil
        super.tearDown()
    }

    // MARK: - Image OCR Tests

    func testExtractTextFromImageWithText() async throws {
        // Create a simple test image with text
        let image = createTestImage(withText: "Test Word - Test Definition")

        let text = try await ocrService.extractText(from: image)

        // OCR might not be perfect, but should extract something
        XCTAssertFalse(text.isEmpty, "Should extract some text from image")
    }

    func testExtractTextFromEmptyImage() async throws {
        let image = UIImage(systemName: "square")!

        let text = try await ocrService.extractText(from: image)

        // Empty or minimal text expected
        XCTAssertTrue(text.isEmpty || text.count < 10)
    }

    func testInvalidImageThrowsError() async {
        // Create an image without CGImage
        let image = UIImage()

        do {
            _ = try await ocrService.extractText(from: image)
            XCTFail("Should throw error for invalid image")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - PDF OCR Tests

    func testExtractTextFromPDFWithText() async throws {
        // Create a simple PDF with text
        let pdfData = createTestPDF(withText: "Abundant - Present in great quantity")

        let text = try await ocrService.extractText(from: pdfData)

        XCTAssertFalse(text.isEmpty, "Should extract text from PDF")
        XCTAssertTrue(text.contains("Abundant") || text.contains("great"), "Should contain some of the original text")
    }

    func testInvalidPDFThrowsError() async {
        let invalidData = Data([0x00, 0x01, 0x02])

        do {
            _ = try await ocrService.extractText(from: invalidData)
            XCTFail("Should throw error for invalid PDF")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Helper Methods

    private func createTestImage(withText text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100))
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 100))

            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 20, y: 40))
        }
    }

    private func createTestPDF(withText text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Test",
            kCGPDFContextAuthor: "Test Author"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 50, y: 50))
        }

        return data
    }
}
