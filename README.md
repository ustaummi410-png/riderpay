# Riderpay - Motorbike Delivery Escrow System

A blockchain-based escrow smart contract system for secure motorbike delivery payments built on the Stacks blockchain using Clarity smart contracts.

## Overview

Riderpay is a decentralized escrow platform specifically designed for motorbike delivery services that ensures:
- Secure payment handling with escrow protection
- Automatic fund release upon delivery confirmation
- Dispute resolution mechanisms
- Transparent and immutable transaction records

## System Architecture

The system consists of two main smart contracts:

### 1. Delivery Escrow Contract (`delivery-escrow.clar`)
- Manages individual delivery orders and escrow payments
- Handles order creation, payment deposits, and fund releases
- Tracks delivery status and manages dispute resolution
- Provides secure payment processing for delivery services

### 2. Rider Management Contract (`rider-management.clar`)
- Manages rider registration and verification
- Tracks rider performance metrics and ratings
- Handles rider payments and commission structures
- Maintains rider availability and delivery capacity

## Key Features

- **Secure Escrow**: Funds are held in escrow until delivery confirmation
- **Multi-party System**: Customers, riders, and platform administrators
- **Automated Payments**: Smart contract automatically releases payments upon confirmation
- **Dispute Resolution**: Built-in mechanisms for handling delivery disputes
- **Rating System**: Customer and rider rating system for quality assurance
- **Commission Management**: Flexible commission structures for platform sustainability

## Delivery Process Flow

1. **Order Creation**: Customer creates delivery order with payment deposit
2. **Rider Assignment**: Available riders can accept delivery requests
3. **Pickup Confirmation**: Rider confirms item pickup from sender
4. **Delivery Transit**: Package is transported to destination
5. **Delivery Confirmation**: Recipient confirms successful delivery
6. **Payment Release**: Escrowed funds are automatically released to rider
7. **Rating & Feedback**: Both parties can rate the delivery experience

## Smart Contract Functions

### Delivery Escrow Contract
- Order creation and payment handling
- Delivery status tracking and updates
- Automatic payment release mechanisms
- Dispute resolution and refund processing

### Rider Management Contract
- Rider registration and profile management
- Performance tracking and rating systems
- Payment distribution and commission handling
- Availability and capacity management

## Security Features

- **Multi-signature Operations**: Critical operations require multiple confirmations
- **Time-locked Transactions**: Automatic refunds for undelivered orders
- **Dispute Arbitration**: Platform administrators can resolve conflicts
- **Fraud Prevention**: Built-in mechanisms to prevent payment fraud

## Platform Benefits

### For Customers
- Secure payment processing with escrow protection
- Transparent tracking of delivery status
- Dispute resolution if delivery issues occur
- Rating system to choose reliable riders

### For Riders
- Guaranteed payment upon successful delivery
- Performance-based rating system
- Flexible working arrangements
- Transparent commission structure

### For Platform
- Automated payment processing reduces overhead
- Built-in dispute resolution mechanisms
- Commission-based revenue model
- Scalable smart contract architecture

## Development

Built using:
- **Clarity**: Smart contract language for Stacks blockchain
- **Clarinet**: Development and testing framework
- **GitHub Actions**: Continuous integration and contract validation

## Getting Started

1. Clone this repository
2. Install Clarinet development tools
3. Run `clarinet check` to verify contract syntax
4. Use `clarinet test` to run the comprehensive test suite
5. Deploy to testnet for testing and integration

## Testing

The project includes comprehensive tests covering:
- Order creation and payment processing
- Rider assignment and delivery workflows
- Payment release and commission distribution
- Dispute resolution and refund mechanisms
- Rating system functionality
- Error handling and edge cases

---

*Riderpay: Revolutionizing motorbike delivery payments through blockchain technology and smart contracts*
