import Foundation
import Combine

// Minimal Nostr transport conforming to Transport for offline sending
final class NostrTransport: Transport {
    weak var delegate: BitchatDelegate?
    weak var peerEventsDelegate: TransportPeerEventsDelegate?
    var peerSnapshotPublisher: AnyPublisher<[TransportPeerSnapshot], Never> {
        Just([]).eraseToAnyPublisher()
    }
    func currentPeerSnapshots() -> [TransportPeerSnapshot] { [] }

    // Provide BLE short peer ID for BitChat embedding
    var senderPeerID: String = ""

    // Throttle READ receipts to avoid relay rate limits
    private struct QueuedRead {
        let receipt: ReadReceipt
        let peerID: String
    }
    private var readQueue: [QueuedRead] = []
    private var isSendingReadAcks = false
    private let readAckInterval: TimeInterval = 0.35 // ~3 per second

    var myPeerID: String { senderPeerID }
    var myNickname: String { "" }
    func setNickname(_ nickname: String) { /* not used for Nostr */ }

    func startServices() { /* no-op */ }
    func stopServices() { /* no-op */ }
    func emergencyDisconnectAll() { /* no-op */ }

    func isPeerConnected(_ peerID: String) -> Bool { false }
    func peerNickname(peerID: String) -> String? { nil }
    func getPeerNicknames() -> [String : String] { [:] }

    func getFingerprint(for peerID: String) -> String? { nil }
    func getNoiseSessionState(for peerID: String) -> LazyHandshakeState { .none }
    func triggerHandshake(with peerID: String) { /* no-op */ }
    func getNoiseService() -> NoiseEncryptionService { NoiseEncryptionService() }
    
    func setMeshService(_ service: Transport?) {
        // Not needed for Nostr transport
    }

    // Public broadcast not supported over Nostr here
    func sendMessage(_ content: String, mentions: [String]) { /* no-op */ }

    func sendPrivateMessage(_ content: String, to peerID: String, recipientNickname: String, messageID: String) {
        Task { @MainActor in
            // Resolve favorite by full noise key or by short peerID fallback
            var recipientNostrPubkey: String?
            if let noiseKey = Data(hexString: peerID),
               let fav = FavoritesPersistenceService.shared.getFavoriteStatus(for: noiseKey) {
                recipientNostrPubkey = fav.peerNostrPublicKey
            }
            if recipientNostrPubkey == nil, peerID.count == 16 {
                recipientNostrPubkey = FavoritesPersistenceService.shared.getFavoriteStatus(forPeerID: peerID)?.peerNostrPublicKey
            }
            guard let recipientNpub = recipientNostrPubkey else { return }
            guard let senderIdentity = try? NostrIdentityBridge.getCurrentNostrIdentity() else { return }
            SecureLogger.log("NostrTransport: preparing PM to \(recipientNpub.prefix(16))… for peerID \(peerID.prefix(8))… id=\(messageID.prefix(8))…",
                            category: SecureLogger.session, level: .debug)
            // Convert recipient npub -> hex (x-only)
            let recipientHex: String
            do {
                let (hrp, data) = try Bech32.decode(recipientNpub)
                guard hrp == "npub" else {
                    SecureLogger.log("NostrTransport: recipient key not npub (hrp=\(hrp))", category: SecureLogger.session, level: .error)
                    return
                }
                recipientHex = data.hexEncodedString()
            } catch {
                SecureLogger.log("NostrTransport: failed to decode npub -> hex: \(error)", category: SecureLogger.session, level: .error)
                return
            }
            guard let embedded = NostrEmbeddedBitChat.encodePMForNostr(content: content, messageID: messageID, recipientPeerID: peerID, senderPeerID: senderPeerID) else {
                SecureLogger.log("NostrTransport: failed to embed PM packet", category: SecureLogger.session, level: .error)
                return
            }
            guard let event = try? NostrProtocol.createPrivateMessage(content: embedded, recipientPubkey: recipientHex, senderIdentity: senderIdentity) else {
                SecureLogger.log("NostrTransport: failed to build Nostr event for PM", category: SecureLogger.session, level: .error)
                return
            }
            SecureLogger.log("NostrTransport: sending PM giftWrap id=\(event.id.prefix(16))…",
                            category: SecureLogger.session, level: .debug)
            NostrRelayManager.shared.sendEvent(event)
        }
    }

    func sendReadReceipt(_ receipt: ReadReceipt, to peerID: String) {
        // Enqueue and process with throttling to avoid relay rate limits
        readQueue.append(QueuedRead(receipt: receipt, peerID: peerID))
        processReadQueueIfNeeded()
    }

