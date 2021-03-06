public protocol CoproductType {
	associatedtype LeftType
	associatedtype RightType

	func fold<T>(onLeft: @escaping (LeftType) -> T, onRight: @escaping (RightType) -> T) -> T
}

public enum Coproduct<A,B>: CoproductType {
	case left(A)
	case right(B)

	public func fold<T>(onLeft: @escaping (A) -> T, onRight: @escaping (B) -> T) -> T {
		switch self {
		case .left(let a):
			return onLeft(a)
		case .right(let b):
			return onRight(b)
		}
	}
}

// MARK: - Equatable

extension CoproductType where LeftType: Equatable, RightType: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.fold(
			onLeft: { left in
				rhs.fold(
					onLeft: { left == $0 },
					onRight: fconstant(false))
		},
			onRight: { right in
				rhs.fold(
					onLeft: fconstant(false),
					onRight: { right == $0 })
		})
	}
}

// MARK: - Projections

extension CoproductType {
	public var toCoproduct: Coproduct<LeftType,RightType> {
		return fold(onLeft: Coproduct<LeftType,RightType>.left, onRight: Coproduct<LeftType,RightType>.right)
	}

	public var tryLeft: LeftType? {
		return fold(onLeft: fidentity, onRight: { _ in nil })
	}

	public var tryRight: RightType? {
		return fold(onLeft: { _ in nil }, onRight: fidentity)
	}

	public func foldToLeft(_ transform: @escaping (RightType) -> LeftType) -> LeftType {
		return fold(onLeft: fidentity, onRight: transform)
	}

	public func foldToRight(_ transform: @escaping (LeftType) -> RightType) -> RightType {
		return fold(onLeft: transform, onRight: fidentity)
	}
}

extension CoproductType where LeftType == RightType {
	public var merged: LeftType {
		return fold(onLeft: fidentity, onRight: fidentity)
	}
}

// MARK: - Functor

extension CoproductType {
	public func bimap<T,U>(onLeft: @escaping (LeftType) -> T, onRight: @escaping (RightType) -> U) -> Coproduct<T,U> {
		return fold(
			onLeft: { Coproduct<T,U>.left(onLeft($0)) },
			onRight: { Coproduct<T,U>.right(onRight($0)) })
	}

	public func mapLeft<T>(_ transform: @escaping (LeftType) -> T) -> Coproduct<T,RightType> {
		return fold(
			onLeft: { Coproduct<T,RightType>.left(transform($0)) },
			onRight: { Coproduct<T,RightType>.right($0) })
	}

	public func mapRight<U>(_ transform: @escaping (RightType) -> U) -> Coproduct<LeftType,U> {
		return fold(
			onLeft: { Coproduct<LeftType,U>.left($0) },
			onRight: { Coproduct<LeftType,U>.right(transform($0)) })
	}
}
