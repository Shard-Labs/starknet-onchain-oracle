# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin)


struct MatchResult:
    member game: felt
    member team1: felt
    member team1_score: felt
    member team2: felt
    member team2_score: felt
    member date: felt
end

#################################################################
#   Storage Variables
#################################################################


#/
#/  Mock Storage variable for fullfiled requests
#/
@storage_var
func _requests() -> ( match_result : MatchResult ):
end


#################################################################
#   Interfaces
#################################################################

#
# Interface for the Oracle contract
# 
@contract_interface
namespace IOracleContract:

    # Receives a request, which is an array of values defined in the oracle contract
    func receive_request( request_data_len : felt, request_data : felt* ):
    end

end

#################################################################
#   External functions to be called by a client
#################################################################

#
# Get the results of a basketball game by providing the name of one of the teams and the date the match took place in
#
@external
func request_basketball_results{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}( oracle_address : felt, team : felt, date : felt ):
    
    # Allocate array.
    let (request_data : felt*) = alloc()

    # Populate data into array
    # According to the oracle's interface:
    #   - the first element is the game type, which for Basketball is 0
    #   - the second element is the name of one of the teams, which should have previously been converted to int
    #   - the third element is the date of the match, which should be passed in the format YYYYMMDD
    assert request_data[0] = 0
    assert request_data[1] = team
    assert request_data[2] = date

    # Must always pass the array length when passing an array as an argument
    IOracleContract.receive_request( oracle_address, 3, request_data )
    return()
end

#################################################################
#   External functions to be called by the Oracle contract
#################################################################

#
# Callback function for the oracle to interact with. Should be named according to the contract's definition
# Receives an array with the callback data
#
@external
func receive_callback{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}( response_data_len : felt, response_data : felt* ):
    
    let result = MatchResult(
        game=response_data[0],
        team1=response_data[1],
        team1_score=response_data[2],
        team2=response_data[3],
        team2_score=response_data[4],
        date=response_data[5]
    )
    _requests.write(result)
    return ()
end


@view
func get_result{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> ( result : MatchResult):
    
    let (result) = _requests.read()
    return (result)
end
