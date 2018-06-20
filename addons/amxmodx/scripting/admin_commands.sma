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
#define turn_into_bit(%1)	( 1 << ( %1 ) )

// Bitsums!
#define bit_set(%1,%2)	( %1 |= turn_into_bit( %2 - 1 ) )
#define bit_del(%1,%2)	( %1 &= ~ turn_into_bit( %2 - 1 ) )
#define bit_get(%1,%2)	( %1 & turn_into_bit( %2 - 1 ) )

// Checks whether a player is valid or not
#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bit_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bit_get( g_bIsAlive, %1 ) )

// Version details is in the plugin_init( ) comment block before plugin registration
#define PLUGIN_VERSION	"1.0.6"

// Prefix for the plugin
#define PLUGIN_PREFIX "^1[^4AC^1]"

// Authentication information - Function: GetAuthenticationInfo( )
enum _:AuthenticationInfo( )
{
	AI_NAME = 0,
	AI_AUTHID,
	AI_IP
};

// Admin command target
enum ( )
{
	ACT_ALL = 0,
	ACT_T,
	ACT_CT
};

// Admin command target skip
enum ( )
{
	ACTS_NO = 0,
	ACTS_BOTS,
	ACTS_DEAD,
	ACTS_ALIVE
};

// Integers
new g_iShowActivity;

// Bitsums
new g_bIsConnected;
new g_bIsAlive;
new g_bHasInfiniteNoclip;
new g_bHasInfiniteGodmode;

