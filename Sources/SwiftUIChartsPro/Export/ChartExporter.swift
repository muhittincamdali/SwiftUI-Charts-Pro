import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Chart Exporter

/// Exports charts to various image formats.
///
/// Use `ChartExporter` to save charts as PNG or PDF files, or to
/// get image data for sharing.
///
/// ```swift
/// let exporter = ChartExporter()
///
/// if let image = exporter.exportToImage(view: myChart, size: CGSize(width: 800, height: 600)) {
///     // Use image
/// }
/// ```
public class ChartExporter {
    
    /// Export quality settings
    public enum ExportQuality {
        /// Standard quality (1x scale)
        case standard
        
        /// High quality (2x scale)
        case high
        
        /// Maximum quality (3x scale)
        case maximum
        
        /// Custom scale factor
        case custom(CGFloat)
        
        var scale: CGFloat {
            switch self {
            case .standard: return 1.0
            case .high: return 2.0
            case .maximum: return 3.0
            case .custom(let scale): return scale
            }
        }
    }
    
    /// Export format
    public enum ExportFormat {
        case png
        case jpeg(quality: CGFloat)
        case pdf
    }
    
    /// Export result
    public struct ExportResult {
        public let data: Data
        public let format: ExportFormat
        public let size: CGSize
        
        /// File extension for the format
        public var fileExtension: String {
            switch format {
            case .png: return "png"
            case .jpeg: return "jpg"
            case .pdf: return "pdf"
            }
        }
        
        /// MIME type for the format
        public var mimeType: String {
            switch format {
            case .png: return "image/png"
            case .jpeg: return "image/jpeg"
            case .pdf: return "application/pdf"
            }
        }
    }
    
    public init() {}
    
    // MARK: - Export to Image
    
    #if canImport(UIKit)
    /// Exports a SwiftUI view to a UIImage.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to export
    ///   - size: The target size
    ///   - quality: Export quality setting
    /// - Returns: The rendered UIImage, or nil if export fails
    @MainActor
    public func exportToImage<V: View>(
        view: V,
        size: CGSize,
        quality: ExportQuality = .high
    ) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: {
                let format = UIGraphicsImageRendererFormat()
                format.scale = quality.scale
                return format
            }()
        )
        
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    /// Exports a SwiftUI view to image data.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to export
    ///   - size: The target size
    ///   - format: Export format (PNG or JPEG)
    ///   - quality: Export quality setting
    /// - Returns: Export result with image data
    @MainActor
    public func exportToData<V: View>(
        view: V,
        size: CGSize,
        format: ExportFormat = .png,
        quality: ExportQuality = .high
    ) -> ExportResult? {
        guard let image = exportToImage(view: view, size: size, quality: quality) else {
            return nil
        }
        
        let data: Data?
        
        switch format {
        case .png:
            data = image.pngData()
        case .jpeg(let jpegQuality):
            data = image.jpegData(compressionQuality: jpegQuality)
        case .pdf:
            data = exportToPDFData(view: view, size: size)
        }
        
        guard let exportData = data else { return nil }
        
        return ExportResult(data: exportData, format: format, size: size)
    }
    
    /// Exports a SwiftUI view to PDF data.
    @MainActor
    public func exportToPDFData<V: View>(view: V, size: CGSize) -> Data? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        
        return pdfRenderer.pdfData { context in
            context.beginPage()
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    #endif
    
    // MARK: - Save to File
    
    #if canImport(UIKit)
    /// Saves an exported chart to a file.
    ///
    /// - Parameters:
    ///   - result: The export result to save
    ///   - url: The destination file URL
    /// - Throws: An error if saving fails
    public func saveToFile(_ result: ExportResult, at url: URL) throws {
        try result.data.write(to: url)
    }
    
    /// Exports and saves a chart view to a file.
    @MainActor
    public func exportAndSave<V: View>(
        view: V,
        to url: URL,
        size: CGSize,
        format: ExportFormat = .png,
        quality: ExportQuality = .high
    ) throws {
        guard let result = exportToData(view: view, size: size, format: format, quality: quality) else {
            throw ExportError.exportFailed
        }
        
        try saveToFile(result, at: url)
    }
    #endif
    
    // MARK: - Export Errors
    
    public enum ExportError: LocalizedError {
        case exportFailed
        case saveFailed
        case invalidFormat
        
        public var errorDescription: String? {
            switch self {
            case .exportFailed:
                return "Failed to export chart to image"
            case .saveFailed:
                return "Failed to save chart to file"
            case .invalidFormat:
                return "Invalid export format"
            }
        }
    }
}

