;; SecureWhistle: Decentralized Anonymous Reporting Platform Contract
;; A blockchain-based platform enabling secure, anonymous whistleblowing with cryptographic privacy,
;; community-driven verification, economic incentives, and transparent investigation tracking.
;; Features include anonymous identity protection, stake-based verification, reward distribution,
;; and decentralized governance for misconduct reporting across organizations and institutions.

;; Error handling constants for contract validation and security
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-REPORT-DATA (err u101))
(define-constant ERR-REPORT-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-VERIFIED (err u103))
(define-constant ERR-INSUFFICIENT-STAKE-AMOUNT (err u104))
(define-constant ERR-DUPLICATE-VOTE-DETECTED (err u105))
(define-constant ERR-VOTING-PERIOD-EXPIRED (err u106))
(define-constant ERR-REPORT-UNVERIFIED (err u107))
(define-constant ERR-REWARD-ALREADY-CLAIMED (err u108))
(define-constant ERR-INVALID-EVIDENCE-FORMAT (err u109))
(define-constant ERR-CASE-PERMANENTLY-CLOSED (err u110))
(define-constant ERR-INVALID-AMOUNT-VALUE (err u111))
(define-constant ERR-INVALID-ADDRESS-FORMAT (err u112))

;; Platform configuration and operational parameters
(define-constant contract-owner tx-sender)
(define-constant required-verifier-stake-amount u1000000)
(define-constant community-voting-duration-blocks u144)
(define-constant required-consensus-vote-count u3)
(define-constant whistleblower-reward-rate u10)
(define-constant maximum-transaction-limit u1000000000)

;; Report lifecycle status enumeration
(define-constant report-status-pending u0)
(define-constant report-status-under-review u1)
(define-constant report-status-verified u2)
(define-constant report-status-rejected u3)
(define-constant report-status-closed u4)

;; Severity classification system for misconduct reports
(define-constant severity-low-impact u1)
(define-constant severity-medium-impact u2)
(define-constant severity-high-impact u3)
(define-constant severity-critical-impact u4)

;; Global platform state variables
(define-data-var next-report-identifier uint u1)
(define-data-var platform-treasury-funds uint u0)
(define-data-var total-platform-reports uint u0)
(define-data-var total-verified-reports uint u0)

;; Core data structure for misconduct reports with comprehensive tracking
(define-map misconduct-reports
  uint
  {
    original-whistleblower: principal,
    anonymous-identity-signature: (buff 64),
    target-organization-name: (string-ascii 100),
    violation-category-type: (string-ascii 50),
    impact-severity-level: uint,
    primary-evidence-signature: (buff 64),
    report-description-signature: (buff 64),
    verification-status: uint,
    report-submission-block: uint,
    positive-verification-count: uint,
    negative-verification-count: uint,
    voting-period-end-block: uint,
    earned-reward-amount: uint,
    reward-claim-status: bool,
    recovered-damages-amount: uint
  })

;; Supporting documentation and evidence management
(define-map report-evidence-collection
  uint
  {
    evidence-item-count: uint,
    evidence-signature-list: (list 10 (buff 64)),
    latest-evidence-update-block: uint
  })

;; Community verifier registration and reputation system
(define-map registered-community-verifiers
  principal
  {
    deposited-stake-amount: uint,
    verifier-reputation-score: uint,
    total-participation-count: uint,
    successful-verification-count: uint,
    active-participation-status: bool,
    initial-registration-block: uint
  })

;; Voting records for community verification process
(define-map verification-voting-records
  {voter-principal: principal, target-report-identifier: uint}
  {
    vote-decision: bool,
    voting-power-utilized: uint,
    vote-timestamp-block: uint
  })

;; Anonymous reporter activity and performance tracking
(define-map anonymous-reporter-metrics
  (buff 64)
  {
    submitted-report-count: uint,
    total-earned-rewards: uint,
    last-activity-block: uint
  })

;; Investigation case management and progress tracking
(define-map investigation-case-records
  uint
  {
    assigned-investigator-principal: principal,
    investigation-phase-status: (string-ascii 50),
    latest-update-block: uint,
    investigation-documentation-hash: (buff 64)
  })

