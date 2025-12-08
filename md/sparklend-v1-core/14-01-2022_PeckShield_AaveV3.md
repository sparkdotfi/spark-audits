                                                               Public




       SMART CONTRACT AUDIT REPORT
                       for


                 Aave V3




                Prepared By: Yiqun Chen

                      PeckShield
                   January 10, 2022



1/31                               PeckShield Audit Report #: 2021-373

                                                                                            Public



Document Properties

  Client            Aave
  Title             Smart Contract Audit Report
  Target            Aave V3
  Version           1.0
  Author            Xuxian Jiang
  Auditors          Patrick Liu, Stephen Bie, Jing Wang, Xuxian Jiang
  Reviewed by       Yiqun Chen
  Approved by       Xuxian Jiang
  Classification    Public




Version Info

 Version    Date                    Author(s)       Description
 1.0        January 10, 2022        Xuxian Jiang    Final Release
 1.0-rc     November 20, 2021       Xuxian Jiang    Release Candidate #1




Contact

For more information about this document and its contents, please contact PeckShield Inc.

 Name               Yiqun Chen
 Phone              +86 183 5897 7782
 Email              contact@peckshield.com




2/31                                                       PeckShield Audit Report #: 2021-373

                                                                                                Public




                                            Contents



1 Introduction                                                                                        4
   1.1   About Aave V3 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       4
   1.2   About PeckShield . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      5
   1.3   Methodology . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     5
   1.4   Disclaimer . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    7

2 Findings                                                                                            10
   2.1   Summary . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 10
   2.2   Key Findings . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 11

3 Detailed Results                                                                                    12
   3.1   Suggested Constant/Immutable Usages For Gas Efficiency . . . . . . . . . . . . . . . 12
   3.2   Improved Logic of Pool::_addReserveToList() . . . . . . . . . . . . . . . . . . . . . 13
   3.3   Proper And Consistent Collateral Enabling . . . . . . . . . . . . . . . . . . . . . . . 14
   3.4   Improvement on UserConfiguration::_getFirstAssetAsCollateralId() . . . . . . . . . . 16
   3.5   Redundant State/Code Removal . . . . . . . . . . . . . . . . . . . . . . . . . . . . 18
   3.6   Proper Asset Price in GenericLogic::calculateUserAccountData() . . . . . . . . . . . 19
   3.7   Proper EMode Category Use in Pool::borrow() . . . . . . . . . . . . . . . . . . . . . 21
   3.8   Possible Underflow Avoidance in BorrowLogic And UserConfiguration . . . . . . . . . 22
   3.9   Consistent Reserve Cache Use in rebalanceStableBorrowRate() . . . . . . . . . . . . 23
   3.10 Health Validation in EModeLogic::executeSetUserEMode() . . . . . . . . . . . . . . 25
   3.11 Potential Reentrancy Risk in flashLoanSimple() . . . . . . . . . . . . . . . . . . . . 26

4 Conclusion                                                                                          29

References                                                                                            30




3/31                                                           PeckShield Audit Report #: 2021-373

                                                                                               Public




1 | Introduction

Given the opportunity to review the design document and related smart contract source code of
the Aave V3 protocol, we outline in the report our systematic approach to evaluate potential security
issues in the smart contract implementation, expose possible semantic inconsistencies between smart
contract code and design document, and provide additional suggestions or recommendations for
improvement. Our results show that the given version of smart contracts can be further improved
due to the presence of several issues related to either security or performance. This document outlines
our audit results.


1.1     About Aave V3
Aave is a popular decentralized non-custodial money market protocol where users can participate as
depositors or borrowers. Depositors provide liquidity to the market to earn a passive income, while
borrowers are able to borrow in an over-collateralized (perpetually) or under-collateralized (one-block
liquidity) fashion. The audited Aave V3 protocol includes new features for new usage scenarios and
improves earlier versions on capital efficiency, security, decentralization, UX while at the same time
providing new functionalities to leverage the capabilities of rollups and the growing ecosystem of
competing L1s. The basic information of Aave V3 is as follows:

                              Table 1.1: Basic Information of Aave V3

                                       Item      Description
                                       Name      Aave
                                     Website     https://aave.com/
                                        Type     Ethereum Smart Contract
                                    Platform     Solidity
                               Audit Method      Whitebox
                         Latest Audit Report     January 10, 2022


   In the following, we show the Git repository of reviewed files and the commit hash value used in



4/31                                                           PeckShield Audit Report #: 2021-373

                                                                                                     Public


this audit.

          • https://github.com/aave/aave-v3-core.git (14f6148)

          And this is the commit ID after all fixes for the issues found in the audit have been checked in:

          • https://github.com/aave/aave-v3-core.git (c71d57d)


1.2           About PeckShield
PeckShield Inc. [13] is a leading blockchain security company with the goal of elevating the secu-
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
Methodology [12]:

          • Likelihood represents how likely a particular vulnerability is to be uncovered and exploited in
            the wild;

          • Impact measures the technical loss and business damage of a successful attack;

          • Severity demonstrates the overall criticality of the risk.




5/31                                                                     PeckShield Audit Report #: 2021-373

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




6/31                                                PeckShield Audit Report #: 2021-373

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
Enumeration (CWE-699) [11], which is a community-developed list of software weakness types to
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



7/31                                                           PeckShield Audit Report #: 2021-373

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




8/31                                                       PeckShield Audit Report #: 2021-373

                                                                                            Public


comprehensive, we always recommend proceeding with several independent audits and a public bug
bounty program to ensure the security of smart contract(s). Last but not least, this security audit
should not be used as investment advice.




9/31                                                        PeckShield Audit Report #: 2021-373

                                                                                                 Public




2 | Findings

