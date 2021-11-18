//
//  ViewController.swift
//  SwipeView
//
//  Created by Jiwon Yoon on 2021/11/10.
//

import UIKit
import MapKit

class ResultDetailViewController: UIViewController {
    
    weak var coordinator: ResultDetailViewCoordinator?
    
    private var viewModel: ResultDetailViewModel?
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.mapType = .mutedStandard
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    private var informationView: ResultDetailSmallerInfoView = {
        let view = ResultDetailSmallerInfoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var backButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "chevron.backward"), for: .normal)
        button.setPreferredSymbolConfiguration(.init(pointSize: 25), forImageIn: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        return button
    }()
    
    private var changeButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "ellipsis.circle"), for: .normal)
        button.setPreferredSymbolConfiguration(.init(pointSize: 25), forImageIn: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    convenience init(viewModel: ResultDetailViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViews()
        self.viewModel?.recordDidFetch = { [weak self] in
            guard let data = self?.viewModel?.resultDetailData else { return }
            self?.informationView.configureLayout(
                distance: "\(data.distance.total)",
                time: "\(data.time.spent)",
                steps: "\(data.distance.steps)",
                maxAltitude: "\(data.altitude.highest)",
                minAltitude: "\(data.altitude.lowest)",
                averageSpeed: "0"
            )
        }
        viewModel?.setUp()
    }
    
    private func configureSmallerView() {
        
        print(informationView.bounds)
        self.informationView = ResultDetailSmallerInfoView(frame: self.informationView.bounds)
        print(view.subviews)
    }
    
    private func configureViews() {
        self.view.addSubview(self.mapView)
        self.view.addSubview(self.backButton)
        self.view.addSubview(self.changeButton)
        self.view.addSubview(self.informationView)
        NSLayoutConstraint.activate([
            self.mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mapView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.mapView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.view.frame.height * 0.25)
        ])
        NSLayoutConstraint.activate([
            self.backButton.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            self.backButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.backButton.widthAnchor.constraint(equalToConstant: 40),
            self.backButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        NSLayoutConstraint.activate([
            self.changeButton.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            self.changeButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.changeButton.widthAnchor.constraint(equalToConstant: 40),
            self.changeButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        NSLayoutConstraint.activate([
            self.informationView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.informationView.topAnchor.constraint(equalTo: self.mapView.bottomAnchor),
            self.informationView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.informationView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc func dismissViewController() {
        coordinator?.dismiss()
    }
}



extension ResultDetailViewController {
    private func registerRecognizers() {
        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(showSmallInfoView))
        swipeDownRecognizer.direction = .down
        self.informationView.addGestureRecognizer(swipeDownRecognizer)
        
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(showLargeInfoView))
        swipeUpRecognizer.direction = .up
        self.informationView.addGestureRecognizer(swipeUpRecognizer)
    }
}

extension ResultDetailViewController {
    @objc private func showLargeInfoView() {
        self.informationView.subviews.forEach { $0.removeFromSuperview() }
        let newY = self.view.bounds.height * 0.1
        let newHeight = self.view.bounds.height * 0.9
        self.mapView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.informationView.frame = CGRect(x: 0, y: newY, width: self.view.bounds.width, height: newHeight)
        }
//        self.informationView.addSubview(ResultDetailLargerInfoView(frame: self.informationView.bounds CGRect.zero))
    }
    
    @objc private func showSmallInfoView() {
        self.informationView.subviews.forEach { $0.removeFromSuperview() }
        let newY = self.view.bounds.height * 0.75
        let newHeight = self.view.bounds.height * 0.25
        self.mapView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.informationView.frame = CGRect(x: 0, y: newY, width: self.view.bounds.width, height: newHeight)
        }
//        self.informationView.addSubview(ResultDetailSmallerInfoView(frame: self.informationView.bounds CGRect.zero))
    }
}