;; Access control and permission management
(define-map authorized-investigators principal bool)
(define-map authorized-administrators principal bool)

;; Initialize contract with deployer having full administrative privileges
(begin
  (map-set authorized-administrators contract-owner true)
  (map-set authorized-investigators contract-owner true)
)

;; Query function to retrieve complete report information
(define-read-only (fetch-report-details (report-id uint))
  (map-get? misconduct-reports report-id))

;; Query function to access report evidence collection
(define-read-only (fetch-evidence-collection (report-id uint))
  (map-get? report-evidence-collection report-id))

;; Query function to retrieve verifier profile information
(define-read-only (fetch-verifier-profile (verifier-address principal))
  (map-get? registered-community-verifiers verifier-address))

;; Query function to check individual voting record
(define-read-only (fetch-voting-record (voter-address principal) (report-id uint))
  (map-get? verification-voting-records {voter-principal: voter-address, target-report-identifier: report-id}))

;; Query function to access anonymous reporter statistics
(define-read-only (fetch-anonymous-statistics (identity-hash (buff 64)))
  (map-get? anonymous-reporter-metrics identity-hash))

;; Query function to retrieve investigation case information
(define-read-only (fetch-investigation-details (report-id uint))
  (map-get? investigation-case-records report-id))

;; Query function to get comprehensive platform statistics
(define-read-only (fetch-platform-metrics)
  {
    total-reports-submitted: (var-get total-platform-reports),
    community-verified-reports: (var-get total-verified-reports),
    available-treasury-balance: (var-get platform-treasury-funds),
    next-available-report-id: (var-get next-report-identifier)
  })

;; Query function to verify investigator authorization status
(define-read-only (verify-investigator-permissions (user-address principal))
  (default-to false (map-get? authorized-investigators user-address)))

;; Query function to verify administrator authorization status
(define-read-only (verify-administrator-permissions (user-address principal))
  (default-to false (map-get? authorized-administrators user-address)))

;; Calculate reward amount based on recovered funds percentage
(define-read-only (calculate-reward-amount (recovered-funds uint))
  (/ (* recovered-funds whistleblower-reward-rate) u100))

;; Determine voting power based on verifier stake amount
(define-read-only (determine-voting-power (verifier-address principal))
  (let ((verifier-data (map-get? registered-community-verifiers verifier-address)))
    (match verifier-data
      profile (get deposited-stake-amount profile)
      u0)))

;; Generate cryptographically secure anonymous identity for whistleblower protection
(define-private (create-anonymous-identity (reporter-address principal) (entropy-nonce uint))
  (let ((address-bytes (unwrap-panic (to-consensus-buff? reporter-address)))
        (nonce-bytes (unwrap-panic (to-consensus-buff? entropy-nonce)))
        (block-bytes (unwrap-panic (to-consensus-buff? block-height))))
    (sha512 (concat (concat address-bytes nonce-bytes) block-bytes))))

;; Update verifier reputation based on verification accuracy
(define-private (adjust-verifier-reputation (verifier-address principal) (verification-accuracy bool))
  (let ((current-profile (default-to 
    {deposited-stake-amount: u0, verifier-reputation-score: u0, total-participation-count: u0, 
     successful-verification-count: u0, active-participation-status: false, initial-registration-block: u0}
    (map-get? registered-community-verifiers verifier-address))))
    (map-set registered-community-verifiers verifier-address
      (merge current-profile {
        total-participation-count: (+ (get total-participation-count current-profile) u1),
        successful-verification-count: (if verification-accuracy 
          (+ (get successful-verification-count current-profile) u1)
          (get successful-verification-count current-profile)),
        verifier-reputation-score: (if verification-accuracy
          (+ (get verifier-reputation-score current-profile) u10)
          (if (> (get verifier-reputation-score current-profile) u5)
            (- (get verifier-reputation-score current-profile) u5)
            u0))
      }))))

;; Validate evidence hash format and integrity
(define-private (validate-evidence-signature (evidence-hash (buff 64)))
  (> (len evidence-hash) u0))