2.1      Summary
Here is a summary of our findings after analyzing the implementation of the Aave V3 protocol. During
the first phase of our audit, we study the smart contract source code and run our in-house static
code analyzer through the codebase. The purpose here is to statically identify known coding bugs,
and then manually verify (reject or confirm) issues reported by our tool. We further manually review
business logic, examine system operations, and place DeFi-related aspects under scrutiny to uncover
possible pitfalls and/or bugs.

 Severity                                                            # of Findings
 Critical                                           0
 High                                               2
 Medium                                             3
 Low                                                4
 Informational                                      2
 Total                                             11


We have so far identified a list of potential issues: some of them involve subtle corner cases that might
not be previously thought of, while others refer to unusual interactions among multiple contracts.
For each uncovered issue, we have therefore developed test cases for reasoning, reproduction, and/or
verification. After further analysis and internal discussion, we determined a few issues of varying
severities need to be brought up and paid more attention to, which are categorized in the above
table. More information can be found in the next subsection, and the detailed discussions of each of
them are in Section 3.




10/31                                                           PeckShield Audit Report #: 2021-373

                                                                                                Public


2.2        Key Findings
Overall, these smart contracts are well-designed and engineered, though the implementation can be
improved by resolving the identified issues (shown in Table 2.1), including 2 high-severity vulnerabil-
ities, 3 medium-severity vulnerabilities, 4 low-severity vulnerabilities, and 2 informational recommen-
dations.
                               Table 2.1: Key Aave V3 Audit Findings

   ID            Severity      Title                                       Category            Status
 PVE-001       Informational   Suggested immutable For Gas Effi-         Coding Practice        Fixed
                               ciency
 PVE-002         Medium        Improved Logic of Pool::_addReserve-       Business Logic        Fixed
                               ToList()
 PVE-003         Medium        Proper And Consistent Collateral En-       Business Logic        Fixed
                               abling
 PVE-004           Low         Improvement      on    UserConfigura-     Coding Practice        Fixed
                               tion::_getFirstAssetAsCollateralId()
 PVE-005       Informational   Redundant State/Code Removal              Coding Practice        Fixed
 PVE-006            High       Proper Asset Price in Generi-             Business Logic         Fixed
                               cLogic::calculateUserAccountData()
 PVE-007         Medium        Proper EMode Category Use in               Business Logic        Fixed
                               Pool::borrow()
 PVE-008           Low         Possible Underflow Avoidance in Bor-      Coding Practices    Confirmed
                               rowLogic And UserConfiguration
 PVE-009           Low         Consistent Reserve Cache Use in rebal-    Coding Practice        Fixed
                               anceStableBorrowRate()
 PVE-010           Low         Health Validation in EModeL-               Business Logic        Fixed
                               ogic::executeSetUserEMode()
 PVE-011           High        Potential    Reentrancy     Risk     in   Time and State         Fixed
                               flashLoanSimple()



    Beside the identified issues, we emphasize that for any user-facing applications and services, it is
always important to develop necessary risk-control mechanisms and make contingency plans, which
may need to be exercised before the mainnet deployment. The risk-control mechanisms should kick
in at the very moment when the contracts are being deployed on mainnet. Please refer to Section 3
for details.




11/31                                                           PeckShield Audit Report #: 2021-373

                                                                                                                               Public




     3 | Detailed Results

     3.1         Suggested Constant/Immutable Usages For Gas Efficiency

          • ID: PVE-001                                                               • Target: Multiple Contracts
          • Severity: Informational                                                   • Category: Coding Practices [8]
          • Likelihood: N/A                                                           • CWE subcategory: CWE-1099 [2]
          • Impact: N/A

     Description
     Since version 0.6.5, Solidity introduces the feature of declaring a state as immutable. An immutable
     state variable can only be assigned during contract creation, but will remain constant throughout the
     life-time of a deployed contract. The main benefit of declaring a state as immutable is that reading
     the state is significantly cheaper than reading from regular storage, since it is not stored in storage
     anymore. Instead, an immutable state will be directly inserted into the runtime code.
          This feature is introduced based on the observation that the reading and writing of storage-based
     contract states are gas-expensive. Therefore, it is always preferred if we can reduce, if not eliminate,
     storage reading and writing as much as possible. Those state variables that are written only once
     are candidates of immutable states under the condition that each fits the pattern, i.e., “a constant,
     once assigned in the constructor, is read-only during the subsequent operation.”
          In the following, we show a number of key state variables defined in PriceOracleSentinel, including
     _addressesProvider, _oracle, and _gracePeriod. If there is no need to dynamically update these state
     variables, they can be declared as either constants or immutable for gas efficiency. In particular, the
     above three states can be defined as immutable.
14   contract P r i c e O r a c l e S e n t i n e l is I P r i c e O r a c l e S e n t i n e l {
15     I P o o l A d d r e s s e s P r o v i d e r public _ a d d r e s s e s P r o v i d e r ;
16     I S e q u e n c e r O r a c l e public _oracle ;
17     uint256 public _gracePeriod ;
18     ...




     12/31                                                                                         PeckShield Audit Report #: 2021-373

                                                                                                                          Public


19     }

                                         Listing 3.1: The PriceOracleSentinel Contract

            Similarly, the _addressesProvider state in AaveOracle and ACLManager can be defined as immutable
      for gas efficiency.

            Recommendation              Revisit the state variable definition and make extensive use of constant/
      immutable states.

            Status The issue has been fixed by the following PR: 214.


      3.2         Improved Logic of Pool::_addReserveToList()

      • ID: PVE-002                                                     • Target: Pool
      • Severity: Medium                                                • Category: Business Logic [9]
      • Likelihood: Medium
                                                                        • CWE subcategory: CWE-837 [6]
      • Impact: Low
      Description
      The Aave protocol allows the governance to dynamically add new reserves into the protocol. To keep
      track of the list of active reserves, the protocol maintains the internal state _reservesList. While
      reviewing the accounting of active reserves, we notice the internal routine to add a new reserve needs
      to be improved.
            To elaborate, we show below the _addReserveToList() function. It implements a rather straight-
      forward logic in validating the new asset and then adding it into the internal _reservesList. It comes
      to our attention that the internal for-loop needs to terminate the execution once a vacant spot is
      located and populated. Note the current implementation will simply fill all available slots with the
      new reserve asset.
