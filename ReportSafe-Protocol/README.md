# SecureWhistle: Decentralized Anonymous Reporting Platform

A blockchain-based platform enabling secure, anonymous whistleblowing with cryptographic privacy, community-driven verification, economic incentives, and transparent investigation tracking.

## Overview

SecureWhistle is a decentralized platform built on the Stacks blockchain that allows individuals to report misconduct across organizations and institutions while maintaining complete anonymity. The platform features community-driven verification, economic incentives for both reporters and verifiers, and transparent investigation tracking.

## Key Features

### Anonymous Identity Protection
- Cryptographically secure anonymous identity generation
- Optional anonymity for whistleblower protection
- Anonymous reporter activity tracking without compromising identity

### Community-Driven Verification
- Stake-based verification system requiring community consensus
- Reputation scoring for verifiers based on accuracy
- Voting power proportional to staked amount

### Economic Incentives
- Reward distribution based on recovered damages (10% default rate)
- Verifier stake requirements to ensure quality participation
- Platform treasury management for operational expenses

### Investigation Management
- Authorized investigator assignment system
- Progress tracking with documentation hashing
- Investigation phase status updates

### Decentralized Governance
- Administrator and investigator access control
- Community-based decision making for report verification
- Transparent case lifecycle management

## Contract Architecture

### Core Data Structures

#### Misconduct Reports
- Report metadata (organization, category, severity)
- Verification status and voting records
- Reward and compensation tracking
- Evidence collection management

#### Community Verifiers
- Stake deposit requirements (1,000,000 microSTX minimum)
- Reputation scoring system
- Participation history tracking

#### Investigation Cases
- Investigator assignment
- Progress phase documentation
- Case status management

### Error Handling

The contract implements comprehensive error handling with specific error codes:

- `ERR-UNAUTHORIZED-ACCESS` (u100): Access permission violations
- `ERR-INVALID-REPORT-DATA` (u101): Invalid report submission data
- `ERR-REPORT-NOT-FOUND` (u102): Non-existent report reference
- `ERR-ALREADY-VERIFIED` (u103): Attempt to re-verify verified report
- `ERR-INSUFFICIENT-STAKE-AMOUNT` (u104): Inadequate verifier stake
- `ERR-DUPLICATE-VOTE-DETECTED` (u105): Multiple voting attempts
- `ERR-VOTING-PERIOD-EXPIRED` (u106): Late voting submission
- `ERR-REPORT-UNVERIFIED` (u107): Action on unverified report
- `ERR-REWARD-ALREADY-CLAIMED` (u108): Duplicate reward claim
- `ERR-INVALID-EVIDENCE-FORMAT` (u109): Malformed evidence submission
- `ERR-CASE-PERMANENTLY-CLOSED` (u110): Action on closed case
- `ERR-INVALID-AMOUNT-VALUE` (u111): Invalid transaction amount
- `ERR-INVALID-ADDRESS-FORMAT` (u112): Malformed address format

## Platform Configuration

### Key Parameters
- **Verifier Stake Requirement**: 1,000,000 microSTX
- **Voting Duration**: 144 blocks (~24 hours)
- **Consensus Threshold**: 3 verification votes
- **Whistleblower Reward Rate**: 10% of recovered damages
- **Maximum Transaction Limit**: 1,000,000,000 microSTX

### Severity Levels
1. **Low Impact** (u1): Minor violations
2. **Medium Impact** (u2): Moderate violations
3. **High Impact** (u3): Serious violations
4. **Critical Impact** (u4): Severe violations requiring immediate attention

### Report Status Lifecycle
- **Pending** (u0): Initial submission state
- **Under Review** (u1): Community verification in progress
- **Verified** (u2): Community consensus achieved
- **Rejected** (u3): Community consensus against report
- **Closed** (u4): Investigation completed

## Core Functions

### Report Submission
```clarity
(create-misconduct-report target-organization violation-category impact-level evidence-hash description-hash enable-anonymity)
```
Submit a new misconduct report with optional anonymous protection.

