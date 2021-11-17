//
//  SettingsCell.swift
//  SanTa
//
//  Created by CHANGMIN OH on 2021/11/01.
//

import UIKit

protocol ToggleOptionCellDelegate: AnyObject {
    func toggleOptionCellSwitchChanged(_ cell: ToggleOptionCell, title: String, switchOn: Bool)
}

class ToggleOptionCell: UITableViewCell {
    
    static let identifier = "ToggleOptionCell"
    
    weak var delegate: ToggleOptionCellDelegate?
    
    private var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.init(rawValue: 800), for: .horizontal)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private var controlSwitch: UISwitch = {
        let controlSwitch = UISwitch()
        controlSwitch.translatesAutoresizingMaskIntoConstraints = false
        controlSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        controlSwitch.onTintColor = UIColor(named: "SantaColor")
        controlSwitch.setContentCompressionResistancePriority(.init(rawValue: 1000), for: .horizontal)
        return controlSwitch
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.title, self.controlSwitch])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.configureView()
        self.configureStackViewAccessibility()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onClickSwitch(sender: UISwitch) {
        guard let title = self.title.text else { return }
        self.delegate?.toggleOptionCellSwitchChanged(self,
                                                     title: title,
                                                     switchOn: self.controlSwitch.isOn)
    }
    
    private func configureView() {
        self.contentView.addSubview(self.stackView)
        let locationConstrain = [
            self.stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15),
            self.stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -15),
            self.stackView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 30),
            self.stackView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -30),
        ]
        NSLayoutConstraint.activate(locationConstrain)
    }
    
    func update(option: ToggleOption) {
        self.title.text = option.text
        self.controlSwitch.isOn = option.toggle
    }
}

// MARK: - Accessibility

extension ToggleOptionCell {
    private func configureStackViewAccessibility() {
        self.stackView.axis =
        self.traitCollection.preferredContentSizeCategory < .accessibilityLarge ?
            .horizontal : .vertical
    }
}
