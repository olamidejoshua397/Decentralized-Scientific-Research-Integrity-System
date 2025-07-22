# Decentralized Scientific Research Integrity System

A comprehensive blockchain-based system designed to enhance transparency, accountability, and integrity in scientific research through five interconnected smart contracts.

## System Overview

This system addresses critical issues in modern scientific research including data manipulation, biased peer review, lack of replication incentives, funding conflicts of interest, and barriers to collaboration.

## Core Contracts

### 1. Research Data Immutability Contract (`research-data.clar`)
- **Purpose**: Prevents post-hoc data manipulation in scientific studies
- **Features**:
    - Immutable data storage with cryptographic hashing
    - Version control for research datasets
    - Timestamp verification for data submission
    - Access control for authorized researchers

### 2. Peer Review Transparency Contract (`peer-review.clar`)
- **Purpose**: Creates accountable peer review while maintaining reviewer anonymity
- **Features**:
    - Anonymous reviewer assignment system
    - Review quality scoring mechanism
    - Transparent review timeline tracking
    - Reviewer reputation management

### 3. Replication Study Coordination Contract (`replication-studies.clar`)
- **Purpose**: Incentivizes and tracks replication of important research findings
- **Features**:
    - Replication bounty system
    - Study priority ranking
    - Result verification mechanism
    - Reward distribution for successful replications

### 4. Research Funding Bias Detection Contract (`funding-bias.clar`)
- **Purpose**: Identifies potential conflicts of interest in research funding
- **Features**:
    - Funding source transparency tracking
    - Conflict of interest detection algorithms
    - Bias risk scoring system
    - Public disclosure requirements

### 5. Open Science Collaboration Contract (`collaboration.clar`)
- **Purpose**: Facilitates global scientific collaboration and data sharing
- **Features**:
    - Collaborative project management
    - Resource sharing mechanisms
    - Contribution tracking and attribution
    - Cross-institutional coordination

## Technical Architecture

### Data Structures
- **Research Records**: Immutable data entries with metadata
- **Review Records**: Anonymous review submissions with quality metrics
- **Replication Requests**: Bounty-based replication coordination
- **Funding Records**: Transparent funding source tracking
- **Collaboration Projects**: Multi-party research coordination

### Security Features
- Principal-based access control
- Cryptographic data integrity verification
- Time-locked data submission
- Multi-signature validation for critical operations

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js 18+ for testing
- Basic understanding of Clarity smart contracts

### Installation

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd scientific-research-integrity

# Install dependencies
npm install

# Run tests
npm test

# Deploy contracts (testnet)
clarinet deploy --testnet
\`\`\`

### Usage Examples

#### Submitting Research Data
\`\`\`clarity
(contract-call? .research-data submit-data
"study-001"
0x1234567890abcdef
"Clinical Trial Results - Phase II"
u1000)
\`\`\`

#### Requesting Peer Review
\`\`\`clarity
(contract-call? .peer-review request-review
"paper-001"
"Efficacy of Novel Treatment Protocol"
u3)
\`\`\`

#### Creating Replication Bounty
\`\`\`clarity
(contract-call? .replication-studies create-bounty
"study-001"
u50000
u30)
\`\`\`

## Contract Interactions

### Data Flow
1. **Research Submission**: Data submitted to immutability contract
2. **Peer Review**: Review requests processed through transparency contract
3. **Replication**: Important studies flagged for replication bounties
4. **Funding Tracking**: All funding sources recorded for bias detection
5. **Collaboration**: Multi-party projects coordinated through collaboration contract

### Error Handling
Each contract implements comprehensive error handling with descriptive error codes:
- `ERR-NOT-AUTHORIZED` (u100): Unauthorized access attempt
- `ERR-INVALID-INPUT` (u101): Invalid input parameters
- `ERR-ALREADY-EXISTS` (u102): Duplicate entry attempt
- `ERR-NOT-FOUND` (u103): Requested resource not found
- `ERR-INSUFFICIENT-FUNDS` (u104): Insufficient balance for operation

## Testing

The system includes comprehensive test coverage using Vitest:

\`\`\`bash
# Run all tests
npm test

# Run specific contract tests
npm test research-data
npm test peer-review
npm test replication-studies
npm test funding-bias
npm test collaboration
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or support, please open an issue in the repository.
