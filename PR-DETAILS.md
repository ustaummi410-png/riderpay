# Riderpay - Motorbike Delivery Escrow System

## 🏍️ Overview

Riderpay is a comprehensive blockchain-based escrow system for motorbike delivery services built on Stacks blockchain using Clarity smart contracts. The system provides secure payment processing, rider management, and dispute resolution for delivery platforms.

## 📋 Features

### 🔒 Delivery Escrow Contract (`delivery-escrow.clar`)

**Core Functionality:**
- **Secure Escrow Payments**: Customers deposit funds into escrow before delivery begins
- **Order Lifecycle Management**: Complete order tracking from creation to completion
- **Automatic Payment Release**: Funds automatically released when delivery is confirmed
- **Dispute Resolution**: Built-in dispute handling with administrative oversight
- **Commission Management**: Automatic platform commission calculation and distribution

**Key Functions:**
- `create-order`: Create new delivery orders with escrow deposits
- `accept-order`: Riders accept available delivery orders
- `confirm-pickup`: Track item pickup confirmation
- `confirm-delivery`: Confirm delivery completion (customer or rider)
- `release-payment`: Automatic payment distribution to riders and platform
- `cancel-order`: Cancel orders before acceptance with automatic refunds
- `create-dispute`: Dispute resolution system for problematic orders

**Order Status Tracking:**
- `ORDER_CREATED` → `ORDER_ACCEPTED` → `ORDER_PICKED_UP` → `ORDER_DELIVERED` → `ORDER_COMPLETED`
- Alternative flows: `ORDER_CANCELLED` or `ORDER_DISPUTED`

### 👥 Rider Management Contract (`rider-management.clar`)

**Core Functionality:**
- **Rider Registration**: Complete rider onboarding and verification
- **Performance Tracking**: Comprehensive delivery performance metrics
- **Dynamic Commission Tiers**: Performance-based commission rates
- **Payment Distribution**: Automated payment processing with commission deduction
- **Availability Management**: Real-time rider availability and capacity tracking
- **Rating System**: Customer feedback and rating management

**Key Functions:**
- `register-rider`: New rider registration with profile setup
- `verify-rider`: Administrative rider verification process
- `set-availability`: Rider availability and capacity management
- `add-rider-rating`: Customer rating and review system
- `process-rider-payment`: Automated payment processing
- `set-commission-rate`: Platform commission rate management

**Commission Tier System:**
- **Standard Tier (u1)**: 0+ deliveries, 3.0+ rating → 15% commission
- **Gold Tier (u2)**: 20+ deliveries, 4.0+ rating → 10% commission, bonus eligible
- **Premium Tier (u3)**: 50+ deliveries, 4.5+ rating → 5% commission, bonus eligible

## 🛠️ Technical Implementation

### Architecture
- **Language**: Clarity smart contracts for Stacks blockchain
- **Testing Framework**: Clarinet with TypeScript support
- **CI/CD**: GitHub Actions for automated syntax checking
- **Version Control**: Git with feature branch workflow

### Data Structures
- **Order Management**: Comprehensive order tracking with timestamps
- **Rider Profiles**: Complete rider information and performance metrics
- **Payment Records**: Detailed payment history and commission tracking
- **Rating System**: Customer feedback with review storage
- **Dispute Records**: Structured dispute resolution tracking

### Security Features
- **Access Control**: Function-level authorization with role-based permissions
- **Input Validation**: Comprehensive parameter validation throughout
- **Error Handling**: Structured error codes with descriptive messages
- **State Management**: Consistent state transitions with validation
- **Commission Protection**: Automated commission calculation prevents manipulation

## 🔧 Development Setup

### Prerequisites
```bash
# Required tools
- Clarinet (Stacks smart contract development)
- Node.js (for testing framework)
- Git (version control)
```

### Installation & Testing
```bash
# Clone repository
git clone [repository-url]
cd riderpay

# Install dependencies
npm install

# Run contract syntax check
clarinet check

# Run tests
npm test
```