// Plugin starts!
public plugin_init( )
{
	/* ===========================================================================
		
		---------------------------
		-*- Version Information -*-
		---------------------------

		Version string is divided into three parts:
		A- Major version number -> Major changes, new functions and updates
		B- Minor version number -> Better codes, major optimisations 
		C- Beta version number -> Brief updates and bug fixes

		- If major version number changes, both minor and beta reset to 0
		- If minor version number changes, only beta resets to 0
		- If beta version number changes, nothing resets

		This plugin supports only AMX Mod X 1.8.3, so compiling this plugin
		with AMX Mod X 1.8.2 compiler will throw serious errors, and I will
		not support it!

		-----------------
		-*- Changelog -*-
		-----------------

		v1.0.0 - First release - 29-05-2018 / Tuesday (In Development)
		- Created the basic structure of the plugin
		- Added the command "ac_health"

		v1.0.1 - Beta release - 29-05-2018 / Tuesday (In Development)
		- Added the command "ac_armour" for admins with ADMIN_LEVEL_A access
		- Added the command "ac_noclip" for admins with ADMIN_LEVEL_A access
		- Added the command "ac_godmode" for admins with ADMIN_LEVEL_A access

		v1.0.2 - Beta release - 03-06-2018 / Sunday (In Development)
		- Added the command "ac_money" for admins with ADMIN_LEVEL_A access
		- Updated syntax text for "ac_noclip" and "ac_godmode" commands
		- Updated "amx_show_activity" cvar retrieving method

		v1.0.3 - Beta release - 07-06-2018 / Thursday (In Development)
		- Updated noclip command to be set until disabled
		- Updated godmode command to be set until disabled

		v1.0.4 - Beta release - 08-06-2018 / Friday (In Development)
		- Added the command "ac_revive" for admins with ADMIN_LEVEL_A access
		- Added the command "ac_transfer" for admins with ADMIN_LEVEL_A access
		- Fixed bug with infinite noclip not set immediately
		- Fixed bug with infinite godmode not set immediately
		- Updated 'GetTeamTarget( )' to also skip alive players

		v1.0.5 - Beta release - 19-06-2018 / Tuesday (In Development)
		- Added AMX Mod X 1.8.3 support, now the plugin won't support 1.8.2

		v1.0.6 - Beta release - 20-06-2018 / Wednesday (In Development)
		- Stablised plugin, it will not cause problems with your server
		- Fixed typos in the chat messages

	=========================================================================== */

	/* ===========================================================================
		
		-----------------
		-*- Todo List -*-
		-----------------

		Todos are marked with 4 different characters with different meaning,
		on every new version, this todo list is removed and probably added to
		the next version changelog, new entries here are based on testing the
		plugin in a test server or suggestions from beta testers

		[ - ] -> Not implemented (Pending)
		[ + ] -> Implemented, completely done and tested
		[ * ] -> Implemented, completely done but not tested
		[ x ] -> Cancelled
		
		Date: 29-05-2018 - Day: Tuesday
		[ + ] Add the command "ac_armour" - ADMIN_LEVEL_A (v1.0.1)
		[ + ] Add the command "ac_noclip" - ADMIN_LEVEL_A (v1.0.1)
		[ + ] Add the command "ac_godmode" - ADMIN_LEVEL_A (v1.0.1)
		[ + ] Add the command "ac_money" - ADMIN_LEVEL_A (v1.0.2)

		Date: 07-06-2018 - Day: Thursday
		[ + ] Update noclip command to be set until disabled (v1.0.3)
		[ + ] Update godmode command to be set until disabled (v1.0.3)
		[ + ] Add the command "ac_revive" - ADMIN_LEVEL_A (v1.0.4)
		[ + ] Add the command "ac_transfer" - ADMIN_LEVEL_A (v1.0.4)
		[ x ] Add the command "ac_spectate" - ADMIN_LEVEL_A

		Date: 08-06-2018 - Day: Friday
		[ + ] Fix bug with infinite noclip not set immediately (v1.0.4)
		[ + ] Fix bug with infinite godmode not set immediately (v1.0.4)

		Date: 14-06-2018 - Day: Thursday
		[ - ] Add the command "ac_swap" - ADMIN_LEVEL_A
		[ - ] Add the command "ac_teamswap" - ADMIN_LEVEL_A
		[ - ] Add the command "ac_glow" - ADMIN_LEVEL_A
		[ - ] Add the command "ac_slay" - ADMIN_LEVEL_B
		[ - ] Add the command "ac_autoslay" - ADMIN_LEVEL_B
		[ - ] Add the command "ac_exec" - ADMIN_LEVEL_B
		[ - ] Add the command "ac_restart" - ADMIN_LEVEL_B

	=========================================================================== */

	// Register our plugin
	register_plugin( "Admin Commands", PLUGIN_VERSION, "Taurus" );

	// Make servers using this plugin easier to find
	register_cvar( "ac_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "ac_version", PLUGIN_VERSION );

	// Register dictionary
	register_dictionary_color( "admin_commands.txt" );

	// Console commands
	register_concmd( "ac_health", "ConCmd_Health", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <#HP>" );
	register_concmd( "ac_armour", "ConCmd_Armour", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <#AP>" );
	register_concmd( "ac_money", "ConCmd_Money", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <#Money>" );
	register_concmd( "ac_noclip", "ConCmd_Noclip", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <0 | 1 | 2>" );
	register_concmd( "ac_godmode", "ConCmd_Godmode", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <0 | 1 | 2>" );
	register_concmd( "ac_revive", "ConCmd_Revive", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team>" );
	register_concmd( "ac_transfer", "ConCmd_Transfer", ADMIN_LEVEL_A, "<nick | #user_id | auth_id | @team> <T | CT | SPEC>" );

	// Hamsandwich
	RegisterHamPlayer( Ham_Spawn, "fw_Spawn_Post", true );
	RegisterHamPlayer( Ham_Killed, "fw_Killed_Pre" );
}

public plugin_cfg( )
{
	// Get cvar pointer
	new cvar_show_activity = get_cvar_pointer( "amx_show_activity" );

	// Does not exist?
	if( cvar_show_activity == 0 )
	{
		// Register it
		cvar_show_activity = register_cvar( "amx_show_activity", "2" );

		// Cache it
		g_iShowActivity = get_pcvar_num( cvar_show_activity );
	}
	else
		g_iShowActivity = get_pcvar_num( cvar_show_activity );
}

public client_putinserver( id )
{
	// Set bitsum
	bit_set( g_bIsConnected, id );

	// Clear bitsum
	bit_del( g_bIsAlive, id );
	bit_del( g_bHasInfiniteNoclip, id );
	bit_del( g_bHasInfiniteGodmode, id );
}

public client_disconnected( id )
{
	// Clear bitsum
	bit_del( g_bIsConnected, id );
	bit_del( g_bIsAlive, id );
	bit_del( g_bHasInfiniteNoclip, id );
	bit_del( g_bHasInfiniteGodmode, id );
}

public ConCmd_Health( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szHealth[ 8 ], temp_id, current_health;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szHealth, charsmax( szHealth ) );

	// Regardless of the target, define new health
	new new_health = str_to_num( szHealth );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_DEAD );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Get current player's health
			current_health = get_user_health( temp_id );

			// Update player's health
			set_user_health( temp_id, current_health + new_health );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_ALL_NO_NAME", new_health );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_ALL", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_T_NO_NAME", new_health );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_T", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_CT_NO_NAME", new_health );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_CT", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Get current player's health
		current_health = get_user_health( temp_id );

		// Update player's health
		set_user_health( temp_id, current_health + new_health );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_PLAYER_NO_NAME", new_health, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_HEALTH_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_health, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Gave %d HP to %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Armour( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szArmour[ 8 ], temp_id, current_armour;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szArmour, charsmax( szArmour ) );

	// Regardless of the target, define new armour
	new new_armour = str_to_num( szArmour );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_DEAD );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Get current player's armour
			current_armour = get_user_armor( temp_id );

			// Update player's armour
			set_user_armor( temp_id, current_armour + new_armour );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_ALL_NO_NAME", new_armour );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_ALL", GetAuthenticationInfo( id, AI_NAME ), new_armour );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d AP to ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_armour, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_T_NO_NAME", new_armour );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_T", GetAuthenticationInfo( id, AI_NAME ), new_armour );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d AP to TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_armour, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_CT_NO_NAME", new_armour );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_CT", GetAuthenticationInfo( id, AI_NAME ), new_armour );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d AP to COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_armour, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Get current player's armour
		current_armour = get_user_armor( temp_id );

		// Update player's armour
		set_user_armor( temp_id, current_armour + new_armour );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_PLAYER_NO_NAME", new_armour, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_ARMOUR_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_armour, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Gave %d AP to %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_armour, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Money( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szMoney[ 8 ], temp_id, current_money;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szMoney, charsmax( szMoney ) );

	// Regardless of the target, define new money
	new new_money = str_to_num( szMoney );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_BOTS );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Get current player's money
			current_money = cs_get_user_money( temp_id );

			// Update player's money
			cs_set_user_money( temp_id, current_money + new_money );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_ALL_NO_NAME", new_money );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_ALL", GetAuthenticationInfo( id, AI_NAME ), new_money );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d money to ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_money, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_T_NO_NAME", new_money );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_T", GetAuthenticationInfo( id, AI_NAME ), new_money );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d money to TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_money, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_CT_NO_NAME", new_money );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_CT", GetAuthenticationInfo( id, AI_NAME ), new_money );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d money to COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_money, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Get current player's money
		current_money = cs_get_user_money( temp_id );

		// Update player's money
		cs_set_user_money( temp_id, current_money + new_money );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_PLAYER_NO_NAME", new_money, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_MONEY_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_money, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Gave %d money to %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_money, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Noclip( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szNoclip[ 2 ], temp_id;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szNoclip, charsmax( szNoclip ) );

	// Regardless of the target, define new noclip
	new new_noclip = clamp( str_to_num( szNoclip ), 0, 2 );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_DEAD );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Update player's noclip
			set_user_noclip( temp_id, new_noclip ? 1 : 0 );

			// Should we set infinite noclip?
			if( new_noclip > 1 )
				bit_set( g_bHasInfiniteNoclip, temp_id );
			else
				bit_del( g_bHasInfiniteNoclip, temp_id );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_ALL_NO_NAME", new_noclip );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_ALL", GetAuthenticationInfo( id, AI_NAME ), new_noclip );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set noclip to %d for ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_noclip, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_T_NO_NAME", new_noclip );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_T", GetAuthenticationInfo( id, AI_NAME ), new_noclip );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set noclip to %d for TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_noclip, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_CT_NO_NAME", new_noclip );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_CT", GetAuthenticationInfo( id, AI_NAME ), new_noclip );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set noclip to %d for COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_noclip, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Update player's noclip
		set_user_noclip( temp_id, new_noclip ? 1 : 0 );

		// Should we set infinite noclip?
		if( new_noclip > 1 )
			bit_set( g_bHasInfiniteNoclip, temp_id );
		else
			bit_del( g_bHasInfiniteNoclip, temp_id );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_PLAYER_NO_NAME", new_noclip, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_NOCLIP_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_noclip, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Set noclip to %d for %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_noclip, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Godmode( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szGodmode[ 2 ], temp_id;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szGodmode, charsmax( szGodmode ) );

	// Regardless of the target, define new godmode
	new new_godmode = clamp( str_to_num( szGodmode ), 0, 2 );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_DEAD );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Update player's godmode
			set_user_godmode( temp_id, new_godmode ? 1 : 0 );

			// Should we set infinite godmode?
			if( new_godmode > 1 )
				bit_set( g_bHasInfiniteGodmode, temp_id );
			else
				bit_del( g_bHasInfiniteGodmode, temp_id );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_ALL_NO_NAME", new_godmode );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_ALL", GetAuthenticationInfo( id, AI_NAME ), new_godmode );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set godmode to %d for ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_godmode, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_T_NO_NAME", new_godmode );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_T", GetAuthenticationInfo( id, AI_NAME ), new_godmode );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set godmode to %d for TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_godmode, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_CT_NO_NAME", new_godmode );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_CT", GetAuthenticationInfo( id, AI_NAME ), new_godmode );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Set godmode to %d for COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_godmode, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Update player's godmode
		set_user_godmode( temp_id, new_godmode ? 1 : 0 );

		// Should we set infinite godmode?
		if( new_godmode > 1 )
			bit_set( g_bHasInfiniteGodmode, temp_id );
		else
			bit_del( g_bHasInfiniteGodmode, temp_id );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_PLAYER_NO_NAME", new_godmode, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_GODMODE_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_godmode, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Set godmode to %d for %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_godmode, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Revive( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 2 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], temp_id;
	read_argv( 1, szTarget, charsmax( szTarget ) );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_ALIVE );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Revive target!
			ExecuteHamB( Ham_CS_RoundRespawn, temp_id );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_ALL_NO_NAME" );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_ALL", GetAuthenticationInfo( id, AI_NAME ) );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Revived ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_T_NO_NAME" );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_T", GetAuthenticationInfo( id, AI_NAME ) );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Revived TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_CT_NO_NAME" );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_CT", GetAuthenticationInfo( id, AI_NAME ) );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Revived COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Player is alive? Ignore!
		if( is_user_valid_alive( temp_id ) )
		{
			console_print( id, "%L", id, "CMD_ERROR_ALIVE", GetAuthenticationInfo( temp_id, AI_NAME ) );
			return PLUGIN_HANDLED;
		}

		// Revive target!
		ExecuteHamB( Ham_CS_RoundRespawn, temp_id );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_PLAYER_NO_NAME", GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_REVIVE_PLAYER", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Revived %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public ConCmd_Transfer( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szTeam[ 32 ], temp_id;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szTeam, charsmax( szTeam ) );

	// Regardless of the target, define new team
	new CsTeams:iTeam;

	// What's our argument
	switch( szTeam[ 0 ] )
	{
		// Terrorist?
		case 'T', 't': iTeam = CS_TEAM_T;

		// Counter-Terrorist?
		case 'C', 'c': iTeam = CS_TEAM_CT;

		// Spectator?
		case 'S', 's': iTeam = CS_TEAM_SPECTATOR;

		// Unknown? Unassigned?
		default:
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_TEAM" );
			return PLUGIN_HANDLED;
		}
	}

	// Now let's define team string?
	switch( iTeam )
	{
		// Terrorist?
		case CS_TEAM_T: formatex( szTeam, charsmax( szTeam ), "%L", LANG_SERVER, "MSG_CS_TEAM_T" );

		// Counter-Terrorist?
		case CS_TEAM_CT: formatex( szTeam, charsmax( szTeam ), "%L", LANG_SERVER, "MSG_CS_TEAM_CT" );

		// Spectator?
		case CS_TEAM_SPECTATOR:  formatex( szTeam, charsmax( szTeam ), "%L", LANG_SERVER, "MSG_CS_TEAM_SPECTATOR" );
	}

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ MAX_PLAYERS ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !bit_get( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Set user team
			if( iTeam == CS_TEAM_SPECTATOR )
			{
				// Move player to new team
				cs_set_user_team( temp_id, iTeam );

				// Kill player if alive, spectators are dead :P
				if( bit_get( g_bIsAlive, temp_id ) )
					user_kill( temp_id, 1 );
			}
			else
			{
				// Move player to new team
				cs_set_user_team( temp_id, iTeam );

				// Revive player if alraedy alive, so they get spawned in team spawn
				if( bit_get( g_bIsAlive, temp_id ) )
					ExecuteHamB( Ham_CS_RoundRespawn, temp_id );
			}
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_ALL_NO_NAME", szTeam );
					case 2: client_print_color( 0, print_team_default, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_ALL", GetAuthenticationInfo( id, AI_NAME ), szTeam );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Transferred ALL to %s team (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), szTeam, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_T_NO_NAME", szTeam );
					case 2: client_print_color( 0, print_team_red, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_T", GetAuthenticationInfo( id, AI_NAME ), szTeam );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Transferred TERRORISTS to %s team (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), szTeam, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_CT_NO_NAME", szTeam );
					case 2: client_print_color( 0, print_team_blue, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_CT", GetAuthenticationInfo( id, AI_NAME ), szTeam );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Transferred COUNTER-TERRORISTS to %s team (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), szTeam, iCount );
			}
		}
	}
	else
	{
		// Define a single player target id
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

		// Validate player
		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Set user team
		if( iTeam == CS_TEAM_SPECTATOR )
		{
			// Move player to new team
			cs_set_user_team( temp_id, iTeam );

			// Kill player if alive, spectators are dead :P
			if( bit_get( g_bIsAlive, temp_id ) )
				user_kill( temp_id, 1 );
		}
		else
		{
			// Move player to new team
			cs_set_user_team( temp_id, iTeam );

			// Revive player if alraedy alive, so they get spawned in team spawn
			if( bit_get( g_bIsAlive, temp_id ) )
				ExecuteHamB( Ham_CS_RoundRespawn, temp_id );
		}

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_PLAYER_NO_NAME", GetAuthenticationInfo( temp_id, AI_NAME ), szTeam );
			case 2: client_print_color( 0, temp_id, "%s %L", PLUGIN_PREFIX, LANG_SERVER, "CMD_TRANSFER_PLAYER", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_NAME ), szTeam );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Transferred %s <%s><%s> to %s team", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ), szTeam );
	}

	return PLUGIN_HANDLED;
}