703        function _ a d d R e s e r v e T o L i s t ( address asset ) internal {
704          uint256 reservesCount = _ reserv esCoun t ;
705
706          require ( reservesCount < _maxNumberOfReserves , Errors . P _ N O _ M O R E _ R E S E R V E S _ A L L O W E D ) ;
707
708          bool r e s e r v e A l r e a d y A d d e d = _reserves [ asset ]. id != 0   _reserves List [0] == asset ;
709
710          if (! r e s e r v e A l r e a d y A d d e d ) {
711            for ( uint8 i = 0; i <= reservesCount ; i ++) {
712              if ( _reservesList [ i ] == address (0) ) {
713                  _reserves [ asset ]. id = i ;
714                  _reservesList [ i ] = asset ;
715                  _res ervesC ount = reservesCount + 1;




      13/31                                                                          PeckShield Audit Report #: 2021-373

                                                                                                                       Public


716                 }
717             }
718         }
719     }

                                             Listing 3.2:     Pool::_addReserveToList()



            Recommendation Revise the above _addReserveToList() function to proper add a new reserve
      asset.

            Status The issue has been fixed by the following PR: 196.


      3.3           Proper And Consistent Collateral Enabling

      • ID: PVE-003                                                  • Target: Multiple Contracts
      • Severity: Medium                                             • Category: Business Logic [9]
      • Likelihood: Medium
                                                                     • CWE subcategory: CWE-837 [6]
      • Impact: Low
      Description
      The Aave protocol supports dynamic updates on the set of assets that are considered as collateral.
      This is important as these collateral assets directly determine the borrowing power of the respective
      users. In addition, these collateral assets have profound implications on the new features on eMode and
      isolation mode. While reviewing the logic to enable a collateral, we observe unnecessary inconsistency
      that may introduce unwanted confusion and errors.
            To elaborate, we show below the executeSupply() function from the SupplyLogic library. To turn
      on the collateral, the logic requires (!isolationModeActive && (reserveCache.reserveConfiguration.
      getDebtCeiling()== 0)) or !userConfig.isUsingAsCollateralAny() (lines 72 − 73).

46      function executeSupply (
47        mapping ( address = > DataTypes . ReserveData ) storage reserves ,
48        mapping ( uint256 = > address ) storage reservesList ,
49        DataTypes . U s e r C o n f i g u r a t i o n M a p storage userConfig ,
50        DataTypes . E x e c u t e S u p p l y P a r a m s memory params
51      ) external {
52        DataTypes . ReserveData storage reserve = reserves [ params . asset ];
53        DataTypes . ReserveCache memory reserveCache = reserve . cache () ;
54
55          reserve . updateState ( reserveCache ) ;
56
57          V al id a ti on L og i c . valida teSupp ly ( reserveCache , params . amount ) ;
58
59          reserve . u p d a t e I n t e r e s t R a t e s ( reserveCache , params . asset , params . amount , 0) ;




      14/31                                                                        PeckShield Audit Report #: 2021-373

                                                                                                                                          Public


60
61         IERC20 ( params . asset ) . s a f e T r a n s f e r F r o m ( msg . sender , reserveCache . aTokenAddress , params
               . amount ) ;
62
63         bool isFirstSupply = IAToken ( reserveCache . aTokenAddress ) . mint (
64            params . onBehalfOf ,
65            params . amount ,
66            reserveCache . n e x t L i q u i d i t y I n d e x
67         );
68
69         if ( isFirstSupply ) {
70           ( bool isolationModeActive , , ) = userConfig . g e t I s o l a t i o n M o d e S t a t e ( reserves ,
                  reservesList ) ;
71           if (
72              ((! i s o l a t i o n M o d e A c t i v e && ( reserveCache . r e s e r v e C o n f i g u r a t i o n . getDe btCeil ing () ==
                       0) )
73                ! userConfig . i s U s i n g A s C o l l a t e r a l A n y () )
74           ) {
75              userConfig . s e t U s i n g A s C o l l a t e r a l ( reserve . id , true ) ;
76              emit R e s e r v e U s e d A s C o l l a t e r a l E n a b l e d ( params . asset , params . onBehalfOf ) ;
77           }
78         }
79
80         emit Supply ( params . asset , msg . sender , params . onBehalfOf , params . amount , params .
               referralCode ) ;
81     }

                                               Listing 3.3:       SupplyLogic::executeSupply()


           However, if we examine another function mintUnbacked() from the BorrowLogic library, the logic
     simply requires it is the isFirstSupply. The inconsistency on the same collateral-enabling logic
     among current libraries SupplyLogic, BridgeLogic, and LiquidationLogic needs to be resolved before
     production deployment.