;; Validate report submission data completeness and format
(define-private (validate-report-parameters (organization-name (string-ascii 100)) 
                                          (category-type (string-ascii 50))
                                          (severity-level uint))
  (and 
    (> (len organization-name) u0)
    (> (len category-type) u0)
    (>= severity-level severity-low-impact)
    (<= severity-level severity-critical-impact)))

;; Validate principal address format and legitimacy
(define-private (validate-address-format (target-address principal))
  (not (is-eq target-address 'ST000000000000000000002AMW42H)))

;; Validate transaction amount within acceptable bounds
(define-private (validate-amount-bounds (amount-value uint))
  (and (> amount-value u0) (<= amount-value maximum-transaction-limit)))

;; Validate report identifier exists and is within valid range
(define-private (validate-report-existence (report-id uint))
  (and (> report-id u0) (< report-id (var-get next-report-identifier))))

;; Submit new misconduct report with optional anonymous protection
(define-public (create-misconduct-report 
  (target-organization (string-ascii 100))
  (violation-category (string-ascii 50))
  (impact-level uint)
  (evidence-hash (buff 64))
  (description-hash (buff 64))
  (enable-anonymity bool))
  (let ((current-report-id (var-get next-report-identifier))
        (whistleblower-identity (if enable-anonymity 
          (create-anonymous-identity tx-sender current-report-id)
          (sha512 (unwrap-panic (to-consensus-buff? tx-sender))))))
    (asserts! (validate-report-parameters target-organization violation-category impact-level) ERR-INVALID-REPORT-DATA)
    (asserts! (validate-evidence-signature evidence-hash) ERR-INVALID-EVIDENCE-FORMAT)
    (asserts! (validate-evidence-signature description-hash) ERR-INVALID-EVIDENCE-FORMAT)
    
    (map-set misconduct-reports current-report-id {
      original-whistleblower: tx-sender,
      anonymous-identity-signature: whistleblower-identity,
      target-organization-name: target-organization,
      violation-category-type: violation-category,
      impact-severity-level: impact-level,
      primary-evidence-signature: evidence-hash,
      report-description-signature: description-hash,
      verification-status: report-status-pending,
      report-submission-block: block-height,
      positive-verification-count: u0,
      negative-verification-count: u0,
      voting-period-end-block: (+ block-height community-voting-duration-blocks),
      earned-reward-amount: u0,
      reward-claim-status: false,
      recovered-damages-amount: u0
    })
    
    (map-set report-evidence-collection current-report-id {
      evidence-item-count: u1,
      evidence-signature-list: (list evidence-hash),
      latest-evidence-update-block: block-height
    })
    
    (if enable-anonymity
      (let ((existing-metrics (default-to 
        {submitted-report-count: u0, total-earned-rewards: u0, last-activity-block: u0}
        (map-get? anonymous-reporter-metrics whistleblower-identity))))
        (map-set anonymous-reporter-metrics whistleblower-identity
          (merge existing-metrics {
            submitted-report-count: (+ (get submitted-report-count existing-metrics) u1),
            last-activity-block: block-height
          })))
      true)
    
    (var-set next-report-identifier (+ current-report-id u1))
    (var-set total-platform-reports (+ (var-get total-platform-reports) u1))
    
    (ok current-report-id)))

;; Add supplementary evidence to existing report
(define-public (add-supplementary-evidence (report-id uint) (evidence-signature (buff 64)))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND))
        (existing-evidence (unwrap! (map-get? report-evidence-collection report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (is-eq (get original-whistleblower target-report) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq (get verification-status target-report) report-status-closed)) ERR-CASE-PERMANENTLY-CLOSED)
    (asserts! (validate-evidence-signature evidence-signature) ERR-INVALID-EVIDENCE-FORMAT)
    (asserts! (< (get evidence-item-count existing-evidence) u10) ERR-INVALID-EVIDENCE-FORMAT)
    
    (map-set report-evidence-collection report-id {
      evidence-item-count: (+ (get evidence-item-count existing-evidence) u1),
      evidence-signature-list: (unwrap-panic (as-max-len? 
        (append (get evidence-signature-list existing-evidence) evidence-signature) u10)),
      latest-evidence-update-block: block-height
    })
    
    (ok true)))

;; Register as community verifier with required stake deposit
(define-public (become-community-verifier)
  (let ((available-balance (stx-get-balance tx-sender)))
    (asserts! (>= available-balance required-verifier-stake-amount) ERR-INSUFFICIENT-STAKE-AMOUNT)
    
    (try! (stx-transfer? required-verifier-stake-amount tx-sender (as-contract tx-sender)))
    
    (map-set registered-community-verifiers tx-sender {
      deposited-stake-amount: required-verifier-stake-amount,
      verifier-reputation-score: u100,
      total-participation-count: u0,
      successful-verification-count: u0,
      active-participation-status: true,
      initial-registration-block: block-height
    })
    
    (var-set platform-treasury-funds (+ (var-get platform-treasury-funds) required-verifier-stake-amount))
    (ok true)))

;; Cast verification vote on submitted report
(define-public (cast-verification-vote (report-id uint) (approve-report bool))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND))
        (voter-profile (unwrap! (map-get? registered-community-verifiers tx-sender) ERR-UNAUTHORIZED-ACCESS))
        (available-voting-power (get deposited-stake-amount voter-profile)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (get active-participation-status voter-profile) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= block-height (get voting-period-end-block target-report)) ERR-VOTING-PERIOD-EXPIRED)
    (asserts! (is-none (map-get? verification-voting-records 
      {voter-principal: tx-sender, target-report-identifier: report-id})) ERR-DUPLICATE-VOTE-DETECTED)
    (asserts! (not (is-eq (get verification-status target-report) report-status-verified)) ERR-ALREADY-VERIFIED)
    
    (map-set verification-voting-records {voter-principal: tx-sender, target-report-identifier: report-id} {
      vote-decision: approve-report,
      voting-power-utilized: available-voting-power,
      vote-timestamp-block: block-height
    })
    
    (map-set misconduct-reports report-id
      (merge target-report {
        positive-verification-count: (if approve-report 
          (+ (get positive-verification-count target-report) u1)
          (get positive-verification-count target-report)),
        negative-verification-count: (if approve-report
          (get negative-verification-count target-report)
          (+ (get negative-verification-count target-report) u1)),
        verification-status: report-status-under-review
      }))
    
    (let ((updated-report (unwrap-panic (map-get? misconduct-reports report-id))))
      (if (>= (get positive-verification-count updated-report) required-consensus-vote-count)
        (begin
          (map-set misconduct-reports report-id
            (merge updated-report {verification-status: report-status-verified}))
          (var-set total-verified-reports (+ (var-get total-verified-reports) u1))
          (adjust-verifier-reputation tx-sender true))
        (if (>= (get negative-verification-count updated-report) required-consensus-vote-count)
          (begin
            (map-set misconduct-reports report-id
              (merge updated-report {verification-status: report-status-rejected}))
            (adjust-verifier-reputation tx-sender false))
          true)))
    
    (ok true)))

