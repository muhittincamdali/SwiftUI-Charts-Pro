import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import PDFKit

// MARK: - Chart Exporter

/// Exports charts to various formats including PNG, JPEG, PDF, and SVG.
///
/// ```swift
/// let exporter = ChartExporter()
///
/// // Export to PNG
/// let pngData = try await exporter.exportToPNG(view: myChart, size: CGSize(width: 800, height: 600))
///
/// // Export to PDF
/// let pdfData = try await exporter.exportToPDF(view: myChart, size: CGSize(width: 800, height: 600))
///
/// // Save to file
/// try exporter.saveToFile(data: pngData, filename: "chart.png")
/// ```
@MainActor
public final class ChartExporter {
    
    // MARK: - Export Options
    
    /// Options for chart export.
    public struct ExportOptions {
        /// Image scale factor (for retina displays)
        public var scale: CGFloat
        
        /// Background color (nil for transparent)
        public var backgroundColor: Color?
        
        /// Whether to include chart title
        public var includeTitle: Bool
        
        /// Whether to include legend
        public var includeLegend: Bool
        
        /// Whether to include timestamp
        public var includeTimestamp: Bool
        
        /// Custom watermark text
        public var watermark: String?
        
        /// JPEG quality (0.0-1.0)
        public var jpegQuality: CGFloat
        
        /// PDF metadata
        public var pdfMetadata: PDFMetadata?
        
        public init(
            scale: CGFloat = 2.0,
            backgroundColor: Color? = .white,
            includeTitle: Bool = true,
            includeLegend: Bool = true,
            includeTimestamp: Bool = false,
            watermark: String? = nil,
            jpegQuality: CGFloat = 0.9,
            pdfMetadata: PDFMetadata? = nil
        ) {
            self.scale = scale
            self.backgroundColor = backgroundColor
            self.includeTitle = includeTitle
            self.includeLegend = includeLegend
            self.includeTimestamp = includeTimestamp
            self.watermark = watermark
            self.jpegQuality = jpegQuality
            self.pdfMetadata = pdfMetadata
        }
    }
    
    /// PDF document metadata.
    public struct PDFMetadata {
        public var title: String?
        public var author: String?
        public var subject: String?
        public var keywords: [String]?
        public var creator: String?
        
        public init(
            title: String? = nil,
            author: String? = nil,
            subject: String? = nil,
            keywords: [String]? = nil,
            creator: String? = nil
        ) {
            self.title = title
            self.author = author
            self.subject = subject
            self.keywords = keywords
            self.creator = creator
        }
    }
    
    // MARK: - Properties
    
    private let defaultOptions: ExportOptions
    
    // MARK: - Initialization
    
    public init(defaultOptions: ExportOptions = ExportOptions()) {
        self.defaultOptions = defaultOptions
    }
    
    // MARK: - PNG Export
    