47     function mintUnbacked (
48       DataTypes . ReserveData storage reserve ,
49       DataTypes . U s e r C o n f i g u r a t i o n M a p storage userConfig ,
50       address asset ,
51       uint256 amount ,
52       address onBehalfOf ,
53       uint16 referralCode
54     ) external {
55       DataTypes . ReserveCache memory reserveCache = reserve . cache () ;
56
57         reserve . updateState ( reserveCache ) ;
58
59         V al id a ti on L og i c . valida teSupp ly ( reserveCache , amount ) ;
60
61         uint256 un b ac ke d Mi nt C ap = reserveCache . r e s e r v e C o n f i g u r a t i o n . g e t U n b a c k e d M i n t C a p () ;
62         uint256 re s er ve D ec im a ls = reserveCache . r e s e r v e C o n f i g u r a t i o n . g etDecimals () ;
63
64         uint256 unbacked = reserve . unbacked = reserve . unbacked + Helpers . castUint128 ( amount )




     15/31                                                                                  PeckShield Audit Report #: 2021-373

                                                                                                                       Public


                 ;
65
66         require (
67            u nb ac k ed M in tC a p > 0 && unbacked / (10** r e se rv e De ci m al s ) < unbackedMintCap ,
68            Errors . V L _ U N B A C K E D _ M I N T _ C A P _ E X C E E D E D
69         );
70
71         reserve . u p d a t e I n t e r e s t R a t e s ( reserveCache , asset , 0 , 0) ;
72
73         bool isFirstSupply = IAToken ( reserveCache . aTokenAddress ) . mint (
74            onBehalfOf ,
75            amount ,
76            reserveCache . n e x t L i q u i d i t y I n d e x
77         );
78
79         if ( isFirstSupply ) {
80           userConfig . s e t U s i n g A s C o l l a t e r a l ( reserve . id , true ) ;
81           emit R e s e r v e U s e d A s C o l l a t e r a l E n a b l e d ( asset , onBehalfOf ) ;
82         }
83
84         emit MintUnbacked ( asset , msg . sender , onBehalfOf , amount , referralCode ) ;
85     }
86     }

                                                Listing 3.4:      BridgeLogic::mintUnbacked()



           Recommendation               Revise the above functions to be consistent on the enabling of a specific
     asset as collateral.

           Status The issue has been fixed by the following PR: 256.


     3.4        Improvement on
                UserConfiguration::_getFirstAssetAsCollateralId()

           • ID: PVE-004                                                          • Target: UserConfiguration
           • Severity: Low                                                        • Category: Business Logic [9]
           • Likelihood: Low                                                      • CWE subcategory: CWE-841 [7]
           • Impact: Low

     Description
     The Aave protocol has a flexible mechanism to keep track of the configuration of current protocol
     users. This mechanism is mainly implemented in the UserConfiguration contract. In the process of
     reviewing this contract, we notice an internal helper function can be simplified.



     16/31                                                                                 PeckShield Audit Report #: 2021-373

                                                                                                                                           Public


            To elaborate, we show below this helper routine, i.e., _getFirstAssetAsCollateralId(). As the
      name indicates, this routine is designed to return the address of the first asset used as collateral by
      the user. It turns out the collateralData & ~(collateralData - 1) computation is unnecessary and
      the step size of 2 can be avoided as well.
197     function _ g e t F i r s t A s s e t A s C o l l a t e r a l I d ( DataTypes . U s e r C o n f i g u r a t i o n M a p memory self )
198       internal
199       pure
200       returns ( uint256 )
201     {
202       unchecked {
203         uint256 c ollate ralDat a = self . data & C O LL AT E RA L _M AS K ;
204         uint256 f i r s t C o l l a t e r a l P o s i t i o n = col latera lData & ~( coll ateral Data - 1) ;
205         uint256 id ;

207             while (( f i r s t C o l l a t e r a l P o s i t i o n > >= 2) > 0) {
208               id += 2;
209             }
210             return id / 2;
211         }
212     }

                                  Listing 3.5:       UserConfiguration::_getFirstAssetAsCollateralId()



            Recommendation Simplify the above routine as the follows:
197     function _ g e t F i r s t A s s e t A s C o l l a t e r a l I d ( DataTypes . U s e r C o n f i g u r a t i o n M a p memory self )
198       internal
199       pure
200       returns ( uint256 )
201     {
202         uint256 c ollate ralDat a = self . data & C O LL AT E RA L _M AS K ;
203         uint256 id ;

205             while (( colla teralD ata > >= 2) > 0) {
206               id += 1;
207             }
208             return id ;
209     }

                                  Listing 3.6:       UserConfiguration::_getFirstAssetAsCollateralId()



            Status The issue has been fixed by the following PR: 261.




      17/31                                                                                  PeckShield Audit Report #: 2021-373

                                                                                                                  Public


      3.5        Redundant State/Code Removal

      • ID: PVE-005                                                          • Target: Multiple Contracts
      • Severity: Informational                                              • Category: Coding Practices [8]
      • Likelihood: N/A                                                      • CWE subcategory: CWE-563 [4]
      • Impact: N/A

      Description
      The Aave protocol makes good use of a number of reference contracts, such as ERC20, SafeERC20,
      SafeMath, and Address, to facilitate its code implementation and organization. For example, the Pool
      smart contract has so far imported at least five reference contracts. However, we observe the inclusion
      of certain unused code or the presence of unnecessary redundancies that can be safely removed.
          For example, if we examine closely the ReserveLogic library, there is an AccrueToTreasuryLocalVars
       structure with a number of member fields that are defined, but not used. Examples include the
      avgStableRate and stableSupplyUpdatedTimestamp fields. Also, another structure UpdateInterestRatesLocalVars
      defines an unused member field avgStableRate.
