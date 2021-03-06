//
//  RxCLLocationManagerDelegateProxy.swift
//  RxExample
//
//  Created by Carlos García on 8/7/15.
//  Copyright © 2015 Krunoslav Zaher. MIT License.
//

import CoreLocation
import RxSwift
import RxCocoa

extension CLLocationManager: HasDelegate {
	public typealias Delegate = CLLocationManagerDelegate
}

public final class RxCLLocationManagerDelegateProxy
	: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>
	, DelegateProxyType
, CLLocationManagerDelegate {

	public init(locationManager: CLLocationManager) {
		super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
	}

	public static func registerKnownImplementations() {
		self.register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
	}

	internal let didUpdateLocationsSubject = PublishSubject<[CLLocation]>()
	internal let didFailWithErrorSubject = PublishSubject<Error>()

	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		_forwardToDelegate?.locationManager?(manager, didUpdateLocations: locations)
		didUpdateLocationsSubject.onNext(locations)
	}

	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		_forwardToDelegate?.locationManager?(manager, didFailWithError: error)
		didFailWithErrorSubject.onNext(error)
	}

	deinit {
		self.didUpdateLocationsSubject.on(.completed)
		self.didFailWithErrorSubject.on(.completed)
	}
}
