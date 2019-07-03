
import AVKit
import CoreImage
import GameplayKit
import StoreKit
import UIKit

extension Array {
    /**
     Counts how many items in an array match a filter you specify
     - Parameter where: The test to perform
     - Returns: The number of matching items
     */
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }

    /**
     Chooses N random items from an array
     - Parameter num: How many random items to return
     - Returns: An array of zero or more random items.
     */
    func random(_ num: Int) -> [Element] {
        let items = (self as NSArray).shuffled() as! [Element]
        return Array(items.prefix(num))
    }

    /**
     Shuffles an array in placey
     */
    mutating func shuffle() {
        self = self.shuffled()
    }

    /**
     Returns a randomized version of the array.
     - Returns: A shuffled array
     */
    func shuffled() -> [Element] {
        return (self as NSArray).shuffled() as! [Element]
    }
}

extension Array where Element: BinaryFloatingPoint {
    /**
     Calculates the mean average of all elements in this array
     - Returns: The mean average of elements
     */
    var average: Element {
        return self.reduce(0, +) / Element(self.count)
    }
}

extension Array where Element: Equatable {
    /**
     Returns all indexes where an item exists.
     - Parameter of: The item to search for
     - Returns: An array of integers
     */
    func indexes(of searchItem: Element) -> [Int] {
        var returnValue = [Int]()

        for (index, item) in self.enumerated() {
            if item == searchItem {
                returnValue.append(index)
            }
        }

        return returnValue
    }

    /**
     Removes all instances of an item.
     - Parameter obj: The element to find and remove
     */
    mutating func remove(_ obj: Element) {
        self = self.filter { $0 != obj }
    }
}

extension BinaryFloatingPoint {
    /**
     Ensures a number lies between low and high bounds, inclusive.
     - Parameter low: The lowerbound, inclusive.
     - Parameter high: The upperbound, inclusive.
     - Returns: The clamped number.
     */
    func clamp(low: Self, high: Self) -> Self {
        if (self > high) {
            return high
        } else if (self < low) {
            return low
        }

        return self
    }

    /**
     Internal helper that calculates a hermite spline interpolation based on a weighting factor
     - Parameter value1: The first point to interpolate
     - Parameter tangent1: Tangent at the first point
     - Parameter value2: The secondpoint to interpolate
     - Parameter tangent2: Tangent at the second point
     - Parameter amount: Weighting factor, from 0 to 1
     - Returns: The result of the hermite spline interpolation
     */
    fileprivate static func hermite(value1: Self, tangent1: Self, value2: Self, tangent2: Self, amount: Self) -> Self {
        let amountSquared = amount * amount
        let amountCubed = amountSquared * amount

        if amount == 0 {
            return value1
        } else if amount == 1 {
            return value2
        } else {
            let doubleValue1 = 2 * value1
            let tripleValue1 = 3 * value1
            let doubleValue2 = 2 * value2
            let tripleValue2 = 3 * value2

            let a = (doubleValue1 - doubleValue2 + tangent2 + tangent1) * amountCubed
            let b = (tripleValue2 - tripleValue1 - 2 * tangent1 - tangent2) * amountSquared
            let c = tangent1 * amount + value1
            return a + b + c
        }
    }

    /**
     Performs a linear interpolation from one value to another by a weighting factor you specify
     - Parameter to: The value to interpolate towards
     - Parameter amount: The weighting factor, from 0 to 1.
     - Returns: The interpolated value
     */
    func lerp(to value: Self, amount: Self) -> Self {
        let result = amount.clamp(low: 0, high: 1)
        return self + (value - self) * result
    }

    /**
     Returns a random number between 0 and 1
     */
    static func random() -> Self {
        return Self(GKRandomSource.sharedRandom().nextUniform())
    }

    /**
     Interpolates from one value to another using a cubic equation
     - Parameter to: The value to interpolate towards
     - Parameter amount: The weighting value, from 0 to 1
     - Returns: The interpolated value
     */
    func smoothStep(to value: Self, amount: Self) -> Self {
        let result = amount.clamp(low: 0, high: 1)
        return Self.hermite(value1: self, tangent1: 0, value2: value, tangent2: 0, amount: result)
    }