;; Assign verified case to authorized investigator for follow-up
(define-public (delegate-investigation-case (report-id uint) (investigator-address principal))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (validate-address-format investigator-address) ERR-INVALID-ADDRESS-FORMAT)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-investigator-permissions investigator-address) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get verification-status target-report) report-status-verified) ERR-REPORT-UNVERIFIED)
    
    (map-set investigation-case-records report-id {
      assigned-investigator-principal: investigator-address,
      investigation-phase-status: "initial-case-review",
      latest-update-block: block-height,
      investigation-documentation-hash: 0x00
    })
    
    (ok true)))

;; Update investigation progress and documentation
(define-public (update-case-progress 
  (report-id uint) 
  (phase-description (string-ascii 50))
  (documentation-hash (buff 64)))
  (let ((case-data (unwrap! (map-get? investigation-case-records report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (> (len phase-description) u0) ERR-INVALID-REPORT-DATA)
    (asserts! (validate-evidence-signature documentation-hash) ERR-INVALID-EVIDENCE-FORMAT)
    (asserts! (or (is-eq (get assigned-investigator-principal case-data) tx-sender)
                  (verify-administrator-permissions tx-sender)) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set investigation-case-records report-id
      (merge case-data {
        investigation-phase-status: phase-description,
        latest-update-block: block-height,
        investigation-documentation-hash: documentation-hash
      }))
    
    (ok true)))

;; Establish reward amount based on recovered funds calculation
(define-public (set-whistleblower-compensation (report-id uint) (recovered-amount uint))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (validate-amount-bounds recovered-amount) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get verification-status target-report) report-status-verified) ERR-REPORT-UNVERIFIED)
    
    (let ((compensation-amount (calculate-reward-amount recovered-amount)))
      (map-set misconduct-reports report-id
        (merge target-report {
          earned-reward-amount: compensation-amount,
          recovered-damages-amount: recovered-amount
        })))
    
    (ok true)))