// MARK: - Export Button View

/// A button that triggers chart export.
public struct ChartExportButton<ChartView: View>: View {
    let chartView: ChartView
    let size: CGSize
    let format: ChartExporter.ExportFormat
    let quality: ChartExporter.ExportQuality
    let onExport: (ChartExporter.ExportResult) -> Void
    
    @State private var isExporting: Bool = false
    
    public init(
        chartView: ChartView,
        size: CGSize,
        format: ChartExporter.ExportFormat = .png,
        quality: ChartExporter.ExportQuality = .high,
        onExport: @escaping (ChartExporter.ExportResult) -> Void
    ) {
        self.chartView = chartView
        self.size = size
        self.format = format
        self.quality = quality
        self.onExport = onExport
    }
    
    public var body: some View {
        Button(action: exportChart) {
            HStack(spacing: 6) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Export")
            }
        }
        .disabled(isExporting)
    }
    
    @MainActor
    private func exportChart() {
        #if canImport(UIKit)
        isExporting = true
        
        Task {
            let exporter = ChartExporter()
            if let result = exporter.exportToData(
                view: chartView,
                size: size,
                format: format,
                quality: quality
            ) {
                onExport(result)
            }
            
            isExporting = false
        }
        #endif
    }
}

// MARK: - Share Sheet Helper

#if canImport(UIKit)
/// Presents a share sheet for exported chart data.
@MainActor
public func shareChart(_ result: ChartExporter.ExportResult, from viewController: UIViewController? = nil) {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("chart_export")
        .appendingPathExtension(result.fileExtension)
    
    do {
        try result.data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        let presenter = viewController ?? UIApplication.shared.windows.first?.rootViewController
        presenter?.present(activityVC, animated: true)
    } catch {
        print("Failed to share chart: \(error)")
    }
}
#endif

// MARK: - Export Configuration

/// Configuration for chart export operations.
public struct ExportConfiguration {
    /// The export size
    public var size: CGSize
    
    /// The export format
    public var format: ChartExporter.ExportFormat
    
    /// The export quality
    public var quality: ChartExporter.ExportQuality
    
    /// Background color (nil for transparent)
    public var backgroundColor: Color?
    
    /// Padding around the chart
    public var padding: EdgeInsets
    
    /// Whether to include a title
    public var includeTitle: Bool
    
    /// Title text
    public var title: String?
    
    /// Whether to include a timestamp
    public var includeTimestamp: Bool
    
    /// Creates an export configuration.
    public init(
        size: CGSize = CGSize(width: 800, height: 600),
        format: ChartExporter.ExportFormat = .png,
        quality: ChartExporter.ExportQuality = .high,
        backgroundColor: Color? = .white,
        padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        includeTitle: Bool = false,
        title: String? = nil,
        includeTimestamp: Bool = false
    ) {
        self.size = size
        self.format = format
        self.quality = quality
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.includeTitle = includeTitle
        self.title = title
        self.includeTimestamp = includeTimestamp
    }
    
    /// Standard configuration for social media
    public static let socialMedia = ExportConfiguration(
        size: CGSize(width: 1200, height: 630),
        quality: .high
    )
    
    /// Configuration for presentations
    public static let presentation = ExportConfiguration(
        size: CGSize(width: 1920, height: 1080),
        quality: .maximum
    )
    
    /// Configuration for print
    public static let print = ExportConfiguration(
        size: CGSize(width: 2480, height: 3508), // A4 at 300 DPI
        format: .pdf,
        quality: .maximum
    )
}

// MARK: - Preview Provider

#if DEBUG
struct ChartExporter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Export functionality available on device")
                .padding()
        }
    }
}
#endif
