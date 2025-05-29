;; MedicalRecordVault: Secure Healthcare Data Management System
;; Version: 1.0.0
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-RECORD-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-PRIORITY (err u5))
(define-constant ERR-INVALID-DEPARTMENT (err u6))
(define-constant ERR-INVALID-PRIVACY (err u7))
(define-constant ERR-INVALID-SUBJECT (err u8))
(define-constant ERR-INVALID-CONTENT (err u9))
(define-constant MIN-PRIORITY u1)
(define-data-var next-record-id uint u1)
(define-map medical-records
    uint
    {
        physician: principal,
        record-subject: (string-utf8 50),
        record-content: (string-utf8 200),
        medical-department: (string-utf8 10),
        privacy-level: (string-utf8 20),
        status: (string-utf8 10),
        priority-level: uint
    }
)
(define-private (validate-department (department (string-utf8 10)))
    (or 
        (is-eq department u"Cardiology")
        (is-eq department u"Neurology")
        (is-eq department u"Pediatrics")
        (is-eq department u"Oncology")
        (is-eq department u"Radiology")
        (is-eq department u"Emergency")
    )
)
(define-private (validate-privacy (privacy (string-utf8 20)))
    (or 
        (is-eq privacy u"Restricted")
        (is-eq privacy u"Confidential")
        (is-eq privacy u"Physician-Only")
        (is-eq privacy u"Research-Use")
        (is-eq privacy u"Patient-Access")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (create-medical-record 
    (record-subject (string-utf8 50))
    (record-content (string-utf8 200))
    (medical-department (string-utf8 10))
    (privacy-level (string-utf8 20))
    (priority-level uint)
)
    (let
        (
            (record-id (var-get next-record-id))
        )
        (asserts! (validate-text-length record-subject u3 u50) ERR-INVALID-SUBJECT)
        (asserts! (validate-text-length record-content u10 u200) ERR-INVALID-CONTENT)
        (asserts! (>= priority-level MIN-PRIORITY) ERR-INVALID-PRIORITY)
        (asserts! (validate-department medical-department) ERR-INVALID-DEPARTMENT)
        (asserts! (validate-privacy privacy-level) ERR-INVALID-PRIVACY)
        
        (map-set medical-records record-id {
            physician: tx-sender,
            record-subject: record-subject,
            record-content: record-content,
            medical-department: medical-department,
            privacy-level: privacy-level,
            status: u"active",
            priority-level: priority-level
        })
        (var-set next-record-id (+ record-id u1))
        (ok record-id)
    )
)
(define-public (archive-medical-record (record-id uint))
    (let
        (
            (record (unwrap! (map-get? medical-records record-id) ERR-RECORD-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get physician record)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status record) u"active") ERR-INVALID-STATUS)
        (ok (map-set medical-records record-id (merge record { status: u"archived" })))
    )
)
(define-read-only (get-medical-record (record-id uint))
    (ok (map-get? medical-records record-id))
)
(define-read-only (get-physician (record-id uint))
    (ok (get physician (unwrap! (map-get? medical-records record-id) ERR-RECORD-NOT-FOUND)))
)
