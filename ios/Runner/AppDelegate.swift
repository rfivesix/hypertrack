import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()
  private let stepsChannelName = "hypertrack.health/steps"
  private let sleepHealthKitChannelName = "hypertrack.health/sleep_healthkit"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: stepsChannelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleStepsCall(call: call, result: result)
      }
      let sleepChannel = FlutterMethodChannel(
        name: sleepHealthKitChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      sleepChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleSleepHealthKitCall(call: call, result: result)
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
    guard let fromDate = formatter.date(from: fromIso),
          let toDate = formatter.date(from: toIso),
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

  private func handleSleepHealthKitCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "checkPermissions":
      result(currentSleepPermissionSnapshot())
    case "requestPermissions":
      requestSleepPermissions(result: result)
    case "readSleepAndHeartRate":
      readSleepAndHeartRate(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestSleepPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }
    guard
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
    else {
      result(FlutterError(code: "not_available", message: "Sleep/HR types unavailable", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: [sleepType, heartRateType]) { [weak self] success, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }
      if !success {
        result(self?.currentSleepPermissionSnapshot() ?? ["sleepGranted": false, "heartRateGranted": false])
        return
      }
      result(self?.currentSleepPermissionSnapshot() ?? ["sleepGranted": false, "heartRateGranted": false])
    }
  }

  private func currentSleepPermissionSnapshot() -> [String: Any] {
    guard
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
    else {
      return ["sleepGranted": false, "heartRateGranted": false]
    }
    let sleepGranted = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
    let heartRateGranted = healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized
    return ["sleepGranted": sleepGranted, "heartRateGranted": heartRateGranted]
  }

  private func readSleepAndHeartRate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String
    else {
      result(["sessions": [], "stageSegments": [], "heartRateSamples": []])
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard
      let fromDate = formatter.date(from: fromIso),
      let toDate = formatter.date(from: toIso),
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let heartType = HKObjectType.quantityType(forIdentifier: .heartRate)
    else {
      result(["sessions": [], "stageSegments": [], "heartRateSamples": []])
      return
    }
    let predicate = HKQuery.predicateForSamples(
      withStart: fromDate,
      end: toDate,
      options: [.strictStartDate]
    )

    let dispatch = DispatchGroup()
    var sleepSamples: [HKCategorySample] = []
    var heartSamples: [HKQuantitySample] = []
    var queryError: Error?

    dispatch.enter()
    let sleepQuery = HKSampleQuery(
      sampleType: sleepType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error { queryError = error }
      sleepSamples = (samples as? [HKCategorySample]) ?? []
      dispatch.leave()
    }
    healthStore.execute(sleepQuery)

    dispatch.enter()
    let hrQuery = HKSampleQuery(
      sampleType: heartType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error { queryError = error }
      heartSamples = (samples as? [HKQuantitySample]) ?? []
      dispatch.leave()
    }
    healthStore.execute(hrQuery)

    dispatch.notify(queue: .main) {
      if let queryError = queryError {
        result(FlutterError(code: "query_failed", message: queryError.localizedDescription, details: nil))
        return
      }
      let formatterOut = ISO8601DateFormatter()
      formatterOut.timeZone = TimeZone(secondsFromGMT: 0)
      formatterOut.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let sessions: [[String: Any]] = sleepSamples.map { sample in
        [
          "recordId": sample.uuid.uuidString,
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "platformSessionType": "sleep",
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }
      let stageSegments: [[String: Any]] = sleepSamples.map { sample in
        [
          "recordId": "stage-\(sample.uuid.uuidString)",
          "sessionRecordId": sample.uuid.uuidString,
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "platformStage": self.mapHealthKitSleepValue(sample.value),
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }

      let hrRows: [[String: Any]] = heartSamples.compactMap { sample in
        guard let session = sleepSamples.first(where: { overlap(sample.startDate, sample.endDate, $0.startDate, $0.endDate) }) else {
          return nil
        }
        return [
          "recordId": sample.uuid.uuidString,
          "sessionRecordId": session.uuid.uuidString,
          "sampledAtUtcIso": formatterOut.string(from: sample.startDate),
          "bpm": sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }
      result([
        "sessions": sessions,
        "stageSegments": stageSegments,
        "heartRateSamples": hrRows
      ])
    }
  }

  private func mapHealthKitSleepValue(_ value: Int) -> String {
    switch value {
    case HKCategoryValueSleepAnalysis.inBed.rawValue:
      return "in_bed"
    case HKCategoryValueSleepAnalysis.awake.rawValue:
      return "awake"
    default:
      return "asleep"
    }
  }

  private func overlap(_ aStart: Date, _ aEnd: Date, _ bStart: Date, _ bEnd: Date) -> Bool {
    return aStart < bEnd && aEnd > bStart
  }
}
