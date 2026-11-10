import AuthenticationServices
import Observation

@MainActor
@Observable
final class AuthStore {
    static let localHandle = "you"

    private(set) var userID: String?
    private(set) var displayName: String?
    private(set) var handle: String
    var signInError: String?

    var isSignedIn: Bool { userID != nil }

    private let defaults = UserDefaults.standard

    init() {
        userID = defaults.string(forKey: Keys.userID)
        displayName = defaults.string(forKey: Keys.displayName)
        handle = defaults.string(forKey: Keys.handle) ?? Self.localHandle
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            store(credential)
        case .failure(let error):
            guard (error as? ASAuthorizationError)?.code != .canceled else { return }
            signInError = "サインインできませんでした。通信状況を確認して、もう一度お試しください。"
        }
    }

    /// Apple IDの連携が解除されていないかを起動時に確かめる。
    func refreshCredentialState() async {
        guard let userID else { return }

        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
        if state == .revoked || state == .notFound {
            signOut()
        }
    }

    func signOut() {
        userID = nil
        displayName = nil
        handle = Self.localHandle
        defaults.removeObject(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.displayName)
        defaults.removeObject(forKey: Keys.handle)
    }

    private func store(_ credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        defaults.set(credential.user, forKey: Keys.userID)

        // 氏名は初回サインインのときしか渡されないため、取れたときだけ保存する。
        if let name = credential.fullName, let given = name.givenName {
            let full = [name.familyName, given].compactMap { $0 }.joined(separator: " ")
            displayName = full
            defaults.set(full, forKey: Keys.displayName)
        }

        handle = Self.makeHandle(userID: credential.user, displayName: displayName)
        defaults.set(handle, forKey: Keys.handle)
    }

    /// Apple IDのユーザー識別子から、表示用の安定したハンドルを作る。
    private static func makeHandle(userID: String, displayName: String?) -> String {
        if let displayName, !displayName.isEmpty {
            return displayName.replacingOccurrences(of: " ", with: "_")
        }

        let suffix = userID.filter(\.isLetter).suffix(6).lowercased()
        return suffix.isEmpty ? localHandle : "user_\(suffix)"
    }

    private enum Keys {
        static let userID = "auth.userID"
        static let displayName = "auth.displayName"
        static let handle = "auth.handle"
    }
}
