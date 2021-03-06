//
//  EarthquakeDetailBinder.swift
//  RxEarthquake
//
//  Created by Daniel Tartaglia on 5/16/20.
//	Copyright © 2020 Daniel Tartaglia. MIT License.
//

import CoreLocation
import MapKit
import RxCocoa
import RxSwift
import UIKit

func createEarthquakeDetail(earthquake: Observable<Earthquake>, userLocation: Observable<CLLocation>) -> UIViewController {
	let controller = createRaw()
	controller.bind(earthquake: earthquake, userLocation: userLocation)
	return controller
}

struct ShareInfo {
	let items: [Any]
	let barButtonItem: Any
}

private extension EarthquakeDetailViewController {
	func bind(earthquake: Observable<Earthquake>, userLocation: Observable<CLLocation>) {
		loadViewIfNeeded()

		earthquake
			.map { $0.coordinate }
			.distinctUntilChanged { $0.latitude == $1.latitude && $0.longitude == $1.longitude }
			.bind { [mapView] coordinate in
				let span = MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
				mapView?.region = MKCoordinateRegion(center: coordinate, span: span)

				let annotation = MKPointAnnotation()
				annotation.coordinate = coordinate
				mapView?.removeAnnotations(mapView?.annotations ?? [])
				mapView?.addAnnotation(annotation)
			}
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.name(earthquake: earthquake)
			.bind(to: nameLabel.rx.text)
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.magnitude(earthquake: earthquake)
			.bind(to: magnitudeLabel.rx.text)
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.depth(earthquake: earthquake)
			.bind(to: depthLabel.rx.text)
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.time(earthquake: earthquake)
			.bind(to: timeLabel.rx.text)
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.distance(earthquake: earthquake, userLocation: userLocation)
			.bind(to: distanceLabel.rx.text)
			.disposed(by: disposeBag)

		tableView.rx.itemSelected
			.bind { [weak self] in
				self?.tableView.deselectRow(at: $0, animated: true)
			}
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.presentSafari(
			itemSelected: tableView.rx.itemSelected.asObservable(),
			earthquake: earthquake
		)
			.bind { [weak self] url in
				self?.presentSafari(url: url, animated: true)
			}
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.presentAlert(
			itemSelected: tableView.rx.itemSelected.asObservable(),
			earthquake: earthquake
		)
			.bind { [weak self] title, message in
				self?.presentAlert(title: title, message: message, animated: true)
			}
			.disposed(by: disposeBag)

		EarthquakeDetailLogic.presentShare(
			shareTrigger: shareButton.rx.tap.asObservable(),
			earthquake: earthquake,
			shareButton: { [weak self] in self?.shareButton }
		)
			.bind { [weak self] shareInfo in
				self?.presentActivity(shareInfo: shareInfo, animated: true)
			}
			.disposed(by: disposeBag)
	}
}

extension SharedSequence {
	func compactMap<T>(_ transform: @escaping (Element)-> T?) -> SharedSequence<SharingStrategy, T> {
		return map { transform($0) }.filter { $0 != nil }.map { $0! }
	}
}

private func createRaw() -> EarthquakeDetailViewController {
	let storyboard = UIStoryboard(name: "EarthquakeDetail", bundle: nil)
	return storyboard.instantiateInitialViewController() as! EarthquakeDetailViewController
}