    /**
     Interpolates from one value to another and back again using a cubic equation
     - Parameter to: The value to interpolate towards
     - Parameter amount: The weighting value, from 0 to 1, where values of 0 and 1 are fully value1, and a value of 0.5 is fully value2.
     - Returns: The interpolated value
     */
    func smoothStep2(to: Self, amount: Self) -> Self {
        let result = amount.clamp(low: 0, high: 1)

        if result > 0.5 {
            return Self.hermite(value1: to, tangent1: 0, value2: self, tangent2: 0, amount: (result - 0.5) * 2.0)
        } else {
            return Self.hermite(value1: self, tangent1: 0, value2: to, tangent2: 0, amount: result * 2.0)
        }
    }
}

extension BinaryInteger {
    /**
     Ensures a number lies between low and high bounds, inclusive.
     - Parameter low: The lowerbound, inclusive.
     - Parameter high: The upperbound, inclusive.
     - Returns: The clamped number.
     */
    func clamp(low: Self, high: Self) -> Self {
        if (self > high) {
            return high
        } else if (self < low) {
            return low
        }

        return self
    }

    /**
     Returns true if this number is odd
     */
    var isOdd: Bool {
        return self % 2 == 1
    }

    /**
     Returns true if this number is even
     */
    var isEven: Bool {
        return self % 2 == 0
    }
}

extension Bundle {
    /**
     Decodes one object type from a JSON filename stored in our bundle. It is a programmer error to call this with a valid that might be missing, corrupt, or invalid JSON.
     - Parameter type: The type of thing to decode, e.g. `[Project].self`
     - Parameter filename: The filename in your bundle, e.g. "projects.json"
     - Returns: The decoded object.
    */
    func decode<T: Decodable>(_ type: T.Type, from filename: String) -> T {
        guard let json = url(forResource: filename, withExtension: nil) else {
            fatalError("Failed to locate \(filename) in app bundle.")
        }

        guard let jsonData = try? Data(contentsOf: json) else {
            fatalError("Failed to load \(filename) from app bundle.")
        }

        let decoder = JSONDecoder()

        guard let result = try? decoder.decode(T.self, from: jsonData) else {
            fatalError("Failed to decode \(filename) from app bundle.")
        }

        return result
    }
}

extension CGAffineTransform {
    /**
     Reads the rotation from an affine transform
     */
    var rotation: CGFloat {
        get {
            return CGFloat(atan2(Double(self.b), Double(self.a)))
        }
    }

    /**
     Reads the scale from an affine transform
     */
    var scale: CGFloat {
        get {
            return CGFloat(sqrt(Double(self.a * self.a + self.c * self.c)))
        }
    }

    /**
     Reads the translation from an affine transform
     */
    var translation: CGPoint {
        get {
            return CGPoint(x: self.tx, y: self.ty)
        }
    }
}

extension CGFloat {
    /// e
    static let e: CGFloat = 2.71828182845904523536028747135266250

    /// log2(e)
    static let log2e: CGFloat = 1.44269504088896340735992468100189214

    /// log10(e)
    static let log10e: CGFloat = 0.434294481903251827651128918916605082

    /// loge(2)
    static let ln2: CGFloat = 0.693147180559945309417232121458176568

    /// loge(10)
    static let ln10: CGFloat = 2.30258509299404568401799145468436421

    /// pi/2
    static let pi2: CGFloat = 1.57079632679489661923132169163975144

    /// pi/4
    static let pi4: CGFloat = 0.785398163397448309615660845819875721

    /// sqrt(2)
    static let sqrt2: CGFloat = 1.41421356237309504880168872420969808

    /// 1/sqrt(2)
    static let sqrt1_2: CGFloat = 0.707106781186547524400844362104849039
}

extension CGPoint {
    /**
     Calculates the normalized form of this CGPoint.
     - Returns: A point that represents the same direction from zero but with a length of 1.
     */
    var normalized: CGPoint {
        let len = self.distance(to: .zero)
        return CGPoint(x: self.x / len, y: self.y / len)
    }

