import Foundation

#if canImport(ObjectiveC)
import ObjectiveC
#endif

#if canImport(ObjectiveC)
public typealias NSObjectOrAnyObject = NSObject
#else
public typealias NSObjectOrAnyObject = AnyObject
#endif
