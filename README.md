# ClearSight - Supply Chain Transparency Platform

## Overview
ClearSight is a blockchain-based supply chain transparency solution built on Stacks using Clarity smart contracts. It enables tracking and verification of products from source to consumer, promoting ethical and sustainable consumption through unprecedented supply chain visibility.

## Features
- Product Registration: Manufacturers can register new products with unique IDs
- Ownership Transfer: Track product movement through the supply chain
- Verification System: Stakeholders can verify product authenticity and location
- History Tracking: Complete audit trail of product journey
- Ownership Management: Secure transfer of product ownership

## Smart Contract Functions

### Read-Only Functions
- `get-product-details`: Retrieve current product information
- `get-product-history`: Access historical records for a product

### Public Functions
- `register-product`: Register a new product in the system
- `transfer-product`: Transfer product ownership to a new stakeholder
- `verify-product`: Verify product authenticity at current location

## Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Caller not authorized for action
- `ERR-PRODUCT-EXISTS (u101)`: Product ID already registered
- `ERR-PRODUCT-NOT-FOUND (u102)`: Product ID not found
- `ERR-INVALID-STATUS (u103)`: Invalid product status

## Data Structures

### Product Information
```clarity
{
    manufacturer: principal,
    timestamp: uint,
    current-owner: principal,
    status: string-utf8,
    verified: bool
}
```

### History Record
```clarity
{
    owner: principal,
    action: string-utf8,
    location: string-utf8
}
```

## Usage Example

```clarity
;; Register a new product
(contract-call? .clearsight register-product "prod123" "Factory A")

;; Transfer product to distributor
(contract-call? .clearsight transfer-product "prod123" 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "Warehouse B")

;; Verify product at new location
(contract-call? .clearsight verify-product "prod123" "Warehouse B")
```

## Security Considerations
- Only the current owner can transfer or verify a product
- Product history is immutable once recorded
- Ownership transfers require verification at destination
- All actions are timestamped and logged

## Future Enhancements
1. Integration with IoT devices for automated verification
2. QR code generation for product tracking
3. Enhanced metadata support for product specifications
4. Multi-signature verification for high-value items
5. Integration with sustainability scoring systems

