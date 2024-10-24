# ClearSight - Supply Chain Transparency Platform

## Overview
ClearSight is a blockchain-based supply chain transparency solution built on Stacks using Clarity smart contracts. It provides robust tracking and verification of products throughout the supply chain, incorporating role-based access control (RBAC), comprehensive audit trails, and advanced status management to ensure reliable and secure supply chain visibility.

## Key Features
- **Role-Based Access Control**: Granular permissions for manufacturers, distributors, and retailers
- **Product Lifecycle Management**: Sophisticated status tracking with validated transitions
- **Comprehensive Audit Trail**: Complete history of all product-related actions
- **Input Validation**: Robust validation for all data inputs and status transitions
- **Status History**: Detailed tracking of status changes with reasons and locations
- **Secure Ownership Management**: Controlled transfer of product ownership with verification

## Smart Contract Functions

### Public Functions
- `register-product`: Register new products with location tracking
- `update-product-status`: Update product status with validation
- `assign-role`: Manage user roles and permissions

### Read-Only Functions
- `get-product-details`: Retrieve detailed product information
- `get-status-history`: Access historical status records for a product

## Role-Based Access Control
- **ROLE-ADMIN (u1)**: System administration and role management
- **ROLE-MANUFACTURER (u2)**: Product registration and initial status management
- **ROLE-DISTRIBUTOR (u3)**: Transport and delivery management
- **ROLE-RETAILER (u4)**: Final verification and retail operations

## Status Management
Valid product statuses:
- `registered`: Initial product registration
- `in-transit`: Product in transportation
- `delivered`: Product arrived at destination
- `transferred`: Ownership transferred
- `verified`: Product authenticity verified
- `returned`: Product returned in supply chain
- `rejected`: Product failed verification

## Error Codes
```clarity
ERR-NOT-AUTHORIZED (u100): Unauthorized action attempt
ERR-PRODUCT-EXISTS (u101): Duplicate product registration
ERR-PRODUCT-NOT-FOUND (u102): Product lookup failed
ERR-INVALID-STATUS (u103): Invalid status value
ERR-INVALID-PRODUCT-ID (u104): Invalid product identifier
ERR-INVALID-LOCATION (u105): Invalid location data
ERR-INVALID-OWNER (u106): Invalid ownership data
ERR-ROLE-EXISTS (u107): Role already assigned
ERR-INVALID-ROLE (u108): Invalid role specification
ERR-INVALID-STATUS-TRANSITION (u109): Invalid status change
ERR-INVALID-REASON (u110): Invalid reason provided
```

## Data Structures

### Product Information
```clarity
{
    manufacturer: principal,
    timestamp: uint,
    current-owner: principal,
    current-status: (string-ascii 12),
    verified: bool,
    status-update-count: uint
}
```

### Status History
```clarity
{
    status: (string-ascii 12),
    timestamp: uint,
    changed-by: principal,
    reason: (string-ascii 50),
    location: (string-ascii 50)
}
```

### Audit Log Entry
```clarity
{
    actor: principal,
    action: (string-ascii 12),
    product-id: (string-ascii 36),
    details: (string-ascii 50)
}
```

## Usage Examples

### Product Registration
```clarity
;; Register a new product
(contract-call? .clearsight register-product 
    "PROD123ABC" 
    "Manufacturing Plant A"
)
```

### Status Update
```clarity
;; Update product status
(contract-call? .clearsight update-product-status
    "PROD123ABC"
    "in-transit"
    "Shipping to distribution center"
    "Distribution Center B"
)
```

### Role Assignment
```clarity
;; Assign manufacturer role
(contract-call? .clearsight assign-role
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
    u2
)
```

## Security Features
- Strict input validation for all data fields
- Role-based access control for all operations
- Validated status transitions
- Comprehensive audit logging
- Immutable history tracking
- Secure ownership management

## Data Validation
- Product ID length: Max 36 characters
- Location length: Max 50 characters
- Reason length: Max 50 characters
- Status transitions: Strictly controlled flow
- Role assignments: Validated permissions

## Future Enhancements
1. **Enhanced Authentication**
   - Multi-signature requirements for critical operations
   - Time-based role restrictions
   - Delegated authentication support

2. **Extended Tracking Capabilities**
   - Real-time location tracking integration
   - Environmental condition monitoring
   - Batch and lot management

3. **Advanced Analytics**
   - Supply chain performance metrics
   - Predictive analytics integration
   - Sustainability scoring

4. **Integration Capabilities**
   - IoT device integration
   - External oracle support
   - Cross-chain verification

5. **User Interface Improvements**
   - QR code generation and scanning
   - Mobile app integration
   - Real-time notifications

## Development Setup
1. Install Clarinet for local development
2. Clone the repository
3. Deploy contract using Clarinet console
4. Run test suite to verify functionality


## Contributing
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests
4. Ensure CI/CD checks pass