# starknet-onchain-oracle
Cairo implementation of a POC on-chain oracle for Starknet, along with a sample Client contract and tests


It works by storing received requests in a storage variable, which is then fed to the off-chain Oracle.

## Implementation

### Request Structure

A request is defined by the following structure:
```
struct RequestData:
    member caller_address: felt
    member game: felt
    member team: felt
    member date: felt 
end
```

- "caller_address" is the contract address of the client contract that interacts with the Oracle contract;

- "game" is the type of game that the client contract is requesting. In this POC it is only possible to query basketball matches, for which the felt value is 0;

- "team" is a BigInt conversion from the hex value of the ascii code of the team name that the client contract is requesting the information for ("nameInString" is converted to "nameInHex", and finally to BigInt("nameInHex"));

- "date" is the date of the match that the client contract is requesting, which should be provided in the format YYYYMMDD.

### Storage variables

There are 3 storage_variables being used:

```
@storage_var
func _requests(index : felt) -> ( request_data : RequestData ):
end
```
- Stores the pending requests received by the on-chain Oracle that were not yet consumed by the off-chain Oracle. Works like a queue, in the sense that requests will be processed in the order they are received.

```
@storage_var
func _index() -> ( res : felt ):
end
```
- Stores the index for the next request saved in "\_requests" to be consumed by the off-chain Oracle

```
@storage_var
func _queue_size() -> ( res : felt ):
end
```
- Current size of the queue of pending requests. The off-chain Oracle queries this value to check if there are any pending requests.


### Client contract Interface

Every client contract should implement a function "receive_callback", that the on-chain Oracle contract calls when a request has been fulfilled by the off-chain Oracle, with the following signature:
```
@contract_interface
namespace IClientContract:

    # Receives the callback
    func receive_callback( response_data_len : felt, response_data : felt* ):
    end

end
```

### External functions
```
@view
func get_queue_size{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt)
```
Called by the off-chain Oracle to check if there are any pending requests in the queue


```
@external
func receive_request{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}( request_data_len : felt, request_data : felt* )
```
Similarly to the "receive_callback" function, this interface should be referenced in every Client contract, as it is the function that they will call when interacting with the Oracle contract.


```
@external
func consume_next_request{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : RequestData)
```
Called by the off-chain Oracle to retrieve the next pending request in the queue.


```
@external
func callback_client{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(client_address : felt, response_data_len : felt, response_data : felt*)
```
Called by the off-chain Oracle to retrieve the next pending request in the queue.


```
@external
func callback_client{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(client_address : felt, response_data_len : felt, response_data : felt*)
```
Called by the off-chain Oracle in order for it to call back the Client contract with the response.


## Calldata structure

### Client Contract → Oracle Contract

The Client contract calls the function `receive_request( request_data_len : felt, request_data : felt* )` in the Oracle contract. 

- "request_data_len" is the size of the array "request_data", always 3 in this POC;

- "request_data" is the array with the request parameters, defined as follows:
```
request_data[0] = the game type, which for Basketball is 0
request_data[1] = the name of one of the teams, which should have previously been converted to int
request_data[2] = the date of the match, which should be passed in the format YYYYMMDD
```

### Off-chain Oracle →  Oracle Contract
The off-chain Oracle first calls the `get_queue_sizefunction` in the on-chain Oracle, which returns an int, to assert if there are any new requests to be consumed. When there is at least 1, it then calls `consume_next_request() -> (res : RequestData)` to get the next request in the queue, returned in the RequestData structure.

### Oracle Contract → Client Contract
The Oracle contract calls the function `receive_callback( response_data_len : felt, response_data : felt* )` in the Client contract in order to feed it the response that was given by the off-chain Oracle.

- "response_data_len" is the size of the array "response_data", always 6 in this POC;

- "response_data" is the array with the response values, defined in the calldata section of the off-chain implementation in this document.