public fw_Spawn_Post( id )
{
	// Player is not alive?
	if( !is_user_alive( id ) )
		return;

	// Set bitsum
	bit_set( g_bIsAlive, id );

	// Reset noclip
	if( bit_get( g_bHasInfiniteNoclip, id ) )
		set_user_noclip( id, 1 );
	else
		set_user_noclip( id, 0 );

	// Reset godmode
	if( bit_get( g_bHasInfiniteGodmode, id ) )
		set_user_godmode( id, 1 );
	else
		set_user_godmode( id, 0 );
}

public fw_Killed_Pre( victim_id, attacker_id )
{
	// Victim is not in-game?
	if( !is_user_valid_connected( victim_id ) )
		return;

	// Clear bitsum
	bit_del( g_bIsAlive, victim_id );
}

GetTeamTarget( szArgument[ ], iPlayers[ MAX_PLAYERS ], &iCount, iSkip = ACTS_NO )
{
	// Declare variables
	new GetPlayersFlags:iFlags, iTargetTeam;

	// Check skip mode
	switch( iSkip )
	{
		case ACTS_NO: iFlags = GetPlayers_MatchTeam;
		case ACTS_BOTS: iFlags = GetPlayers_ExcludeBots | GetPlayers_MatchTeam;
		case ACTS_DEAD: iFlags = GetPlayers_ExcludeDead | GetPlayers_MatchTeam;
		case ACTS_ALIVE: iFlags = GetPlayers_ExcludeAlive | GetPlayers_MatchTeam;
	}

	// Execute command on all players?
	if( equali( szArgument[ 1 ], "ALL", strlen( szArgument[ 1 ] ) ) )
	{
		// Update skip mode
		switch( iSkip )
		{
			case ACTS_NO: iFlags = GetPlayers_None;
			case ACTS_BOTS: iFlags = GetPlayers_ExcludeBots;
			case ACTS_DEAD: iFlags = GetPlayers_ExcludeDead;
			case ACTS_ALIVE: iFlags = GetPlayers_ExcludeAlive;
		}

		// Set target team to ALL!
		iTargetTeam = ACT_ALL;

		// Count all players with skip flags
		get_players_ex( iPlayers, iCount, iFlags );
	}

	// Execute command on terrorists?
	if( equali( szArgument[ 1 ], "TERRORIST", strlen( szArgument[ 1 ] ) ) )
	{
		// Set target team to TERRORISTS
		iTargetTeam = ACT_T;

		// Count all players in terrorist team with skip flags
		get_players_ex( iPlayers, iCount, iFlags, "TERRORIST" );
	}

	// Execute command on COUNTER-TERRORISTS
	if( equali( szArgument[ 1 ], "CT", strlen( szArgument[ 1 ] ) ) )
	{
		// Set target team to COUNTER-TERRORISTS
		iTargetTeam = ACT_CT;

		// Count all players in counter-terrorist team with skip flags
		get_players_ex( iPlayers, iCount, iFlags, "CT" );
	}

	// Return target team value
	return iTargetTeam;
}

