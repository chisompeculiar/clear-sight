;; ClearSight - Supply Chain Transparency Contract
;; Tracks product journey from source to consumer with verification steps

;; Constants for validation
(define-constant MAX-PRODUCT-ID-LENGTH u36)
(define-constant MAX-LOCATION-LENGTH u50)
(define-constant VALID-STATUSES (list "registered" "transferred" "verified"))

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRODUCT-EXISTS (err u101))
(define-constant ERR-PRODUCT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INVALID-PRODUCT-ID (err u104))
(define-constant ERR-INVALID-LOCATION (err u105))
(define-constant ERR-INVALID-OWNER (err u106))

;; Define data variables
(define-data-var contract-owner principal tx-sender)

(define-map products 
    { product-id: (string-ascii 36) }
    { 
        manufacturer: principal,
        timestamp: uint,
        current-owner: principal,
        status: (string-ascii 12),
        verified: bool
    }
)

(define-map product-history
    { 
        product-id: (string-ascii 36),
        timestamp: uint
    }
    {
        owner: principal,
        action: (string-ascii 12),
        location: (string-ascii 50)
    }
)

;; Validation functions
(define-private (is-valid-product-id (product-id (string-ascii 36)))
    (let ((length (len product-id)))
        (and
            (> length u0)
            (<= length MAX-PRODUCT-ID-LENGTH)
        )
    )
)

(define-private (is-valid-location (location (string-ascii 50)))
    (let ((length (len location)))
        (and
            (> length u0)
            (<= length MAX-LOCATION-LENGTH)
        )
    )
)

(define-private (is-valid-owner (owner principal))
    (not (is-eq owner (as-contract tx-sender)))
)

;; Read-only functions
(define-read-only (get-product-details (product-id (string-ascii 36)))
    (if (is-valid-product-id product-id)
        (ok (match (map-get? products { product-id: product-id })
            product (some product)
            none))
        (err ERR-INVALID-PRODUCT-ID)
    )
)

(define-read-only (get-product-history (product-id (string-ascii 36)) (timestamp uint))
    (if (is-valid-product-id product-id)
        (ok (match (map-get? product-history { product-id: product-id, timestamp: timestamp })
            entry (some entry)
            none))
        (err ERR-INVALID-PRODUCT-ID)
    )
)

;; Public functions
(define-public (register-product 
    (product-id (string-ascii 36))
    (location (string-ascii 50)))
    (let ((timestamp block-height))
        (asserts! (is-valid-product-id product-id) (err ERR-INVALID-PRODUCT-ID))
        (asserts! (is-valid-location location) (err ERR-INVALID-LOCATION))
        (asserts! (is-valid-owner tx-sender) (err ERR-INVALID-OWNER))
        
        (match (map-get? products { product-id: product-id })
            existing-product (err ERR-PRODUCT-EXISTS)
            (begin
                (map-set products
                    { product-id: product-id }
                    {
                        manufacturer: tx-sender,
                        timestamp: timestamp,
                        current-owner: tx-sender,
                        status: "registered",
                        verified: true
                    }
                )
                (map-set product-history
                    { product-id: product-id, timestamp: timestamp }
                    {
                        owner: tx-sender,
                        action: "registered",
                        location: location
                    }
                )
                (ok true)
            )
        )
    )
)

(define-public (transfer-product
    (product-id (string-ascii 36))
    (new-owner principal)
    (location (string-ascii 50)))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) (err ERR-PRODUCT-NOT-FOUND)))
        (timestamp block-height)
    )
        (asserts! (is-valid-product-id product-id) (err ERR-INVALID-PRODUCT-ID))
        (asserts! (is-valid-location location) (err ERR-INVALID-LOCATION))
        (asserts! (is-valid-owner new-owner) (err ERR-INVALID-OWNER))
        (asserts! (is-eq tx-sender (get current-owner product)) (err ERR-NOT-AUTHORIZED))
        
        (map-set products
            { product-id: product-id }
            (merge product { 
                current-owner: new-owner,
                status: "transferred",
                verified: false
            })
        )
        (map-set product-history
            { product-id: product-id, timestamp: timestamp }
            {
                owner: new-owner,
                action: "transfer",
                location: location
            }
        )
        (ok true)
    )
)

(define-public (verify-product
    (product-id (string-ascii 36))
    (location (string-ascii 50)))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) (err ERR-PRODUCT-NOT-FOUND)))
        (timestamp block-height)
    )
        (asserts! (is-valid-product-id product-id) (err ERR-INVALID-PRODUCT-ID))
        (asserts! (is-valid-location location) (err ERR-INVALID-LOCATION))
        (asserts! (is-eq tx-sender (get current-owner product)) (err ERR-NOT-AUTHORIZED))
        
        (map-set products
            { product-id: product-id }
            (merge product { 
                status: "verified",
                verified: true
            })
        )
        (map-set product-history
            { product-id: product-id, timestamp: timestamp }
            {
                owner: tx-sender,
                action: "verified",
                location: location
            }
        )
        (ok true)
    )
)