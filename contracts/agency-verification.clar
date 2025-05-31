;; Agency Verification Contract
;; Validates interstellar communication systems and agencies

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_AGENCY_EXISTS (err u101))
(define-constant ERR_AGENCY_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Agency data structure
(define-map agencies
  { agency-id: uint }
  {
    name: (string-ascii 100),
    country: (string-ascii 50),
    verification-status: (string-ascii 20),
    certification-level: uint,
    registered-at: uint,
    verified-by: principal
  }
)

(define-map agency-counter { id: uint } { count: uint })

;; Initialize counter
(map-set agency-counter { id: u0 } { count: u0 })

;; Register new agency
(define-public (register-agency (name (string-ascii 100)) (country (string-ascii 50)))
  (let ((current-count (default-to u0 (get count (map-get? agency-counter { id: u0 }))))
        (new-id (+ current-count u1)))
    (asserts! (is-none (map-get? agencies { agency-id: new-id })) ERR_AGENCY_EXISTS)
    (map-set agencies
      { agency-id: new-id }
      {
        name: name,
        country: country,
        verification-status: "pending",
        certification-level: u0,
        registered-at: block-height,
        verified-by: tx-sender
      }
    )
    (map-set agency-counter { id: u0 } { count: new-id })
    (ok new-id)
  )
)

;; Verify agency (only contract owner)
(define-public (verify-agency (agency-id uint) (status (string-ascii 20)) (level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? agencies { agency-id: agency-id })
      agency-data
      (begin
        (map-set agencies
          { agency-id: agency-id }
          (merge agency-data { verification-status: status, certification-level: level })
        )
        (ok true)
      )
      ERR_AGENCY_NOT_FOUND
    )
  )
)

;; Get agency details
(define-read-only (get-agency (agency-id uint))
  (map-get? agencies { agency-id: agency-id })
)

;; Get total agencies
(define-read-only (get-agency-count)
  (default-to u0 (get count (map-get? agency-counter { id: u0 })))
)

;; Check if agency is verified
(define-read-only (is-agency-verified (agency-id uint))
  (match (map-get? agencies { agency-id: agency-id })
    agency-data (is-eq (get verification-status agency-data) "verified")
    false
  )
)