    /**
     Calculates the Manhattan distance from one CGPoint to another
     - Parameter to: The destination CGPoint
     - Returns: The distance between the two points
     */
    func manhattanDistance(to: CGPoint) -> CGFloat {
        return (abs(self.x - to.x) + abs(self.y - to.y))
    }

    /**
     Calculates the distance squared between two CGPoints. This is significantly faster than calculating regular distance.
     - Parameter to: The destination CGPoint
     - Returns: The distance squared between the two points.
     */
    func distanceSquared(to: CGPoint) -> CGFloat {
        return (self.x - to.x) * (self.x - to.x) + (self.y - to.y) * (self.y - to.y)
    }

    /**
     Calculates the Euclidean distance between two CGPoints. This is significantly slower than calculating squared distance.
     - Parameter to: The destination CGPoint
     - Returns: The Euclidean distance between the two points.
     */
    func distance(to: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(to: to))
    }

    /**
     Adds two CGPoints
     - Parameter lhs: The first CGPoint to add
     - Parameter rhs: The second CGPoint to add
     - Returns: A CGPoint made up of the summed X and Y points
     */
    public static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    /**
     Subtracts two CGPoints
     - Parameter lhs: The first CGPoint to subtract
     - Parameter rhs: The second CGPoint to subtract
     - Returns: A CGPoint made up of the right X and Y coordinates subtracted from the left X and Y coordinates
     */
    public static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /**
     Multiplies the X and Y coordinates of a CGPoint by a CGFloat
     - Parameter lhs: The CGPoint to multiply
     - Parameter rhs: The CGFloat to multiply
     - Returns: A CGPoint built by multiplying the X and Y coordinates with the CGFloat
     */
    public static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension Collection {
    /*
     Returns true if any items in this collection return true when run through your function.
     - Parameter predicate: A function that accepts an element and returns true or false
     - Returns: True if any items return true when run through your function.
     */
    func any(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            let result = try predicate(item)

            if result {
                return true
            }
        }

        return false
    }

    /*
     Returns true if no item in this collection returns true when run through your function.
     - Parameter predicate: A function that accepts an element and returns true or false
     - Returns: True if no item returns true when run through your function.
     */
    func none(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            let result = try predicate(item)

            if result {
                return false
            }
        }

        return true
    }
}

extension Collection where Element: Hashable {
    /**
     Returns true if all items in the array exist only once.
     */
    var isUnique: Bool {
        return self.count == Set(self).count
    }
}

extension Collection where Element: Numeric {
    /**
     Calculates the sum total of all elements in the array
     - Returns: The total of all elements in the array
     */
    var total: Element {
        return reduce(0, +)
    }
}

extension Date {
    /**
     Calculates the number of days between two dates.
     - Parameter otherDate: A date to compare against.
     - Returns: The number of days between this date and the comparison date.
    */
    func days(between otherDate: Date) -> Int {
        let calendar = Calendar.current

        let startOfSelf = calendar.startOfDay(for: self)
        let startOfOther = calendar.startOfDay(for: otherDate)
        let components = calendar.dateComponents([.day], from: startOfSelf, to: startOfOther)

        return abs(components.day ?? 0)
    }

    /**
     Returns true if two dates belong to the same day.
     - Parameter other: The date to compare against.
     - Returns: True if this date and the comparison date fall on the same day.
    */
    func isSameDay(as other: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension Encodable {
    /**
     Convert this item to a Data containing JSON
     */
    var jsonData: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }

    /**
     Convert this item to a String containing JSON
     */
    var jsonString: String? {
        let encoder = JSONEncoder()

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension Int {
    /**
     Writes this number as a string with ordinal suffix, e.g. 1st, 3rd.
     */
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: self as NSNumber) ?? String(self)
    }

    /**
     Spells out this number using the current locale, e.g. "twenty six"
     */
    var spelledOut: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: self as NSNumber) ?? String(self)
    }

    /**
     Generates a random number between 0 and the upperboard
     - Returns: The random number
     */
    static func random(upperBound: Int) -> Int {
        return GKRandomSource.sharedRandom().nextInt(upperBound: upperBound)
    }

    static func *(lhs: Int, rhs: CGFloat) -> CGFloat {
        return CGFloat(lhs) * rhs
    }

    static func *(lhs: CGFloat, rhs: Int) -> CGFloat {
        return lhs * CGFloat(rhs)
    }

    static func *(lhs: Int, rhs: Double) -> Double {
        return Double(lhs) * rhs
    }

    static func *(lhs: Double, rhs: Int) -> Double {
        return lhs * Double(rhs)
    }
}

