;; Communication Protocol Contract
;; Manages interstellar message transmission protocols

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_MESSAGE_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PROTOCOL (err u202))
(define-constant ERR_TRANSMISSION_FAILED (err u203))

;; Message data structure
(define-map messages
  { message-id: uint }
  {
    sender-agency: uint,
    target-system: (string-ascii 100),
    protocol-type: (string-ascii 50),
    message-content: (string-ascii 500),
    transmission-status: (string-ascii 20),
    sent-at: uint,
    estimated-arrival: uint,
    priority-level: uint
  }
)

;; Protocol definitions
(define-map protocols
  { protocol-name: (string-ascii 50) }
  {
    transmission-speed: uint,
    reliability-score: uint,
    energy-cost: uint,
    max-distance: uint,
    active: bool
  }
)

(define-map message-counter { id: uint } { count: uint })

;; Initialize
(map-set message-counter { id: u0 } { count: u0 })

;; Initialize default protocols
(map-set protocols
  { protocol-name: "quantum-entanglement" }
  { transmission-speed: u100, reliability-score: u95, energy-cost: u1000, max-distance: u1000000, active: true }
)

(map-set protocols
  { protocol-name: "gravitational-wave" }
  { transmission-speed: u50, reliability-score: u85, energy-cost: u500, max-distance: u500000, active: true }
)

;; Send interstellar message
(define-public (send-message
  (sender-agency uint)
  (target-system (string-ascii 100))
  (protocol-type (string-ascii 50))
  (content (string-ascii 500))
  (priority uint))
  (let ((current-count (default-to u0 (get count (map-get? message-counter { id: u0 }))))
        (new-id (+ current-count u1))
        (protocol-data (map-get? protocols { protocol-name: protocol-type })))
    (asserts! (is-some protocol-data) ERR_INVALID_PROTOCOL)
    (asserts! (get active (unwrap-panic protocol-data)) ERR_INVALID_PROTOCOL)
    (map-set messages
      { message-id: new-id }
      {
        sender-agency: sender-agency,
        target-system: target-system,
        protocol-type: protocol-type,
        message-content: content,
        transmission-status: "transmitting",
        sent-at: block-height,
        estimated-arrival: (+ block-height (get transmission-speed (unwrap-panic protocol-data))),
        priority-level: priority
      }
    )
    (map-set message-counter { id: u0 } { count: new-id })
    (ok new-id)
  )
)

;; Update message status
(define-public (update-message-status (message-id uint) (status (string-ascii 20)))
  (match (map-get? messages { message-id: message-id })
    message-data
    (begin
      (map-set messages
        { message-id: message-id }
        (merge message-data { transmission-status: status })
      )
      (ok true)
    )
    ERR_MESSAGE_NOT_FOUND
  )
)

;; Get message details
(define-read-only (get-message (message-id uint))
  (map-get? messages { message-id: message-id })
)

;; Get protocol details
(define-read-only (get-protocol (protocol-name (string-ascii 50)))
  (map-get? protocols { protocol-name: protocol-name })
)

;; Get message count
(define-read-only (get-message-count)
  (default-to u0 (get count (map-get? message-counter { id: u0 })))
)
