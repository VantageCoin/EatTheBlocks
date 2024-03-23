//Homework 3
pragma solidity 0.8.23;

contract Counter {
    uint256 private count; // should be slot zero

    function increment() public {

        assembly {
            let counter_ := sload(0)
            counter_ := add(counter_,1)
            sstore(0, counter_)
        }
    }

    function decrement() public {
        require(count > 0, "Counter: cannot decrement below 0");

        assembly {

            let counter_ := sload(0)
            counter_ := sub(counter_,1)
            sstore(0, counter_)
        }
        
    }

    function reset() public {
        assembly {
            let count :=0
        }
    }

    function getCount() public view returns (uint256) {
        return count;
        assembly
        {
            function getCount() -> result {
            let result := sload(0)
            }

        }
    }
}