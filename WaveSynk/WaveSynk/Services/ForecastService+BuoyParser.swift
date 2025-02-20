import Foundation

extension ForecastService {
    func parseBuoyData(_ data: Data) throws -> BuoyData {
        guard let string = String(data: data, encoding: .utf8) else {
            throw ForecastError.invalidData
        }
        
        let lines = string.components(separatedBy: .newlines)
        guard lines.count > 2 else {
            throw ForecastError.invalidData
        }
        
        // NDBC buoy data format:
        // Line 1: Header with column names
        // Line 2: Units
        // Line 3+: Data (most recent first)
        let headers = lines[0].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let values = lines[2].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard headers.count == values.count else {
            throw ForecastError.invalidData
        }
        
        // Create dictionary of column name to value
        var data: [String: String] = [:]
        for (index, header) in headers.enumerated() {
            data[header] = values[index]
        }
        
        // Parse required values
        guard let waveHeight = Double(data["WVHT"] ?? ""),
              let wavePeriod = Double(data["DPD"] ?? ""),
              let windSpeed = Double(data["WSPD"] ?? ""),
              let windDir = data["WD"] else {
            throw ForecastError.invalidData
        }
        
        // Parse optional values
        let waterTemp = Double(data["WTMP"] ?? "")
        
        // Parse timestamp
        let year = Int(data["YY"] ?? "") ?? 0
        let month = Int(data["MM"] ?? "") ?? 0
        let day = Int(data["DD"] ?? "") ?? 0
        let hour = Int(data["hh"] ?? "") ?? 0
        let minute = Int(data["mm"] ?? "") ?? 0
        
        var dateComponents = DateComponents()
        dateComponents.year = 2000 + year // NDBC uses 2-digit year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        guard let timestamp = Calendar.current.date(from: dateComponents) else {
            throw ForecastError.invalidData
        }
        
        // Convert wind direction to cardinal direction
        let windDirection = convertWindDirection(degrees: Int(Double(windDir) ?? 0))
        
        return BuoyData(
            waveHeight: waveHeight,
            wavePeriod: wavePeriod,
            windSpeed: windSpeed,
            windDirection: windDirection,
            waterTemperature: waterTemp,
            timestamp: timestamp
        )
    }
    
    private func convertWindDirection(degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(Double(degrees) / 22.5)) % 16
        return directions[index]
    }
} 