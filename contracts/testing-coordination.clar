;; Testing Coordination Contract
;; Manages business continuity testing

;; Constants
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_NOT_FOUND (err u401))
(define-constant ERR_INVALID_STATUS (err u402))

;; Data Variables
(define-data-var next-test-id uint u1)

;; Data Maps
(define-map continuity-tests
  { test-id: uint }
  {
    test-name: (string-ascii 100),
    test-type: (string-ascii 50),
    plan-id: uint,
    scheduled-date: uint,
    duration-minutes: uint,
    test-coordinator: principal,
    participants: (string-ascii 500),
    objectives: (string-ascii 1000),
    success-criteria: (string-ascii 1000),
    actual-start: (optional uint),
    actual-end: (optional uint),
    results: (optional (string-ascii 2000)),
    issues-found: (optional (string-ascii 1000)),
    recommendations: (optional (string-ascii 1000)),
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map test-results
  { test-id: uint }
  {
    passed: bool,
    score: uint,
    completion-time: uint,
    critical-issues: uint,
    minor-issues: uint,
    evaluated-by: principal,
    evaluated-at: uint
  }
)

;; Public Functions

;; Schedule continuity test
(define-public (schedule-test
  (test-name (string-ascii 100))
  (test-type (string-ascii 50))
  (plan-id uint)
  (scheduled-date uint)
  (duration-minutes uint)
  (participants (string-ascii 500))
  (objectives (string-ascii 1000))
  (success-criteria (string-ascii 1000))
)
  (let ((test-id (var-get next-test-id)))
    (map-set continuity-tests
      { test-id: test-id }
      {
        test-name: test-name,
        test-type: test-type,
        plan-id: plan-id,
        scheduled-date: scheduled-date,
        duration-minutes: duration-minutes,
        test-coordinator: tx-sender,
        participants: participants,
        objectives: objectives,
        success-criteria: success-criteria,
        actual-start: none,
        actual-end: none,
        results: none,
        issues-found: none,
        recommendations: none,
        status: "scheduled",
        created-at: block-height
      }
    )

    (var-set next-test-id (+ test-id u1))
    (ok test-id)
  )
)

;; Start test execution
(define-public (start-test (test-id uint))
  (let ((test (unwrap! (map-get? continuity-tests { test-id: test-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get test-coordinator test)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status test) "scheduled") ERR_INVALID_STATUS)

    (map-set continuity-tests
      { test-id: test-id }
      (merge test {
        actual-start: (some block-height),
        status: "in-progress"
      })
    )

    (ok true)
  )
)

;; Complete test execution
(define-public (complete-test
  (test-id uint)
  (results (string-ascii 2000))
  (issues-found (string-ascii 1000))
  (recommendations (string-ascii 1000))
)
  (let ((test (unwrap! (map-get? continuity-tests { test-id: test-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get test-coordinator test)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status test) "in-progress") ERR_INVALID_STATUS)

    (map-set continuity-tests
      { test-id: test-id }
      (merge test {
        actual-end: (some block-height),
        results: (some results),
        issues-found: (some issues-found),
        recommendations: (some recommendations),
        status: "completed"
      })
    )

    (ok true)
  )
)

;; Evaluate test results
(define-public (evaluate-test
  (test-id uint)
  (passed bool)
  (score uint)
  (completion-time uint)
  (critical-issues uint)
  (minor-issues uint)
)
  (let ((test (unwrap! (map-get? continuity-tests { test-id: test-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status test) "completed") ERR_INVALID_STATUS)
    (asserts! (<= score u100) ERR_INVALID_STATUS)

    (map-set test-results
      { test-id: test-id }
      {
        passed: passed,
        score: score,
        completion-time: completion-time,
        critical-issues: critical-issues,
        minor-issues: minor-issues,
        evaluated-by: tx-sender,
        evaluated-at: block-height
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get test details
(define-read-only (get-test (test-id uint))
  (map-get? continuity-tests { test-id: test-id })
)

;; Get test results
(define-read-only (get-test-results (test-id uint))
  (map-get? test-results { test-id: test-id })
)

;; Check if test passed
(define-read-only (test-passed (test-id uint))
  (match (map-get? test-results { test-id: test-id })
    results (get passed results)
    false
  )
)

;; Get test score
(define-read-only (get-test-score (test-id uint))
  (match (map-get? test-results { test-id: test-id })
    results (some (get score results))
    none
  )
)
