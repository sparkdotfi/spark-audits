                                                                Public




       SMART CONTRACT AUDIT REPORT
                        for


                Aave V3.0.1




                Prepared By: Xiaomi Huang

                       PeckShield
                   December 22, 2022



1/17                                PeckShield Audit Report #: 2022-416

                                                                                            Public



Document Properties

  Client            Aave
  Title             Smart Contract Audit Report
  Target            Aave V3.0.1
  Version           1.0
  Author            Stephen Bie
  Auditors          Stephen Bie, Xuxian Jiang
  Reviewed by       Xiaomi Huang
  Approved by       Xuxian Jiang
  Classification    Public




Version Info

 Version    Date                    Author(s)      Description
 1.0        December 22, 2022       Stephen Bie    Final Release
 1.0-rc     December 6, 2022        Stephen Bie    Release Candidate



Contact

For more information about this document and its contents, please contact PeckShield Inc.

 Name               Xiaomi Huang
 Phone              +86 183 5897 7782
 Email              contact@peckshield.com




2/17                                                       PeckShield Audit Report #: 2022-416

                                                                                                Public




                                            Contents



1 Introduction                                                                                        4
   1.1   About Aave V3.0.1 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       4
   1.2   About PeckShield . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      5
   1.3   Methodology . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     5
   1.4   Disclaimer . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    7

2 Findings                                                                                            10
   2.1   Summary . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 10
   2.2   Key Findings . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 11

3 Detailed Results                                                                                    12
   3.1   Improved Logic of LiquidationLogic::executeLiquidationCall() . . . . . . . . . . . . . 12
   3.2   Improved Event Generation in ScaledBalanceTokenBase::_transfer() . . . . . . . . . 14

4 Conclusion                                                                                          16

References                                                                                            17




3/17                                                           PeckShield Audit Report #: 2022-416

                                                                                               Public




1 | Introduction

Given the opportunity to review the design document and related smart contract source code of the
Aave V3.0.1 protocol, we outline in the report our systematic approach to evaluate potential security
issues in the smart contract implementation, expose possible semantic inconsistencies between smart
contract code and design document, and provide additional suggestions or recommendations for
improvement. Our results show that the given version of smart contracts is well designed and
engineered, though it can be further improved by addressing our suggestions. This document outlines
our audit results.


1.1     About Aave V3.0.1
Aave is a popular decentralized non-custodial liquidity protocol where users can participate as de-
positors or borrowers. Depositors provide liquidity to the market to earn a passive income, while
borrowers are able to borrow in an over-collateralized (perpetually) or under-collateralized (one-block
liquidity) fashion. Aave V3 protocol includes new features for new usage scenarios and improves earlier
versions on capital efficiency, security, decentralization, UX while at the same time providing new
functionalities to leverage the capabilities of rollups and the growing ecosystem of competing L1s.
The audited Aave V3.0.1 adds a variety of improvements and new minor features that the community
had identified valuable for the protocol (Please refer to Issue Comments Link for details).

                            Table 1.1: Basic Information of Aave V3.0.1

                                          Item     Description
                                          Name     Aave
                                        Website    https://aave.com/
                                           Type    EVM Smart Contract
                                       Platform    Solidity
                                  Audit Method     Whitebox
                            Latest Audit Report    December 22, 2022




4/17                                                           PeckShield Audit Report #: 2022-416

                                                                                                     Public


          In the following, we show the specific pull request and the commit hash value used in this audit.

          • https://github.com/aave/aave-v3-core/pull/701 (f8825f8)

          And this is the commit ID after all fixes for the issues found in the audit have been checked in:

          • https://github.com/aave/aave-v3-core/pull/701 (428e258)