213     struct A c c r u e T o T r e a s u r y L o c a l V a r s {
214       uint256 p r e v T o t a l S t a b l e D e b t ;
215       uint256 p r e v T o t a l V a r i a b l e D e b t ;
216       uint256 c u r r T o t a l V a r i a b l e D e b t ;
217       uint256 avgStableRate ;
218       uint256 c u m u l a t e d S t a b l e I n t e r e s t ;
219       uint256 t o t a l D e b t A c c r u e d ;
220       uint256 amountToMint ;
221       uint40 s t a b l e S u p p l y U p d a t e d T i m e s t a m p ;
222     }

                                                     Listing 3.7: The ReserveLogic Library

          Recommendation                    Consider the removal of the redundant state (or code) with a simplified,
      consistent implementation.

          Status The issue has been fixed by the following PR: 212.




      18/31                                                                           PeckShield Audit Report #: 2021-373

                                                                                                                        Public


     3.6        Proper Asset Price in
                GenericLogic::calculateUserAccountData()

     • ID: PVE-006                                                                 • Target: GenericLogic
     • Severity: High                                                              • Category: Coding Practices [8]
     • Likelihood: High                                                            • CWE subcategory: CWE-563 [4]
     • Impact: High

     Description
     For any lending protocol, there is a need to reliably and accurately measure the borrower’s debt
     position and provide necessary means to liquidate underwater positions. The Aave protocol is no
     exception. While reviewing the implementation to measure the debt position, we notice the key
     function calculateUserAccountData() needs to be improved.
        To illustrate, we show below this function. As the name indicates, the function is dedicated to
     calculate the user data across the reserves. For this end, it requires the total liquidity/collateral/bor-
     row balances in the base currency used by the price feed, as well as the average loan to value (LVT),
     the average liquidation ratio, and the health factor. However, it misuses the eModeAssetPrice as
     the price for each iterated reserve (lines 134-136), which leads to erroneous calculation of collateral
     value and borrow power. This issue is possibly introduced to support the eMode feature, but has been
     mistakenly used to consider all reserve assets to be part of the same eMode category.