extension SKProduct {
    /**
     Returns this product's price formatted using the user's local currency.
     */
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}

extension String {
    fileprivate static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    /**
     Returns the dominant language used in a string, or nil if it can't be determined.
     */
    var dominantLanguage: String? {
        return NSLinguisticTagger.dominantLanguage(for: self)
    }

    /**
     Returns true if this string is a valid number.
     */
    var isNumeric: Bool {
        return Double(self) != nil
    }

    /**
     Returns an array of characters for this string, which is easier to
     read through than the default character views.
     */
    var letters: [Character] {
        return Array(self)
    }

    /**
     Returns a string split up by line breaks.
     */
    var lines: [String] {
        return self.components(separatedBy: "\n")
    }

    /**
     Removes all whitespace from both sides of a string
     */
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /**
     Converts this String into a URL if possible
     */
    var url: URL? {
        return URL(string: self)
    }

    /**
     Returns an array of all email address and website URLs contained in a string.
     */
    var webAddresses: [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        var addresses = [String]()

        for match in matches {
            // convert the NSRanges to Swift ranges
            guard let range = Range(match.range, in: self) else { continue }
            let url = String(self[range])
            addresses.append(url)
        }

        return addresses
    }

    /**
     Returns the number of words in this string.
     */
    var wordCount: Int {
        let regex = try? NSRegularExpression(pattern: "\\w+", options: NSRegularExpression.Options())
        return regex?.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: self.utf16.count)) ?? 0
    }

    /**
     Lets you read one character from this string using its integer index
     */
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }

    /**
     Lets you read a slice of a string using a regular int range.
     */
    subscript(range: Range<Int>) -> String {
        guard range.lowerBound < count else { return "" }
        guard range.upperBound < count else { return self[range.lowerBound...] }

        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start ..< end])
    }

    /**
     Lets you read a slice of a string using a regular int range.
     */
    subscript(range: ClosedRange<Int>) -> String {
        guard range.lowerBound < count else { return "" }
        guard range.upperBound < count else { return self[range.lowerBound...] }

        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start ... end])
    }

    /**
     Lets you read a slice of a string using a partial range from, e.g. 3...
     */
    subscript(range: CountablePartialRangeFrom<Int>) -> String {
        guard range.lowerBound < count else { return "" }
        let start = index(startIndex, offsetBy: range.lowerBound)
        return String(self[start ..< endIndex])
    }

    /**
     Lets you read a slice of a string using a partial range through, e.g. ...3
     */
    subscript(range: PartialRangeThrough<Int>) -> String {
        guard range.upperBound < count else { return self }
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[startIndex ... end])
    }

    /**
     Lets you read a slice of a string using a partial range up to, e.g. ..<3
     */
    subscript(range: PartialRangeUpTo<Int>) -> String {
        guard range.upperBound < count else { return self }
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[startIndex ..< end])
    }

    /**
     Deletes a prefix from a string; does nothing if the prefix doesn't exist.
     */
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    /**
     Deletes a suffix from a string; does nothing if the suffix doesn't exist.
     */
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }

    /**
     Returns true if all words in a string are spelled correctly.
     Uses the current locale if none is specified.
     */
    func isSpelledCorrectly(for locale: Locale = Locale.current) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: self.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: self, range: range, startingAt: 0, wrap: false, language: locale.languageCode ?? "en")

        return misspelledRange.location == NSNotFound
    }

    /**
     Returns true if a string matches a regular expression.
     **Warning:** Causes a fatal error if the regex is invalid.
     - Parameter regex: The regular expression to search for.
     - Parameter caseInsensitive: Whether to search case sensitive or not; default is false.
     */
    func matches(regex: String, caseInsensitive: Bool = false) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            return matches.count > 0
        } catch {
            fatalError("Invalid regular expression: \(regex)")
        }
    }

    /**
     Parses variables placed inside a string in the format {$varName}, replacing them
     with the equivalent values in the dictionary.
     - Parameter from: A dictionary of variable names and values, e.g. dict["foo"] = "bar"
     - Returns: A parsed string with all variables replaced inline. Missing variables are replaced by empty strings.
     */
    func parsingVariables(from dictionary: [String: Any]) -> String {
        guard self.contains("{$") else { return self }

        var returnValue = self
        let pattern = try! NSRegularExpression(pattern: "\\{\\$([^\\}]+)\\}", options: [])
        let matches = pattern.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))

        for match in matches {
            let range = match.range(at: 1)
            guard let swiftRange = Range(range, in: self) else { continue }
            let textMatch = String(self[swiftRange])

            let value = dictionary[textMatch, default: ""]
            let matchName = "{$\(textMatch)}"

            returnValue = returnValue.replacingOccurrences(of: matchName, with: String(describing: value))
        }

        return returnValue
    }

    /**
     Replaces occurences of one string with another, up to `count` times.
     - Parameter of: The string to look for.
     - Parameter with: The string to replace.
     - Parameter count: The maximum number of replacements
     - Returns: The string with replacements made.
     */
    func replacingOccurrences(of search: String, with replacement: String, count maxReplacements: Int) -> String {
        var count = 0
        var returnValue = self

        while let range = returnValue.range(of: search) {
            returnValue = returnValue.replacingCharacters(in: range, with: replacement)
            count += 1

            // exit as soon as we've made all replacements
            if count == maxReplacements {
                return returnValue
            }
        }

        return returnValue
    }

    /**
     Converts a string to a slug, which is a version of a string that
     removes all non-Latin alphabet characters. All punctuation and accents
     get removed, and the resulting string is lowercased. Slugs are designed
     to be safe for filenames and URLs.
     - Returns: The slug string, or nil if it could not be converted.
     */
    public func slugify() -> String? {
        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
            let result = urlComponents.filter { $0 != "" }.joined(separator: "-")

            if result.characters.count > 0 {
                return result
            }
        }

        return nil
    }

    /**
     Trims a string to a specific length, optionally adding an
     ellipsis ("...") to the end.
     - Parameter to: The length to trim the string to.
     - Parameter addEllipsis: Whether to add "..." to the end
     - Returns: The truncated string.
     */
    func truncate(to length: Int, addEllipsis: Bool = false) -> String  {
        if length > count { return self }

        let trimmed = self[0 ..< length]

        if addEllipsis {
            return "\(trimmed)..."
        } else {
            return trimmed
        }
    }

    /**
     Ensures a string starts with a given prefix.
     Parameter prefix: The prefix to ensure.
     */
    func withPrefix(_ prefix: String) -> String {
        if self.hasPrefix(prefix) { return self }
        return "\(prefix)\(self)"
    }

    /**
     Ensures a string ends with a given suffix.
     Parameter suffix: The suffix to ensure.
     */
    func withSuffix(_ suffix: String) -> String {
        if self.hasSuffix(suffix) { return self }
        return "\(self)\(suffix)"
    }
}

