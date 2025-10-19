//
//  OCRService.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import Foundation
import Vision
import UIKit
import PDFKit

class OCRService {
    static let shared = OCRService()

    private init() {}

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func extractText(from pdfData: Data) async throws -> String {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw OCRError.invalidPDF
        }

        var allText = ""

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            // First try to extract text directly
            if let pageText = page.string, !pageText.isEmpty {
                allText += pageText + "\n"
            } else {
                // If no text, use OCR on the page image
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let pageImage = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }

                let ocrText = try await extractText(from: pageImage)
                allText += ocrText + "\n"
            }
        }

        return allText
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case invalidPDF
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image"
        case .invalidPDF:
            return "Unable to process the PDF file"
        case .noTextFound:
            return "No text was found in the document"
        }
    }
}
