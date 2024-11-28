import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 1. Flutterのプラグインを登録
        GeneratedPluginRegistrant.register(with: self)

        // 2. FlutterMethodChannelの設定
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.ocr", binaryMessenger: controller.binaryMessenger)

        let ocrHandler = OCRHandler()

        channel.setMethodCallHandler { (call, result) in
            if call.method == "recognizeText" {
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path not provided", details: nil))
                    return
                }

                ocrHandler.recognizeText(from: imagePath) { recognizedText in
                    result(recognizedText)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

@objc class OCRHandler: NSObject {
    @objc func recognizeText(from imagePath: String, completion: @escaping (String?) -> Void) {
        guard let image = UIImage(contentsOfFile: imagePath)?.cgImage else {
            completion(nil)
            return
        }

        if #available(iOS 13.0, *) {
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    print("Error recognizing text: \(error)")
                    completion(nil)
                    return
                }

                // 観測結果を取得
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil)
                    return
                }
                // 画像サイズを取得
                let imageHeight = CGFloat(image.height)
                let imageWidth = CGFloat(image.width)

                // 条件に基づいてフィルタリング
                let recognizedText = observations.compactMap {  observation -> String? in
                    // 文字候補を取得
                    guard let topCandidate = observation.topCandidates(1).first else {
                        return nil
                    }
                    // 文字列が3文字でかつ数字か確認
                    let recognizedString = topCandidate.string
                    let isThreeDigitNumber = recognizedString.count == 3 && recognizedString.allSatisfy { $0.isNumber }
                    if !isThreeDigitNumber {
                      debugPrint("Not a 3-digit number: \(recognizedString)")
                      return nil
                    }

                    // 文字のバウンディングボックスの大きさを取得
                    let boundingBox = observation.boundingBox
                    let boxHeight = boundingBox.height * imageHeight // 実際の高さに変換
                    let boxWidth = boundingBox.width * imageWidth    // 実際の幅に変換

                    // 条件を計算（例: 画像の高さの2%～5%を有効な文字サイズとする）
                    let minHeight = imageHeight * 0.01
                    let maxHeight = imageHeight * 0.03
                    let minWidth = imageWidth * 0.07
                    let maxWidth = imageWidth * 0.10

                    // 一定の大きさの文字のみ取得
                    if !(boxHeight >= minHeight && boxHeight <= maxHeight) {
                        let boxHeightString = String(format: "%.2f", boxHeight)
                        let minHeightString = String(format: "%.2f", minHeight)
                        let maxHeightString = String(format: "%.2f", maxHeight)

                        debugPrint("\(recognizedString),H \(boxHeightString), \(minHeightString), \(maxHeightString)")
                        // return "\(recognizedString),H \(boxHeightString), \(minHeightString), \(maxHeightString)"
                        return nil
    
                    }
                    // 一定の幅の文字のみ取得
                    if !(boxWidth >= minWidth && boxWidth <= maxWidth) {
                        let boxWidthString = String(format: "%.2f", boxWidth)
                        let minWidthString = String(format: "%.2f", minWidth)
                        let maxWidthString = String(format: "%.2f", maxWidth)

                        debugPrint("\(recognizedString),W \(boxWidthString), \(minWidthString), \(maxWidthString)")
                        // return "\(recognizedString),W \(boxWidthString), \(minWidthString), \(maxWidthString)"
                        return nil
                    }
                    return "\(recognizedString)"
                }.joined(separator: "\n")

                completion(recognizedText)
            }
            // オプション設定
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "ja"] // 認識言語の指定
            request.usesLanguageCorrection = true // 言語補正を有効にする

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                completion(nil)
            }
        } else {
            print("VNRecognizeTextRequest is not available on iOS versions below 13.0")
            completion(nil)
        }
    }
}
