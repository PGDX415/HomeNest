//
//  BarcodeScannerView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/7/27.
//

import SwiftUI
import AVFoundation

/// 条形码扫描视图（UIKit 封装）
struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func didScanBarcode(_ code: String) {
            onScan(code)
        }
    }
}

// MARK: - UIKit Scanner

protocol ScannerViewControllerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
}

final class ScannerViewController: UIViewController {
    weak var delegate: ScannerViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showError("无法访问摄像头")
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [
            .ean8, .ean13, .upce, .code39, .code128, .code93, .pdf417, .qr
        ]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview
        captureSession = session
        // 必须在后台线程启动摄像头
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
    }

    private func showError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }

        captureSession?.stopRunning()
        delegate?.didScanBarcode(code)
    }
}
