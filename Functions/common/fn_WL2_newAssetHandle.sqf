#include "..\warlords_constants.inc"

params ["_asset", ["_owner", objNull]];

if (isServer && {isNull _owner}) exitWith {
	if !(_asset isKindOf "Man") then {
		call APS_fnc_RegisterVehicle;
	};
	_asset call APS_fnc_SetupProjectiles;
	_asset setSkill (0.2 + random 0.3);
};

if (isPlayer _owner) then {
	WAS_store = true;

	if (_asset isKindOf "Man") then {
		_asset call APS_fnc_SetupProjectiles;
		_asset addEventHandler ["Killed", {
			missionNamespace setVariable ["WL2_manLost", true];
			BIS_WL_matesAvailable = (BIS_WL_matesAvailable - 1) max 0;
			false spawn BIS_fnc_WL2_refreshOSD;
		}];
	} else {
		call APS_fnc_RegisterVehicle;
		_asset call APS_fnc_SetupProjectiles;
		_asset setVariable ["BIS_WL_nextRepair", 0];
		
		private _defaultMags = magazinesAllTurrets _asset;
		_asset setVariable ["BIS_WL_defaultMagazines", _defaultMags];
		_var = format ["BIS_WL_ownedVehicles_%1", getPlayerUID player];
		_vehicles = missionNamespace getVariable [_var, []];
		_vehicles pushBack _asset;
		missionNamespace setVariable [_var, _vehicles, [2, clientOwner]];
		
		if !(_asset isKindOf "StaticWeapon") then {
			_rearmTime = if (_asset isKindOf "Helicopter" || {_asset isKindOf "Plane"}) then {30} else {((missionNamespace getVariable "BIS_WL2_rearmTimers") getOrDefault [(typeOf _asset), 600])};
			_asset setVariable ["BIS_WL_nextRearm", serverTime + _rearmTime];

			if (typeOf _asset != "B_UAV_06_F" && {typeOf _asset != "O_UAV_06_F"}) then {
				if (_asset isKindOf "Air") then {
					_asset spawn BIS_fnc_WL2_sub_rearmActionAir;
				} else {
					_asset spawn BIS_fnc_WL2_sub_rearmAction;
					if (typeOf _asset == "O_T_Truck_03_device_ghex_F" || {typeOf _asset == "O_Truck_03_device_F"}) then {
						_asset setVariable ["dazzlerActivated", false];
						_asset call BIS_fnc_WL2_sub_dazzlerAction;
					};

					if (typeOf _asset == "B_Truck_01_flatbed_F" || {typeOf _asset == "B_T_VTOL_01_vehicle_F" || {typeOf _asset == "O_T_VTOL_02_vehicle_dynamicLoadout_F"}}) then {
						_asset call BIS_fnc_WL2_sub_logisticsAddAction;
						if (side _owner == east && {typeOf _asset == "B_Truck_01_flatbed_F"}) then {
							_asset setObjectTextureGlobal [0, "A3\Soft_F_Exp\Truck_01\Data\Truck_01_ext_01_olive_CO.paa"];
							_asset setObjectTextureGlobal [2, "A3\Soft_F_EPC\Truck_03\Data\Truck_03_ammo_CO.paa"];
						};
					};
				};
			} else {
				waitUntil {sleep 0.1; !(isNull group _asset)};
				_asset spawn {
					params ["_asset"];
					[
						driver _asset,
						format["<t color='#E5E500' shadow='2'>&#160;%1</t>", "*Arm Drone*"],
						"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\attack_ca.paa",
						"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\attack_ca.paa",
						"!(isNull (getConnectedUAVUnit player))",
						"!(isNull (getConnectedUAVUnit player))",
						{ 
							playSound3D ["a3\sounds_f\sfx\objects\upload_terminal\terminal_antena_close.wss", (getConnectedUAVUnit player), false, getPosASL (getConnectedUAVUnit player), 1, 1, 0];
						},
						{},
						{
							(getConnectedUAVUnit player) addEventHandler ["Killed", { params ["_unit", "_killer", "_instigator", "_useEffects"]; 
								[player, "droneExplode"] remoteExec ["BIS_fnc_WL2_handleClientRequest", 2];
							}];
							[
								getConnectedUAVUnit player,
								format["<t color='#f80e1a' shadow='2'>&#160;%1</t>", "*Detonate*"],
								"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\destroy_ca.paa",
								"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\destroy_ca.paa",
								"!(isNull (getConnectedUAVUnit player))",
								"!(isNull (getConnectedUAVUnit player))",
								{},
								{},
								{ 
									[player, "droneExplode"] remoteExec ["BIS_fnc_WL2_handleClientRequest", 2];
								},
								{},
								[],
								1
							] call BIS_fnc_holdActionAdd;
						},
						{},
						[],
						2
					] call BIS_fnc_holdActionAdd;
				
				};
			};
		} else {
			_rearmTime = ((missionNamespace getVariable "BIS_WL2_rearmTimers") getOrDefault [(typeOf _asset), 600]);
			_asset setVariable ["BIS_WL_nextRearm", serverTime + _rearmTime];
			_asset spawn BIS_fnc_WL2_sub_rearmAction;

			if (typeOf _asset == "B_Radar_System_01_F" || {typeOf _asset == "O_Radar_System_02_F"}) then {
				_asset spawn {
					params ["_asset"];

					_asset setVariable ["radarRotation", false];
					[_asset, "rotation"] call BIS_fnc_WL2_sub_radarOperate;
					_lookAtPositions = [0, 45, 90, 135, 180, 225, 270, 315] apply { _asset getRelPos [100, _x] };
					_radarIter = 0;

					while {alive _asset} do {
						if (_asset getVariable "radarRotation") then {
							_asset lookAt (_lookAtPositions # _radarIter);
							_radarIter = (_radarIter + 1) % 8;
						};
						sleep 1.2;
					};				
				};
			};
		};

		if (unitIsUAV _asset) then {
			if (profileNamespace getVariable ["MRTM_enableAuto", true]) then {
				_asset setAutonomous false;
			};
			_asset setVariable ["BIS_WL_ownerUavAsset", getPlayerUID player, true];
		};

		if !(typeOf _asset == "B_Truck_01_medical_F" || {typeOf _asset == "O_Truck_03_medical_F" || {typeOf _asset == "Land_Pod_Heli_Transport_04_medevac_F" || {typeOf _asset == "B_Slingload_01_Medevac_F"}}}) then {
			_asset call BIS_fnc_WL2_sub_vehicleLockAction;
		};

		if (profileNamespace getVariable ["MRTM_spawnEmpty", false]) then {
			if (typeOf _asset != "B_supplyCrate_F" && {typeOf _asset != "O_supplyCrate_F"}) then {
				if !((typeOf _asset) in (getArray (missionConfigFile >> "logisticsConfig" >> "cargoTypes" >> "Cargo"))) then {
					clearMagazineCargoGlobal _asset;
					clearItemCargoGlobal _asset;
					clearWeaponCargoGlobal _asset;
				};
			};
		};
		
		_asset spawn {
			params ["_asset"];
			_repairActionID = -1;
			while {alive _asset} do {
				_nearbyVehicles = (_asset nearEntities ["All", WL_MAINTENANCE_RADIUS]) select {alive _x};
				_repairCooldown = ((_asset getVariable "BIS_WL_nextRepair") - serverTime) max 0;
				
				if (_nearbyVehicles findIf {getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "transportRepair") > 0} != -1) then {
					if (_repairActionID == -1) then {
						_repairActionID = _asset addAction [
							"",
							{
								params ["_asset"];
								if ((_asset getVariable "BIS_WL_nextRepair") <= serverTime) then {
									[player, "repair", (_asset getVariable "BIS_WL_nextRepair"), 0, _asset] remoteExec ["BIS_fnc_WL2_handleClientRequest", 2];
									playSound3D ["A3\Sounds_F\sfx\UI\vehicles\Vehicle_Repair.wss", _asset, FALSE, getPosASL _asset, 2, 1, 75];
									[toUpper localize "STR_A3_WL_popup_asset_repaired"] spawn BIS_fnc_WL2_smoothText;
									_asset setVariable ["BIS_WL_nextRepair", serverTime + WL_MAINTENANCE_COOLDOWN_REPAIR];
								} else {
									playSound "AddItemFailed";
								};
							},
							[],
							5,
							TRUE,
							FALSE,
							"",
							"alive _target && {getPlayerUID _this == (_target getVariable ['BIS_WL_ownerAsset', '123']) && {vehicle _this == _this}}",
							WL_MAINTENANCE_RADIUS,
							FALSE
						];
					};
					_asset setUserActionText [_repairActionID, if (_repairCooldown == 0) then {format ["<t color = '#4bff58'>%1</t>", localize "STR_repair"]} else {format ["<t color = '#7e7e7e'><t align = 'left'>%1</t><t align = 'right'>%2     </t></t>", localize "STR_repair", [_repairCooldown, "MM:SS"] call BIS_fnc_secondsToString]}, format ["<img size='2' color = '%1' image='\A3\ui_f\data\IGUI\Cfg\Actions\repair_ca.paa'/>", if (_repairCooldown == 0) then {"#ffffff"} else {"#7e7e7e"}]];
				} else {
					if (_repairActionID != -1) then {
						_asset removeAction _repairActionID;
						_repairActionID = -1;
					};
				};
				sleep WL_TIMEOUT_STANDARD;
			};
			
			_asset removeAction _repairActionID;
		};
		
		if (getNumber (configFile >> "CfgVehicles" >> typeOf _asset >> "transportRepair") > 0) then {
			[_asset, 0] remoteExec ["setRepairCargo", 0];
			_amount = ((getNumber (configfile >> "CfgVehicles" >> typeof _asset >> "transportRepair")) min 10000);
			_asset setvariable ["GOM_fnc_repairCargo", _amount, true];
		};
		if (getNumber (configFile >> "CfgVehicles" >> typeOf _asset >> "transportAmmo") > 0) then {
			[_asset, 0] remoteExec ["setAmmoCargo", 0];
			_amount = 10000;
			if (typeOf _asset == "B_Truck_01_ammo_F" || {typeOf _asset == "O_Truck_03_ammo_F" || {typeOf _asset == "Land_Pod_Heli_Transport_04_ammo_F" || {typeOf _asset == "B_Slingload_01_Ammo_F"}}}) then {
				_amount = ((getNumber (configfile >> "CfgVehicles" >> typeof _asset >> "transportAmmo")) min 30000);
			};
			_asset setvariable ["GOM_fnc_ammoCargo",_amount,true];
		};
	};

	_asset call BIS_fnc_WL2_sub_removeAction;
	_crewPosition = (fullCrew [_asset, "", true]) select {!("cargo" in _x)};
	_radarSensor = (listVehicleSensors _asset) select {{"ActiveRadarSensorComponent" in _x}forEach _x};
	if ((count _radarSensor > 0) && (count _crewPosition > 1 || (unitIsUAV _asset))) then {
		_asset setVariable ["radarOperation", false];
		_asset setVehicleRadar 2;
		[_asset, "toggle"] call BIS_fnc_WL2_sub_radarOperate;
	};
};