;; Claim and distribute earned whistleblower rewards
(define-public (claim-whistleblower-reward (report-id uint))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (is-eq (get original-whistleblower target-report) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get verification-status target-report) report-status-verified) ERR-REPORT-UNVERIFIED)
    (asserts! (> (get earned-reward-amount target-report) u0) ERR-INVALID-REPORT-DATA)
    (asserts! (not (get reward-claim-status target-report)) ERR-REWARD-ALREADY-CLAIMED)
    
    (try! (as-contract (stx-transfer? (get earned-reward-amount target-report) tx-sender tx-sender)))
    
    (map-set misconduct-reports report-id
      (merge target-report {reward-claim-status: true}))
    
    (let ((identity-metrics (map-get? anonymous-reporter-metrics (get anonymous-identity-signature target-report))))
      (match identity-metrics
        metrics (map-set anonymous-reporter-metrics (get anonymous-identity-signature target-report)
          (merge metrics {
            total-earned-rewards: (+ (get total-earned-rewards metrics) (get earned-reward-amount target-report))
          }))
        true))
    
    (ok true)))

;; Finalize and close completed investigation case
(define-public (finalize-investigation-case (report-id uint))
  (let ((target-report (unwrap! (map-get? misconduct-reports report-id) ERR-REPORT-NOT-FOUND)))
    (asserts! (validate-report-existence report-id) ERR-INVALID-REPORT-DATA)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set misconduct-reports report-id
      (merge target-report {verification-status: report-status-closed}))
    
    (ok true)))

;; Grant investigation privileges to qualified personnel
(define-public (grant-investigator-access (investigator-address principal))
  (begin
    (asserts! (validate-address-format investigator-address) ERR-INVALID-ADDRESS-FORMAT)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (map-set authorized-investigators investigator-address true)
    (ok true)))

;; Revoke investigation privileges from personnel
(define-public (revoke-investigator-access (investigator-address principal))
  (begin
    (asserts! (validate-address-format investigator-address) ERR-INVALID-ADDRESS-FORMAT)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (map-delete authorized-investigators investigator-address)
    (ok true)))

;; Grant platform administration privileges (contract owner only)
(define-public (grant-administrator-access (admin-address principal))
  (begin
    (asserts! (validate-address-format admin-address) ERR-INVALID-ADDRESS-FORMAT)
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (map-set authorized-administrators admin-address true)
    (ok true)))

;; Add funds to platform treasury for operational expenses and rewards
(define-public (fund-platform-treasury (deposit-amount uint))
  (begin
    (asserts! (validate-amount-bounds deposit-amount) ERR-INVALID-AMOUNT-VALUE)
    (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
    (var-set platform-treasury-funds (+ (var-get platform-treasury-funds) deposit-amount))
    (ok true)))

;; Emergency withdrawal of verifier stake for dispute resolution
(define-public (execute-emergency-stake-withdrawal (verifier-address principal))
  (let ((verifier-data (unwrap! (map-get? registered-community-verifiers verifier-address) ERR-UNAUTHORIZED-ACCESS)))
    (asserts! (validate-address-format verifier-address) ERR-INVALID-ADDRESS-FORMAT)
    (asserts! (verify-administrator-permissions tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> (get deposited-stake-amount verifier-data) u0) ERR-INVALID-AMOUNT-VALUE)
    
    (try! (as-contract (stx-transfer? (get deposited-stake-amount verifier-data) tx-sender verifier-address)))
    
    (map-delete registered-community-verifiers verifier-address)
    (var-set platform-treasury-funds (- (var-get platform-treasury-funds) (get deposited-stake-amount verifier-data)))
    
    (ok true)))