//
//  NicknameEditorVC.swift
//  Runnect-iOS
//
//  Created by 몽이 누나 on 2023/01/05.
//

import UIKit

import SnapKit
import Then
import Moya

protocol NicknameEditorVCDelegate: AnyObject {
    func nicknameEditDidSuccess()
}

final class NicknameEditorVC: UIViewController {
    
    // MARK: - Properties
    
    private var userProvider = Providers.userProvider
    
    weak var delegate: NicknameEditorVCDelegate?
    
    private let nicknameMaxLength: Int = 7
    
    var currentNickname = String()
    
    // MARK: - UI Components
    
    private lazy var navibar = CustomNavigationBar(self, type: .titleWithLeftButton).setTitle("닉네임 수정")
    
    private lazy var nickNameTextField = UITextField().then {
        $0.resignFirstResponder()
        $0.text = self.currentNickname
        $0.textColor = .g1
        $0.font = .h5
        $0.textAlignment = .center
        $0.attributedPlaceholder = NSAttributedString(
            string: "닉네임을 입력하세요",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.g2, NSAttributedString.Key.font: UIFont.h5]
        )
        $0.keyboardType = .webSearch
    }
    
    private let personImageView = UIImageView().then {
        $0.image = ImageLiterals.imgPerson
    }
    
    private let nickNameContainer = UIView().then {
        $0.layer.cornerRadius = 5
        $0.layer.borderColor = UIColor.m1.cgColor
        $0.layer.borderWidth = 1
    }
    
    private lazy var finishNickNameLabel = UILabel().then {
        $0.text = "완료"
        $0.font = .h4
        $0.textColor = .m1
        let tap = UITapGestureRecognizer(target: self, action: #selector(finishEditNickname))
        $0.isUserInteractionEnabled = true
        $0.addGestureRecognizer(tap)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nickNameTextField.delegate = self
        isTextExist(textField: nickNameTextField)
        setUI()
        setLayout()
        showKeyboard()
        setAddTarget()
    }
}

// MARK: - Method

extension NicknameEditorVC {
    func setData(nickname: String) {
        self.currentNickname = nickname
    }
    
    private func setAddTarget() {
        nickNameTextField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
    }
    
    func showKeyboard() {
        self.nickNameTextField.becomeFirstResponder()
    }
    
    func isTextExist(textField: UITextField) {
        if textField.text == nil {
            textField.enablesReturnKeyAutomatically = false
        } else {
            textField.enablesReturnKeyAutomatically = true
        }
    }
}

// MARK: - @objc Function

extension NicknameEditorVC {
    @objc private func popToPreviousVC() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func textFieldTextDidChange() {
        guard let text = nickNameTextField.text else { return }
        
        if text.count > nicknameMaxLength {
            let index = text.index(text.startIndex, offsetBy: nicknameMaxLength)
            let newString = text[text.startIndex..<index]
            self.nickNameTextField.text = String(newString)
        }
    }
    
    @objc private func finishEditNickname() {
        guard let nickname = nickNameTextField.text else { return }
        
        self.updateUserNickname(nickname: nickname)
    }
}

// MARK: - Layout Helpers

extension NicknameEditorVC {
    private func setUI() {
        view.backgroundColor = .w1
    }
    
    private func setLayout() {
        view.addSubviews(navibar, finishNickNameLabel, personImageView, nickNameContainer)
        
        navibar.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
        
        finishNickNameLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(23)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
        }
        
        personImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(96)
            $0.top.equalTo(navibar.snp.bottom).offset(98)
        }
        
        nickNameContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(44)
            $0.top.equalTo(personImageView.snp.bottom).offset(51)
        }
        
        nickNameContainer.addSubview(nickNameTextField)
        
        nickNameTextField.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
    }
}

// MARK: - UITextFieldDelegate

extension NicknameEditorVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nickNameTextField {
            finishEditNickname()
        }
        return true
    }
}

// MARK: - Network

extension NicknameEditorVC {
    func updateUserNickname(nickname: String) {
        
        guard nickname != self.currentNickname else {
            print("💪 닉네임 변경 시도 전에 현재 닉네임과 동일한지 검사 성공 처리")
//            self.delegate?.nicknameEditDidSuccess()
//            닉네임 같은데 굳이 또 서버 요청을 할 필요가 있나?
            self.navigationController?.popViewController(animated: false)
            return
        }
        
        LoadingIndicator.showLoading()
        userProvider.request(.updateUserNickname(nickname: nickname)) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    self.delegate?.nicknameEditDidSuccess()
                    self.navigationController?.popViewController(animated: false)
                } else {
                    self.showNetworkFailureToast()
                }
            case .failure(let error):
                self.showToast(message: "중복된 닉네임입니다.")
                print(error.localizedDescription)
            }
        }
    }
}