### Contract Deployment
```bash
# Local deployment for testing
clarinet deploy --local

# Testnet deployment
clarinet deploy --testnet
```

## 📊 Contract Statistics

### Delivery Escrow Contract
- **Lines of Code**: ~440 lines
- **Functions**: 15+ public/private functions
- **Data Maps**: 8 structured data storage maps
- **Error Codes**: 10 comprehensive error definitions
- **Constants**: Order status and platform settings

### Rider Management Contract  
- **Lines of Code**: ~490 lines
- **Functions**: 20+ public/private functions
- **Data Maps**: 10 structured data storage maps
- **Error Codes**: 10 comprehensive error definitions
- **Constants**: Rider status, rating, and commission settings

## 🔄 Development Workflow

### Branch Strategy
- `main`: Production-ready code
- `development`: Feature integration and testing
- `feature/*`: Individual feature development

### Continuous Integration
- **Automated Syntax Checking**: Every push triggers contract validation
- **Error Prevention**: Prevents merging code with syntax errors
- **Quality Assurance**: Maintains code quality standards

## 🧪 Quality Assurance

### Syntax Validation
- ✅ Both contracts pass `clarinet check` without errors
- ✅ Proper Clarity syntax and data structure validation
- ✅ Function signature and parameter validation
- ✅ Error handling and return type consistency

### Code Quality
- **Comprehensive Comments**: Detailed function and logic documentation  
- **Consistent Naming**: Clear, descriptive variable and function names
- **Modular Design**: Separated concerns between escrow and rider management
- **Error Handling**: Structured error codes with descriptive messages

## 🎯 Use Cases

### For Customers
1. **Safe Payments**: Escrow protection ensures payment only after delivery
2. **Order Tracking**: Complete visibility into delivery status
3. **Dispute Resolution**: Built-in protection for problematic deliveries
4. **Rating System**: Ability to rate and review delivery experiences

### For Riders
1. **Fair Compensation**: Performance-based commission tiers
2. **Payment Security**: Guaranteed payment upon delivery completion
3. **Performance Tracking**: Comprehensive metrics and improvement insights
4. **Flexible Availability**: Real-time capacity and schedule management

### For Platform Operators
1. **Commission Management**: Automated commission collection and rate adjustment
2. **Rider Verification**: Administrative tools for rider onboarding
3. **Dispute Resolution**: Tools for handling customer-rider disputes
4. **Analytics**: Comprehensive platform performance metrics

## 🔐 Security Considerations

### Access Control
- **Function-level Authorization**: Each function validates caller permissions
- **Role-based Security**: Different access levels for customers, riders, and admins
- **State Validation**: Consistent state transition validation

### Payment Security
- **Escrow Protection**: Customer funds held securely until delivery
- **Automatic Distribution**: Prevents manual payment manipulation
- **Commission Transparency**: Clear commission calculation and deduction

## 📈 Future Enhancements

### Potential Features
- **Multi-token Support**: Support for different payment tokens
- **Advanced Analytics**: Detailed performance dashboards
- **Integration APIs**: External platform integration capabilities
- **Mobile SDK**: Native mobile app integration
- **Real-time Tracking**: GPS integration for live delivery tracking

### Scalability Improvements
- **Batch Operations**: Support for bulk order processing
- **Optimization**: Gas cost optimization for high-volume usage
- **Caching**: Smart contract state caching for improved performance

## 📄 Documentation

### Contract Documentation
- **Function Specifications**: Detailed parameter and return documentation
- **Error Code Reference**: Comprehensive error handling guide
- **Data Structure Guide**: Complete data model documentation
- **Integration Examples**: Sample usage patterns and integration code

---

**Repository**: [GitHub Repository URL]
**Documentation**: Complete in-code documentation and README
**Testing**: Comprehensive test coverage with Clarinet framework
**CI/CD**: Automated quality assurance with GitHub Actions