68     function c a l c u l a t e U s e r A c c o u n t D a t a (
69       mapping ( address = > DataTypes . ReserveData ) storage reservesData ,
70       mapping ( uint256 = > address ) storage reserves ,
71       mapping ( uint8 = > DataTypes . EModeCategory ) storage eModeCategories ,
72       DataTypes . C a l c u l a t e U s e r A c c o u n t D a t a P a r a m s memory params
73     )
74       internal
75       view
76       returns (
77         uint256 ,
78         uint256 ,
79         uint256 ,
80         uint256 ,
81         uint256 ,
82         bool
83       )
84     {
85       if ( params . userConfig . isEmpty () ) {
86         return (0 , 0 , 0 , 0 , type ( uint256 ) . max , false ) ;
87       }
88
89         C a l c u l a t e U s e r A c c o u n t D a t a V a r s memory vars ;




     19/31                                                                                  PeckShield Audit Report #: 2021-373

                                                                                                                                         Public


90
91         if ( params . u s e r E M o d e C a t e g o r y != 0) {
92           vars . e M o d e P r i c e S o u r c e = eM o de Ca t eg or i es [ params . u s e r E M o d e C a t e g o r y ]. priceSource ;
93           vars . eModeLtv = eM o de Ca t eg or i es [ params . u s e r E M o d e C a t e g o r y ]. ltv ;
94           vars . e M o d e L i q T h r e s h o l d = e Mo de C at e go ri e s [ params . u s e r E M o d e C a t e g o r y ].
                  liquidationThreshold ;
 95
 96            if ( vars . e M o d e P r i c e S o u r c e != address (0) ) {
 97              vars . eM o de A ss et P ri ce = I P r i c e O r a c l e G e t t e r ( params . oracle ) . getAssetPrice (
 98                 vars . e M o d e P r i c e S o u r c e
 99              );
100            }
101        }
102
103        while ( vars . i < params . reservesCount ) {
104          if (! params . userConfig . i s U s i n g A s C o l l a t e r a l O r B o r r o w i n g ( vars . i ) ) {
105            unchecked {
106              ++ vars . i ;
107            }
108            continue ;
109          }
110
111            vars . c u r r e n t R e s e r v e A d d r e s s = reserves [ vars . i ];
112
113            if ( vars . c u r r e n t R e s e r v e A d d r e s s == address (0) ) {
114              unchecked {
115                 ++ vars . i ;
116              }
117              continue ;
118            }
119
120            DataTypes . ReserveData storage cur rentRe serve = reservesData [ vars .
                   c u r r e n t R e s e r v e A d d r e s s ];
121
122            (
123              vars . ltv ,
124              vars . liquidationThreshold ,
125              ,
126              vars . decimals ,
127              ,
128              vars . e M o d e A s s e t C a t e g o r y
129            ) = cu rrentR eserve . configuration . getParams () ;
130
131          unchecked {
132            vars . assetUnit = 10** vars . decimals ;
133          }
134          vars . assetPrice = vars . eM od e As se t Pr ic e > 0
135            ? vars . e M od eA s se tP r ic e
136            : I P r i c e O r a c l e G e t t e r ( params . oracle ) . getAssetPrice ( vars . c u r r e n t R e s e r v e A d d r e s s ) ;
137        ...
138    }

                                         Listing 3.8:      GenericLogic::calculateUserAccountData




      20/31                                                                                 PeckShield Audit Report #: 2021-373

                                                                                                        Public


          Recommendation Apply the right price oracle in the above calculateUserAccountData() routine
      to compute the user account data.

          Status The issue has been fixed by the following PR: 262.


      3.7       Proper EMode Category Use in Pool::borrow()

      • ID: PVE-007                                                • Target: Pool
      • Severity: Medium                                           • Category: Coding Practices [8]
      • Likelihood: High                                           • CWE subcategory: CWE-1041 [1]
      • Impact: Medium

      Description
      The Aave protocol has a nice feature credit delegation, which allows a credit delegator to delegate
      the credit of their account’s position to a borrower. This feature requires proper accounting of
      delegation allowance and actual expenditure. While examining its implementation, we notice a key
      function borrow() does not properly follow the credit delegation logic.
          To elaborate, we show below this borrow() function. This is a core lending function and is used to
      borrow funds from the lending protocol. It comes to our attention that the encapsulated DataTypes.
      ExecuteBorrowParams parameters mistakenly uses _usersEModeCategory[msg.sender] as the user’s eMode
      category. In the credit delegation situation, the real eMode category should be _usersEModeCategory[
      onBehalfOf].

189     // / @inheritdoc IPool
190     function borrow (
191        address asset ,
192        uint256 amount ,
193        uint256 interestRateMode ,
194        uint16 referralCode ,
195        address onBehalfOf
196     ) external override {
197        BorrowLogic . executeBorrow (
198          _reserves ,
199          _reservesList ,
200          _eModeCategories ,
201          _usersConfig [ onBehalfOf ] ,
202          DataTypes . E x e c u t e B o r r o w P a r a m s (
203            asset ,
204            msg . sender ,
205            onBehalfOf ,
206            amount ,
207            interestRateMode ,
208            referralCode ,




      21/31                                                                 PeckShield Audit Report #: 2021-373

                                                                                                                                        Public


209                  true ,
210                  _ m ax S t a b le R a t eB o r r ow S i z e Pe r c e nt ,
211                  _reservesCount ,
212                  _ a d d r e s s e s P r o v i d e r . ge tPrice Oracle () ,
213                  _ u s e r s E M o d e C a t e g o r y [ msg . sender ] ,
214                  _ a d d r e s s e s P r o v i d e r . g e t P r i c e O r a c l e S e n t i n e l ()
215              )
216         );
217     }

                                                                     Listing 3.9:           Pool::borrow()



            Recommendation Ensure the credit delegation feature is consistently honored in all aspects
      of the lending protocol.

            Status The issue has been fixed by the following PR: 204.


      3.8            Possible Underflow Avoidance in BorrowLogic And
                     UserConfiguration

            • ID: PVE-004                                                                           • Target: BorrowLogic, UserConfiguration
            • Severity: Low                                                                         • Category: Coding Practices [8]
            • Likelihood: Low                                                                       • CWE subcategory: CWE-561 [3]
            • Impact: Low

      Description
      The Aave protocol has established itself as the leading lending protocol. Within each lending proto-
      col, there is a constant need of accommodating various precision issues. SafeMath is a widely-used
      Solidity math library that is designed to support safe math operations by preventing common overflow
      or underflow issues when working with uint256 operands. Since the version 0.8.0, Solidity includes
      checked arithmetic operations by default, and this largely renders SafeMath unnecessary. While re-
      viewing arithmetic operations in current implementation, we notice occasions that may introduce
      unexpected overflows/underflows.
            For example, if we examine the isUsingAsCollateralOne() function, it may revert if the current
      collateralData (line 121) is equal to 0. Another example is when the underlying asset of a reserve has
      an unusual decimal, which may revert the following calculation of reserveCache.reserveConfiguration.
      getDecimals()- ReserveConfiguration.DEBT_CEILING_DECIMALS. Note this calculation appears in a num-
      ber of routines. Its revert may bring in unnecessary frictions and cause issues for integration and
      composability.



      22/31                                                                                                 PeckShield Audit Report #: 2021-373

                                                                                                                                   Public


115     function i s U s i n g A s C o l l a t e r a l O n e ( DataTypes . U s e r C o n f i g u r a t i o n M a p memory self )
116       internal
117       pure
118       returns ( bool )
119     {
120       uint256 co llater alData = self . data & C O LL AT E RA L_ M AS K ;
121       return coll ateral Data & ( collat eralDa ta - 1) == 0;
122     }

                                    Listing 3.10:        UserConfiguration::isUsingAsCollateralOne()



          Recommendation Revise the above calculation to avoid the unnecessary overflows and under-
      flows.

          Status The issue has been confirmed.


      3.9       Consistent Reserve Cache Use in
                rebalanceStableBorrowRate()

         • ID: PVE-009                                                            • Target: BorrowLogic
         • Severity: Low                                                          • Category: Coding Practices [8]
         • Likelihood: Low                                                        • CWE subcategory: CWE-561 [3]
         • Impact: Low

      Description
      For gas efficiency, the Aave protocol is engineered with the reserve cache mechanism, which necessi-
      tates the common steps to be followed when operating with the reserve data in different scenarios,
      including the cache generation, update, and eventual persistence. However, our analysis shows cer-
      tain inconsistency in the reserve cache usages and the inconsistency needs to be resolved to avoid
      confusions and errors.
          To elaborate, we show below two functions executeSupply() and rebalanceStableBorrowRate().
      These functions are self-explanatory and it comes to our attention that the first function updates
      the reserve cache before applying the validation logic while the second function validates the reserve
      cache before updating it. As mentioned earlier, this inconsistency may introduce issues when using
      the stale cache state for validation.
46      function executeSupply (
47        mapping ( address = > DataTypes . ReserveData ) storage reserves ,
48        mapping ( uint256 = > address ) storage reservesList ,
49        DataTypes . U s e r C o n f i g u r a t i o n M a p storage userConfig ,
50        DataTypes . E x e c u t e S u p p l y P a r a m s memory params




      23/31                                                                                 PeckShield Audit Report #: 2021-373

                                                                                                                                         Public


51        ) external {
52          DataTypes . ReserveData storage reserve = reserves [ params . asset ];
53          DataTypes . ReserveCache memory reserveCache = reserve . cache () ;
54
55          reserve . updateState ( reserveCache ) ;
56
57          V al id a ti on L og i c . valida teSupp ly ( reserveCache , params . amount ) ;
58
59          reserve . u p d a t e I n t e r e s t R a t e s ( reserveCache , params . asset , params . amount , 0) ;
60
61          ...
62    }

                                                     Listing 3.11:           SupplyLogic::executeSupply()


238       function r e b a l a n c e S t a b l e B o r r o w R a t e (
239         DataTypes . ReserveData storage reserve ,
240         address asset ,
241         address user
242       ) external {
243         DataTypes . ReserveCache memory reserveCache = reserve . cache () ;
244
245         IERC20 s t ab le D eb tT o ke n = IERC20 ( reserveCache . s t a b l e D e b t T o k e n A d d r e s s ) ;
246         IERC20 v a r i a b l e D e b t T o k e n = IERC20 ( reserveCache . v a r i a b l e D e b t T o k e n A d d r e s s ) ;
247         uint256 stableDebt = IERC20 ( s ta bl e De bt T ok en ) . balanceOf ( user ) ;
248
249         V al id a ti on L og i c . v a l i d a t e R e b a l a n c e S t a b l e B o r r o w R a t e (
250            reserve ,
251            reserveCache ,
252            asset ,
253            stableDebtToken ,
254            variableDebtToken ,
255            reserveCache . aTokenAddress
256         );
257
258         reserve . updateState ( reserveCache ) ;
259         ...
260   }

                                            Listing 3.12:           BorrowLogic::rebalanceStableBorrowRate()



           Recommendation                      Revise the above functions to following a consistent approach to use the
      reserve cache mechanism.

           Status The issue has been fixed by the following PR: 213.




      24/31                                                                                                  PeckShield Audit Report #: 2021-373

                                                                                                               Public


     3.10        Health Validation in EModeLogic::executeSetUserEMode()

        • ID: PVE-010                                                     • Target: EModeLogic
        • Severity: Low                                                   • Category: Business Logic [9]
        • Likelihood: Low                                                 • CWE subcategory: CWE-837 [6]
        • Impact: Low

     Description
     As mentioned earlier, the Aave protocol introduces a new feature eMode, which stands for High
     Efficiency Mode and allows borrowers to extract the highest borrowing power out of their collateral.
     In other words, assets can now be categorized, with each category having a shared risk management
     parameters, e.g., LTV, liquidation threshold, liquidation bonus, and a custom price oracle. While
     reviewing the current eMode support, we notice the related executeSetUserEMode() function needs to
     be revisited.
33     function e x e c u t e S e t U s e r E M o d e (
34       mapping ( address = > DataTypes . ReserveData ) storage reserves ,
35       mapping ( uint256 = > address ) storage reservesList ,
36       mapping ( uint8 = > DataTypes . EModeCategory ) storage eModeCategories ,
37       mapping ( address = > uint8 ) storage usersEModeCategory ,
38       DataTypes . U s e r C o n f i g u r a t i o n M a p storage userConfig ,
39       DataTypes . E x e c u t e S e t U s e r E M o d e P a r a m s memory params
40     ) external {
41       V al id a ti on L og i c . v a l i d a t e S e t U s e r E M o d e (
42          reserves ,
43          reservesList ,
44          eModeCategories ,
45          userConfig ,
46          params . reservesCount ,
47          params . categoryId
48       );
49
50        uint8 pre vCateg oryId = u s e r s E M o d e C a t e g o r y [ msg . sender ];
51        u s e r s E M o d e C a t e g o r y [ msg . sender ] = params . categoryId ;
52
53       if ( p revCat egoryI d != 0 && params . categoryId == 0) {
54         V al id a ti o nL og i c . v a l i d a t e H e a l t h F a c t o r (
55            reserves ,
56            reservesList ,
57            eModeCategories ,
58            userConfig ,
59            msg . sender ,
60            params . categoryId ,
61            params . reservesCount ,
62            params . oracle
63         );




     25/31                                                                         PeckShield Audit Report #: 2021-373

                                                                                                       Public


64         }
65         emit UserEModeSet ( msg . sender , params . categoryId ) ;
66     }

                                   Listing 3.13:   EModeLogic::executeSetUserEMode()


           To elaborate, we show above its full implementation, which indicates that the health check is
     not performed unless the following condition is satisfied prevCategoryId != 0 && params.categoryId
      == 0 (line 53).    However, in the situation where params.categoryId !=0, there is still a need to
     invoke validateHalthFactor(). The reason is that the new category may have different LTV and/or
     liquidationThreshold.

           Recommendation         Revise the above executeSetUserEMode() function to enforce the health
     check.

           Status The issue has been fixed by the following PR: 218.


     3.11        Potential Reentrancy Risk in flashLoanSimple()

     • ID: PVE-011                                           • Target: FlashLoanLogic
     • Severity: High                                        • Category: Time and State [10]
     • Likelihood: High                                      • CWE subcategory: CWE-663 [5]
     • Impact: High

     Description
     A common coding best practice in Solidity is the adherence of checks-effects-interactions principle.
     This principle is effective in mitigating a serious attack vector known as re-entrancy. Via this
     particular attack vector, a malicious contract can be reentering a vulnerable contract in a nested
     manner. Specifically, it first calls a function in the vulnerable contract, but before the first instance
     of the function call is finished, second call can be arranged to re-enter the vulnerable contract by
     invoking functions that should only be executed once. This attack was part of several most prominent
     hacks in Ethereum history, including the DAO [15] exploit, and the recent Uniswap/Lendf.Me hack [14].
           We notice there is an occasions where the checks-effects-interactions principle is violated. Using
     the FlashLoanLogic as an example, the flashLoanSimple() function (see the code snippet below) is
     provided to deposit additional tokens into the option contract. However, the invocation of an external
     contract requires extra care in avoiding the above re-entrancy.
           In particular, the interaction with the external contract inside flashLoanSimple() (line 201) starts
     before effecting the update on the internal state. More importantly, it carries over the stale cache




     26/31                                                              PeckShield Audit Report #: 2021-373

                                                                                                                                          Public


      states and apply them for the calculation of protocol-wide interest rates, while ignoring the possi-
      bility that it may re-enter to update the protocol state. These updates may be lost since they are
      overwritten by the stale states!
183     function e x e c u t e F l a s h L o a n S i m p l e (
184       DataTypes . ReserveData storage reserve ,
185       DataTypes . F l a s h l o a n S i m p l e P a r a m s memory params
186     ) external {
187       F l a s h L o a n S i m p l e L o c a l V a r s memory vars ;
188
189        DataTypes . ReserveCache memory reserveCache = reserve . cache () ;
190        reserve . updateState ( reserveCache ) ;
191
192        V al id a ti on L og i c . v a l i d a t e F l a s h l o a n S i m p l e ( reserveCach e ) ;
193
194        vars . receiver = I F l a s h L o a n S i m p l e R e c e i v e r ( params . re c ei ve r Ad dr e ss ) ;
195
196        vars . totalPremium = params . amount . percentMul ( params . f l a s h L o a n P r e m i u m T o t a l ) ;
197        vars . a m o u n t P l u s P r e m i u m = params . amount + vars . totalPrem ium ;
198        IAToken ( reserveCache . aTokenAddress ) . t r a n s f e r U n d e r l y i n g T o ( params . receiverAddress ,
                params . amount ) ;
199
200       require (
201          vars . receiver . e x e c u t e O p e r a t i o n (
202             params . asset ,
203             params . amount ,
204             vars . totalPremium ,
205             msg . sender ,
206             params . params
207          ),
208          Errors . P _ I N V A L I D _ F L A S H _ L O A N _ E X E C U T O R _ R E T U R N
209       );
210
211        vars . p r e m i u m T o P r o t o c o l = params . amount . percentMul ( params . f l a s h L o a n P r e m i u m T o P r o t o c o l )
                ;
212        vars . premiumToLP = vars . totalPremium - vars . p r e m i u m T o P r o t o c o l ;
213
214       reserve . c u m u l a t e T o L i q u i d i t y I n d e x (
215          IERC20 ( reserveCache . aTokenAddress ) . totalSupply () ,
216          vars . premiumToLP
217       );
218
219        reserve . a c c r u e d T o T r e a s u r y =
220          reserve . a c c r u e d T o T r e a s u r y +
221          Helpers . castUint128 ( vars . p r e m i u m T o P r o t o c o l . rayDiv ( reserve . liqui dityIn dex ) ) ;
222
223        reserve . u p d a t e I n t e r e s t R a t e s ( reserveCache , params . asset , vars . amountPlusPremium , 0) ;
224
225        IERC20 ( params . asset ) . s a f e T r a n s f e r F r o m (
226          params . receiverAddress ,
227          reserveCache . aTokenAddress ,
228          vars . a m o u n t P l u s P r e m i u m




      27/31                                                                                      PeckShield Audit Report #: 2021-373

                                                                                                    Public


229         );
230
231         emit FlashLoan (
232            params . receiverAddress ,
233            msg . sender ,
234            params . asset ,
235            params . amount ,
236            vars . totalPremium ,
237            0
238         );
239     }

                                   Listing 3.14:   FlashLoanLogic::flashLoanSimple()



            Recommendation Revise the above flashLoanSimple() routine by applying necessary reentrancy
      prevention to avoid the use of cached state to overwrite legitimate protocol updates.

            Status The issue has been fixed by the following PR: #201.




      28/31                                                             PeckShield Audit Report #: 2021-373

                                                                                                Public




4 | Conclusion

In this audit, we have analyzed the Aave V3 design and implementation. The system presents a
unique, robust offering as a decentralized non-custodial money market protocol where users can
participate as depositors or borrowers. Aave V3 improves early versions on capital efficiency, security,
decentralization, UX while at the same time providing new functionalities to leverage the capabilities
of rollups and the growing ecosystem of competing L1s. The current code base is well structured
and neatly organized. Those identified issues are promptly confirmed and fixed.
   Moreover, we need to emphasize that Solidity-based smart contracts as a whole are still in
an early, but exciting stage of development. To improve this report, we greatly appreciate any
constructive feedbacks or suggestions, on our methodology, audit findings, or potential gaps in
scope/coverage.




29/31                                                          PeckShield Audit Report #: 2021-373

                                                                                     Public




References

[1] MITRE. CWE-1041: Use of Redundant Code. https://cwe.mitre.org/data/definitions/1041.

    html.

[2] MITRE. CWE-1099: Inconsistent Naming Conventions for Identifiers. https://cwe.mitre.org/

    data/definitions/1099.html.

[3] MITRE. CWE-561: Dead Code. https://cwe.mitre.org/data/definitions/561.html.

[4] MITRE.       CWE-563: Assignment to Variable without Use.    https://cwe.mitre.org/data/

    definitions/563.html.

[5] MITRE. CWE-663: Use of a Non-reentrant Function in a Concurrent Context. https://cwe.

    mitre.org/data/definitions/663.html.

[6] MITRE. CWE-837: Improper Enforcement of a Single, Unique Action. https://cwe.mitre.org/

    data/definitions/837.html.

[7] MITRE. CWE-841: Improper Enforcement of Behavioral Workflow. https://cwe.mitre.org/

    data/definitions/841.html.

[8] MITRE. CWE CATEGORY: Bad Coding Practices. https://cwe.mitre.org/data/definitions/

    1006.html.

[9] MITRE. CWE CATEGORY: Business Logic Errors. https://cwe.mitre.org/data/definitions/

    840.html.



30/31                                                   PeckShield Audit Report #: 2021-373

                                                                                       Public


[10] MITRE. CWE CATEGORY: Concurrency. https://cwe.mitre.org/data/definitions/557.html.

[11] MITRE. CWE VIEW: Development Concepts. https://cwe.mitre.org/data/definitions/699.

    html.

[12] OWASP.     Risk Rating Methodology.        https://www.owasp.org/index.php/OWASP_Risk_

    Rating_Methodology.

[13] PeckShield. PeckShield Inc. https://www.peckshield.com.

[14] PeckShield. Uniswap/Lendf.Me Hacks: Root Cause and Loss Analysis. https://medium.com/

    @peckshield/uniswap-lendf-me-hacks-root-cause-and-loss-analysis-50f3263dcc09.

[15] David   Siegel.     Understanding    The    DAO    Attack.     https://www.coindesk.com/

    understanding-dao-hack-journalists.




31/31                                                      PeckShield Audit Report #: 2021-373

