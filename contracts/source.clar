;; ClearSight - Supply Chain Transparency Contract
;; Enhanced with RBAC, Audit Trail, and Advanced Status Management

;; Constants for validation
(define-constant MAX-PRODUCT-ID-LENGTH u36)
(define-constant MAX-LOCATION-LENGTH u50)

;; Enhanced status constants
(define-constant STATUS-REGISTERED "registered")
(define-constant STATUS-IN-TRANSIT "in-transit")
(define-constant STATUS-DELIVERED "delivered")
(define-constant STATUS-TRANSFERRED "transferred")
(define-constant STATUS-VERIFIED "verified")
(define-constant STATUS-RETURNED "returned")
(define-constant STATUS-REJECTED "rejected")

;; Action constants (all 12 chars or less)
(define-constant ACTION-UPDATE "status-upd")
(define-constant ACTION-REGISTER "register")
(define-constant ACTION-TRANSFER "transfer")

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
(define-constant ERR-INVALID-STATUS-TRANSITION (err u109))

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

;; Enhanced products map with status tracking
(define-map products 
    { product-id: (string-ascii 36) }
    { 
        manufacturer: principal,
        timestamp: uint,
        current-owner: principal,
        current-status: (string-ascii 12),
        verified: bool,
        status-update-count: uint  ;; Track number of status updates
    }
)

;; New map for status history
(define-map status-history
    { 
        product-id: (string-ascii 36),
        update-number: uint
    }
    {
        status: (string-ascii 12),
        timestamp: uint,
        changed-by: principal,
        reason: (string-ascii 50),
        location: (string-ascii 50)
    }
)

;; Product history
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

;; Audit trail
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

;; Validation functions
(define-private (is-valid-product-id (product-id (string-ascii 36)))
    (and
        (>= (len product-id) u1)
        (<= (len product-id) MAX-PRODUCT-ID-LENGTH)
        true
    )
)

(define-private (is-valid-location (location (string-ascii 50)))
    (and
        (>= (len location) u1)
        (<= (len location) MAX-LOCATION-LENGTH)
        true
    )
)

;; Status validation functions
(define-private (is-valid-status (status (string-ascii 12)))
    (or 
        (is-eq status STATUS-REGISTERED)
        (is-eq status STATUS-IN-TRANSIT)
        (is-eq status STATUS-DELIVERED)
        (is-eq status STATUS-TRANSFERRED)
        (is-eq status STATUS-VERIFIED)
        (is-eq status STATUS-RETURNED)
        (is-eq status STATUS-REJECTED)
    )
)

(define-private (is-valid-status-transition (current-status (string-ascii 12)) (new-status (string-ascii 12)))
    (or
        ;; Valid transitions from registered
        (and (is-eq current-status STATUS-REGISTERED)
             (or (is-eq new-status STATUS-IN-TRANSIT)
                 (is-eq new-status STATUS-TRANSFERRED)))
        ;; Valid transitions from in-transit
        (and (is-eq current-status STATUS-IN-TRANSIT)
             (or (is-eq new-status STATUS-DELIVERED)
                 (is-eq new-status STATUS-RETURNED)))
        ;; Valid transitions from delivered
        (and (is-eq current-status STATUS-DELIVERED)
             (or (is-eq new-status STATUS-VERIFIED)
                 (is-eq new-status STATUS-REJECTED)))
        ;; Other valid transitions
        (and (is-eq current-status STATUS-TRANSFERRED)
             (is-eq new-status STATUS-VERIFIED))
    )
)

;; New function to update product status
(define-public (update-product-status
    (product-id (string-ascii 36))
    (new-status (string-ascii 12))
    (reason (string-ascii 50))
    (location (string-ascii 50)))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) (err ERR-PRODUCT-NOT-FOUND)))
        (current-status (get current-status product))
        (timestamp block-height)
    )
        (asserts! (is-valid-status new-status) (err ERR-INVALID-STATUS))
        (asserts! (is-valid-status-transition current-status new-status) (err ERR-INVALID-STATUS-TRANSITION))
        (asserts! (is-authorized tx-sender ROLE-MANUFACTURER) (err ERR-NOT-AUTHORIZED))
        
        ;; Update product status
        (map-set products
            { product-id: product-id }
            (merge product { 
                current-status: new-status,
                status-update-count: (+ (get status-update-count product) u1)
            })
        )
        
        ;; Record in status history
        (map-set status-history
            { 
                product-id: product-id,
                update-number: (get status-update-count product)
            }
            {
                status: new-status,
                timestamp: timestamp,
                changed-by: tx-sender,
                reason: reason,
                location: location
            }
        )
        
        ;; Create audit log entry
        (create-audit-log tx-sender ACTION-UPDATE product-id 
            (concat "Status: " new-status))
        (ok true)
    )
)

;; Read-only function to get product status history
(define-read-only (get-status-history (product-id (string-ascii 36)) (update-number uint))
    (match (map-get? status-history { product-id: product-id, update-number: update-number })
        entry (ok (some entry))
        (err none)
    )
)

;; Modified register-product function to use new status system
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
                        current-status: STATUS-REGISTERED,
                        verified: true,
                        status-update-count: u1
                    }
                )
                ;; Initial status history entry
                (map-set status-history
                    { product-id: product-id, update-number: u0 }
                    {
                        status: STATUS-REGISTERED,
                        timestamp: timestamp,
                        changed-by: tx-sender,
                        reason: "Initial registration",
                        location: location
                    }
                )
                (create-audit-log tx-sender ACTION-REGISTER product-id 
                    "Product registered")
                (ok true)
            )
        )
    )
)

;; Helper functions
(define-private (is-authorized (user principal) (required-role uint))
    (match (map-get? user-roles { user: user })
        role-data (is-eq (get role role-data) required-role)
        false
    )
)

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