    private func processReadQueueIfNeeded() {
        guard !isSendingReadAcks else { return }
        guard !readQueue.isEmpty else { return }
        isSendingReadAcks = true
        sendNextReadAck()
    }

    private func sendNextReadAck() {
        guard !readQueue.isEmpty else { isSendingReadAcks = false; return }
        let item = readQueue.removeFirst()
        Task { @MainActor in
            var recipientNostrPubkey: String?
            if let noiseKey = Data(hexString: item.peerID),
               let fav = FavoritesPersistenceService.shared.getFavoriteStatus(for: noiseKey) {
                recipientNostrPubkey = fav.peerNostrPublicKey
            }
            if recipientNostrPubkey == nil, item.peerID.count == 16 {
                recipientNostrPubkey = FavoritesPersistenceService.shared.getFavoriteStatus(forPeerID: item.peerID)?.peerNostrPublicKey
            }
            guard let recipientNpub = recipientNostrPubkey else { scheduleNextReadAck(); return }
            guard let senderIdentity = try? NostrIdentityBridge.getCurrentNostrIdentity() else { scheduleNextReadAck(); return }
            SecureLogger.log("NostrTransport: preparing READ ack for id=\(item.receipt.originalMessageID.prefix(8))… to \(recipientNpub.prefix(16))…",
                            category: SecureLogger.session, level: .debug)
            // Convert recipient npub -> hex
            let recipientHex: String
            do {
                let (hrp, data) = try Bech32.decode(recipientNpub)
                guard hrp == "npub" else { scheduleNextReadAck(); return }
                recipientHex = data.hexEncodedString()
            } catch { scheduleNextReadAck(); return }
            guard let ack = NostrEmbeddedBitChat.encodeAckForNostr(type: .readReceipt, messageID: item.receipt.originalMessageID, recipientPeerID: item.peerID, senderPeerID: senderPeerID) else {
                SecureLogger.log("NostrTransport: failed to embed READ ack", category: SecureLogger.session, level: .error)
                scheduleNextReadAck(); return
            }
            guard let event = try? NostrProtocol.createPrivateMessage(content: ack, recipientPubkey: recipientHex, senderIdentity: senderIdentity) else {
                SecureLogger.log("NostrTransport: failed to build Nostr event for READ ack", category: SecureLogger.session, level: .error)
                scheduleNextReadAck(); return
            }
            SecureLogger.log("NostrTransport: sending READ ack giftWrap id=\(event.id.prefix(16))…",
                            category: SecureLogger.session, level: .debug)
            NostrRelayManager.shared.sendEvent(event)
            scheduleNextReadAck()
        }
    }

