import ArgumentParser
import Foundation
import os
import RealityKit

struct Threedify: ParsableCommand {
    
    private typealias Request = PhotogrammetrySession.Request
    private typealias Result = PhotogrammetrySession.Result
    private typealias ProgressInfo = PhotogrammetrySession.Output.ProgressInfo
    private typealias Configuration = PhotogrammetrySession.Configuration
    private typealias CustomDetailSpecification = PhotogrammetrySession.Configuration.CustomDetailSpecification
    private typealias TextureDimension = PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureDimension;
    
    public static let configuration = CommandConfiguration(
        commandName: "threedify",
        abstract: "Creates 3D models from images using photogrammetry.",
        version: "0.1.0")
    
    @Argument(help: "The folder of images.")
    private var inputFolder: String
    
    @Argument(help: "The output filename. If the path is a .usdz file path, the export will generatea a USDZ file, if the path is a directory, it will generate an OBJ in the directory.")
    private var outputFilename: String
    
    @Flag(help: "Determines whether or not to disable masking of the scene around the model.")
    private var disableMasking = false
    
    @Option(name: .shortAndLong,
            parsing: .next,
            help: "detail {preview, reduced, medium, full, raw, custom}  Detail of output model in terms of mesh size and texture size.",
            transform: Request.Detail.init)
    private var detail: Request.Detail? = nil
    
    @Option(name: .shortAndLong,
            parsing: .next,
            help: "Provide a checkoint directory to be able to restart a session which was interrupted.")
    private var checkpointDirectory: String = ""
    
    @Option(name: [.customShort("o"), .long],
            parsing: .next,
            help: "sampleOrdering {unordered, sequential}  Setting to sequential may speed up computation if images are captured in a spatially sequential pattern.",
            transform: Configuration.SampleOrdering.init)
    private var sampleOrdering: Configuration.SampleOrdering?
    
    @Option(name: .shortAndLong,
            parsing: .next,
            help: "featureSensitivity {normal, high}  Set to high if the scanned object does not contain a lot of discernible structures, edges or textures.",
            transform: Configuration.FeatureSensitivity.init)
    private var featureSensitivity: Configuration.FeatureSensitivity?
    
    @Option(name: [.customShort("p"), .long],
            parsing: .next,
            help: "maxPolygons {number} Reducing the maximum number if polygons can help tweak the detail level of detail of the mesh. Only applies to custom detail level.",
            transform: UInt.init)
    private var maxPolygons: UInt? = nil
    
    func run() {
        guard PhotogrammetrySession.isSupported else {
            print("Object Capture is not available on this computer.")
            Foundation.exit(1)
        }
        
        let inputFolderUrl: URL = URL(fileURLWithPath: inputFolder, isDirectory: true)
        let configuration: Threedify.Configuration = makeConfigurationFromArguments()
        
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: inputFolderUrl, configuration: configuration)
        } catch {
            Foundation.exit(1)
        }
        guard let session: PhotogrammetrySession = maybeSession else {
            Foundation.exit(1)
        }
        
        let waiter: Task<(), Never> = Task {
            do {
                for try await output: PhotogrammetrySession.Outputs.Element in session.outputs {
                    switch output {
                        case .processingComplete:
                            Foundation.exit(0)
                        case .requestProgress(let request, let fractionComplete):
                            self.handleRequestProgress(request: request, fractionComplete: fractionComplete)
                        case .requestProgressInfo(let request, let progressInfo):
                            self.handleRequestProgressInfo(request: request, progressInfo: progressInfo)
                    @unknown default:
                            print("")
                    }
                }
            } catch {
                Foundation.exit(0)
            }
        }
        
        withExtendedLifetime((session, waiter)) {
            do {
                let request: Threedify.Request = makeRequestFromArguments()
                try session.process(requests: [ request ])
                RunLoop.main.run()
            } catch {
                Foundation.exit(1)
            }
        }
    }

    private func makeConfigurationFromArguments() -> Configuration {
        var configuration: Threedify.Configuration = Configuration();
        
        if (checkpointDirectory != "") {
            var checkpointDirectoryUrl = URL(fileURLWithPath: checkpointDirectory);
            configuration = Configuration(checkpointDirectory: checkpointDirectoryUrl);
        }
        
        if (disableMasking) {
            configuration.isObjectMaskingEnabled = false;
        }

        if let maxPolygonsValue = maxPolygons {
            var customDetail: Threedify.CustomDetailSpecification = CustomDetailSpecification();
            customDetail.maximumPolygonCount = maxPolygonsValue;
            configuration.customDetailSpecification = customDetail;
        }
            
        sampleOrdering.map { configuration.sampleOrdering = $0 }
        featureSensitivity.map { configuration.featureSensitivity = $0 }
        return configuration
    }

    private func makeRequestFromArguments() -> Request {
        let outputUrl: URL = URL(fileURLWithPath: outputFilename)
        if let detailSetting: Threedify.Request.Detail = detail {
            return Request.modelFile(url: outputUrl, detail: detailSetting)
        } else {
            return Request.modelFile(url: outputUrl)
        }
    }
    
    private func handleRequestProgress(request: Request, fractionComplete: Double) {
        print("Progress: \(fractionComplete.asPercentage())")
    }

    private func handleRequestProgressInfo(request: Request, progressInfo: ProgressInfo) {
        print("Processing: \(progressInfo.processingStage?.description ?? "Unknown stage")")
        print("ETA: \(progressInfo.estimatedRemainingTime?.asHHMMSS() ?? "Unknown")")
    }
}

private enum IllegalOption: Swift.Error {
    case invalidDetail(String)
    case invalidSampleOverlap(String)
    case invalidSampleOrdering(String)
    case invalidFeatureSensitivity(String)
}

@available(macOS 14.0, *)
extension PhotogrammetrySession.Request.Detail {
    init(_ detail: String) throws {
        switch detail {
            case "preview": self = .preview
            case "reduced": self = .reduced
            case "medium": self = .medium
            case "full": self = .full
            case "raw": self = .raw
            case "custom": self = .custom
            default: throw IllegalOption.invalidDetail(detail)
        }
    }
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.SampleOrdering {
    init(sampleOrdering: String) throws {
        if sampleOrdering == "unordered" {
            self = .unordered
        } else if sampleOrdering == "sequential" {
            self = .sequential
        } else {
            throw IllegalOption.invalidSampleOrdering(sampleOrdering)
        }
    }
    
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    init(featureSensitivity: String) throws {
        if featureSensitivity == "normal" {
            self = .normal
        } else if featureSensitivity == "high" {
            self = .high
        } else {
            throw IllegalOption.invalidFeatureSensitivity(featureSensitivity)
        }
    }
}

extension PhotogrammetrySession.Output.ProcessingStage {
    var description: String {
        switch self {
        case .imageAlignment:
            return "Image alignment"
        case .meshGeneration:
            return "Mesh generation"
        case .optimization:
            return "Optimization"
        case .preProcessing:
            return "Pre-processing"
        case .textureMapping:
            return "Texture mapping"
        @unknown default:
            return "Unknown stage"
        }
    }
}

extension TimeInterval {
    func asHHMMSS() -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

extension Double {
    func asPercentage(decimalPlaces: Int = 2) -> String {
        let numberFormatter: NumberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = decimalPlaces
        numberFormatter.maximumFractionDigits = decimalPlaces
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)%"
    }
}

if #available(macOS 14.0, *) {
    Threedify.main()
} else {
    fatalError("Requires minimum macOS 14.0")
}