    /// Exports a SwiftUI view to PNG data.
    @available(iOS 16.0, macOS 13.0, *)
    public func exportToPNG<V: View>(
        view: V,
        size: CGSize,
        options: ExportOptions? = nil
    ) async throws -> Data {
        let opts = options ?? defaultOptions
        
        let renderer = await ImageRenderer(content: prepareView(view, size: size, options: opts))
        renderer.scale = opts.scale
        
        #if canImport(UIKit)
        guard let uiImage = await renderer.uiImage else {
            throw ExportError.renderingFailed
        }
        guard let data = uiImage.pngData() else {
            throw ExportError.encodingFailed
        }
        return data
        #elseif canImport(AppKit)
        guard let nsImage = await renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ExportError.encodingFailed
        }
        return data
        #else
        throw ExportError.unsupportedPlatform
        #endif
    }
    
    // MARK: - JPEG Export
    
    /// Exports a SwiftUI view to JPEG data.
    @available(iOS 16.0, macOS 13.0, *)
    public func exportToJPEG<V: View>(
        view: V,
        size: CGSize,
        options: ExportOptions? = nil
    ) async throws -> Data {
        let opts = options ?? defaultOptions
        
        let renderer = await ImageRenderer(content: prepareView(view, size: size, options: opts))
        renderer.scale = opts.scale
        
        #if canImport(UIKit)
        guard let uiImage = await renderer.uiImage else {
            throw ExportError.renderingFailed
        }
        guard let data = uiImage.jpegData(compressionQuality: opts.jpegQuality) else {
            throw ExportError.encodingFailed
        }
        return data
        #elseif canImport(AppKit)
        guard let nsImage = await renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: opts.jpegQuality]) else {
            throw ExportError.encodingFailed
        }
        return data
        #else
        throw ExportError.unsupportedPlatform
        #endif
    }
    
    // MARK: - PDF Export
    
    /// Exports a SwiftUI view to PDF data.
    @available(iOS 16.0, macOS 13.0, *)
    public func exportToPDF<V: View>(
        view: V,
        size: CGSize,
        options: ExportOptions? = nil
    ) async throws -> Data {
        let opts = options ?? defaultOptions
        
        let renderer = await ImageRenderer(content: prepareView(view, size: size, options: opts))
        
        var pdfData = Data()
        
        #if canImport(UIKit)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            // Draw the view
            if let uiImage = renderer.uiImage {
                uiImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            // Add metadata if provided
            if let metadata = opts.pdfMetadata {
                let info = context.pdfContextBounds
                // Note: PDF metadata is set through UIGraphicsPDFRendererFormat
            }
        }
        #elseif canImport(AppKit)
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw ExportError.renderingFailed
        }
        
        var mediaBox = CGRect(origin: .zero, size: size)
        pdfContext.beginPDFPage(nil)
        
        if let nsImage = renderer.nsImage,
           let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            pdfContext.draw(cgImage, in: mediaBox)
        }
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
        #else
        throw ExportError.unsupportedPlatform
        #endif
        
        return pdfData
    }
    
    // MARK: - SVG Export
    
    /// Exports chart data to SVG format.
    public func exportToSVG(
        chartData: SVGExportable,
        size: CGSize,
        options: ExportOptions? = nil
    ) throws -> String {
        let opts = options ?? defaultOptions
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(Int(size.width)) \(Int(size.height))" width="\(Int(size.width))" height="\(Int(size.height))">
        """
        
        // Background
        if let bgColor = opts.backgroundColor {
            let colorHex = colorToHex(bgColor)
            svg += """
            
            <rect width="100%" height="100%" fill="\(colorHex)"/>
            """
        }
        
        // Chart content
        svg += chartData.toSVGPath(size: size)
        
        // Watermark
        if let watermark = opts.watermark {
            svg += """
            
            <text x="\(Int(size.width) - 10)" y="\(Int(size.height) - 10)" text-anchor="end" font-size="12" fill="#999999" opacity="0.5">\(watermark)</text>
            """
        }
        
        // Timestamp
        if opts.includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let timestamp = formatter.string(from: Date())
            svg += """
            
            <text x="10" y="\(Int(size.height) - 10)" font-size="10" fill="#666666">\(timestamp)</text>
            """
        }
        
        svg += "\n</svg>"
        
        return svg
    }
    
    // MARK: - File Saving
    
    /// Saves data to a file.
    public func saveToFile(data: Data, filename: String, directory: URL? = nil) throws -> URL {
        let fileManager = FileManager.default
        
        let targetDirectory: URL
        if let dir = directory {
            targetDirectory = dir
        } else {
            targetDirectory = fileManager.temporaryDirectory
        }
        
        let fileURL = targetDirectory.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    /// Saves SVG string to a file.
    public func saveSVGToFile(svg: String, filename: String, directory: URL? = nil) throws -> URL {
        guard let data = svg.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return try saveToFile(data: data, filename: filename, directory: directory)
    }
    
    // MARK: - Share Sheet
    
    #if canImport(UIKit)
    /// Presents a share sheet for the exported image.
    @available(iOS 16.0, *)
    public func shareImage<V: View>(
        view: V,
        size: CGSize,
        from viewController: UIViewController,
        options: ExportOptions? = nil
    ) async throws {
        let data = try await exportToPNG(view: view, size: size, options: options)
        
        guard let image = UIImage(data: data) else {
            throw ExportError.encodingFailed
        }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        await MainActor.run {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
            viewController.present(activityVC, animated: true)
        }
    }
    #endif
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func prepareView<V: View>(_ view: V, size: CGSize, options: ExportOptions) -> some View {
        ZStack {
            if let bgColor = options.backgroundColor {
                bgColor
            }
            
            VStack(spacing: 0) {
                view
                
                if options.includeTimestamp {
                    HStack {
                        Spacer()
                        Text(Date(), style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                }
            }
            
            if let watermark = options.watermark {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(watermark)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(8)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private func colorToHex(_ color: Color) -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return "#FFFFFF" }
        return String(format: "#%02X%02X%02X", Int(rgbColor.redComponent * 255), Int(rgbColor.greenComponent * 255), Int(rgbColor.blueComponent * 255))
        #else
        return "#FFFFFF"
        #endif
    }
}

// MARK: - Export Errors

/// Errors that can occur during chart export.
public enum ExportError: Error, LocalizedError {
    case renderingFailed
    case encodingFailed
    case unsupportedPlatform
    case fileWriteFailed
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render the chart"
        case .encodingFailed:
            return "Failed to encode the image data"
        case .unsupportedPlatform:
            return "Export is not supported on this platform"
        case .fileWriteFailed:
            return "Failed to write file to disk"
        case .invalidData:
            return "Invalid data provided for export"
        }
    }
}

// MARK: - SVG Exportable Protocol

/// Protocol for chart types that support SVG export.
public protocol SVGExportable {
    func toSVGPath(size: CGSize) -> String
}

// MARK: - Line Data SVG Export

extension LineDataSeries: SVGExportable {
    public func toSVGPath(size: CGSize) -> String {
        guard values.count >= 2 else { return "" }
        
        let minY = values.min() ?? 0
        let maxY = values.max() ?? 100
        let range = max(maxY - minY, 0.001)
        
        let padding: CGFloat = 40
        let chartWidth = size.width - padding * 2
        let chartHeight = size.height - padding * 2
        
        var pathData = "M"
        
        for (index, value) in values.enumerated() {
            let x = padding + chartWidth * CGFloat(index) / CGFloat(values.count - 1)
            let normalizedY = (value - minY) / range
            let y = padding + chartHeight * (1 - CGFloat(normalizedY))
            
            if index == 0 {
                pathData += " \(Int(x)),\(Int(y))"
            } else {
                pathData += " L \(Int(x)),\(Int(y))"
            }
        }
        
        let colorHex = "#3B82F6" // Default blue
        
        return """
        
        <path d="\(pathData)" fill="none" stroke="\(colorHex)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        """
    }
}

