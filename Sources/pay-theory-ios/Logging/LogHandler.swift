// Copyright 2022-present 650 Industries. All rights reserved.

import os.log

func createOSLogHandler(category: String) -> LogHandler {
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        return OSLogHandler(category: category)
    }
    return PrintLogHandler()
}

/// The protocol that needs to be implemented by log handlers.
protocol LogHandler {
    func log(type: LogType, _ message: String)
}

/// The log handler that uses the new `os.Logger` API.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
class OSLogHandler: LogHandler {
    private let osLogger: os.Logger

    required init(category: String) {
        osLogger = os.Logger(
            subsystem: Logger.LOG_SUBSYSTEM, category: category)
    }

    func log(type: LogType, _ message: String) {
        osLogger.log(level: type.toOSLogType(), "\(message)")
    }
}

/// Simple log handler that forwards all logs to `print` function.
class PrintLogHandler: LogHandler {
    func log(type: LogType, _ message: String) {
        print(message)
    }
}