// Formats a string to player authentication information as defined
GetAuthenticationInfo( id, iAuthenticationInfo )
{
	// Declare a variable
	static szAuthenticationInfo[ 32 ];

	// What is the authentication info defined?
	switch( iAuthenticationInfo )
	{
		// Get player's name
		case AI_NAME: get_user_name( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ) );

		// Get player's authentication id
		case AI_AUTHID: get_user_authid( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ) );

		// Get player's IP without port
		case AI_IP: get_user_ip( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ), true );
	}

	// Return our formatted string
	return szAuthenticationInfo;
}

// Formats a message and logs into a file designed for events of this plugin
Log( const szFormat[ ], any:... )
{
	// Declare and define some variables
	static szMessage[ 256 ], szDate[ 16 ], szFileName[ 32 ];
	vformat( szMessage, charsmax( szMessage ), szFormat, 2 );
	format_time( szDate, charsmax( szDate ), "%Y-%m-%d" );
	formatex( szFileName, charsmax( szFileName ), "AC_%s.log", szDate );

	// Log our message to the file! :)
	log_to_file( szFileName, "%s", szMessage );
}

// Registers a coloured dictionary
register_dictionary_color( const szFileName[ ] )
{
	// Could not register dictionary with this file name
	if( !register_dictionary( szFileName ) )
		return false;

	// Format language directory
	new szData[ 128 ];
	get_localinfo( "amxx_datadir", szData, charsmax( szData ) );
	format( szData, charsmax( szData ), "%s/lang/%s", szData, szFileName );

	// Open up our file
	new iFile = fopen( szData, "rt" );

	// Could not open our file!
	if( !iFile )
	{
		log_amx( "[AMXX] Failed to open file: %s", szData );
		return false;
	}

	// Declare some variables that will be useful soon!
	new TransKey:iKey, buffer[ 512 ], szLanguage[ 3 ], szKey[ 64 ], szTranslation[ 256 ];

	// Read our file until the end line by line!
	while( iFile && !feof( iFile ) )
	{
		// Get file file's lines and trim spaces
		fgets( iFile, buffer, charsmax( buffer ) );
		trim( buffer );

		// If it is a language key section see what is it! Otherwise see translations
		if( buffer[ 0 ] == '[' )
			strtok( buffer[ 1 ], szLanguage, charsmax( szLanguage ), buffer, 1, ']' );
		else if( buffer[ 0 ] )
		{
			// strbreak( buffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );
			argbreak( buffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );

			iKey = GetLangTransKey( szKey );

			if( iKey != TransKey_Bad )
			{
				// Replace colour tags by colour codes
				while( replace( szTranslation, charsmax( szTranslation ), "!g", "^4" ) ) { /* Keep Looping! */ }
				while( replace( szTranslation, charsmax( szTranslation ), "!t", "^3" ) ) { /* Keep Looping! */ }
				while( replace( szTranslation, charsmax( szTranslation ), "!n", "^1" ) ) { /* Keep Looping! */ }

				// Add translation
				AddTranslation( szLanguage, iKey, szTranslation[ 2 ] );
			}
		}
	}

	// Close file after we finish translation and colourisation
	fclose( iFile );
	return true;
}