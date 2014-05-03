/**
 * mf-tow/tow_AttachTow.sqf
 * The action for attaching the tow to another vehicle. 
 *
 * Created by Matt Fairbrass (matt_d_rat)
 * Version: 1.0.0
 * MIT Licence
 **/

private ["_vehicle","_started","_finished","_animState","_isMedic","_abort","_vehicleNameText","_towTruckNameText","_findNearestVehicles","_findNearestVehicle","_IsNearVehicle","_towTruck","_towableVehicles","_vehicleOffset","_towTruckOffset","_hasToolbox"];

if(DZE_ActionInProgress) exitWith { cutText [(localize "str_epoch_player_96") , "PLAIN DOWN"] };
DZE_ActionInProgress = true;

player removeAction s_player_towing;
s_player_towing = 1;

// Tow Truck
_towTruck = _this select 3;
_towableVehicles = [_towTruck] call MF_Tow_Towable_Array;
_towTruckNameText = [_towTruck] call MF_Tow_Get_Vehicle_Name;

// Get all nearby vehicles that can be towed by the towTruck within the minimum tow distance
_findNearestVehicles = nearestObjects [_towTruck, _towableVehicles, MF_Tow_Distance];
_findNearestVehicle = [];
{
	if (alive _x && _towTruck != _x) then {
		_findNearestVehicle set [(count _findNearestVehicle),_x];
	};
} foreach _findNearestVehicles;
		
_IsNearVehicle = count (_findNearestVehicle);

if(_IsNearVehicle >= 1) then {
	// select the nearest one
	_vehicle = _findNearestVehicle select 0;
	_vehicleNameText = [_vehicle] call MF_Tow_Get_Vehicle_Name;
	_hasToolbox = "ItemToolbox" in (items player);
	
	// Check the player has a toolbox
	if(!_hasToolbox) exitWith {
		cutText ["Cannot attach tow without a toolbox.", "PLAIN DOWN"];
	};
	
	// Check if the vehicle we want to tow is locked
	if((_vehicle getVariable ["MF_Tow_Cannot_Tow", false])) exitWith {
		cutText [format["Cannot tow %1 because it is locked.", _vehicleNameText], "PLAIN DOWN"];
	};
	
	_finished = false;
	
	[_towTruck] call MF_Tow_Animate_Player_Tow_Action;
	
	r_interrupt = false;
	_animState = animationState player;
	r_doLoop = true;
	_started = false;

	while {r_doLoop} do {
		_animState = animationState player;
		_isMedic = ["medic",_animState] call fnc_inString;
		if (_isMedic) then {
			_started = true;
		};
		if (_started and !_isMedic) then {
			r_doLoop = false;
			_finished = true;
		};
		if (r_interrupt) then {
			detach player;
			r_doLoop = false;
		};
		sleep 0.1;
	};
	r_doLoop = false;

	if(!_finished) then {
		r_interrupt = false;
			
		if (vehicle player == player) then {
			[objNull, player, rSwitchMove,""] call RE;
			player playActionNow "stop";
		};
		_abort = true;
	};

	if (_finished) then {
		if(((vectorUp _vehicle) select 2) > 0.5) then {
			if(typeOf _towTruck in MF_Tow_Vehicles ) then {
				// Calculate the offset positions depending on the kind of tow truck and vehicle
				if (_towTruck isKindOf "SUV_Base_EP1" || _towTruck isKindOf "ArmoredSUV_Base_PMC") then {
					_towTruckOffset = 0.9;
				} else {
					_towTruckOffset = 0.8
				};
				
				if (_vehicle isKindOf "Truck" && !(_towTruck isKindOf "Truck")) then {
					_vehicleOffset = 0.9;
				} else {
					_vehicleOffset = 0.8
				};
					
				// Attach the vehicle to the tow truck
				_vehicle attachTo [ _towTruck,
					[
						0,
						(boundingBox _towTruck select 0 select 1) * _towTruckOffset + (boundingBox _vehicle select 0 select 1) * _vehicleOffset,
						(boundingBox _towTruck select 0 select 2) - (boundingBox _vehicle select 0 select 2) + 0.1
					]
				];
				
				// Detach the player from the tow truck
				detach player;
				
				_towTruck setVariable ["MFTowInTow", true, true];
				_towTruck setVariable ["MFTowVehicleInTow", _vehicle, true];
				
				cutText [format["%1 has been attached to %2.", _vehicleNameText, _towTruckNameText], "PLAIN DOWN"];
			};	
		} else {
			cutText [format["Failed to attach %1 to %2.", _vehicleNameText, _towTruckNameText], "PLAIN DOWN"];
		};
	};
} else {
	cutText [format["No vehicles nearby to tow. Move within %1m of a vehicle.", MF_Tow_Distance], "PLAIN DOWN"];
};
DZE_ActionInProgress = false;
s_player_towing = -1;