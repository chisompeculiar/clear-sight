;; ClearSight - Supply Chain Transparency Contract
;; Tracks product journey from source to consumer with verification steps

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map products 
    { product-id: (string-ascii 36) }
    { 
        manufacturer: principal,
        timestamp: uint,
        current-owner: principal,
        status: (string-ascii 12),  ;; Increased to accommodate "registered"
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
        action: (string-ascii 12),  ;; Increased to match status length
        location: (string-ascii 50)
    }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRODUCT-EXISTS (err u101))
(define-constant ERR-PRODUCT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

;; Read-only functions
(define-read-only (get-product-details (product-id (string-ascii 36)))
    (ok (match (map-get? products { product-id: product-id })
        product (some product)
        none))
)

(define-read-only (get-product-history (product-id (string-ascii 36)) (timestamp uint))
    (ok (match (map-get? product-history { product-id: product-id, timestamp: timestamp })
        entry (some entry)
        none))
)

;; Public functions
(define-public (register-product 
    (product-id (string-ascii 36))
    (location (string-ascii 50)))
    (let ((timestamp block-height))
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
        (if (is-eq tx-sender (get current-owner product))
            (begin
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
            (err ERR-NOT-AUTHORIZED)
        )
    )
)

(define-public (verify-product
    (product-id (string-ascii 36))
    (new-owner principal)
    (location (string-ascii 50)))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) (err ERR-PRODUCT-NOT-FOUND)))
        (timestamp block-height)
    )
        (if (is-eq tx-sender (get current-owner product))
            (begin
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
            (err ERR-NOT-AUTHORIZED)
        )
    )
)