// MARK: - Bar Data SVG Export

extension BarDataSeries: SVGExportable {
    public func toSVGPath(size: CGSize) -> String {
        guard !values.isEmpty else { return "" }
        
        let minY: Double = 0
        let maxY = values.max() ?? 100
        let range = max(maxY - minY, 0.001)
        
        let padding: CGFloat = 40
        let chartWidth = size.width - padding * 2
        let chartHeight = size.height - padding * 2
        
        let barWidth = chartWidth / CGFloat(values.count) * 0.8
        let barSpacing = chartWidth / CGFloat(values.count) * 0.1
        
        var svg = ""
        let colorHex = "#3B82F6"
        
        for (index, value) in values.enumerated() {
            let x = padding + (chartWidth / CGFloat(values.count)) * CGFloat(index) + barSpacing
            let normalizedHeight = value / range
            let barHeight = chartHeight * CGFloat(normalizedHeight)
            let y = padding + chartHeight - barHeight
            
            svg += """
            
            <rect x="\(Int(x))" y="\(Int(y))" width="\(Int(barWidth))" height="\(Int(barHeight))" fill="\(colorHex)" rx="4"/>
            """
        }
        
        return svg
    }
}

// MARK: - Clipboard Support

#if canImport(UIKit)
public extension ChartExporter {
    /// Copies the chart image to clipboard.
    @available(iOS 16.0, *)
    func copyToClipboard<V: View>(
        view: V,
        size: CGSize,
        options: ExportOptions? = nil
    ) async throws {
        let data = try await exportToPNG(view: view, size: size, options: options)
        
        guard let image = UIImage(data: data) else {
            throw ExportError.encodingFailed
        }
        
        await MainActor.run {
            UIPasteboard.general.image = image
        }
    }
}
#endif

#if canImport(AppKit)
public extension ChartExporter {
    /// Copies the chart image to clipboard.
    @available(macOS 13.0, *)
    func copyToClipboard<V: View>(
        view: V,
        size: CGSize,
        options: ExportOptions? = nil
    ) async throws {
        let data = try await exportToPNG(view: view, size: size, options: options)
        
        guard let image = NSImage(data: data) else {
            throw ExportError.encodingFailed
        }
        
        await MainActor.run {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }
}
#endif
