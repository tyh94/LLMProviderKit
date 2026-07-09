//
//  GigaChatTrust.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import Foundation
import MKVNetwork

/// Серверы GigaChat отдают TLS-сертификат, выпущенный корневым УЦ Минцифры
/// (Russian Trusted Root CA), которого нет в доверенном хранилище iOS.
/// Исключения `NSAppTransportSecurity` в Info.plist этого НЕ решают — они
/// ослабляют политику ATS, но не добавляют доверие к неизвестному корню.
///
/// Единственный способ — своя `URLSession` с делегатом, который добавляет
/// корень Минцифры в набор доверенных якорей при проверке цепочки сертификатов.
final class GigaChatServerTrustDelegate: NSObject, URLSessionDelegate {
    /// Хосты, для которых мы доверяем корню Минцифры.
    private static let trustedHosts: Set<String> = [
        "gigachat.devices.sberbank.ru",
        "ngw.devices.sberbank.ru"
    ]

    /// Сертификаты Минцифры (корень + промежуточный), загруженные из ресурсов пакета.
    private let anchors: [SecCertificate]
    private let logger: LLMLogger?

    init(logger: LLMLogger? = nil) {
        self.logger = logger
        self.anchors = ["russian_trusted_root_ca", "russian_trusted_sub_ca"]
            .compactMap { GigaChatServerTrustDelegate.loadCertificate(named: $0, logger: logger) }
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        let method = challenge.protectionSpace.authenticationMethod
        logger?.debug("GigaChatTrust challenge host=\(host) method=\(method) anchors=\(anchors.count)")

        guard
            method == NSURLAuthenticationMethodServerTrust,
            Self.trustedHosts.contains(host),
            let serverTrust = challenge.protectionSpace.serverTrust,
            !anchors.isEmpty
        else {
            // Не наш хост или нет сертификатов — стандартная системная проверка.
            logger?.debug("GigaChatTrust default handling for host=\(host)")
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Сервер GigaChat присылает только листовой сертификат, без промежуточного.
        // Поэтому собираем новую цепочку: серверные сертификаты + наши (root+sub) как кандидаты,
        // а корень Минцифры назначаем доверенным якорем.
        let serverCerts = (SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate]) ?? []
        let candidates = serverCerts + anchors
        let policy = SecPolicyCreateSSL(true, host as CFString)

        var rebuilt: SecTrust?
        let status = SecTrustCreateWithCertificates(candidates as CFArray, policy, &rebuilt)
        guard status == errSecSuccess, let rebuilt else {
            logger?.error("GigaChatTrust SecTrustCreateWithCertificates failed status=\(status)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        SecTrustSetAnchorCertificates(rebuilt, anchors as CFArray)
        SecTrustSetAnchorCertificatesOnly(rebuilt, false)

        var error: CFError?
        if SecTrustEvaluateWithError(rebuilt, &error) {
            logger?.debug("GigaChatTrust trust OK for host=\(host)")
            completionHandler(.useCredential, URLCredential(trust: rebuilt))
        } else {
            logger?.error("GigaChatTrust trust FAILED for host=\(host) error=\(String(describing: error))")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Загружает PEM-сертификат из ресурсов пакета и превращает его в `SecCertificate`.
    private static func loadCertificate(named name: String, logger: LLMLogger?) -> SecCertificate? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "pem") else {
            logger?.error("GigaChatTrust cert not found in bundle: \(name)")
            return nil
        }
        guard
            let pem = try? String(contentsOf: url, encoding: .utf8),
            let der = derData(fromPEM: pem),
            let cert = SecCertificateCreateWithData(nil, der as CFData)
        else {
            logger?.error("GigaChatTrust cert failed to parse: \(name)")
            return nil
        }
        return cert
    }

    /// Извлекает DER-данные из PEM-строки (убирает заголовок/футер и base64-декодирует).
    private static func derData(fromPEM pem: String) -> Data? {
        let base64 = pem
            .components(separatedBy: "-----BEGIN CERTIFICATE-----").last?
            .components(separatedBy: "-----END CERTIFICATE-----").first?
            .components(separatedBy: .whitespacesAndNewlines)
            .joined() ?? ""
        return Data(base64Encoded: base64)
    }
}

extension NetworkManager {
    /// Сетевой менеджер с доверием к корню Минцифры — для запросов к GigaChat.
    static func gigaChat(timeoutInterval: TimeInterval = 30.0, logger: LLMLogger? = nil) -> NetworkManager {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(
            configuration: configuration,
            delegate: GigaChatServerTrustDelegate(logger: logger),
            delegateQueue: nil
        )
        return NetworkManager(session: session, timeoutInterval: timeoutInterval)
    }
}
