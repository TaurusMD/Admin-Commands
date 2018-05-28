/* ===========================================================================
	
	----------------------
	-*- Admin Commands -*-
	----------------------

	(c) 2018 - Taurus
	Website: https://genjero.com

=========================================================================== */

// Includes
#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < fun >
#include < hamsandwich >

// Semicolon coding style
#pragma semicolon 1;

// Turns stuff into bitsums
#define TurnIntoBit(%1)	( 1 << %1 )

// Bitsums!
#define SetBit(%1,%2)	( %1 |= TurnIntoBit( %2 - 1 ) )
#define ClearBit(%1,%2)	( %1 &= ~ TurnIntoBit( %2 - 1 ) )
#define CheckBit(%1,%2)	( %1 & TurnIntoBit( %2 - 1 ) )

// Checks whether a player is valid or not
#define is_user_valid(%1)			( 1 <= %1 <= g_iMaxPlayers )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && CheckBit( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && CheckBit( g_bIsAlive, %1 ) )

// Version details is in the plugin_init( ) comment block before plugin registration
#define PLUGIN_VERSION	"1.0.0"

// Admin command target (Values between 1 - 32 are for player index)
enum AdminCommandTarget( )
{
	/*
		Admin Command Target: ACT_EVERYONE

		This value is used to execute a certain command on all players
		who can have that certain command executed on
	*/
	ACT_EVERYONE = 0,

	/*
		Admin Command Target: ACT_T

		This value is used to execute a certain command on players in
		the terrorist team that can have that certain command executed
		on
	*/
	ACT_T = 33,

	/*
		Admin Command Target: ACT_CT

		This value is used to execute a certain command on players in
		the counter-terrorist team that can have that certain command
		executed on
	*/
	ACT_CT = 34,

	/*
		Admin Command Target: ACT_SPECTATOR

		This value is used to execute a certain command on players in
		the spectator team that can have that certain command executed
		on
	*/
	ACT_SPECTATOR = 35
};

// Integers
new g_iMaxPlayers;

// Plugin starts!
public plugin_init( )
{
	/* ===========================================================================
		
		---------------------------
		-*- Version Information -*-
		---------------------------

		Version string is divided into three parts:
		A- Major version number -> Major changes, new functions and updates
		B- Minor version number -> Better codes, minor optimisations 
		C- Beta version number -> Brief updates and bug fixes

		- If major version number changes, both minor and beta reset to 0
		- If minor version number changes, only beta resets to 0
		- If beta version number changes, nothing resets

		This plugin supports only AMX Mod X 1.8.2, so compiling this plugin
		with AMX Mod X 1.8.3 compiler will throw serious errors, and I will
		not support it, unless a feature in my plugin requires it!

		-----------------
		-*- Changelog -*-
		-----------------

		v1.0.0 - First release - DATE / DAY (In Development)
		- Basic and most important commands

	=========================================================================== */

	/* ===========================================================================
		
		-----------------
		-*- Todo List -*-
		-----------------

		Todos are marked with 4 different characters with different meaning,
		on every new version, this todo list is removed and probably added to
		the next version changelog, new entries here are based on testing the
		plugin in a test server or suggestions from Jailbreak players

		[ - ] -> Not implemented (Pending)
		[ + ] -> Implemented, completely done and tested
		[ * ] -> Implemented, completely done but not tested
		[ x ] -> Cancelled
		
		Date: N/A - Day: N/A

	=========================================================================== */

	// Register our plugin
	register_plugin( "Admin Commands", PLUGIN_VERSION, "Taurus" );

	// Make servers using this plugin easier to find
	register_cvar( "ac_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "ac_version", PLUGIN_VERSION );

	// Get maximum players (counting purposes :P)
	g_iMaxPlayers = get_maxplayers( );

	// Hamsandwich
	RegisterHam( Ham_Spawn, "player", "fw_Spawn_Post", true );
	RegisterHam( Ham_Killed, "player", "fw_Killed_Pre" );
}

public client_putinserver( id )
{
	// Set bitsum
	SetBit( g_bIsConnected, id );

	// Clear bitsum
	ClearBit( g_bIsAlive, id );
}

public client_disconnect( id )
{
	// Clear bitsum
	ClearBit( g_bIsConnected, id );
	ClearBit( g_bIsAlive, id );
}

public fw_Spawn_Post( id )
{
	// Player is not alive?
	if( !is_user_alive( id ) )
		return;

	// Set bitsum
	SetBit( g_bIsAlive, id );
}

public fw_Killed_Pre( victim_id, attacker_id )
{
	// Victim is not in-game?
	if( !is_user_valid_connected( victim_id ) )
		return;

	// Clear bitsum
	ClearBit( g_bIsAlive, victim_id )
}