    private func scheduleNextReadAck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + readAckInterval) { [weak self] in
            guard let self = self else { return }
            self.isSendingReadAcks = false
            self.processReadQueueIfNeeded()
        }
    }

    func sendFavoriteNotification(to peerID: String, isFavorite: Bool) {
        Task { @MainActor in
            var recipientNostrPubkey: String?
            if let noiseKey = Data(hexString: peerID),
               let fav = FavoritesPersistenceService.shared.getFavoriteStatus(for: noiseKey) {
                recipientNostrPubkey = fav.peerNostrPublicKey
            }
            if recipientNostrPubkey == nil, peerID.count == 16 {
                recipientNostrPubkey = FavoritesPersistenceService.shared.getFavoriteStatus(forPeerID: peerID)?.peerNostrPublicKey
            }
            guard let recipientNpub = recipientNostrPubkey else { return }
            guard let senderIdentity = try? NostrIdentityBridge.getCurrentNostrIdentity() else { return }
            let content = isFavorite ? "[FAVORITED]:\(senderIdentity.npub)" : "[UNFAVORITED]:\(senderIdentity.npub)"
            SecureLogger.log("NostrTransport: preparing FAVORITE(\(isFavorite)) to \(recipientNpub.prefix(16))…",
                            category: SecureLogger.session, level: .debug)
            // Convert recipient npub -> hex
            let recipientHex: String
            do {
                let (hrp, data) = try Bech32.decode(recipientNpub)
                guard hrp == "npub" else { return }
                recipientHex = data.hexEncodedString()
            } catch { return }
            guard let embedded = NostrEmbeddedBitChat.encodePMForNostr(content: content, messageID: UUID().uuidString, recipientPeerID: peerID, senderPeerID: senderPeerID) else {
                SecureLogger.log("NostrTransport: failed to embed favorite notification", category: SecureLogger.session, level: .error)
                return
            }
            guard let event = try? NostrProtocol.createPrivateMessage(content: embedded, recipientPubkey: recipientHex, senderIdentity: senderIdentity) else {
                SecureLogger.log("NostrTransport: failed to build Nostr event for favorite notification", category: SecureLogger.session, level: .error)
                return
            }
            SecureLogger.log("NostrTransport: sending favorite giftWrap id=\(event.id.prefix(16))…",
                            category: SecureLogger.session, level: .debug)
            NostrRelayManager.shared.sendEvent(event)
        }
    }

    func sendBroadcastAnnounce() { /* no-op for Nostr */ }
    func sendDeliveryAck(for messageID: String, to peerID: String) {
        Task { @MainActor in
            var recipientNostrPubkey: String?
            if let noiseKey = Data(hexString: peerID),
               let fav = FavoritesPersistenceService.shared.getFavoriteStatus(for: noiseKey) {
                recipientNostrPubkey = fav.peerNostrPublicKey
            }
            if recipientNostrPubkey == nil, peerID.count == 16 {
                recipientNostrPubkey = FavoritesPersistenceService.shared.getFavoriteStatus(forPeerID: peerID)?.peerNostrPublicKey
            }
            guard let recipientNpub = recipientNostrPubkey else { return }
            guard let senderIdentity = try? NostrIdentityBridge.getCurrentNostrIdentity() else { return }
            SecureLogger.log("NostrTransport: preparing DELIVERED ack for id=\(messageID.prefix(8))… to \(recipientNpub.prefix(16))…",
                            category: SecureLogger.session, level: .info)
            let recipientHex: String
            do {
                let (hrp, data) = try Bech32.decode(recipientNpub)
                guard hrp == "npub" else { return }
                recipientHex = data.hexEncodedString()
            } catch { return }
            guard let ack = NostrEmbeddedBitChat.encodeAckForNostr(type: .delivered, messageID: messageID, recipientPeerID: peerID, senderPeerID: senderPeerID) else {
                SecureLogger.log("NostrTransport: failed to embed DELIVERED ack", category: SecureLogger.session, level: .error)
                return
            }
            guard let event = try? NostrProtocol.createPrivateMessage(content: ack, recipientPubkey: recipientHex, senderIdentity: senderIdentity) else {
                SecureLogger.log("NostrTransport: failed to build Nostr event for DELIVERED ack", category: SecureLogger.session, level: .error)
                return
            }
            SecureLogger.log("NostrTransport: sending DELIVERED ack giftWrap id=\(event.id.prefix(16))…",
                            category: SecureLogger.session, level: .info)
            NostrRelayManager.shared.sendEvent(event)
        }
    }
    
    func sendNoiseEncryptedPayload(_ encryptedData: Data, to peerID: String) {
        // Not implemented for Nostr transport - only BLE supports Noise encryption
    }
    
    // MARK: - Group Messaging (Transport Protocol)
    
    func sendGroupMessage(_ content: String, to groupID: String, mentions: [String]) {
        // Group messaging over Nostr not implemented yet
        // This would require group coordination over Nostr relays
        SecureLogger.log("📨 Group message over Nostr not implemented (groupID: \(groupID.prefix(8))...)", 
                        category: SecureLogger.session, level: .debug)
    }
    
    func sendGroupInvitation(_ invitation: GroupInvitation, to peerID: String) {
        // Group invitations over Nostr not implemented yet
        // This would use gift wraps to send invitations
        SecureLogger.log("📤 Group invitation over Nostr not implemented (to: \(peerID.prefix(8))...)", 
                        category: SecureLogger.session, level: .debug)
    }
    
    func sendGroupInviteResponse(invitationID: String, accepted: Bool, to peerID: String) {
        // Group invite responses over Nostr not implemented yet
        SecureLogger.log("📤 Group invite response over Nostr not implemented (accepted: \(accepted))", 
                        category: SecureLogger.session, level: .debug)
    }
    
    func sendGroupMemberUpdate(_ update: GroupMemberUpdate, to groupID: String) {
        // Group member updates over Nostr not implemented yet
        SecureLogger.log("📤 Group member update over Nostr not implemented (groupID: \(groupID.prefix(8))...)", 
                        category: SecureLogger.session, level: .debug)
    }
    
    func sendGroupInfoUpdate(_ update: GroupInfoUpdate, to groupID: String) {
        // Group info updates over Nostr not implemented yet
        SecureLogger.log("📤 Group info update over Nostr not implemented (groupID: \(groupID.prefix(8))...)", 
                        category: SecureLogger.session, level: .debug)
    }
}
