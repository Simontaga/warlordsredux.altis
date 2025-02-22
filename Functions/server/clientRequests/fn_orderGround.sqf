params ["_sender", "_pos", "_class", "_direction"];

if !(isServer) exitWith {};

_asset = [_class, _pos, _direction] call BIS_fnc_WL2_createVehicleCorrectly;

//Livery change
if (typeOf _asset == "I_Truck_02_MRL_F") then {
	_asset setObjectTextureGlobal [0, "a3\soft_f_beta\truck_02\data\truck_02_kab_opfor_co.paa"];
	_asset setObjectTextureGlobal [2, "a3\soft_f_gamma\truck_02\data\truck_02_mrl_opfor_co.paa"];
};

if (typeOf _asset == "B_APC_Wheeled_03_cannon_F") then {
	_asset setObjectTextureGlobal [0, "A3\armor_f_gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_co.paa"];
	_asset setObjectTextureGlobal [1, "A3\armor_f_gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext2_co.paa"];
	_asset setObjectTextureGlobal [2, "A3\armor_f_gamma\APC_Wheeled_03\Data\rcws30_co.paa"];
	_asset setObjectTextureGlobal [3, "A3\armor_f_gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_alpha_co.paa"];
};

if (typeOf _asset == "O_T_Truck_03_device_ghex_F") then {
	_asset setObjectTextureGlobal [0, "#(argb,8,8,3)color(0.80,0.76,0.66,0.15)"];
};

waitUntil {sleep 0.1; !(isNull _asset)};

if (typeOf _asset == "B_APC_Tracked_01_AA_F" || {typeOf _asset == "O_APC_Tracked_02_AA_F"}) then {
	_asset removeMagazinesTurret ["4Rnd_Titan_long_missiles",[0]];
	_asset removeMagazinesTurret ["4Rnd_Titan_long_missiles_O",[0]];
	_asset removeWeaponTurret ["missiles_titan_AA",[0]];
	{_asset addMagazineTurret ["4Rnd_GAA_missiles",[0]];} forEach [1,2];
	_asset addWeaponTurret ["missiles_titan_AA",[0]];
};

_owner = owner _sender;
_asset setVariable ["BIS_WL_ownerAsset", (getPlayerUID _sender), [2, _owner]];
_asset setVariable ["BIS_WL_lastActive", 0, _owner];
[_asset, _sender] remoteExec ["BIS_fnc_WL2_newAssetHandle", _owner];
_sender setVariable ["BIS_WL_isOrdering", false, [2, _owner]];