### Evidence Management
```clarity
(add-supplementary-evidence report-id evidence-signature)
```
Add additional evidence to existing reports (up to 10 items per report).

### Community Verification
```clarity
(become-community-verifier)
```
Register as a community verifier by depositing the required stake.

```clarity
(cast-verification-vote report-id approve-report)
```
Cast verification votes on submitted reports.

### Investigation Management
```clarity
(delegate-investigation-case report-id investigator-address)
```
Assign verified cases to authorized investigators.

```clarity
(update-case-progress report-id phase-description documentation-hash)
```
Update investigation progress and documentation.

### Reward System
```clarity
(set-whistleblower-compensation report-id recovered-amount)
```
Establish reward amounts based on recovered damages.

```clarity
(claim-whistleblower-reward report-id)
```
Claim and distribute earned whistleblower rewards.

### Access Control
```clarity
(grant-investigator-access investigator-address)
(revoke-investigator-access investigator-address)
(grant-administrator-access admin-address)
```
Manage platform access permissions.

## Query Functions

### Report Information
- `fetch-report-details`: Get complete report information
- `fetch-evidence-collection`: Access report evidence collection
- `fetch-investigation-details`: Retrieve investigation case information

### User Profiles
- `fetch-verifier-profile`: Get verifier profile information
- `fetch-voting-record`: Check individual voting records
- `fetch-anonymous-statistics`: Access anonymous reporter statistics

### Platform Statistics
- `fetch-platform-metrics`: Get comprehensive platform statistics
- `verify-investigator-permissions`: Check investigator authorization
- `verify-administrator-permissions`: Check administrator authorization

### Utility Functions
- `calculate-reward-amount`: Calculate reward based on recovered funds
- `determine-voting-power`: Get voting power based on stake amount

## Security Features

### Data Validation
- Report parameter validation (organization name, category, severity)
- Evidence signature format validation
- Address format validation
- Amount bounds validation
- Report existence validation

### Access Control
- Role-based permission system
- Contract owner privileges
- Authorized investigator management
- Administrator access control

### Anonymous Identity Protection
- Cryptographic identity generation using SHA512
- Entropy from multiple sources (address, nonce, block height)
- Anonymous activity tracking without identity exposure

## Platform Treasury Management

The platform maintains a treasury funded by:
- Verifier stake deposits
- Direct platform funding contributions
- Operational reserves for reward distribution

Treasury functions include:
- Reward payment processing
- Emergency stake withdrawals
- Platform operational expenses

## Getting Started

### Prerequisites
- Stacks blockchain wallet
- Sufficient STX balance for transactions and stakes
- Basic understanding of smart contract interactions

### Deployment
1. Deploy the contract to Stacks blockchain
2. Initialize with contract owner having administrative privileges
3. Configure platform parameters as needed
4. Set up initial authorized investigators and administrators

### Usage Workflow

#### For Whistleblowers
1. Prepare evidence and documentation (hash-based)
2. Submit report using `create-misconduct-report`
3. Add supplementary evidence if needed
4. Monitor verification progress
5. Claim rewards after successful verification and investigation

#### For Community Verifiers
1. Deposit required stake using `become-community-verifier`
2. Review submitted reports
3. Cast verification votes using `cast-verification-vote`
4. Build reputation through accurate verification

#### For Investigators
1. Obtain investigator authorization from administrators
2. Accept case assignments from administrators
3. Update investigation progress regularly
4. Provide documentation for case progression

#### For Administrators
1. Manage investigator and administrator permissions
2. Assign cases to qualified investigators
3. Set compensation amounts based on recovered damages
4. Oversee platform operations and treasury management

## Development Considerations

### Testing
- Comprehensive unit testing for all contract functions
- Integration testing for complex workflows
- Security testing for access control and validation
- Performance testing for large-scale operations

### Monitoring
- Platform metrics tracking
- Treasury balance monitoring
- Verification accuracy assessment
- Investigation progress tracking

### Upgrades
- Smart contract immutability considerations
- Governance mechanisms for parameter updates
- Migration strategies for major updates