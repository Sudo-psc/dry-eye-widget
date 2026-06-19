import Foundation
import FlutterMacOS

#if canImport(HealthKit)
import HealthKit
#endif

final class HealthKitDashboardBridge {
  static let channelName = "dry_eye_widget/healthkit_dashboard"

  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: binaryMessenger)
    let bridge = HealthKitDashboardBridge()
    channel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(isHealthKitAvailable())
    case "requestAuthorization":
      requestAuthorization(result: result)
    case "fetchDailySummaries":
      guard let args = call.arguments as? [String: Any],
        let startMillis = args["startMillis"] as? NSNumber,
        let endMillis = args["endMillis"] as? NSNumber
      else {
        result(FlutterError(code: "bad_args", message: "startMillis/endMillis ausentes", details: nil))
        return
      }
      let start = Date(timeIntervalSince1970: startMillis.doubleValue / 1000)
      let end = Date(timeIntervalSince1970: endMillis.doubleValue / 1000)
      fetchDailySummaries(start: start, end: end, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isHealthKitAvailable() -> Bool {
    #if canImport(HealthKit)
    if #available(macOS 13.0, *) {
      return HKHealthStore.isHealthDataAvailable()
    }
    #endif
    return false
  }

  private func requestAuthorization(result: @escaping FlutterResult) {
    #if canImport(HealthKit)
    if #available(macOS 13.0, *) {
      guard HKHealthStore.isHealthDataAvailable() else {
        result(["available": false, "authorized": false, "reason": "HealthKit unavailable on this Mac."])
        return
      }
      guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)
      else {
        result(["available": false, "authorized": false, "reason": "HealthKit types unavailable."])
        return
      }
      let readTypes: Set<HKObjectType> = [sleep, heartRate]
      HKHealthStore().requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { success, error in
        DispatchQueue.main.async {
          if let error = error {
            result(["available": true, "authorized": false, "reason": error.localizedDescription])
          } else {
            result(["available": true, "authorized": success])
          }
        }
      }
      return
    }
    #endif
    result(["available": false, "authorized": false, "reason": "HealthKit framework unavailable."])
  }

  private func fetchDailySummaries(start: Date, end: Date, result: @escaping FlutterResult) {
    #if canImport(HealthKit)
    if #available(macOS 13.0, *) {
      guard HKHealthStore.isHealthDataAvailable() else {
        result(FlutterError(code: "healthkit_unavailable", message: "HealthKit unavailable on this Mac.", details: nil))
        return
      }
      let store = HKHealthStore()
      let group = DispatchGroup()
      var sleepByDay: [String: Double] = [:]
      var heartRateByDay: [String: Double] = [:]
      var firstError: Error?

      group.enter()
      fetchSleepSeconds(store: store, start: start, end: end) { values, error in
        if firstError == nil { firstError = error }
        sleepByDay = values
        group.leave()
      }

      group.enter()
      fetchAverageHeartRate(store: store, start: start, end: end) { values, error in
        if firstError == nil { firstError = error }
        heartRateByDay = values
        group.leave()
      }

      group.notify(queue: .main) {
        if let firstError = firstError {
          result(FlutterError(code: "healthkit_read_failed", message: firstError.localizedDescription, details: nil))
          return
        }
        let rows = self.dayKeys(start: start, end: end).map { key -> [String: Any] in
          var row: [String: Any] = ["date": key]
          if let sleep = sleepByDay[key], sleep > 0 {
            row["sleepSeconds"] = sleep
          } else {
            row["sleepAbsenceReason"] = "No sleep samples for this day."
          }
          if let heartRate = heartRateByDay[key], heartRate > 0 {
            row["averageHeartRateBpm"] = heartRate
          } else {
            row["heartRateAbsenceReason"] = "No heart-rate samples for this day."
          }
          return row
        }
        result(rows)
      }
      return
    }
    #endif
    result(FlutterError(code: "healthkit_unavailable", message: "HealthKit framework unavailable.", details: nil))
  }

  #if canImport(HealthKit)
  @available(macOS 13.0, *)
  private func fetchSleepSeconds(
    store: HKHealthStore,
    start: Date,
    end: Date,
    completion: @escaping ([String: Double], Error?) -> Void
  ) {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      completion([:], nil)
      return
    }
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)
    let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
      guard error == nil else {
        completion([:], error)
        return
      }
      var values: [String: Double] = [:]
      for case let sample as HKCategorySample in samples ?? [] {
        if !self.isAsleep(sample.value) { continue }
        self.accumulateOverlap(sampleStart: sample.startDate, sampleEnd: sample.endDate, rangeStart: start, rangeEnd: end, into: &values)
      }
      completion(values, nil)
    }
    store.execute(query)
  }

  @available(macOS 13.0, *)
  private func fetchAverageHeartRate(
    store: HKHealthStore,
    start: Date,
    end: Date,
    completion: @escaping ([String: Double], Error?) -> Void
  ) {
    guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
      completion([:], nil)
      return
    }
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)
    let interval = DateComponents(day: 1)
    let calendar = Calendar.current
    let anchor = calendar.startOfDay(for: start)
    let query = HKStatisticsCollectionQuery(
      quantityType: heartRateType,
      quantitySamplePredicate: predicate,
      options: .discreteAverage,
      anchorDate: anchor,
      intervalComponents: interval
    )
    query.initialResultsHandler = { _, collection, error in
      guard error == nil else {
        completion([:], error)
        return
      }
      var values: [String: Double] = [:]
      let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
      collection?.enumerateStatistics(from: start, to: end) { stats, _ in
        if let quantity = stats.averageQuantity() {
          values[self.dayKey(stats.startDate)] = quantity.doubleValue(for: unit)
        }
      }
      completion(values, nil)
    }
    store.execute(query)
  }

  @available(macOS 13.0, *)
  private func isAsleep(_ value: Int) -> Bool {
    if value == HKCategoryValueSleepAnalysis.asleep.rawValue { return true }
    if value == HKCategoryValueSleepAnalysis.asleepCore.rawValue { return true }
    if value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue { return true }
    if value == HKCategoryValueSleepAnalysis.asleepREM.rawValue { return true }
    return false
  }
  #endif

  private func dayKeys(start: Date, end: Date) -> [String] {
    var result: [String] = []
    let calendar = Calendar.current
    var day = calendar.startOfDay(for: start)
    let last = calendar.startOfDay(for: end)
    while day < last {
      result.append(dayKey(day))
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
    }
    return result
  }

  private func accumulateOverlap(
    sampleStart: Date,
    sampleEnd: Date,
    rangeStart: Date,
    rangeEnd: Date,
    into values: inout [String: Double]
  ) {
    let calendar = Calendar.current
    var cursor = max(sampleStart, rangeStart)
    let final = min(sampleEnd, rangeEnd)
    while cursor < final {
      let dayStart = calendar.startOfDay(for: cursor)
      guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
      let segmentEnd = min(final, nextDay)
      values[dayKey(dayStart), default: 0] += segmentEnd.timeIntervalSince(cursor)
      cursor = segmentEnd
    }
  }

  private func dayKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = Calendar.current.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
