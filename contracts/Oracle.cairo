# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check ecdsa

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin)




#################################################################
#
#   Game type enumerator
#   Possible values of the 'game' member of RequestData structure
#
#   0 - Basketball
#
#   ...
#
#   TODO: Support more games
#
#################################################################


struct RequestData:
    member caller_address: felt
    member game: felt
    member team: felt
    member date: felt # Date should be passed in the format YYYYMMDD
end


#################################################################
#   Storage Variables
#################################################################


#/
#/  Request storage variable
#/
@storage_var
func _requests(index : felt) -> ( request_data : RequestData ):
end

#/
#/  Current index for the front of the queue
#/
@storage_var
func _index() -> ( res : felt ):
end

#/
#/  Current request list size
#/
@storage_var
func _queue_size() -> ( res : felt ):
end


#################################################################
#   Interfaces
#################################################################

#
# Interface for the Client contracts. All client contracts should implement the "receive_callback" function, as specified in this interface
# 
@contract_interface
namespace IClientContract:

    # Receives the callback
    func receive_callback( response_data_len : felt, response_data : felt* ):
    end

end


#################################################################
#   External functions to be called by client contracts
#################################################################

#
# Receives a request and adds it to the queue
#
@external
func receive_request{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}( request_data_len : felt, request_data : felt* ):

    let (caller_address) = get_caller_address()
    let req_data = RequestData(
        caller_address=caller_address,
        game=request_data[0],
        team=request_data[1],
        date=request_data[2]
    )
    create_request(req_data)
    return()
end

#################################################################
#   External functions to be called by the Offchain Oracle
#################################################################

#
#  Return the size of the request queue
#
@view
func get_queue_size{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt) :

    let (res) = _queue_size.read()
    return (res)
end

#
#  Return the next request in the queue
#
@external
func consume_next_request{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : RequestData) :

    alloc_locals
       
    let (index) = _index.read()
    let (res) = _requests.read(index)
    
    # Increment the index
    _index.write(index+1)

    # Update the size of the queue
    let (queue_size) = _queue_size.read()
    _queue_size.write(queue_size - 1)

    return (res)
end

#
#  Call the callback function on the client contract
#
@external
func callback_client{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(client_address : felt, response_data_len : felt, response_data : felt*) :

    IClientContract.receive_callback(client_address, response_data_len, response_data)
    return ()
end



############################################
#   Internal functions
############################################

#
#   Add a new request to the queue
#
func create_request{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}( request_data : RequestData):

    # Get current queue size and index
    let (queue_size) = _queue_size.read()
    let (index) = _index.read()
    
    # Push a new request
    _requests.write(index + queue_size,request_data)

    # Update size and index
    _queue_size.write(queue_size + 1)

    return()
end


