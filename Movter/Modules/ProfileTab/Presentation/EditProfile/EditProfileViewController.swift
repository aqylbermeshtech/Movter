//
//  EditProfileViewController.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//
import UIKit

@MainActor
final class EditProfileViewController: UIViewController {

    var onSave: (() -> Void)?

    private let viewModel: EditProfileViewModel
    private var task: Task<Void, Never>?

    // MARK: - UI Components

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let avatarHintLabel: UILabel = {
        let label = UILabel()
        label.text = "Your avatar is generated from your name"
        label.font = .footnote
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let nameFieldLabel: UILabel = {
        let label = UILabel()
        label.text = "DISPLAY NAME"
        label.font = .fieldLabel
        label.textColor = .textSecondary
        return label
    }()

    private lazy var nameTextField: UITextField = {
        let field = UITextField()
        field.font = .movter(size: 17, weight: .regular)
        field.textColor = .textPrimary
        field.backgroundColor = .surface
        field.layer.cornerRadius = 10
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.attributedPlaceholder = NSAttributedString(
            string: "Your name",
            attributes: [.foregroundColor: UIColor.textSecondary]
        )
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        field.rightViewMode = .unlessEditing
        field.delegate = self
        field.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let emailFieldLabel: UILabel = {
        let label = UILabel()
        label.text = "EMAIL"
        label.font = .fieldLabel
        label.textColor = .textSecondary
        return label
    }()

    private let emailValueLabel: UILabel = {
        let label = UILabel()
        label.font = .movter(size: 17, weight: .regular)
        label.textColor = .textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let emailHintLabel: UILabel = {
        let label = UILabel()
        label.text = "Your email is tied to your sign-in and can't be changed here."
        label.font = .footnote
        label.textColor = .textSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Save Changes"
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .onAccent
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initialization

    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(onSave: (() -> Void)? = nil) {
        let authDataSource = FirebaseAuthProfileDataSource()
        let repository = DefaultProfileRepository(dataSource: authDataSource)
        let getUseCase = DefaultGetProfileUseCase(repository: repository)
        let updateUseCase = DefaultUpdateProfileUseCase(repository: repository)
        let viewModel = EditProfileViewModel(
            getProfileUseCase: getUseCase,
            updateProfileUseCase: updateUseCase
        )
        self.init(viewModel: viewModel)
        self.onSave = onSave
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        task?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        title = "Edit Profile"

        setupUI()
        bindViewModel()
        loadData()

        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        )
    }

    // MARK: - Setup UI

    private func setupUI() {
        let nameStack = UIStackView(arrangedSubviews: [nameFieldLabel, nameTextField])
        nameStack.axis = .vertical
        nameStack.spacing = 8

        let emailStack = UIStackView(arrangedSubviews: [emailFieldLabel, emailValueLabel, emailHintLabel])
        emailStack.axis = .vertical
        emailStack.spacing = 6
        emailStack.setCustomSpacing(10, after: emailValueLabel)

        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarImageView)

        let stack = UIStackView(arrangedSubviews: [
            avatarContainer, avatarHintLabel, nameStack, emailStack, saveButton
        ])
        stack.axis = .vertical
        stack.spacing = 28
        stack.alignment = .fill
        stack.setCustomSpacing(12, after: avatarContainer)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),

            nameTextField.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] in
            self?.render()
        }
    }

    private func loadData() {
        task?.cancel()
        task = Task { [weak self, viewModel] in
            await viewModel.loadProfile()
            guard let self else { return }
            self.nameTextField.text = viewModel.currentName
            self.emailValueLabel.text = viewModel.email.isEmpty ? "—" : viewModel.email
            self.render()
        }
    }

    private func render() {
        refreshAvatar()
        updateSaveButtonState()
    }

    private func refreshAvatar() {
        avatarImageView.image = InitialsAvatar.image(
            name: viewModel.trimmedName,
            email: viewModel.email,
            size: 200
        )
    }

    private func updateSaveButtonState() {
        let isEnabled = viewModel.canSave
        saveButton.isEnabled = isEnabled
        saveButton.configuration?.showsActivityIndicator = viewModel.isSaving
        saveButton.configuration?.title = viewModel.isSaving ? nil : "Save Changes"
        saveButton.configuration?.baseBackgroundColor = isEnabled ? .accent : .surface
        saveButton.configuration?.baseForegroundColor = isEnabled ? .onAccent : .textSecondary
        nameTextField.isEnabled = !viewModel.isSaving
    }

    // MARK: - Actions

    @objc private func nameChanged() {
        viewModel.updateCurrentName(nameTextField.text ?? "")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        task?.cancel()
        task = Task { [weak self, viewModel] in
            do {
                try await viewModel.save()
                self?.onSave?()
                self?.navigationController?.popViewController(animated: true)
            } catch {
                self?.presentAlert(title: "Couldn't save", message: error.localizedDescription)
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension EditProfileViewController: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: range, with: string).count <= EditProfileViewModel.maxNameLength
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