extension UIApplication {
    /**
     Reads the app version key from your Info.plist
     */
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    /**
     Returns the `URL` to your app's documents directory.
     */
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    /**
     Returns the root view controller for the whole application, if there is one.
     */
    static var rootViewController: UIViewController? {
        guard let window = UIApplication.shared.keyWindow else { return nil }
        return window.rootViewController
    }
}

extension UIColor {
    /**
     Calculates the best approximate gray for this color.
     */
    var grayscale: UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // human eyes see colors at different brightnesses; this weighting mechanism reflects that
            return UIColor(white: (0.299 * red) + (0.587 * green) + (0.114 * blue), alpha: alpha)
        } else {
            return self
        }
    }

    /**
     Creates a UIColor from an RGBA hex value, e.g #FFE700FF
     - Parameter hexString: The hexadecimal string to parse, starting with #.
     s*/
    convenience init?(hexString: String) {
        let r, g, b, a: CGFloat

        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }

    /**
     Performs a linear interpolation from one color to another by a weighting factor you specify
     - Parameter to: The color to interpolate towards
     - Parameter amount: The weighting factor, from 0 to 1.
     - Returns: The interpolated color
     */
    func lerp(to: UIColor, amount: CGFloat) -> UIColor {
        var selfR: CGFloat = 0
        var selfG: CGFloat = 0
        var selfB: CGFloat = 0
        var selfA: CGFloat = 0

        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0

        guard self.getRed(&selfR, green: &selfG, blue: &selfB, alpha: &selfA) else { return self }
        guard to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA) else { return self }

        return UIColor(
            red: selfR.lerp(to: toR, amount: amount),
            green: selfG.lerp(to: toG, amount: amount),
            blue: selfB.lerp(to: toB, amount: amount),
            alpha: selfA.lerp(to: toA, amount: amount)
        )
    }

    /**
     Returns a UIColor with alpha 1 and random R, G, and B values.
     - Returns: A random UIColor.
     */
    static func random(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: CGFloat.random(), green: CGFloat.random(), blue: CGFloat.random(), alpha: alpha)
    }
}

