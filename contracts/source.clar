;; ClearSight - Supply Chain Transparency Contract
;; Enhanced with RBAC and Audit Trail

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
(define-constant ERR-ROLE-EXISTS (err u107))
(define-constant ERR-INVALID-ROLE (err u108))

;; Define roles
(define-constant ROLE-ADMIN u1)
(define-constant ROLE-MANUFACTURER u2)
(define-constant ROLE-DISTRIBUTOR u3)
(define-constant ROLE-RETAILER u4)

;; Define data variables
(define-data-var contract-owner principal tx-sender)

;; Role management
(define-map user-roles
    { user: principal }
    { role: uint }
)

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
        location: (string-ascii 50),
        previous-owner: (optional principal)
    }
)

;; Audit trail for all actions
(define-map audit-log
    { 
        transaction-id: uint,
        timestamp: uint
    }
    {
        actor: principal,
        action: (string-ascii 12),
        product-id: (string-ascii 36),
        details: (string-ascii 50)
    }
)

(define-data-var audit-counter uint u0)

;; Role management functions
(define-private (is-authorized (user principal) (required-role uint))
    (match (map-get? user-roles { user: user })
        role-data (is-eq (get role role-data) required-role)
        false
    )
)

(define-public (assign-role (user principal) (role uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
        (asserts! (or (is-eq role ROLE-MANUFACTURER) 
                     (is-eq role ROLE-DISTRIBUTOR)
                     (is-eq role ROLE-RETAILER)) 
                 (err ERR-INVALID-ROLE))
        (map-set user-roles
            { user: user }
            { role: role }
        )
        (create-audit-log tx-sender "assign-role" "N/A" "Role assignment completed")
        (ok true)
    )
)

;; Audit trail function
(define-private (create-audit-log (actor principal) (action (string-ascii 12)) 
                                 (product-id (string-ascii 36)) (details (string-ascii 50)))
    (let ((current-counter (var-get audit-counter)))
        (map-set audit-log
            { 
                transaction-id: current-counter,
                timestamp: block-height
            }
            {
                actor: actor,
                action: action,
                product-id: product-id,
                details: details
            }
        )
        (var-set audit-counter (+ current-counter u1))
        true
    )
)

;; Enhanced public functions with role checks and audit trails
(define-public (register-product 
    (product-id (string-ascii 36))
    (location (string-ascii 50)))
    (let ((timestamp block-height))
        (asserts! (is-authorized tx-sender ROLE-MANUFACTURER) (err ERR-NOT-AUTHORIZED))
        (asserts! (is-valid-product-id product-id) (err ERR-INVALID-PRODUCT-ID))
        (asserts! (is-valid-location location) (err ERR-INVALID-LOCATION))
        
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
                        location: location,
                        previous-owner: none
                    }
                )
                (create-audit-log tx-sender "register" product-id 
                    "Product registration completed")
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
        (asserts! (and 
            (is-authorized tx-sender ROLE-MANUFACTURER)
            (is-authorized new-owner ROLE-DISTRIBUTOR)) (err ERR-NOT-AUTHORIZED))
        (asserts! (is-valid-product-id product-id) (err ERR-INVALID-PRODUCT-ID))
        (asserts! (is-valid-location location) (err ERR-INVALID-LOCATION))
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
                location: location,
                previous-owner: (some tx-sender)
            }
        )
        (create-audit-log tx-sender "transfer" product-id "Product transfer completed")
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-audit-log (transaction-id uint))
    (match (map-get? audit-log { transaction-id: transaction-id, timestamp: block-height })
        entry (ok (some entry))
        (err none)
    )
)

(define-read-only (get-user-role (user principal))
    (match (map-get? user-roles { user: user })
        role-data (ok (some (get role role-data)))
        (err none)
    )
)

;; Validation functions (from original contract)
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