1.2           About PeckShield
PeckShield Inc. [5] is a leading blockchain security company with the goal of elevating the secu-
rity, privacy, and usability of current blockchain ecosystems by offering top-notch, industry-leading
services and products (including the service of smart contract auditing). We are reachable at Telegram
(https://t.me/peckshield), Twitter (http://twitter.com/peckshield), or Email (contact@peckshield.com).


                                 Table 1.2: Vulnerability Severity Classification

             High               Critical                     High                       Medium
 Impact




            Medium                High                      Medium                       Low


              Low               Medium                        Low                        Low


                                  High                      Medium                       Low

                                                         Likelihood


1.3           Methodology
To standardize the evaluation, we define the following terminology based on the OWASP Risk Rating
Methodology [4]:

          • Likelihood represents how likely a particular vulnerability is to be uncovered and exploited in
            the wild;

          • Impact measures the technical loss and business damage of a successful attack;

          • Severity demonstrates the overall criticality of the risk.




5/17                                                                     PeckShield Audit Report #: 2022-416

                                                                                  Public




                        Table 1.3: The Full Audit Checklist

                Category                          Checklist Items
                                               Constructor Mismatch
                                                Ownership Takeover
                                            Redundant Fallback Function
                                              Overflows & Underflows
                                                      Reentrancy
                                                 Money-Giving Bug
                                                      Blackhole
                                             Unauthorized Self-Destruct
                                                     Revert DoS
           Basic Coding Bugs
                                              Unchecked External Call
                                                     Gasless Send
                                              Send Instead Of Transfer
                                                     Costly Loop
                                        (Unsafe) Use Of Untrusted Libraries
                                       (Unsafe) Use Of Predictable Variables
                                         Transaction Ordering Dependence
                                                   Deprecated Uses
       Semantic Consistency Checks          Semantic Consistency Checks
                                               Business Logics Review
                                                Functionality Checks
                                            Authentication Management
                                          Access Control & Authorization
                                                    Oracle Security
                                                Digital Asset Escrow
         Advanced DeFi Scrutiny
                                               Kill-Switch Mechanism
                                        Operation Trails & Event Generation
                                           ERC20 Idiosyncrasies Handling
                                           Frontend-Contract Integration
                                              Deployment Consistency
                                             Holistic Risk Management
                                        Avoiding Use of Variadic Byte Array
                                            Using Fixed Compiler Version
       Additional Recommendations          Making Visibility Level Explicit
                                          Making Type Inference Explicit
                                      Adhering To Function Declaration Strictly
                                          Following Other Best Practices




6/17                                                PeckShield Audit Report #: 2022-416

                                                                                                Public


    Likelihood and impact are categorized into three ratings: H, M and L, i.e., high, medium and
low respectively. Severity is determined by likelihood and impact and can be classified into four
categories accordingly, i.e., Critical, High, Medium, Low shown in Table 1.2.
    To evaluate the risk, we go through a checklist of items and each would be labeled with a
severity category. For one check item, if our tool or analysis does not identify any issue, the contract
is considered safe regarding the check item. For any discovered issue, we might further deploy
contracts on our private testnet and run tests to confirm the findings. If necessary, we would
additionally build a PoC to demonstrate the possibility of exploitation. The concrete list of check
items is shown in Table 1.3.
    In particular, we perform the audit according to the following procedure:

   • Basic Coding Bugs: We first statically analyze given smart contracts with our proprietary static
       code analyzer for known coding bugs, and then manually verify (reject or confirm) all the issues
       found by our tool.

   • Semantic Consistency Checks: We then manually check the logic of implemented smart con-
       tracts and compare with the description in the white paper.

   • Advanced DeFi Scrutiny: We further review business logics, examine system operations, and
       place DeFi-related aspects under scrutiny to uncover possible pitfalls and/or bugs.

   • Additional Recommendations: We also provide additional suggestions regarding the coding and
       development of smart contracts from the perspective of proven programming practices.

    To better describe each issue we identified, we categorize the findings with Common Weakness
Enumeration (CWE-699) [3], which is a community-developed list of software weakness types to
better delineate and organize weaknesses around concepts frequently encountered in software devel-
opment. Though some categories used in CWE-699 may not be relevant in smart contracts, we use
the CWE categories in Table 1.4 to classify our findings. Moreover, in case there is an issue that
may affect an active protocol that has been deployed, the public version of this report may omit
such issue, but will be amended with full details right after the affected protocol is upgraded with
respective fixes.


1.4      Disclaimer
Note that this security audit is not designed to replace functional tests required before any software
release, and does not give any warranties on finding all possible security issues of the given smart
contract(s) or blockchain software, i.e., the evaluation result does not guarantee the nonexistence
of any further findings of security issues. As one audit-based assessment cannot be considered



7/17                                                           PeckShield Audit Report #: 2022-416

                                                                                            Public




       Table 1.4: Common Weakness Enumeration (CWE) Classifications Used in This Audit

        Category                                               Summary
 Configuration                      Weaknesses in this category are typically introduced during
                                    the configuration of the software.
 Data Processing Issues             Weaknesses in this category are typically found in functional-
                                    ity that processes data.
 Numeric Errors                     Weaknesses in this category are related to improper calcula-
                                    tion or conversion of numbers.
 Security Features                  Weaknesses in this category are concerned with topics like
                                    authentication, access control, confidentiality, cryptography,
                                    and privilege management. (Software security is not security
                                    software.)
 Time and State                     Weaknesses in this category are related to the improper man-
                                    agement of time and state in an environment that supports
                                    simultaneous or near-simultaneous computation by multiple
                                    systems, processes, or threads.
 Error Conditions,                  Weaknesses in this category include weaknesses that occur if
 Return Values,                     a function does not generate the correct return/status code,
 Status Codes                       or if the application does not handle all possible return/status
                                    codes that could be generated by a function.
 Resource Management                Weaknesses in this category are related to improper manage-
                                    ment of system resources.
 Behavioral Issues                  Weaknesses in this category are related to unexpected behav-
                                    iors from code that an application uses.
 Business Logic                     Weaknesses in this category identify some of the underlying
                                    problems that commonly allow attackers to manipulate the
                                    business logic of an application. Errors in business logic can
                                    be devastating to an entire application.
 Initialization and Cleanup         Weaknesses in this category occur in behaviors that are used
                                    for initialization and breakdown.
 Arguments and Parameters           Weaknesses in this category are related to improper use of
                                    arguments or parameters within function calls.
 Expression Issues                  Weaknesses in this category are related to incorrectly written
                                    expressions within code.
 Coding Practices                   Weaknesses in this category are related to coding practices
                                    that are deemed unsafe and increase the chances that an ex-
                                    ploitable vulnerability will be present in the application. They
                                    may not directly introduce a vulnerability, but indicate the
                                    product has not been carefully developed or maintained.




8/17                                                       PeckShield Audit Report #: 2022-416

                                                                                            Public


comprehensive, we always recommend proceeding with several independent audits and a public bug
bounty program to ensure the security of smart contract(s). Last but not least, this security audit
should not be used as investment advice.




9/17                                                        PeckShield Audit Report #: 2022-416

                                                                                              Public




2 | Findings

2.1      Summary
Here is a summary of our findings after analyzing the design and implementation of the Aave V3.0.1
smart contracts. During the first phase of our audit, we study the smart contract source code and
run our in-house static code analyzer through the codebase. The purpose here is to statically identify
known coding bugs, and then manually verify (reject or confirm) issues reported by our tool. We
further manually review business logic, examine system operations, and place DeFi-related aspects
under scrutiny to uncover possible pitfalls and/or bugs.

 Severity                                                          # of Findings
 Critical                                         0
 High                                             0
 Medium                                           0
 Low                                              1
 Informational                                    1
 Total                                            2

We have previously audited the main Aave V3 protocol. In this report, we exclusively focus on the
specific pull request PR701. We examine a few identified issues of varying severities that need to be
brought up and paid more attention to. (The findings are categorized in the above table.) Additional
information can be found in the next subsection, and the detailed discussions are in Section 3.




10/17                                                         PeckShield Audit Report #: 2022-416

                                                                                                  Public


2.2      Key Findings
Overall, these smart contracts are well-designed and engineered, though the implementation can be
improved by resolving the identified issue(s) (shown in Table 2.1), including 1 low-severity vulnerability
and 1 informational recommendation.
                               Table 2.1: Key Aave V3.0.1 Audit Findings

   ID            Severity       Title                                          Category          Status
 PVE-001       Informational    Improved     Logic    of   Liquidation-     Coding Practices      Fixed
                                Logic::executeLiquidationCall()
 PVE-002           Low          Improved Event Generation in Scaled-        Coding Practices     Fixed
                                BalanceTokenBase::_transfer()


    Beside the identified issue(s), we emphasize that for any user-facing applications and services, it
is always important to develop necessary risk-control mechanisms and make contingency plans, which
may need to be exercised before the mainnet deployment. The risk-control mechanisms should kick
in at the very moment when the contracts are being deployed on mainnet. Please refer to Section 3
for details.




11/17                                                            PeckShield Audit Report #: 2022-416

                                                                                                                   Public




     3 | Detailed Results

     3.1       Improved Logic of
               LiquidationLogic::executeLiquidationCall()

        • ID: PVE-001                                                 • Target: LiquidationLogic
        • Severity: Informational                                     • Category: Coding Practices [2]
        • Likelihood: N/A                                             • CWE subcategory: CWE-628 [1]
        • Impact: N/A

     Description
     In the Aave V3 protocol, the LiquidationLogic library implements the liquidation-related logic. In
     particular, one entry routine, i.e., executeLiquidationCall(), is designed to liquidate a position if its
     Health Factor drops below 1.         The caller (i.e., liquidator) can gain the borrower’s collateral assets
     plus a bonus to cover the market risk via repaying the borrowed assets on behalf of the borrower.
     While examining its logic, we observe the current implementation can be improved.
        To elaborate, we show below the related code snippet of the executeLiquidationCall() routine.
     By design, if all the collateral assets of the borrower are liquidated, the borrower will not use this
     kind of assets as collateral anymore. Inside the executeLiquidationCall() routine, there are two
     implementations that meet the requirement (lines 106 and 133). The former does not consider
     the liquidation protocol fee (i.e., vars.liquidationProtocolFeeAmount) while the latter does. If we
     assume the vars.liquidationProtocolFeeAmount variable is 0 and the vars.actualCollateralToLiquidate
     variable is equal to vars.userCollateralBalance, the statement of userConfig.setUsingAsCollateral(
     collateralReserve.id, false) will be executed twice.             We believe the latter is necessary only when
     the vars.actualCollateralToLiquidate variable is not 0.
96         function e x e c u t e L i q u i d a t i o n C a l l (
97             mapping ( address = > DataTypes . ReserveData ) storage reservesData ,
98             mapping ( uint256 = > address ) storage reservesList ,
99             mapping ( address = > DataTypes . U s e r C o n f i g u r a t i o n M a p ) storage usersConfig ,




     12/17                                                                     PeckShield Audit Report #: 2022-416

                                                                                                                                                   Public


100           mapping ( uint8 = > DataTypes . EModeCategory ) storage eModeCategories ,
101           DataTypes . E x e c u t e L i q u i d a t i o n C a l l P a r a m s memory params
102       ) external {
103           ...
104           // If the collateral being liquidated is equal to the user balance ,
105           // we set the currency as not being used as collateral anymore
106           if ( vars . a c t u a l C o l l a t e r a l T o L i q u i d a t e == vars . u s e r C o l l a t e r a l B a l a n c e ) {
107                userConfig . s e t U s i n g A s C o l l a t e r a l ( c o l l a t e r a l R e s e r v e . id , false ) ;
108                emit R e s e r v e U s e d A s C o l l a t e r a l D i s a b l e d ( params . collateralAsset , params . user ) ;
109           }
110
111             ...
112
113             // Transfer fee to treasury if it is non - zero
114             if ( vars . l i q u i d a t i o n P r o t o c o l F e e A m o u n t != 0) {
115                  uint256 li quidit yIndex = c o l l a t e r a l R e s e r v e . g e t N o r m a l i z e d I n c o m e () ;
116                  uint256 s c a l e d D o w n L i q u i d a t i o n P r o t o c o l F e e = vars . l i q u i d a t i o n P r o t o c o l F e e A m o u n t
                          . rayDiv (
117                       liq uidity Index
118                  );
119                  uint256 s c a l e d D o w n U s e r B a l a n c e = vars . c o l l a t e r a l A T o k e n . s c al ed B al an c eO f ( params
                          . user ) ;
120                  // To avoid trying to send more aTokens than available on balance , due to 1
                          wei imprecision
121                  if ( s c a l e d D o w n L i q u i d a t i o n P r o t o c o l F e e > s c a l e d D o w n U s e r B a l a n c e ) {
122                       vars . l i q u i d a t i o n P r o t o c o l F e e A m o u n t = s c a l e d D o w n U s e r B a l a n c e . rayMul (
                                  liqu idityI ndex ) ;
123                  }
124                  vars . c o l l a t e r a l A T o k e n . t r a n s f e r O n L i q u i d a t i o n (
125                       params . user ,
126                       vars . c o l l a t e r a l A T o k e n . R E S E R V E _ T R E A S U R Y _ A D D R E S S () ,
127                       vars . l i q u i d a t i o n P r o t o c o l F e e A m o u n t
128                  );
129             }
130
131             // If the collateral being liquidated is equal to the user balance ,
132             // we set the currency as not being used as collateral anymore
133             if ( vars . a c t u a l C o l l a t e r a l T o L i q u i d a t e + vars . l i q u i d a t i o n P r o t o c o l F e e A m o u n t == vars
                    . userCollateralBalance ) {
134                  userConfig . s e t U s i n g A s C o l l a t e r a l ( c o l l a t e r a l R e s e r v e . id , false ) ;
135                  emit R e s e r v e U s e d A s C o l l a t e r a l D i s a b l e d ( params . collateralAsset , params . user ) ;
136             }
137             ...
138       }

                                      Listing 3.1:         LiquidationLogic::executeLiquidationCall()



         Recommendation                    Improve the implementation of the executeLiquidationCall() routine as
      above-mentioned for gas optimization.

         Status The issue has been addressed by the following commit: 56bcf5d.



      13/17                                                                                       PeckShield Audit Report #: 2022-416

                                                                                                                                             Public


      3.2      Improved Event Generation in
               ScaledBalanceTokenBase::_transfer()

         • ID: PVE-002                                                             • Target: ScaledBalanceTokenBase
         • Severity: Low                                                           • Category: Coding Practices [2]
         • Likelihood: Low                                                         • CWE subcategory: CWE-628 [1]
         • Impact: Low

      Description
      In the Aave V3 protocol, the balance of the depositor’s AToken is constantly increasing as the interest
      accrues. To accommodate the ever-changing indexes in the lending pool, the AToken should internally
      keep the scaled balance. The ScaledBalanceTokenBase contract is designed to meet the requirement.
      In particular, one entry routine, i.e., _transfer(), is designed to transfer the scaled balance between
      the sender and the recipient. While examining its logic, we observe its current implementation can
      be improved.
         To elaborate, we show below the related code snippet of the ScaledBalanceTokenBase() contract.
      As mentioned above, the balance of the user’s AToken is constantly increasing as the interest accrues.
      Inside the _transfer() routine, the increased balances of the sender (line 145) and the recipient
      (line 149) are calculated separately, while the corresponding Transfer and Mint events are emitted
      according to the ERC20 specification. However, we observe there is a corner case (i.e., sender ==
       recipient) where the Transfer and Mint events are emitted repeatedly.                                     Given this, it’s better to
      handle the corner case to avoid emitting the same events twice.
138       function _transfer (
139           address sender ,
140           address recipient ,
141           uint256 amount ,
142           uint256 index
143       ) internal {
144           uint256 s e n d e r S c a l e d B a l a n c e = super . balanceOf ( sender ) ;
145           uint256 s e n d e r B a l a n c e I n c r e a s e = s e n d e r S c a l e d B a l a n c e . rayMul ( index ) -
146           s e n d e r S c a l e d B a l a n c e . rayMul ( _userState [ sender ]. addit ionalD ata ) ;
147
148             uint256 r e c i p i e n t S c a l e d B a l a n c e = super . balanceOf ( recipient ) ;
149             uint256 r e c i p i e n t B a l a n c e I n c r e a s e = r e c i p i e n t S c a l e d B a l a n c e . rayMul ( index ) -
150             r e c i p i e n t S c a l e d B a l a n c e . rayMul ( _userState [ recipient ]. a dditio nalDat a ) ;
151
152             _userState [ sender ]. ad dition alData = index . toUint128 () ;
153             _userState [ recipient ]. add itiona lData = index . toUint12 8 () ;
154
155             super . _transfer ( sender , recipient , amount . rayDiv ( index ) . toUint128 () ) ;
156



      14/17                                                                                  PeckShield Audit Report #: 2022-416

                                                                                                                   Public


157           if ( s e n d e r B a l a n c e I n c r e a s e > 0) {
158                emit Transfer ( address (0) , sender , s e n d e r B a l a n c e I n c r e a s e ) ;
159                emit Mint ( _msgSender () , sender , senderBalanceIncrease , senderBalanceIncrease
                          , index ) ;
160           }
161
162           if ( r e c i p i e n t B a l a n c e I n c r e a s e > 0) {
163                emit Transfer ( address (0) , recipient , r e c i p i e n t B a l a n c e I n c r e a s e ) ;
164                emit Mint ( _msgSender () , recipient , recipientBalanceIncreas e ,
                           recipientBalanceIncrease , index ) ;
165           }
166
167           emit Transfer ( sender , recipient , amount ) ;
168      }

                                     Listing 3.2:     ScaledBalanceTokenBase::_transfer()



         Recommendation Accommodate the corner case to avoid emitting the same events repeatedly.

         Status The issue has been addressed by the following commit: 4449676.




      15/17                                                                       PeckShield Audit Report #: 2022-416

                                                                                             Public




4 | Conclusion

In this audit, we have analyzed the Aave V3.0.1 implementation, which adds a variety of improvements
and new minor features that the community had identified valuable for Aave V3 (Please refer to Issue
 Comments Link for details).   The current code base is well structured and neatly organized. Those
identified issues are promptly confirmed and addressed.
   Moreover, we need to emphasize that Solidity-based smart contracts as a whole are still in
an early, but exciting stage of development. To improve this report, we greatly appreciate any
constructive feedbacks or suggestions, on our methodology, audit findings, or potential gaps in
scope/coverage.




16/17                                                         PeckShield Audit Report #: 2022-416

                                                                                       Public




References

[1] MITRE. CWE-628: Function Call with Incorrectly Specified Arguments. https://cwe.mitre.org/

   data/definitions/628.html.

[2] MITRE. CWE CATEGORY: Bad Coding Practices. https://cwe.mitre.org/data/definitions/

   1006.html.

[3] MITRE. CWE VIEW: Development Concepts. https://cwe.mitre.org/data/definitions/699.html.

[4] OWASP. Risk Rating Methodology. https://www.owasp.org/index.php/OWASP_Risk_Rating_

   Methodology.

[5] PeckShield. PeckShield Inc. https://www.peckshield.com.




17/17                                                     PeckShield Audit Report #: 2022-416

