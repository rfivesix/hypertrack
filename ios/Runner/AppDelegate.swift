import Flutter
import HealthKit
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()
  private let stepsChannelName = "hypertrack.health/steps"
  private let sleepHealthKitChannelName = "hypertrack.health/sleep_healthkit"
  private let exportAppleHealthChannelName = "hypertrack.health/export_apple_health"
  private let todayFocusWidgetChannelName = "hypertrack.widget/today_focus"
  private let widgetLauncherChannelName = "hypertrack.widget/launcher"
  private let todayFocusWidgetSuiteName = "group.com.rfivesix.hypertrack.widget"
  private let todayFocusWidgetPayloadKey = "payload_json"
  private let widgetActionOpenDiary = "openDiary"
  private var widgetLauncherChannel: FlutterMethodChannel?
  private var pendingWidgetAction: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let launchUrl = launchOptions?[.url] as? URL {
      pendingWidgetAction = widgetAction(for: launchUrl)
    }

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
      let exportChannel = FlutterMethodChannel(
        name: exportAppleHealthChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      exportChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleExportAppleHealthCall(call: call, result: result)
      }

      let widgetChannel = FlutterMethodChannel(
        name: todayFocusWidgetChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "internal", message: "AppDelegate unavailable", details: nil))
          return
        }
        switch call.method {
        case "setPayload":
          guard
            let args = call.arguments as? [String: Any],
            let payloadJson = args["payloadJson"] as? String
          else {
            result(FlutterError(code: "invalid_args", message: "payloadJson missing", details: nil))
            return
          }
          self.widgetDefaults().set(payloadJson, forKey: self.todayFocusWidgetPayloadKey)
          self.widgetDefaults().synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(true)
        case "refresh":
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let launcherChannel = FlutterMethodChannel(
        name: widgetLauncherChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      launcherChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "internal", message: "AppDelegate unavailable", details: nil))
          return
        }
        switch call.method {
        case "getInitialAction":
          let action = self.pendingWidgetAction
          self.pendingWidgetAction = nil
          result(action)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      widgetLauncherChannel = launcherChannel
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if let action = widgetAction(for: url) {
      notifyWidgetAction(action)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if
      let url = options.urlContexts.first?.url,
      let action = widgetAction(for: url)
    {
      pendingWidgetAction = action
    }
    return super.application(
      application,
      configurationForConnecting: connectingSceneSession,
      options: options
    )
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

  private func handleExportAppleHealthCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "requestPermissions":
      requestExportPermissions(result: result)
    case "writeMeasurement":
      writeMeasurement(call: call, result: result)
    case "writeNutrition":
      writeNutrition(call: call, result: result)
    case "writeHydration":
      writeHydration(call: call, result: result)
    case "writeWorkout":
      writeWorkout(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestExportPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    guard
      let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
      let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
      let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
      let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
      let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
      let dietaryProtein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
      let dietaryCarbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
      let dietaryFat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
      let dietaryFiber = HKObjectType.quantityType(forIdentifier: .dietaryFiber),
      let dietarySugar = HKObjectType.quantityType(forIdentifier: .dietarySugar),
      let dietarySodium = HKObjectType.quantityType(forIdentifier: .dietarySodium),
      let hydration = HKObjectType.quantityType(forIdentifier: .dietaryWater)
    else {
      result(false)
      return
    }
    let workout = HKObjectType.workoutType()

    let shareTypes: Set<HKSampleType> = [
      bodyMass, bodyFat, bmi, activeEnergy, dietaryEnergy, dietaryProtein,
      dietaryCarbs, dietaryFat, dietaryFiber, dietarySugar, dietarySodium,
      hydration, workout,
    ]

    healthStore.requestAuthorization(toShare: shareTypes, read: nil) { success, _ in
      result(success)
    }
  }

  private func writeMeasurement(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String,
          let typeRaw = args["type"] as? String,
          let rawValue = args["value"] as? NSNumber else {
      result(FlutterError(code: "invalid_args", message: "Invalid measurement payload", details: nil))
      return
    }
    let value = rawValue.doubleValue
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    let quantityType: HKQuantityType?
    let unit: HKUnit
    switch typeRaw {
    case "weight":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass)
      unit = HKUnit.gramUnit(with: .kilo)
    case "bodyFatPercentage":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)
      unit = HKUnit.percent()
    case "bmi":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)
      unit = HKUnit.count()
    default:
      result(FlutterError(code: "invalid_args", message: "Unsupported measurement type", details: nil))
      return
    }

    guard let resolvedType = quantityType else {
      result(FlutterError(code: "not_available", message: "Measurement type unavailable", details: nil))
      return
    }

    let adjustedValue = typeRaw == "bodyFatPercentage" ? value / 100.0 : value
    let quantity = HKQuantity(unit: unit, doubleValue: adjustedValue)
    let sample = HKQuantitySample(type: resolvedType, quantity: quantity, start: timestamp, end: timestamp)
    healthStore.save(sample) { success, error in
      if let error = error {
        result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func writeNutrition(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Invalid nutrition payload", details: nil))
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    var samples: [HKQuantitySample] = []
    func value(_ key: String) -> Double? {
      return (args[key] as? NSNumber)?.doubleValue
    }
    func appendSample(_ identifier: HKQuantityTypeIdentifier, _ value: Double?, _ unit: HKUnit) {
      guard let value = value, let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
      let quantity = HKQuantity(unit: unit, doubleValue: value)
      samples.append(HKQuantitySample(type: type, quantity: quantity, start: timestamp, end: timestamp))
    }

    appendSample(.dietaryEnergyConsumed, value("caloriesKcal"), HKUnit.kilocalorie())
    appendSample(.dietaryProtein, value("proteinGrams"), HKUnit.gram())
    appendSample(.dietaryCarbohydrates, value("carbsGrams"), HKUnit.gram())
    appendSample(.dietaryFatTotal, value("fatGrams"), HKUnit.gram())
    appendSample(.dietaryFiber, value("fiberGrams"), HKUnit.gram())
    appendSample(.dietarySugar, value("sugarGrams"), HKUnit.gram())
    appendSample(.dietarySodium, value("sodiumGrams"), HKUnit.gram())

    if samples.isEmpty {
      result(true)
      return
    }

    healthStore.save(samples) { success, error in
      if let error = error {
        result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func writeHydration(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String,
          let litersRaw = args["volumeLiters"] as? NSNumber,
          let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
      result(FlutterError(code: "invalid_args", message: "Invalid hydration payload", details: nil))
      return
    }
    let liters = litersRaw.doubleValue
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: liters)
    let sample = HKQuantitySample(type: type, quantity: quantity, start: timestamp, end: timestamp)
    healthStore.save(sample) { success, error in
      if let error = error {
        result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func writeWorkout(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let startIso = args["startUtcIso"] as? String,
          let endIso = args["endUtcIso"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Invalid workout payload", details: nil))
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let start = formatter.date(from: startIso), let end = formatter.date(from: endIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid workout time range", details: nil))
      return
    }

    let typeRaw = (args["workoutType"] as? String) ?? "strength"
    let workoutType: HKWorkoutActivityType
    switch typeRaw {
    case "running":
      workoutType = .running
    case "walking":
      workoutType = .walking
    case "cycling":
      workoutType = .cycling
    case "yoga":
      workoutType = .yoga
    default:
      workoutType = .traditionalStrengthTraining
    }

    let calories = (args["caloriesBurnedKcal"] as? NSNumber).map {
      HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0.doubleValue)
    }
    let summaryNotes = (args["notes"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let metadata: [String: Any]? = {
      guard let summaryNotes, !summaryNotes.isEmpty else { return nil }
      // HealthKit workout has no dedicated notes field; persist summary in metadata.
      return ["hypertrack_workout_summary": summaryNotes]
    }()
    let duration = end.timeIntervalSince(start)
    let workout = HKWorkout(
      activityType: workoutType,
      start: start,
      end: end,
      duration: duration,
      totalEnergyBurned: calories,
      totalDistance: nil,
      metadata: metadata
    )
    healthStore.save(workout) { success, error in
      if let error = error {
        result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
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
          guard let session = sleepSamples.first(where: { self.overlap(sample.startDate, sample.endDate, $0.startDate, $0.endDate) }) else {
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

  private func widgetDefaults() -> UserDefaults {
    UserDefaults(suiteName: todayFocusWidgetSuiteName) ?? .standard
  }

  private func widgetAction(for url: URL) -> String? {
    let scheme = url.scheme?.lowercased()
    let host = url.host?.lowercased()
    guard scheme == "hypertrack", host == "diary" else {
      return nil
    }
    return widgetActionOpenDiary
  }

  private func notifyWidgetAction(_ action: String) {
    pendingWidgetAction = action
    widgetLauncherChannel?.invokeMethod(
      "onWidgetAction",
      arguments: ["action": action]
    )
  }
}
