import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()
  private let stepsChannelName = "hypertrack.health/steps"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: stepsChannelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleStepsCall(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleStepsCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "requestPermissions":
      requestHealthKitPermissions(result: result)
    case "readStepSegments":
      readStepSegments(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestHealthKitPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
      result(FlutterError(code: "not_available", message: "Step count type unavailable", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func readStepSegments(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String
    else {
      result([])
      return
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let fromDate = formatter.date(from: fromIso) ?? ISO8601DateFormatter().date(from: fromIso),
          let toDate = formatter.date(from: toIso) ?? ISO8601DateFormatter().date(from: toIso),
          let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)
    else {
      result([])
      return
    }

    let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: [.strictStartDate])
    let query = HKSampleQuery(
      sampleType: stepType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }

      let formatterOut = ISO8601DateFormatter()
      formatterOut.timeZone = TimeZone(secondsFromGMT: 0)
      formatterOut.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
        [
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "stepCount": Int(sample.quantity.doubleValue(for: HKUnit.count())),
          "sourceId": sample.sourceRevision.source.bundleIdentifier,
          "nativeId": sample.uuid.uuidString
        ] as [String: Any]
      }
      result(mapped)
    }
    healthStore.execute(query)
  }
}
