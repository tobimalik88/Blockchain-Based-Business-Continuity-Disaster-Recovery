;; Risk Assessment Contract
;; Manages business continuity risk assessments

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_SCORE (err u202))

;; Data Variables
(define-data-var next-risk-id uint u1)

;; Data Maps
(define-map risks
  { risk-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    probability-score: uint,
    impact-score: uint,
    risk-score: uint,
    mitigation-plan: (string-ascii 500),
    assessor: principal,
    created-at: uint,
    updated-at: uint,
    status: (string-ascii 20)
  }
)

;; Public Functions

;; Create new risk assessment
(define-public (create-risk-assessment
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (probability-score uint)
  (impact-score uint)
  (mitigation-plan (string-ascii 500))
)
  (let ((risk-id (var-get next-risk-id))
        (risk-score (* probability-score impact-score)))

    (asserts! (<= probability-score u5) ERR_INVALID_SCORE)
    (asserts! (<= impact-score u5) ERR_INVALID_SCORE)

    (map-set risks
      { risk-id: risk-id }
      {
        title: title,
        description: description,
        category: category,
        probability-score: probability-score,
        impact-score: impact-score,
        risk-score: risk-score,
        mitigation-plan: mitigation-plan,
        assessor: tx-sender,
        created-at: block-height,
        updated-at: block-height,
        status: "active"
      }
    )

    (var-set next-risk-id (+ risk-id u1))
    (ok risk-id)
  )
)

;; Update risk assessment
(define-public (update-risk-assessment
  (risk-id uint)
  (probability-score uint)
  (impact-score uint)
  (mitigation-plan (string-ascii 500))
)
  (let ((risk (unwrap! (map-get? risks { risk-id: risk-id }) ERR_NOT_FOUND))
        (risk-score (* probability-score impact-score)))

    (asserts! (<= probability-score u5) ERR_INVALID_SCORE)
    (asserts! (<= impact-score u5) ERR_INVALID_SCORE)

    (map-set risks
      { risk-id: risk-id }
      (merge risk {
        probability-score: probability-score,
        impact-score: impact-score,
        risk-score: risk-score,
        mitigation-plan: mitigation-plan,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Close risk assessment
(define-public (close-risk (risk-id uint))
  (let ((risk (unwrap! (map-get? risks { risk-id: risk-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get assessor risk)) ERR_UNAUTHORIZED)

    (map-set risks
      { risk-id: risk-id }
      (merge risk {
        status: "closed",
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get risk by ID
(define-read-only (get-risk (risk-id uint))
  (map-get? risks { risk-id: risk-id })
)

;; Get risk score
(define-read-only (get-risk-score (risk-id uint))
  (match (map-get? risks { risk-id: risk-id })
    risk (some (get risk-score risk))
    none
  )
)

;; Check if high risk (score > 15)
(define-read-only (is-high-risk (risk-id uint))
  (match (get-risk-score risk-id)
    score (> score u15)
    false
  )
)