extension UIDevice {
    /**
     Returns true if this device is an iPad.
     */
    static var isiPad: Bool {
        return current.userInterfaceIdiom == .pad
    }

    /**
     Returns true if this device has low-power mode enabled.
     */
    static var isLowPowerModeEnabled: Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /**
     Returns the country code for this device, e.g. US for the United States.
     */
    static var countryCode: String? {
        return (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String
    }

    /**
     Makes the device vibrate if available.
     */
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    /**
     Enables or disables the torch.
     - Parameter on: Whether to enable or disable the torch.
     - Returns: Boolean true if the torch was adjusted successfully, or false otherwise.
     */
    static func setTorch(on: Bool) -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()

                if on {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }

                device.unlockForConfiguration()
                return true
            } catch {
                print("Torch could not be used")
                return false
            }
        } else {
            print("Torch is not available")
            return false
        }
    }
}

extension UIGestureRecognizer {
    /**
     Cancels a gesture recognizer that is currently in progress by disabling then re-enabling it.
     */
    func cancel() {
        self.isEnabled = false
        self.isEnabled = true
    }
}

extension UIImage {
    enum Filter {
        case grayscale
        case sepia
        case blur(amount: CGFloat)
        case vignette(amount: CGFloat)
    }

    /**
     The height of this image
     */
    var height: CGFloat {
        return size.height
    }

    /**
     The width of this image
     */
    var width: CGFloat {
        return size.width
    }

    /**
     Creates a placeholder image from a size and color, either using
     device-relative sizes (retina, retina HD, etc; the default), or
     using absolute sizes, where 512 is 512 on all devices.
     - Paramater size: The size to create the placeholder
     - Parameter color: The fill color to use for the image
     */
    convenience init(size: CGSize, color: UIColor, absoluteSizes: Bool = false) {
        let rect = CGRect(origin: .zero, size: size)

        let format = UIGraphicsImageRendererFormat()

        if absoluteSizes == true {
            format.scale = 1
        }

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            color.set()
            ctx.fill(rect)
        }

        self.init(cgImage: img.cgImage!)
    }

    /**
     Creates a new image by applying a Core Image filter to
     an existing image.
     - Parameter filter: The Core Image filter to apply
     - Returns: The filtered UIImage
     */
    func applying(filter: UIImage.Filter) -> UIImage {
        let context = CIContext()
        let currentFilter: CIFilter

        switch filter {
        case .blur(let amount):
            currentFilter = CIFilter(name: "CIGaussianBlur")!
            currentFilter.setValue(amount, forKey: kCIInputRadiusKey)
        case .grayscale:
            currentFilter = CIFilter(name: "CIPhotoEffectNoir")!
        case .sepia:
            currentFilter = CIFilter(name: "CISepiaTone")!
        case .vignette(let amount):
            currentFilter = CIFilter(name: "CIVignette")!
            currentFilter.setValue(amount, forKey: kCIInputIntensityKey)
        }

        let beginImage = CIImage(image: self)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            return UIImage(cgImage: cgimg)
        } else {
            return self
        }
    }
}

