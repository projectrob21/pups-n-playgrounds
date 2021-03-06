//
//  CreateAccountView.swift
//  PupsAndPlaygrounds
//
//  Created by William Robinson on 11/21/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit

class CreateAccountView: UIView {
  
  // MARK: Properties
  lazy var scrollView = UIScrollView()
  lazy var pageControl = UIPageControl()
  lazy var cancelButton = UIButton()
  lazy var stackView = UIStackView()
  
  lazy var firstNameField = UITextField()
  lazy var lastNameField = UITextField()
  lazy var emailField = UITextField()
  lazy var passwordField = UITextField()
  
  // MARK: Initialization
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  convenience init() { self.init(frame: CGRect.zero)
    configure()
    constrain()
  }
  
  // MARK: Setup
  private func configure() {
    layer.addSublayer(CAGradientLayer([UIColor.themeMarine, UIColor.themeTeal, UIColor.themeGrass]))
    
    scrollView.isPagingEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 4, height: UIScreen.main.bounds.height)
    
    pageControl.numberOfPages = 4
    
    cancelButton.setImage(#imageLiteral(resourceName: "Close"), for: .normal)
    cancelButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    stackView.distribution = .fillEqually
    stackView.alignment = .center
    stackView.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
    
    firstNameField.placeholder = "First name"
    firstNameField.font = UIFont.themeOversizeThin
    firstNameField.textColor = UIColor.white
    firstNameField.textAlignment = .center
    
    lastNameField.placeholder = "Last name"
    lastNameField.font = UIFont.themeOversizeThin
    lastNameField.textColor = UIColor.white
    lastNameField.textAlignment = .center
    
    emailField.placeholder = "Email"
    emailField.font = UIFont.themeOversizeThin
    emailField.textColor = UIColor.white
    emailField.textAlignment = .center
    
    passwordField.placeholder = "Password"
    passwordField.font = UIFont.themeOversizeThin
    passwordField.textColor = UIColor.white
    passwordField.textAlignment = .center
  }
  
  private func constrain() {
    addSubview(scrollView)
    scrollView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    addSubview(pageControl)
    pageControl.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.centerY.equalToSuperview().multipliedBy(1.8)
    }
    
    addSubview(cancelButton)
    cancelButton.snp.makeConstraints {
      $0.top.equalToSuperview().offset(30)
      $0.trailing.equalToSuperview().offset(-10)
    }
    
    scrollView.addSubview(stackView)
    stackView.addArrangedSubview(firstNameField)
    stackView.addArrangedSubview(lastNameField)
    stackView.addArrangedSubview(emailField)
    stackView.addArrangedSubview(passwordField)
  }
}
