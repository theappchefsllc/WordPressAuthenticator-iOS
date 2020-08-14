import UIKit


/// SignupMagicLinkViewController: step two in the signup flow.
/// This VC prompts the user to open their email app to look for the magic link we sent.
///
final class SignupMagicLinkViewController: LoginViewController {

    // MARK: Properties

    @IBOutlet private weak var tableView: UITableView!
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComSignupMagicLink
        }
    }

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        // TODO: add the action once the button is tapped.
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        validationCheck()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.signUpTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
    }

    /// Some last-minute gatekeeping.
    ///
    func validationCheck() {
        let email = loginFields.username
        // We want to fail fast if a dev has bypassed the email validation in the email login & signup view.
        assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Override the title on 'submit' button
    ///
    override func localizePrimaryButton() {
        submitButton?.setTitle(WordPressAuthenticator.shared.displayStrings.openMailButtonTitle, for: .normal)
    }
}


// MARK: - UITableViewDataSource
extension SignupMagicLinkViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}


// MARK: - Private Methods
private extension SignupMagicLinkViewController {
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.persona, .instructions, .checkSpam]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell where row == .persona:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextLabelTableViewCell where row == .checkSpam:
            configureCheckSpamLabel(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username)
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.openMailSignupInstructions, style: .body)
    }

    /// Configure the "Check spam" cell.
    ///
    func configureCheckSpamLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.checkSpamInstructions, style: .body)
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case persona
        case instructions
        case checkSpam
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .persona:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions, .checkSpam, .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}