extension UIImageView {
    /**
     Returns a rect that represents the size of the image inside this image view
     when rendered using .scaleAspectFit content mode.
     */
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.width > 0 && image.height > 0 else { return bounds }

        let scale: CGFloat
        if image.width > image.height {
            scale = bounds.width / image.width
        } else {
            scale = bounds.height / image.height
        }

        let size = CGSize(width: image.width * scale, height: image.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

extension UIView {
    /**
     Retains an array of subviews of all subviews inside this view, including itself
     and recursively all grandchildren, great-grandchildren, and so on.
     - Returns: An array of UIView subviews.
     */
    var allSubviews: [UIView] {
        var array = [self]

        for subview in self.subviews {
            array.append(contentsOf: subview.allSubviews)
        }

        return array
    }

    /**
     Adjusts the border color of the underlying CALayer.
     */
    var borderColor: UIColor {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor.black
            }
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }

    /**
     Adjusts the border width of the underlying CALayer.
     */
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    /**
     Adjusts the corner radius of the underlying CALayer.
     */
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            if newValue > 1 {
                clipsToBounds = true
            }

            layer.cornerRadius = newValue
        }
    }

    /**
     Adjusts the masked corners of the underlying CALayer.
     */
    var maskedCorners: CACornerMask {
        get {
            return layer.maskedCorners
        }
        set {
            layer.maskedCorners = newValue
        }
    }

    /**
     Reads or writes this view's rotation transform. If you're adjusting
     the value, this is *on top of* any transform already there.
     */
    var rotation: CGFloat {
        get {
            return transform.rotation
        }
        set {
            transform = transform.rotated(by: newValue)
        }
    }

    /**
     Reads or writes this view's scale transform. If you're adjusting
     the value, this is *on top of* any transform already there.
     */
    var scale: CGFloat {
        get {
            return transform.scale
        }
        set {
            transform = transform.scaledBy(x: newValue, y: newValue)
        }
    }

    /**
     Reads or writes this view's translation transform. If you're adjusting
     the value, this is *on top of* any transform already there.
     */
    var translation: CGPoint {
        get {
            return transform.translation
        }
        set {
            transform = transform.translatedBy(x: newValue.x, y: newValue.y)
        }
    }

    /**
     Adds multiple subviews simultaneously.
     - Parameter subviews: One or more views to add.
     */
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach { addSubview($0) }
    }

    /**
     Finds the first responder at or below this view.
     - Returns: The first responder subview, or nil if it wasn't found.
     */
    func findFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }

        for subView in self.subviews {
            if let vw = subView.findFirstResponder() {
                return vw
            }
        }

        return nil
    }

    /**
     Attempts to find the first view controller responsible for a view,
     or nil if there isn't one.
     - Returns: The UIViewController responsible for this view, or nil.
     */
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }

    /**
     Creates Auto Layout constraints that pin this view to the top, bottom, leading, and trailing edges of another
     - Parameter to: The view to pin to.
     */
    func pinEdges(to other: UIView) {
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
    }

    /**
     Removes all subviews from this view.
     */
    func removeSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

    /**
     Renders this view to a UIImage
     - Returns: A UIImage containing the rendered view
     */
    func renderToImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        return renderer.image { ctx in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
    }
}

extension UIViewController {
    /**
     Present a simple alert to the user with an OK button to dismiss.
     - Parameter title: The title of the alert controller
     - Parameter message: The message for the alert controller
     - Parameter dismissTitle: The title of the dismiss button; defaults to "OK"
     */
    func alert(title: String? = nil, message: String? = nil, dismissTitle: String? = "OK") {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: dismissTitle, style: .default, handler: nil))
        present(ac, animated: true)
    }
}

extension URL {
    /**
     Create new URLs by appending strings
     - Parameter lhs: The base URL to use
     - Parameter rhs: The string to append
     - Returns: A new URL combining the two
     */
    static func +(lhs: URL, rhs: String) -> URL {
        return lhs.appendingPathComponent(rhs)
    }

    static func +=(lhs: inout URL, rhs: String) {
        lhs.appendPathComponent(rhs)
    }
}
